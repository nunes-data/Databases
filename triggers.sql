CREATE TRIGGER trg_descontar_lenha_armazem
ON fornada
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @hasError BIT = 0;
    DECLARE @errorMessage NVARCHAR(MAX) = '';
    
    -- Verificar disponibilidade de stock (considerando fallback entre estados)
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN lenha l ON i.codigo_lenha_forn = l.codigo_lenha
        WHERE i.quantidade_lenha > (
            -- Stock total disponível para o mesmo tipo de lenha (ambos estados)
            SELECT ISNULL(SUM(l2.stock_lenha), 0)
            FROM lenha l2
            WHERE l2.codigo_tipo = l.codigo_tipo
        )
    )
    BEGIN
        SET @hasError = 1;
        
        -- Construir mensagem de erro detalhada
        SELECT @errorMessage = @errorMessage + 
               'Stock total insuficiente para tipo de lenha ' + CAST(l.codigo_tipo AS VARCHAR) + 
               '. Stock total disponível: ' + CAST(
                   (SELECT ISNULL(SUM(l2.stock_lenha), 0)
                    FROM lenha l2
                    WHERE l2.codigo_tipo = l.codigo_tipo)
               AS VARCHAR) + 
               ', quantidade requisitada: ' + CAST(i.quantidade_lenha AS VARCHAR) + CHAR(13) + CHAR(10)
        FROM inserted i
        JOIN lenha l ON i.codigo_lenha_forn = l.codigo_lenha
        WHERE i.quantidade_lenha > (
            SELECT ISNULL(SUM(l2.stock_lenha), 0)
            FROM lenha l2
            WHERE l2.codigo_tipo = l.codigo_tipo
        );
        
        RAISERROR('Erro ao inserir fornada: %s', 16, 1, @errorMessage);
        RETURN;
    END;
    
    -- Se o stock for suficiente (considerando fallback), inserir as fornadas e atualizar os stocks
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Inserir as fornadas
        INSERT INTO fornada (
            codigo, data_inicio, data_fim, 
            quantidade_lenha, quantidade_carvao, 
            codigo_lenha_forn, num_serie_forno, codigo_arm
        )
        SELECT 
            codigo, data_inicio, data_fim, 
            quantidade_lenha, quantidade_carvao, 
            codigo_lenha_forn, num_serie_forno, codigo_arm
        FROM inserted;
        
        -- Atualizar os stocks de lenha com lógica de fallback
        DECLARE @codigo_lenha INT, @quantidade_necessaria FLOAT;
        
        DECLARE stock_cursor CURSOR FOR
        SELECT codigo_lenha_forn, quantidade_lenha
        FROM inserted;
        
        OPEN stock_cursor;
        FETCH NEXT FROM stock_cursor INTO @codigo_lenha, @quantidade_necessaria;
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            DECLARE @quantidade_restante FLOAT = @quantidade_necessaria;
            DECLARE @codigo_tipo_atual INT;
            DECLARE @codigo_estado_atual INT;
            
            -- Obter tipo e estado da lenha requisitada
            SELECT @codigo_tipo_atual = codigo_tipo, @codigo_estado_atual = codigo_estado
            FROM lenha 
            WHERE codigo_lenha = @codigo_lenha;
            
            -- Primeiro, tentar descontar do estado específico requisitado
            DECLARE @stock_disponivel FLOAT;
            SELECT @stock_disponivel = stock_lenha
            FROM lenha
            WHERE codigo_lenha = @codigo_lenha;
            
            IF @stock_disponivel >= @quantidade_restante
            BEGIN
                -- Stock suficiente no estado específico
                UPDATE lenha
                SET stock_lenha = stock_lenha - @quantidade_restante
                WHERE codigo_lenha = @codigo_lenha;
                
                SET @quantidade_restante = 0;
            END
            ELSE
            BEGIN
                -- Stock insuficiente no estado específico, usar o que tem
                UPDATE lenha
                SET stock_lenha = 0
                WHERE codigo_lenha = @codigo_lenha;
                
                SET @quantidade_restante = @quantidade_restante - @stock_disponivel;
                
                -- Procurar pelo outro estado do mesmo tipo
                DECLARE @codigo_lenha_alternativo INT;
                SELECT @codigo_lenha_alternativo = codigo_lenha
                FROM lenha
                WHERE codigo_tipo = @codigo_tipo_atual 
                  AND codigo_estado != @codigo_estado_atual
                  AND stock_lenha > 0;
                
                -- Se encontrou alternativo e ainda precisa de quantidade
                IF @codigo_lenha_alternativo IS NOT NULL AND @quantidade_restante > 0
                BEGIN
                    DECLARE @stock_alternativo FLOAT;
                    SELECT @stock_alternativo = stock_lenha
                    FROM lenha
                    WHERE codigo_lenha = @codigo_lenha_alternativo;
                    
                    IF @stock_alternativo >= @quantidade_restante
                    BEGIN
                        -- Stock alternativo suficiente
                        UPDATE lenha
                        SET stock_lenha = stock_lenha - @quantidade_restante
                        WHERE codigo_lenha = @codigo_lenha_alternativo;
                    END
                    ELSE
                    BEGIN
                        -- Usar todo o stock alternativo disponível
                        UPDATE lenha
                        SET stock_lenha = 0
                        WHERE codigo_lenha = @codigo_lenha_alternativo;
                    END
                END
            END
            
            FETCH NEXT FROM stock_cursor INTO @codigo_lenha, @quantidade_necessaria;
        END
        
        CLOSE stock_cursor;
        DEALLOCATE stock_cursor;
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        -- Fechar cursor se ainda estiver aberto
        IF CURSOR_STATUS('global', 'stock_cursor') >= 0
        BEGIN
            CLOSE stock_cursor;
            DEALLOCATE stock_cursor;
        END
            
        DECLARE @errMsg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR('Erro durante a inserção da fornada: %s', 16, 1, @errMsg);
    END CATCH;
