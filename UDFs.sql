CREATE FUNCTION dbo.udf_total_custo_lenha()
RETURNS FLOAT
AS
BEGIN
    DECLARE @custo FLOAT;

    SELECT @custo = ISNULL(SUM(preco * stock_lenha), 0)
    FROM lenha;

    RETURN @custo;
END;
GO

CREATE FUNCTION dbo.udf_total_despesas()
RETURNS FLOAT
AS
BEGIN
    RETURN 
        ISNULL((SELECT SUM(valor_pago) FROM remuneracao), 0)
        + dbo.udf_total_custo_lenha() + ISNULL((SELECT valor FROM seguranca_social), 0) + ISNULL((SELECT valor FROM seguro),0);
END;
GO

CREATE FUNCTION dbo.udf_total_faturacao()
RETURNS FLOAT
AS
BEGIN
    RETURN ISNULL((SELECT SUM(valor_total_encomenda) FROM encomenda), 0);
END;
GO

CREATE FUNCTION dbo.udf_lucro()
RETURNS FLOAT
AS
BEGIN
    RETURN dbo.udf_total_faturacao() - dbo.udf_total_despesas();
END;
GO

CREATE FUNCTION dbo.CalculateTotalFirewoodQuantity()
RETURNS FLOAT
AS
BEGIN
    DECLARE @totalQuantity FLOAT
    
    SELECT @totalQuantity = SUM(stock_lenha)
    FROM lenha
    
    RETURN @totalQuantity
END;
GO
