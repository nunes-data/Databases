CREATE PROCEDURE sp_GetEmpregados
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        e.nif_empregado,
        p.nome,
        e.remuneracao,
        e.horas_trabalho,
        p.fk2_codigo_empresa
    FROM empregado e
    INNER JOIN pessoa p ON e.nif_empregado = p.nif
    ORDER BY p.nome;
END;
GO

CREATE PROCEDURE sp_GetSeguros
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        apolice,
        data_sub,
        data_vencimento,
        valor,
        nif_emp2
    FROM seguro
    ORDER BY data_vencimento DESC;
END;
GO

CREATE PROCEDURE sp_GetSegurancaSocial
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        niss,
        valor,
        nif_emp,
        data_pagamento_seg_social
    FROM seguranca_social
    ORDER BY data_pagamento_seg_social DESC; -- Optional: order by payment date (most recent first)
END;
GO

CREATE PROCEDURE sp_GetEmpresarioDetails
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        nif_empresario,
        domicilio_fiscal,
        cae
    FROM empresario;
END;
GO

CREATE PROCEDURE sp_UpdateEmpresarioDetails
    @NIF INT,
    @DomicilioFiscal VARCHAR(30),
    @CAE VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE empresario 
    SET 
        domicilio_fiscal = @DomicilioFiscal,
        cae = @CAE
    WHERE nif_empresario = @NIF;
    
    SELECT @@ROWCOUNT AS RowsAffected;
END;
GO

CREATE PROCEDURE sp_InsertSegurancaSocial
    @NISS INT,
    @Valor FLOAT,
    @NIFEmp INT,
    @DataPagamento DATE
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO seguranca_social (niss, valor, nif_emp, data_pagamento_seg_social)
    VALUES (@NISS, @Valor, @NIFEmp, @DataPagamento);
    
    -- Return the number of affected rows
    SELECT @@ROWCOUNT AS RowsAffected;
END;
GO

CREATE PROCEDURE sp_InsertSeguro
    @Apolice INT,
    @DataSubscricao DATE,
    @DataVencimento DATE,
    @Valor FLOAT,
    @NIFEmp INT
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO seguro (apolice, data_sub, data_vencimento, valor, nif_emp2)
    VALUES (@Apolice, @DataSubscricao, @DataVencimento, @Valor, @NIFEmp);
    
    -- Return the number of affected rows
    SELECT @@ROWCOUNT AS RowsAffected;
END;
GO

CREATE PROCEDURE sp_UpdateSegurancaSocial
    @OriginalNISS INT,
    @NewNISS INT,
    @Valor FLOAT,
    @DataPagamento DATE,
    @NIFEmp INT
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE seguranca_social 
    SET 
        niss = @NewNISS,
        valor = @Valor,
        data_pagamento_seg_social = @DataPagamento,
        nif_emp = @NIFEmp
    WHERE niss = @OriginalNISS;
    
    -- Return the number of affected rows
    SELECT @@ROWCOUNT AS RowsAffected;
END;
GO

CREATE PROCEDURE sp_UpdateSeguro
    @OriginalApolice INT,
    @NewApolice INT,
    @DataSubscricao DATE,
    @DataVencimento DATE,
    @Valor FLOAT,
    @NIFEmp INT
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE seguro 
    SET 
        apolice = @NewApolice,
        data_sub = @DataSubscricao,
        data_vencimento = @DataVencimento,
        valor = @Valor,
        nif_emp2 = @NIFEmp
    WHERE apolice = @OriginalApolice;
    
    SELECT @@ROWCOUNT AS RowsAffected;
END;
GO

CREATE PROCEDURE sp_RemoverSegurancaSocial
    @NISS INT,
	@DATE DATE
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        
        DELETE FROM seguranca_social 
        WHERE niss = @NISS AND data_pagamento_seg_social=@DATE;
        
        IF @@ROWCOUNT = 0
        BEGIN
            RAISERROR('Nenhuma entrada de Segurança Social encontrada com o NISS especificado.', 16, 1);
        END
        
        COMMIT TRANSACTION;
        
        -- Explicitly return the number of rows affected
        RETURN @@ROWCOUNT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        RETURN -1; -- Indicate failure
    END CATCH
END;
GO