END;
GO

CREATE TRIGGER trg_update_firewood_quantities
ON lenha
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    -- Update the total firewood quantity in armazem_recursos
    UPDATE ar
    SET ar.quantidade_lenha = dbo.CalculateTotalFirewoodQuantity()
    FROM armazem_recursos ar
    JOIN recurso r ON ar.codigo_armz_recursos = r.codigo_armz_rec
    WHERE r.codigo IN (SELECT codigo_lenha FROM inserted UNION SELECT codigo_lenha FROM deleted)
END;
GO

CREATE TRIGGER trg_atualizar_stock_carvao
ON fornada
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @hasError BIT = 0;
    DECLARE @errorMessage NVARCHAR(255) = '';
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        IF EXISTS (SELECT 1 FROM inserted WHERE quantidade_carvao IS NOT NULL AND quantidade_carvao > 0)
        BEGIN
            -- Atualizar stock na tabela carvao
            UPDATE c
            SET c.stock = c.stock + i.quantidade_carvao
            FROM carvao c
            JOIN inserted i ON c.codigo_tipo = (
                SELECT l.codigo_tipo 
                FROM lenha l 
                WHERE l.codigo_lenha = i.codigo_lenha_forn
            )
            WHERE i.quantidade_carvao IS NOT NULL
              AND i.quantidade_carvao > 0;
            
            -- Verificar se existe tipo de carvão correspondente
            IF EXISTS (
                SELECT 1 
                FROM inserted i
                LEFT JOIN lenha l ON l.codigo_lenha = i.codigo_lenha_forn
                LEFT JOIN carvao c ON c.codigo_tipo = l.codigo_tipo
                WHERE i.quantidade_carvao IS NOT NULL 
                  AND i.quantidade_carvao > 0
                  AND c.codigo_tipo IS NULL
            )
            BEGIN
                SET @hasError = 1;
                SELECT @errorMessage = @errorMessage + 
                       'Tipo de carvão não encontrado para lenha tipo ' + CAST(l.codigo_tipo AS VARCHAR) + CHAR(13) + CHAR(10)
                FROM inserted i
                JOIN lenha l ON l.codigo_lenha = i.codigo_lenha_forn
                LEFT JOIN carvao c ON c.codigo_tipo = l.codigo_tipo
                WHERE i.quantidade_carvao IS NOT NULL 
                  AND i.quantidade_carvao > 0
                  AND c.codigo_tipo IS NULL;
                
                RAISERROR('Erro ao atualizar stock de carvão: %s', 16, 1, @errorMessage);
                ROLLBACK TRANSACTION;
                RETURN;
            END;
            
            -- Atualizar quantidade_carvao no armazem_carvao com a soma total dos stocks
            -- Primeiro, obter os armazéns afetados
            DECLARE @codigo_arm INT;
            DECLARE arm_cursor CURSOR FOR
            SELECT DISTINCT i.codigo_arm
            FROM inserted i
            WHERE i.quantidade_carvao IS NOT NULL
              AND i.quantidade_carvao > 0;
            
            OPEN arm_cursor;
            FETCH NEXT FROM arm_cursor INTO @codigo_arm;
            
            WHILE @@FETCH_STATUS = 0
            BEGIN
                -- Atualizar apenas este armazém específico
                UPDATE armazem_carvao
                SET quantidade_carvao = (
                    SELECT ISNULL(SUM(c.stock), 0)
                    FROM carvao c
                )
                WHERE codigo_armz_carvao = @codigo_arm;
                
                FETCH NEXT FROM arm_cursor INTO @codigo_arm;
            END;
            
            CLOSE arm_cursor;
            DEALLOCATE arm_cursor;
        END;
        
        COMMIT TRANSACTION;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        DECLARE @errMsg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR('Erro durante a atualização do stock de carvão: %s', 16, 1, @errMsg);
    END CATCH;