CREATE PROCEDURE sp_RemoverSeguro
    @Apolice INT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        
        DELETE FROM seguro 
        WHERE apolice = @Apolice;
        
        IF @@ROWCOUNT = 0
        BEGIN
            RAISERROR('Nenhum seguro encontrado com a apólice especificada.', 16, 1);
        END
        
        COMMIT TRANSACTION;
        
        -- Explicitly return the number of rows affected
        RETURN @@ROWCOUNT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        RETURN -1;
    END CATCH
END;
GO

CREATE PROCEDURE sp_GetEmpregadosWithContracts
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        SELECT 
            p.nif, 
            p.nome, 
            c.id_contrato, 
            c.designacao, 
            c.data_inicial, 
            c.data_resc, 
            e.remuneracao, 
            e.horas_trabalho 
        FROM pessoa p 
        JOIN empregado e ON p.nif = e.nif_empregado 
        LEFT JOIN contrato c ON e.nif_empregado = c.nif_empreg
        ORDER BY p.nome;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO

CREATE PROCEDURE sp_UpdateEmpregado
    @OldNIF INT,
    @NovoNIF INT,
    @Nome VARCHAR(20),
    @IdContrato INT,
    @Designacao VARCHAR(30),
    @DataInicial DATE,
    @DataResc DATE
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;

    DECLARE @NIFAlterado BIT = CASE WHEN @NovoNIF != @OldNIF THEN 1 ELSE 0 END;

    IF @NIFAlterado = 1
    BEGIN
        -- Check if new NIF already exists
        IF EXISTS (SELECT 1 FROM pessoa WHERE nif = @NovoNIF)
        BEGIN
            ROLLBACK TRANSACTION;
            RAISERROR('Já existe uma pessoa com este NIF.', 16, 1);
            RETURN;
        END

        -- Get current pessoa record
        DECLARE @Telefone INT, @Email VARCHAR(30), @CodigoEmpresa INT;
        SELECT @Telefone = telefone, @Email = email, @CodigoEmpresa = fk2_codigo_empresa
        FROM pessoa WHERE nif = @OldNIF;

        IF @@ROWCOUNT = 0
        BEGIN
            ROLLBACK TRANSACTION;
            RAISERROR('Pessoa não encontrada.', 16, 1);
            RETURN;
        END

        -- Insert new pessoa record with updated NIF and nome
        INSERT INTO pessoa (nif, nome, telefone, email, fk2_codigo_empresa)
        VALUES (@NovoNIF, @Nome, @Telefone, @Email, @CodigoEmpresa);

        -- Insert new empregado record with new NIF
        DECLARE @Remuneracao FLOAT, @HorasTrabalho FLOAT;
        SELECT @Remuneracao = remuneracao, @HorasTrabalho = horas_trabalho
        FROM empregado WHERE nif_empregado = @OldNIF;

        INSERT INTO empregado (nif_empregado, remuneracao, horas_trabalho)
        VALUES (@NovoNIF, @Remuneracao, @HorasTrabalho);

        -- Update remuneracao to reference the new NIF
        UPDATE remuneracao
        SET nif_empregado_remun = @NovoNIF
        WHERE nif_empregado_remun = @OldNIF;

        -- Update contrato to reference the new NIF
        UPDATE contrato
        SET nif_empreg = @NovoNIF
        WHERE nif_empreg = @OldNIF;

        -- Delete old empregado record
        DELETE FROM empregado WHERE nif_empregado = @OldNIF;

        -- Delete old pessoa record
        DELETE FROM pessoa WHERE nif = @OldNIF;
    END
    ELSE
    BEGIN
        -- Update pessoa without changing NIF
        UPDATE pessoa
        SET nome = @Nome
        WHERE nif = @OldNIF;
    END

    -- Update contrato details
    UPDATE contrato
    SET id_contrato = @IdContrato,
        designacao = @Designacao,
        data_inicial = @DataInicial,
        data_resc = @DataResc
    WHERE nif_empreg = CASE WHEN @NIFAlterado = 1 THEN @NovoNIF ELSE @OldNIF END;

    COMMIT TRANSACTION;
END;
GO

CREATE PROCEDURE sp_GetRemuneracoes
    @NIF INT
AS
BEGIN
    SET NOCOUNT ON;

    -- First result set: individual remuneration records
    SELECT data_remuneracao, nif_empregado_remun, valor_pago, horas_pagas
    FROM remuneracao
    WHERE nif_empregado_remun = @NIF
    ORDER BY data_remuneracao DESC;

    -- Second result set: total hours and total value
    SELECT COALESCE(SUM(horas_pagas), 0) AS TotalHoras, 
           COALESCE(SUM(valor_pago), 0) AS TotalValor
    FROM remuneracao
    WHERE nif_empregado_remun = @NIF;
END;
GO

CREATE PROCEDURE sp_AddRemuneracao
    @DataRemuneracao DATE,
    @NIFEmpregado INT,
    @ValorPago FLOAT,
    @HorasPagas FLOAT
AS
BEGIN
    INSERT INTO remuneracao (data_remuneracao, nif_empregado_remun, valor_pago, horas_pagas)
    VALUES (@DataRemuneracao, @NIFEmpregado, @ValorPago, @HorasPagas);
END;
GO

CREATE PROCEDURE sp_RemoveRemuneracao
    @DataRemuneracao DATE,
    @NIFEmpregado INT
AS
BEGIN
    DELETE FROM remuneracao
    WHERE data_remuneracao = @DataRemuneracao
      AND nif_empregado_remun = @NIFEmpregado;
END;
GO

CREATE PROCEDURE sp_UpdateRemuneracao
    @ValorPago FLOAT,
    @HorasPagas FLOAT,
    @NovaDataRemuneracao DATE,
    @OriginalDataRemuneracao DATE,
    @NIFEmpregado INT
AS
BEGIN
    DECLARE @RowsAffected INT = 0;
    
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM dbo.empregado WHERE nif_empregado = @NIFEmpregado)
        BEGIN
            RAISERROR('Empregado não encontrado.', 16, 1);
            RETURN -1;
        END
        
        -- Validate that the remuneration record exists
        IF NOT EXISTS (SELECT 1 FROM dbo.remuneracao 
                      WHERE data_remuneracao = @OriginalDataRemuneracao 
                      AND nif_empregado_remun = @NIFEmpregado)
        BEGIN
            RAISERROR('Remuneração não encontrada para este empregado na data especificada.', 16, 1);
            RETURN -2;
        END
        
        -- Validate input values
        IF @ValorPago < 0
        BEGIN
            RAISERROR('O valor pago não pode ser negativo.', 16, 1);
            RETURN -3;
        END
        
        IF @HorasPagas < 0
        BEGIN
            RAISERROR('As horas pagas não podem ser negativas.', 16, 1);
            RETURN -4;
        END
        
        -- Check if new date would create a duplicate (if different from original)
        IF @NovaDataRemuneracao != @OriginalDataRemuneracao
        BEGIN
            IF EXISTS (SELECT 1 FROM dbo.remuneracao 
                      WHERE data_remuneracao = @NovaDataRemuneracao 
                      AND nif_empregado_remun = @NIFEmpregado)
            BEGIN
                RAISERROR('Já existe uma remuneração para este empregado na nova data especificada.', 16, 1);
                RETURN -5;
            END
        END
        
        -- Update the remuneration
        UPDATE dbo.remuneracao 
        SET valor_pago = @ValorPago, 
            horas_pagas = @HorasPagas,
            data_remuneracao = @NovaDataRemuneracao
        WHERE data_remuneracao = @OriginalDataRemuneracao 
        AND nif_empregado_remun = @NIFEmpregado;
        
        SET @RowsAffected = @@ROWCOUNT;
        
        -- Return success indicator
        SELECT @RowsAffected as RowsAffected;
        RETURN 0;
        
    END TRY
    BEGIN CATCH
        -- Return error information
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        RETURN -99;
    END CATCH
END;
GO

CREATE PROCEDURE sp_LoadFornos
AS
BEGIN
    
    BEGIN TRY
        -- Select all fornos ordered by num_serie
        SELECT 
            num_serie,
            capacidade_max,
            fk1_codigo_empresa
        FROM forno 
        ORDER BY num_serie;
        
        -- Return success
        RETURN 0;
        
    END TRY
    BEGIN CATCH
        -- Return error information
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        RETURN -1;
    END CATCH