END;
GO
CREATE TRIGGER trg_update_encomenda_total
ON produto_final
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    -- Update the total for encomendas affected by INSERT operations
    UPDATE e
    SET e.valor_total_encomenda = ISNULL((
        SELECT SUM(pf.preco)
        FROM produto_final pf
        WHERE pf.referencia_encom = e.referencia
    ), 0)
    FROM encomenda e
    INNER JOIN inserted i ON e.referencia = i.referencia_encom;
    
    -- Update the total for encomendas affected by DELETE operations
    UPDATE e
    SET e.valor_total_encomenda = ISNULL((
        SELECT SUM(pf.preco)
        FROM produto_final pf
        WHERE pf.referencia_encom = e.referencia
    ), 0)
    FROM encomenda e
    INNER JOIN deleted d ON e.referencia = d.referencia_encom;
END;
GO

CREATE TRIGGER trg_produto_final_insert
ON produto_final
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Temporary table to hold required stock calculations
    DECLARE @RequiredStock TABLE (
        codigo_tipo_carv INT,
        total_needed FLOAT
    );
    
    -- Calculate required carvão for all inserted rows
    INSERT INTO @RequiredStock
    SELECT 
        i.codigo_tipo_carv,
        SUM(i.quantidade * TRY_CAST(
            SUBSTRING(ce.designacao, 1, 
                CASE WHEN CHARINDEX(' ', ce.designacao) > 0 
                     THEN CHARINDEX(' ', ce.designacao) - 1 
                     ELSE LEN(ce.designacao) 
                END) AS FLOAT)) AS total_needed
    FROM inserted i
    JOIN embalagem e ON i.codigo_emb_produto = e.codigo_emb
    JOIN capacidade_emb ce ON e.codigo_capacidade = ce.codigo
    GROUP BY i.codigo_tipo_carv;
    
    -- Check if any carvão type has insufficient stock
    IF EXISTS (
        SELECT 1
        FROM @RequiredStock rs
        JOIN carvao c ON rs.codigo_tipo_carv = c.codigo_tipo
        WHERE c.stock < rs.total_needed
    )
    BEGIN
        RAISERROR('Necessita de produzir mais carvão. Carvão insuficiente para realizar a encomenda', 16, 1);
        RETURN;
    END
    
    -- If all stock is available, perform the insert
    INSERT INTO produto_final (
        codigo_tipo_carv, 
        codigo_emb_produto, 
        referencia_encom, 
        preco_unidade, 
        quantidade, 
        preco
    )
    SELECT 
        codigo_tipo_carv, 
        codigo_emb_produto, 
        referencia_encom, 
        preco_unidade, 
        quantidade, 
        preco
    FROM inserted;
    
    -- Update all carvão stocks
    UPDATE c
    SET stock = c.stock - rs.total_needed
    FROM carvao c
    JOIN @RequiredStock rs ON c.codigo_tipo = rs.codigo_tipo_carv;
END;
GO