END;
GO

CREATE PROCEDURE sp_GetFornoDetails
    @numSerie INT
AS
BEGIN
    
    BEGIN TRY
        SELECT 
            num_serie,
            capacidade_max,
            fk1_codigo_empresa
        FROM forno 
        WHERE num_serie = @numSerie;
        
    END TRY
    BEGIN CATCH
        -- Return error information
        SELECT 
            ERROR_NUMBER() AS ErrorNumber,
            ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END;
GO

CREATE PROCEDURE sp_CreateNewForno
    @capacidadeMax FLOAT,
    @codigoEmpresa INT,
    @newNumSerie INT OUTPUT,
    @success BIT OUTPUT,
    @errorMessage NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Initialize output parameters
    SET @newNumSerie = 0;
    SET @success = 0;
    SET @errorMessage = '';
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Get the next num_serie
        SELECT @newNumSerie = ISNULL(MAX(num_serie), 0) + 1 
        FROM forno;
        
        -- Validate input parameters
        IF @capacidadeMax <= 0
        BEGIN
            SET @errorMessage = 'Capacidade máxima deve ser maior que zero.';
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        -- Check if empresa exists
        IF NOT EXISTS (SELECT 1 FROM empresa WHERE codigo = @codigoEmpresa)
        BEGIN
            SET @errorMessage = 'Código da empresa não existe.';
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        -- Insert new forno
        INSERT INTO forno (num_serie, capacidade_max, fk1_codigo_empresa)
        VALUES (@newNumSerie, @capacidadeMax, @codigoEmpresa);
        
        -- Check if insert was successful
        IF @@ROWCOUNT > 0
        BEGIN
            SET @success = 1;
            COMMIT TRANSACTION;
        END
        ELSE
        BEGIN
            SET @errorMessage = 'Falha ao inserir o novo forno.';
            ROLLBACK TRANSACTION;
        END
        
    END TRY
    BEGIN CATCH
        -- Handle errors
        SET @errorMessage = ERROR_MESSAGE();
        SET @success = 0;
        
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
    END CATCH
END;
GO

CREATE PROCEDURE sp_RemoveForno
    @numSerie INT,
    @success BIT OUTPUT,
    @errorMessage NVARCHAR(500) OUTPUT,
    @rowsAffected INT OUTPUT
AS
BEGIN
    
    -- Initialize output parameters
    SET @success = 0;
    SET @errorMessage = '';
    SET @rowsAffected = 0;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Check if forno exists
        IF NOT EXISTS (SELECT 1 FROM forno WHERE num_serie = @numSerie)
        BEGIN
            SET @errorMessage = 'Forno não encontrado.';
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        -- Create the deleted fornadas table if it doesn't exist
        IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fornadas_removidas]') AND type in (N'U'))
        BEGIN
            CREATE TABLE fornadas_removidas (
                codigo INT,
                data_inicio DATE NOT NULL,
                data_fim DATE,
                quantidade_lenha FLOAT NOT NULL,
                quantidade_carvao FLOAT,
                codigo_lenha_forn INT NOT NULL,
                num_serie_forno INT NOT NULL,
                codigo_arm INT NOT NULL,
                data_remocao DATETIME NOT NULL DEFAULT GETDATE(),
                motivo_remocao NVARCHAR(100) NOT NULL DEFAULT 'Forno removido',
				PRIMARY KEY (codigo, data_inicio, num_serie_forno)
            );
        END
        
        -- Move fornadas associated with this forno to the deleted table
        INSERT INTO fornadas_removidas (
            codigo, 
            data_inicio, 
            data_fim, 
            quantidade_lenha, 
            quantidade_carvao, 
            codigo_lenha_forn, 
            num_serie_forno, 
            codigo_arm,
            data_remocao,
            motivo_remocao
        )
        SELECT 
            codigo,
            data_inicio,
            data_fim,
            quantidade_lenha,
            quantidade_carvao,
            codigo_lenha_forn,
            num_serie_forno,
            codigo_arm,
            GETDATE(),
            'Forno ' + CAST(@numSerie AS NVARCHAR(10)) + ' removido'
        FROM fornada 
        WHERE num_serie_forno = @numSerie;
        
        -- Store the number of fornadas moved
        DECLARE @fornadasMovidas INT = @@ROWCOUNT;
        
        -- Delete the fornadas from the original table
        DELETE FROM fornada 
        WHERE num_serie_forno = @numSerie;
        
        -- Delete the forno
        DELETE FROM forno 
        WHERE num_serie = @numSerie;
        
        SET @rowsAffected = @@ROWCOUNT;
        
        -- Check if deletion was successful
        IF @rowsAffected > 0
        BEGIN
            SET @success = 1;
            IF @fornadasMovidas > 0
            BEGIN
                SET @errorMessage = CAST(@fornadasMovidas AS NVARCHAR(10)) + ' fornada(s) foram movidas para a tabela de fornadas removidas.';
            END
            COMMIT TRANSACTION;
        END
        ELSE
        BEGIN
            SET @errorMessage = 'Falha ao remover o forno.';
            ROLLBACK TRANSACTION;
        END
        
    END TRY
    BEGIN CATCH
        -- Handle errors
        SET @errorMessage = ERROR_MESSAGE();
        SET @success = 0;
        SET @rowsAffected = 0;
        
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
    END CATCH