CREATE TRIGGER trg_produto_final_update
ON produto_final
INSTEAD OF UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Temporary tables for calculations
    DECLARE @OldValues TABLE (
        codigo_tipo_carv INT,
        codigo_emb_produto INT,
        quantidade INT,
        old_capacity_value FLOAT,
        old_total_needed FLOAT
    );
    
    DECLARE @NewValues TABLE (
        codigo_tipo_carv INT,
        codigo_emb_produto INT,
        quantidade INT,
        new_capacity_value FLOAT,
        new_total_needed FLOAT
    );
    
    DECLARE @StockChanges TABLE (
        codigo_tipo_carv INT,
        stock_change FLOAT
    );
    
    -- Capture old values (before update)
    INSERT INTO @OldValues
    SELECT 
        d.codigo_tipo_carv,
        d.codigo_emb_produto,
        d.quantidade,
        TRY_CAST(
            SUBSTRING(ce.designacao, 1, 
                CASE WHEN CHARINDEX(' ', ce.designacao) > 0 
                     THEN CHARINDEX(' ', ce.designacao) - 1 
                     ELSE LEN(ce.designacao) 
                END) AS FLOAT) AS old_capacity_value,
        d.quantidade * TRY_CAST(
            SUBSTRING(ce.designacao, 1, 
                CASE WHEN CHARINDEX(' ', ce.designacao) > 0 
                     THEN CHARINDEX(' ', ce.designacao) - 1 
                     ELSE LEN(ce.designacao) 
                END) AS FLOAT) AS old_total_needed
    FROM deleted d
    JOIN embalagem e ON d.codigo_emb_produto = e.codigo_emb
    JOIN capacidade_emb ce ON e.codigo_capacidade = ce.codigo;
    
    -- Calculate new values (after update)
    INSERT INTO @NewValues
    SELECT 
        i.codigo_tipo_carv,
        i.codigo_emb_produto,
        i.quantidade,
        TRY_CAST(
            SUBSTRING(ce.designacao, 1, 
                CASE WHEN CHARINDEX(' ', ce.designacao) > 0 
                     THEN CHARINDEX(' ', ce.designacao) - 1 
                     ELSE LEN(ce.designacao) 
                END) AS FLOAT) AS new_capacity_value,
        i.quantidade * TRY_CAST(
            SUBSTRING(ce.designacao, 1, 
                CASE WHEN CHARINDEX(' ', ce.designacao) > 0 
                     THEN CHARINDEX(' ', ce.designacao) - 1 
                     ELSE LEN(ce.designacao) 
                END) AS FLOAT) AS new_total_needed
    FROM inserted i
    JOIN embalagem e ON i.codigo_emb_produto = e.codigo_emb
    JOIN capacidade_emb ce ON e.codigo_capacidade = ce.codigo;
    
    -- Calculate stock changes for each carvão type
    -- For carvão types that were changed FROM (return stock)
    INSERT INTO @StockChanges
    SELECT 
        ov.codigo_tipo_carv,
        ov.old_total_needed AS stock_change
    FROM @OldValues ov
    LEFT JOIN @NewValues nv ON ov.codigo_tipo_carv = nv.codigo_tipo_carv
    WHERE nv.codigo_tipo_carv IS NULL OR ov.codigo_tipo_carv <> nv.codigo_tipo_carv;
    
    -- For carvão types that were changed TO (check availability and deduct)
    INSERT INTO @StockChanges
    SELECT 
        nv.codigo_tipo_carv,
        -nv.new_total_needed AS stock_change
    FROM @NewValues nv
    LEFT JOIN @OldValues ov ON nv.codigo_tipo_carv = ov.codigo_tipo_carv
    WHERE ov.codigo_tipo_carv IS NULL OR nv.codigo_tipo_carv <> ov.codigo_tipo_carv;
    
    -- For carvão types that stayed the same but quantity/capacity changed
    INSERT INTO @StockChanges
    SELECT 
        nv.codigo_tipo_carv,
        (ov.old_total_needed - nv.new_total_needed) AS stock_change
    FROM @NewValues nv
    JOIN @OldValues ov ON nv.codigo_tipo_carv = ov.codigo_tipo_carv
    WHERE nv.codigo_tipo_carv = ov.codigo_tipo_carv;
    
    -- Check if any carvão type would have insufficient stock after changes
    IF EXISTS (
        SELECT 1
        FROM @StockChanges sc
        JOIN carvao c ON sc.codigo_tipo_carv = c.codigo_tipo
        GROUP BY c.codigo_tipo, c.stock
        HAVING c.stock < SUM(-sc.stock_change)
    )
    BEGIN
        RAISERROR('Operação não permitida. Carvão insuficiente para atualizar a encomenda', 16, 1);
        RETURN;
    END
    
    -- Perform the actual update if validation passes
    UPDATE pf
    SET 
        pf.codigo_tipo_carv = i.codigo_tipo_carv,
        pf.codigo_emb_produto = i.codigo_emb_produto,
        pf.referencia_encom = i.referencia_encom,
        pf.preco_unidade = i.preco_unidade,
        pf.quantidade = i.quantidade,
        pf.preco = i.preco
    FROM produto_final pf
    JOIN inserted i ON pf.codigo_tipo_carv = i.codigo_tipo_carv 
                    AND pf.codigo_emb_produto = i.codigo_emb_produto
                    AND pf.referencia_encom = i.referencia_encom;
    
    -- Update carvão stocks
    UPDATE c
    SET c.stock = c.stock + sc.stock_change
    FROM carvao c
    JOIN @StockChanges sc ON c.codigo_tipo = sc.codigo_tipo_carv;