END;
GO

CREATE PROCEDURE sp_GetFornadasByForno
    @numSerieForno INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Check if forno exists
        IF NOT EXISTS (SELECT 1 FROM forno WHERE num_serie = @numSerieForno)
        BEGIN
            -- Return empty result set with error information
            SELECT 
                CAST(NULL AS INT) as codigo,
                CAST(NULL AS DATE) as data_inicio,
                CAST(NULL AS DATE) as data_fim,
                CAST(NULL AS FLOAT) as quantidade_lenha,
                CAST(NULL AS FLOAT) as quantidade_carvao,
                CAST(NULL AS INT) as codigo_lenha_forn,
                CAST(NULL AS INT) as num_serie_forno,
                CAST(NULL AS INT) as codigo_arm,
                CAST('Forno não encontrado.' AS VARCHAR(100)) as tipo_lenha,
                CAST('ERROR' AS VARCHAR(100)) as estado_lenha
            WHERE 1 = 0; -- This ensures no rows are returned but maintains the structure
            RETURN;
        END
        
        -- Select fornadas with related information
        SELECT 
            f.codigo,
            f.data_inicio,
            f.data_fim,
            f.quantidade_lenha,
            f.quantidade_carvao,
            f.codigo_lenha_forn,
            f.num_serie_forno,
            f.codigo_arm,
            tl.designacao as tipo_lenha,
            el.designacao as estado_lenha
        FROM fornada f
        INNER JOIN lenha l ON f.codigo_lenha_forn = l.codigo_lenha
        INNER JOIN tipo_lenha tl ON l.codigo_tipo = tl.codigo
        INNER JOIN estado_lenha el ON l.codigo_estado = el.codigo
        WHERE f.num_serie_forno = @numSerieForno
        ORDER BY f.data_inicio DESC;
        
    END TRY
    BEGIN CATCH
        -- Return error information in case of exception
        SELECT 
            ERROR_NUMBER() AS ErrorNumber,
            ERROR_MESSAGE() AS ErrorMessage,
            'ERROR' AS Status;
    END CATCH
END;
GO

CREATE PROCEDURE sp_GetTipoLenhaByCodigoLenha
    @codigoLenha INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        SELECT tl.codigo, tl.designacao 
        FROM tipo_lenha tl
        JOIN lenha l ON tl.codigo = l.codigo_tipo
        WHERE l.codigo_lenha = @codigoLenha;
    END TRY
    BEGIN CATCH
        -- Handle any errors that might occur
        THROW;
    END CATCH
END;
GO

CREATE PROCEDURE sp_GetAllTiposLenha
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        SELECT codigo, designacao 
        FROM tipo_lenha
        ORDER BY designacao; -- Optional: order by designation for better UX
    END TRY
    BEGIN CATCH
        -- Handle any errors that might occur
        THROW;
    END CATCH
END;
GO