END;
GO

--TODO: A PARTIR DAQUI NÃO SABEMOS SE FUNCIONA!!!!

/*
CREATE TRIGGER trg_preservar_remuneracao
ON empregado
INSTEAD OF DELETE
AS
BEGIN
    -- Verifica se a tabela existe; se não, cria-a
    IF NOT EXISTS (
        SELECT * FROM INFORMATION_SCHEMA.TABLES 
        WHERE TABLE_NAME = 'remuneracoes_empregados_despedidos' AND TABLE_SCHEMA = 'dbo'
    )
    BEGIN
        EXEC('
            CREATE TABLE remuneracoes_empregados_despedidos (
                data_remuneracao DATE NOT NULL,
                nif_empregado_remun INT NOT NULL,
                valor_pago FLOAT NOT NULL,
                horas_pagas FLOAT NOT NULL
            )
        ');
    END;

    -- Insere os dados na tabela de histórico
    INSERT INTO remuneracoes_empregados_despedidos (data_remuneracao, nif_empregado_remun, valor_pago, horas_pagas)
    SELECT data_remuneracao, nif_empregado_remun, valor_pago, horas_pagas
    FROM remuneracao
    WHERE nif_empregado_remun IN (SELECT nif_empregado FROM deleted);

    -- Elimina as remunerações e o empregado
    DELETE FROM remuneracao
    WHERE nif_empregado_remun IN (SELECT nif_empregado FROM deleted);

    DELETE FROM empregado
    WHERE nif_empregado IN (SELECT nif_empregado FROM deleted);
END;


CREATE TRIGGER trg_preservar_fornadas_fornos
ON forno
INSTEAD OF DELETE
AS
BEGIN
    IF NOT EXISTS (
        SELECT * FROM INFORMATION_SCHEMA.TABLES 
        WHERE TABLE_NAME = 'fornadas_forno_removido' AND TABLE_SCHEMA = 'dbo'
    )
    BEGIN
        EXEC('
            CREATE TABLE fornadas_forno_removido (
                codigo INT NOT NULL,
                data_inicio DATE NOT NULL,
                data_fim DATE,
                quantidade_lenha FLOAT NOT NULL,
                quantidade_carvao FLOAT,
                codigo_lenha_forn INT NOT NULL,
                num_serie_forno INT NOT NULL,
                codigo_arm INT NOT NULL
            )
        ');
    END;

    -- Insere as fornadas na tabela de histórico
    INSERT INTO fornadas_forno_removido
    SELECT codigo, data_inicio, data_fim, quantidade_lenha, quantidade_carvao, codigo_lenha_forn, num_serie_forno, codigo_arm
    FROM fornada
    WHERE num_serie_forno IN (SELECT num_serie FROM deleted);

    -- Elimina as fornadas e o forno
    DELETE FROM fornada
    WHERE num_serie_forno IN (SELECT num_serie FROM deleted);

    DELETE FROM forno
    WHERE num_serie IN (SELECT num_serie FROM deleted);
END;*/