CREATE PROCEDURE sp_AdicionarFornada
    @codigoTipoLenha INT,
    @dataInicio DATE,
    @dataFim DATE = NULL,
    @quantidadeLenha FLOAT,
    @quantidadeCarvao FLOAT,
    @numSerieForno INT,
    @codigoArm INT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        
        DECLARE @nextCodigo INT;
        DECLARE @codigoLenha INT;
        DECLARE @result INT = 0;
        
        -- Get the next available codigo for fornada
        SELECT @nextCodigo = ISNULL(MAX(codigo), 0) + 1 FROM fornada;
        
        -- Get the codigo_lenha from the lenha table using tipo_lenha codigo
        SELECT @codigoLenha = codigo_lenha 
        FROM lenha 
        WHERE codigo_tipo = @codigoTipoLenha;
        
        -- Check if codigo_lenha was found
        IF @codigoLenha IS NULL
        BEGIN
            RAISERROR('Não foi possível encontrar o código da lenha para o tipo selecionado.', 16, 1);
            RETURN -1;
        END
        
        -- Insert the new fornada record
        INSERT INTO fornada 
        (codigo, data_inicio, data_fim, quantidade_lenha, quantidade_carvao, 
         codigo_lenha_forn, num_serie_forno, codigo_arm)
        VALUES 
        (@nextCodigo, @dataInicio, @dataFim, @quantidadeLenha, @quantidadeCarvao,
         @codigoLenha, @numSerieForno, @codigoArm);
        
        SET @result = @@ROWCOUNT;
        
        COMMIT TRANSACTION;
        
        -- Return the number of affected rows and the new codigo
        SELECT @result as RowsAffected, @nextCodigo as NewCodigo;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO

CREATE PROCEDURE sp_EditarFornada
    @codigo INT,
    @codigoTipoLenha INT,
    @dataInicio DATE,
    @dataFim DATE = NULL,
    @quantidadeLenha FLOAT,
    @quantidadeCarvao FLOAT
AS
BEGIN
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        DECLARE @codigoLenha INT;
        DECLARE @result INT = 0;
        
        -- Check if the fornada exists
        IF NOT EXISTS (SELECT 1 FROM fornada WHERE codigo = @codigo)
        BEGIN
            RAISERROR('A fornada especificada não existe.', 16, 1);
            RETURN -1;
        END
        
        -- Get the codigo_lenha from the lenha table using tipo_lenha codigo
        SELECT @codigoLenha = codigo_lenha 
        FROM lenha 
        WHERE codigo_tipo = @codigoTipoLenha;
        
        -- Check if codigo_lenha was found
        IF @codigoLenha IS NULL
        BEGIN
            RAISERROR('Não foi possível encontrar o código da lenha para o tipo selecionado.', 16, 1);
            RETURN -2;
        END
        
        -- Update the fornada record
        UPDATE fornada 
        SET data_inicio = @dataInicio,
            data_fim = @dataFim,
            quantidade_lenha = @quantidadeLenha,
            quantidade_carvao = @quantidadeCarvao,
            codigo_lenha_forn = @codigoLenha
        WHERE codigo = @codigo;
        
        SET @result = @@ROWCOUNT;
        
        COMMIT TRANSACTION;
        
        -- Return the number of affected rows
        SELECT @result as RowsAffected;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO

CREATE PROCEDURE sp_RemoverFornada
    @codigo INT
AS
BEGIN
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        DECLARE @result INT = 0;
        
        -- Check if the fornada exists
        IF NOT EXISTS (SELECT 1 FROM fornada WHERE codigo = @codigo)
        BEGIN
            RAISERROR('A fornada especificada não existe.', 16, 1);
            RETURN -1;
        END
        
        -- Delete the fornada record
        DELETE FROM fornada WHERE codigo = @codigo;
        
        SET @result = @@ROWCOUNT;
        
        COMMIT TRANSACTION;
        
        -- Return the number of affected rows
        SELECT @result as RowsAffected;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO

CREATE PROCEDURE sp_GetRendaArmazemRecursos
AS
BEGIN
    -- Set NOCOUNT ON to prevent extra result sets from interfering with SELECT statements
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Select the first renda value from armazem_recursos
        SELECT TOP 1 ISNULL(renda, 0) AS renda 
        FROM armazem_recursos;
    END TRY
    BEGIN CATCH
        -- Handle any errors that might occur
        DECLARE @ErrorMessage NVARCHAR(4000);
        DECLARE @ErrorSeverity INT;
        DECLARE @ErrorState INT;

        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        -- Re-raise the error
        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO

CREATE PROCEDURE sp_GetCapacidadeEmbalagem
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Select all designacao values from capacidade_emb
        SELECT designacao 
        FROM capacidade_emb
        ORDER BY designacao;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000);
        SELECT @ErrorMessage = ERROR_MESSAGE();
        RAISERROR (@ErrorMessage, 16, 1);
    END CATCH
END;
GO

CREATE PROCEDURE sp_GetMaterialEmbalagem
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Select all designacao values from material_emb
        SELECT designacao 
        FROM material_emb
        ORDER BY designacao;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000);
        SELECT @ErrorMessage = ERROR_MESSAGE();
        RAISERROR (@ErrorMessage, 16, 1);
    END CATCH
END;
GO

CREATE PROCEDURE sp_GetTipoLenha
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Select all designacao values from tipo_lenha
        SELECT designacao 
        FROM tipo_lenha
        ORDER BY designacao;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000);
        SELECT @ErrorMessage = ERROR_MESSAGE();
        RAISERROR (@ErrorMessage, 16, 1);
    END CATCH
END;
GO

CREATE PROCEDURE sp_GetStockForLenha
    @designacao VARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Calculate total stock for the specified tipo lenha
        SELECT ISNULL(SUM(l.stock_lenha), 0) as total_stock
        FROM lenha l 
        JOIN tipo_lenha tl ON l.codigo_tipo = tl.codigo 
        WHERE tl.designacao = @designacao;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000);
        SELECT @ErrorMessage = ERROR_MESSAGE();
        RAISERROR (@ErrorMessage, 16, 1);
    END CATCH
END;
GO

CREATE PROCEDURE sp_GetStockForEmbalagem
    @capacidade VARCHAR(30),
    @material VARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Get stock for the specified capacidade and material embalagem
        SELECT ISNULL(e.stock_embalagem, 0) as stock_embalagem
        FROM embalagem e
        JOIN capacidade_emb ce ON e.codigo_capacidade = ce.codigo
        JOIN material_emb me ON e.codigo_material = me.codigo
        WHERE ce.designacao = @capacidade AND me.designacao = @material;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000);
        SELECT @ErrorMessage = ERROR_MESSAGE();
        RAISERROR (@ErrorMessage, 16, 1);
    END CATCH
END;
GO

-- Stored Procedure to get tipo carvao designations
CREATE PROCEDURE sp_GetTipoCarvao
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Select all designacao values from carvao
        SELECT designacao 
        FROM carvao
        ORDER BY designacao;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000);
        SELECT @ErrorMessage = ERROR_MESSAGE();
        RAISERROR (@ErrorMessage, 16, 1);
    END CATCH
END;
GO

-- Stored Procedure to get stock for carvao by designacao
CREATE PROCEDURE sp_GetCarvaoStock
    @designacao VARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Select stock from carvao table where designacao matches
        SELECT ISNULL(stock, 0) AS stock 
        FROM carvao 
        WHERE designacao = @designacao;
        
        -- If no record found, return 0
        IF @@ROWCOUNT = 0
        BEGIN
            SELECT 0 AS stock;
        END
    END TRY
    BEGIN CATCH
        -- Handle any errors that might occur
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO

-- Stored Procedure to get all encomendas data with related information
CREATE PROCEDURE sp_GetEncomendasData
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        SELECT 
            e.referencia,
            e.valor_total_encomenda,
            e.estado_enc,
            hec.data_encomenda,
            hec.nif_cliente_encomenda,
            ee.designacao as estado_designacao
        FROM encomenda e
        INNER JOIN historico_encomenda_cliente hec ON e.referencia = hec.ref_encomenda
        INNER JOIN estado_encomenda ee ON e.estado_enc = ee.codigo_estado
        ORDER BY e.referencia;
    END TRY
    BEGIN CATCH
        -- Handle any errors that might occur
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO

CREATE PROCEDURE sp_GetEstadosEncomenda
AS
BEGIN
    SELECT codigo_estado, designacao 
    FROM estado_encomenda 
    ORDER BY designacao;
END;