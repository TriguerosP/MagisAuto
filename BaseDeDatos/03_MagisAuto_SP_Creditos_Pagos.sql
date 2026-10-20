USE MagisAuto;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER FUNCTION dbo.fn_Parametro (@Codigo VARCHAR(30))
RETURNS DECIMAL(12,4)
AS
BEGIN
    RETURN (SELECT Valor FROM dbo.Parametro WHERE Codigo = @Codigo);
END
GO

CREATE OR ALTER VIEW dbo.vw_Credito
AS
SELECT cr.CreditoId, cr.NumeroObligacion,
       cr.ClienteId, p.DPI, p.NIT, p.Nombres + ' ' + p.Apellidos AS Cliente,
       cr.VIN, m.Nombre AS Marca, v.Linea, v.Anio, v.Placa,
       cr.VendedorId, ve.CodigoEmpleado, ve.Nombres + ' ' + ve.Apellidos AS Vendedor,
       a.Nombre AS Agencia, a.Region,
       cr.FechaAprobacion, cr.PlazoMeses, cr.PrecioContado, cr.Enganche, cr.MontoFinanciado,
       cr.TasaInteresAnual, cr.PorcentajeComision,
       cr.CuotaNivelada, cr.ManejoCuenta, cr.SeguroAuto, cr.SeguroVida,
       cr.CuotaNivelada + cr.ManejoCuenta + cr.SeguroAuto + cr.SeguroVida AS CuotaMensualTotal,
       cr.TotalIntereses, cr.TotalRecaudable,
       cr.PorcentajeDepreciacion,
       CAST(ROUND(cr.PrecioContado * (1 - cr.PorcentajeDepreciacion / 100), 2) AS DECIMAL(12,2)) AS ValorDespuesRodaje,
       ISNULL(r.CuotasPagadas, 0)    AS CuotasPagadas,
       ISNULL(r.CuotasVencidas, 0)   AS CuotasVencidas,
       ISNULL(r.TotalPagado, 0)      AS TotalPagado,
       ISNULL(r.SaldoPendiente, 0)   AS SaldoPendiente,
       ISNULL(r.CapitalPendiente, 0) AS CapitalPendiente,
       ISNULL(r.DiasAtraso, 0)       AS DiasAtraso,
       (SELECT COUNT(*) FROM dbo.CreditoFiador cf WHERE cf.CreditoId = cr.CreditoId) AS Fiadores,
       cr.Estado, cr.FechaRegistro
FROM dbo.Credito cr
JOIN dbo.Cliente  c  ON c.ClienteId   = cr.ClienteId
JOIN dbo.Persona  p  ON p.PersonaId   = c.PersonaId
JOIN dbo.Vehiculo v  ON v.VIN         = cr.VIN
JOIN dbo.Marca    m  ON m.MarcaId     = v.MarcaId
JOIN dbo.Vendedor ve ON ve.VendedorId = cr.VendedorId
JOIN dbo.Agencia  a  ON a.AgenciaId   = ve.AgenciaId
OUTER APPLY (
    SELECT SUM(CASE WHEN q.Estado = 'PAGADA' THEN 1 ELSE 0 END) AS CuotasPagadas,
           SUM(CASE WHEN q.Estado <> 'PAGADA' AND q.FechaVencimiento < CAST(GETDATE() AS DATE) THEN 1 ELSE 0 END) AS CuotasVencidas,
           SUM(q.MontoPagado) AS TotalPagado,
           SUM(q.TotalCuota - q.MontoPagado) AS SaldoPendiente,
           SUM(CASE WHEN q.Estado <> 'PAGADA' THEN q.Capital ELSE 0 END) AS CapitalPendiente,
           MAX(CASE WHEN q.Estado <> 'PAGADA' AND q.FechaVencimiento < CAST(GETDATE() AS DATE)
                    THEN DATEDIFF(DAY, q.FechaVencimiento, CAST(GETDATE() AS DATE)) ELSE 0 END) AS DiasAtraso
    FROM dbo.Cuota q
    WHERE q.CreditoId = cr.CreditoId
) r;
GO

CREATE OR ALTER VIEW dbo.vw_Cuota
AS
SELECT q.CuotaId, q.CreditoId, cr.NumeroObligacion, cr.ClienteId,
       p.Nombres + ' ' + p.Apellidos AS Cliente,
       q.NumeroCuota, q.FechaVencimiento, q.SaldoInicial,
       q.Capital, q.Interes, q.ManejoCuenta, q.SeguroAuto, q.SeguroVida,
       q.TotalCuota, q.SaldoFinal, q.MontoPagado,
       q.TotalCuota - q.MontoPagado AS SaldoCuota,
       q.Estado, q.FechaCancelacion,
       CASE WHEN q.Estado <> 'PAGADA' AND q.FechaVencimiento < CAST(GETDATE() AS DATE)
            THEN DATEDIFF(DAY, q.FechaVencimiento, CAST(GETDATE() AS DATE)) ELSE 0 END AS DiasAtraso
FROM dbo.Cuota q
JOIN dbo.Credito cr ON cr.CreditoId = q.CreditoId
JOIN dbo.Cliente c  ON c.ClienteId  = cr.ClienteId
JOIN dbo.Persona p  ON p.PersonaId  = c.PersonaId;
GO

CREATE OR ALTER VIEW dbo.vw_TransaccionPago
AS
SELECT tp.TransaccionId, tp.NumeroRecibo, tp.FechaHora, tp.Monto,
       tp.MedioPagoId, mp.Codigo AS CodigoMedioPago, mp.Descripcion AS MedioPago,
       tp.ReferenciaBancaria,
       q.CuotaId, q.NumeroCuota, q.FechaVencimiento,
       cr.CreditoId, cr.NumeroObligacion, cr.ClienteId,
       p.Nombres + ' ' + p.Apellidos AS Cliente,
       cr.VendedorId, ve.Nombres + ' ' + ve.Apellidos AS Vendedor,
       tp.PorcentajeComision, tp.ComisionVendedor, tp.Anulada
FROM dbo.TransaccionPago tp
JOIN dbo.MedioPago mp ON mp.MedioPagoId = tp.MedioPagoId
JOIN dbo.Cuota q      ON q.CuotaId      = tp.CuotaId
JOIN dbo.Credito cr   ON cr.CreditoId   = q.CreditoId
JOIN dbo.Cliente c    ON c.ClienteId    = cr.ClienteId
JOIN dbo.Persona p    ON p.PersonaId    = c.PersonaId
JOIN dbo.Vendedor ve  ON ve.VendedorId  = cr.VendedorId;
GO

CREATE OR ALTER VIEW dbo.vw_CreditoFiador
AS
SELECT cf.CreditoId, cr.NumeroObligacion, cr.Estado AS EstadoCredito,
       pc.Nombres + ' ' + pc.Apellidos AS Cliente,
       cf.FiadorId, pf.DPI AS DPIFiador, pf.NIT AS NITFiador,
       pf.Nombres + ' ' + pf.Apellidos AS Fiador, pf.Correo AS CorreoFiador,
       (SELECT STRING_AGG(t.Numero, ', ') FROM dbo.TelefonoPersona t WHERE t.PersonaId = pf.PersonaId) AS TelefonosFiador,
       cf.FechaAsignacion
FROM dbo.CreditoFiador cf
JOIN dbo.Credito cr ON cr.CreditoId = cf.CreditoId
JOIN dbo.Cliente c  ON c.ClienteId  = cr.ClienteId
JOIN dbo.Persona pc ON pc.PersonaId = c.PersonaId
JOIN dbo.Fiador f   ON f.FiadorId   = cf.FiadorId
JOIN dbo.Persona pf ON pf.PersonaId = f.PersonaId;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Credito_GenerarPlan
    @CreditoId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Monto DECIMAL(12,2), @Tasa DECIMAL(5,2), @Plazo SMALLINT, @Fecha DATE,
            @Manejo DECIMAL(8,2), @SegAuto DECIMAL(10,2), @SegVida DECIMAL(10,2);

    SELECT @Monto = MontoFinanciado, @Tasa = TasaInteresAnual, @Plazo = PlazoMeses,
           @Fecha = FechaAprobacion, @Manejo = ManejoCuenta,
           @SegAuto = SeguroAuto, @SegVida = SeguroVida
    FROM dbo.Credito
    WHERE CreditoId = @CreditoId;

    IF @Monto IS NULL
        THROW 50001, 'El crédito no existe.', 1;
    IF EXISTS (SELECT 1 FROM dbo.TransaccionPago tp
               JOIN dbo.Cuota q ON q.CuotaId = tp.CuotaId
               WHERE q.CreditoId = @CreditoId)
        THROW 50001, 'No se puede generar el plan: el crédito ya tiene pagos registrados.', 1;

    DECLARE @i FLOAT = CAST(@Tasa AS FLOAT) / 100.0 / 12.0;
    DECLARE @CuotaNivelada DECIMAL(12,2) =
        ROUND(CAST(@Monto AS FLOAT) * @i / (1.0 - POWER(1.0 + @i, -CAST(@Plazo AS FLOAT))), 2);

    DECLARE @Saldo DECIMAL(12,2) = @Monto,
            @n SMALLINT = 1,
            @Interes DECIMAL(12,2),
            @Capital DECIMAL(12,2);

    BEGIN TRANSACTION;
        DELETE FROM dbo.Cuota WHERE CreditoId = @CreditoId;

        WHILE @n <= @Plazo
        BEGIN
            SET @Interes = ROUND(CAST(@Saldo AS FLOAT) * @i, 2);
            SET @Capital = CASE WHEN @n = @Plazo THEN @Saldo ELSE @CuotaNivelada - @Interes END;
            IF @Capital > @Saldo SET @Capital = @Saldo;

            INSERT INTO dbo.Cuota (CreditoId, NumeroCuota, FechaVencimiento, SaldoInicial,
                                   Capital, Interes, ManejoCuenta, SeguroAuto, SeguroVida)
            VALUES (@CreditoId, @n, DATEADD(MONTH, @n, @Fecha), @Saldo,
                    @Capital, @Interes, @Manejo, @SegAuto, @SegVida);

            SET @Saldo = @Saldo - @Capital;
            SET @n += 1;
        END

        UPDATE cr
           SET CuotaNivelada   = @CuotaNivelada,
               TotalIntereses  = t.Intereses,
               TotalRecaudable = t.Total
        FROM dbo.Credito cr
        CROSS APPLY (SELECT SUM(Interes) AS Intereses, SUM(TotalCuota) AS Total
                     FROM dbo.Cuota WHERE CreditoId = @CreditoId) t
        WHERE cr.CreditoId = @CreditoId;
    COMMIT TRANSACTION;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Credito_Emitir
    @ClienteId           INT,
    @VIN                 CHAR(17),
    @VendedorId          INT,
    @Enganche            DECIMAL(12,2),
    @FechaAprobacion     DATE         = NULL,
    @PlazoMeses          SMALLINT     = NULL,
    @PorcentajeComision  DECIMAL(5,2) = NULL,
    @Fiadores            VARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Msg NVARCHAR(300);
    SET @VIN = UPPER(LTRIM(RTRIM(@VIN)));
    SET @FechaAprobacion    = ISNULL(@FechaAprobacion, CAST(SYSDATETIME() AS DATE));
    SET @PlazoMeses         = ISNULL(@PlazoMeses, CAST(dbo.fn_Parametro('PLAZO_MESES') AS SMALLINT));
    SET @PorcentajeComision = ISNULL(@PorcentajeComision, dbo.fn_Parametro('COMISION_VENDEDOR'));

    DECLARE @PersonaCliente INT, @Referencias INT, @MinReferencias INT;
    SELECT @PersonaCliente = PersonaId FROM dbo.Cliente WHERE ClienteId = @ClienteId AND Activo = 1;
    IF @PersonaCliente IS NULL
        THROW 50001, 'El cliente no existe o está inactivo.', 1;

    SET @MinReferencias = CAST(dbo.fn_Parametro('MIN_REFERENCIAS') AS INT);
    SELECT @Referencias = COUNT(*) FROM dbo.Referencia WHERE ClienteId = @ClienteId AND Activo = 1;
    IF @Referencias < @MinReferencias
    BEGIN
        SET @Msg = CONCAT('El cliente debe tener al menos ', @MinReferencias,
                          ' referencias personales; actualmente tiene ', @Referencias, '.');
        THROW 50001, @Msg, 1;
    END

    DECLARE @ValorAgencia DECIMAL(12,2);
    SELECT @ValorAgencia = ValorAgencia FROM dbo.Vehiculo WHERE VIN = @VIN;
    IF @ValorAgencia IS NULL
        THROW 50001, 'El vehículo no existe.', 1;
    IF EXISTS (SELECT 1 FROM dbo.Credito WHERE VIN = @VIN AND Estado = 'ACTIVO')
        THROW 50001, 'El vehículo ya es garantía de otro crédito activo.', 1;

    IF NOT EXISTS (SELECT 1 FROM dbo.Vendedor WHERE VendedorId = @VendedorId AND Activo = 1)
        THROW 50001, 'El vendedor no existe o está inactivo.', 1;
    IF @Enganche IS NULL OR @Enganche < 0 OR @Enganche >= @ValorAgencia
        THROW 50001, 'El enganche debe ser mayor o igual a cero y menor al valor de agencia del vehículo.', 1;
    IF @PlazoMeses NOT BETWEEN 1 AND 120
        THROW 50001, 'El plazo debe estar entre 1 y 120 meses.', 1;
    IF @PorcentajeComision NOT BETWEEN 0 AND 100
        THROW 50001, 'El porcentaje de comisión debe estar entre 0 y 100.', 1;

    DECLARE @ListaFiadores TABLE (FiadorId INT NULL);
    IF @Fiadores IS NOT NULL
        INSERT INTO @ListaFiadores (FiadorId)
        SELECT DISTINCT TRY_CAST(LTRIM(RTRIM(value)) AS INT)
        FROM STRING_SPLIT(@Fiadores, ',')
        WHERE LTRIM(RTRIM(value)) <> '';

    IF EXISTS (SELECT 1 FROM @ListaFiadores l
               LEFT JOIN dbo.Fiador f ON f.FiadorId = l.FiadorId AND f.Activo = 1
               WHERE f.FiadorId IS NULL)
        THROW 50001, 'Uno o más fiadores no existen o están inactivos.', 1;
    IF EXISTS (SELECT 1 FROM @ListaFiadores l
               JOIN dbo.Fiador f ON f.FiadorId = l.FiadorId
               WHERE f.PersonaId = @PersonaCliente)
        THROW 50001, 'El cliente no puede ser fiador de su propio crédito.', 1;

    DECLARE @Tasa        DECIMAL(5,2)  = dbo.fn_Parametro('TASA_INTERES_ANUAL'),
            @Manejo      DECIMAL(8,2)  = dbo.fn_Parametro('MANEJO_CUENTA'),
            @Deprec      DECIMAL(5,2)  = dbo.fn_Parametro('DEPRECIACION_RODAJE'),
            @PctSegAuto  DECIMAL(12,4) = dbo.fn_Parametro('SEGURO_AUTO_ANUAL'),
            @PctSegVida  DECIMAL(12,4) = dbo.fn_Parametro('SEGURO_VIDA_ANUAL');

    DECLARE @Financiado DECIMAL(12,2) = @ValorAgencia - @Enganche;
    DECLARE @SegAuto    DECIMAL(10,2) = ROUND(@ValorAgencia * @PctSegAuto / 100 / 12, 2);
    DECLARE @SegVida    DECIMAL(10,2) = ROUND(@Financiado  * @PctSegVida / 100 / 12, 2);
    DECLARE @CreditoId  INT;

    BEGIN TRANSACTION;
        INSERT INTO dbo.Credito (ClienteId, VIN, VendedorId, FechaAprobacion, PlazoMeses,
                                 PrecioContado, Enganche, TasaInteresAnual, PorcentajeComision,
                                 PorcentajeDepreciacion, ManejoCuenta, SeguroAuto, SeguroVida)
        VALUES (@ClienteId, @VIN, @VendedorId, @FechaAprobacion, @PlazoMeses,
                @ValorAgencia, @Enganche, @Tasa, @PorcentajeComision,
                @Deprec, @Manejo, @SegAuto, @SegVida);
        SET @CreditoId = SCOPE_IDENTITY();

        INSERT INTO dbo.CreditoFiador (CreditoId, FiadorId)
        SELECT @CreditoId, FiadorId FROM @ListaFiadores;

        INSERT INTO dbo.HistorialValorVehiculo (VIN, Fecha, ValorEstimado, PorcentajeDepreciacion, Concepto)
        VALUES (@VIN, @FechaAprobacion,
                ROUND(@ValorAgencia * (1 - @Deprec / 100), 2), @Deprec,
                'Depreciación por rodaje al salir de la agencia');

        EXEC dbo.sp_Credito_GenerarPlan @CreditoId;
    COMMIT TRANSACTION;

    SELECT * FROM dbo.vw_Credito WHERE CreditoId = @CreditoId;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Credito_Actualizar
    @CreditoId           INT,
    @VendedorId          INT,
    @Enganche            DECIMAL(12,2),
    @PlazoMeses          SMALLINT,
    @PorcentajeComision  DECIMAL(5,2)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Estado VARCHAR(10), @Precio DECIMAL(12,2);
    SELECT @Estado = Estado, @Precio = PrecioContado FROM dbo.Credito WHERE CreditoId = @CreditoId;

    IF @Estado IS NULL
        THROW 50001, 'El crédito no existe.', 1;
    IF @Estado <> 'ACTIVO'
        THROW 50001, 'Solo se pueden modificar créditos activos.', 1;
    IF EXISTS (SELECT 1 FROM dbo.TransaccionPago tp
               JOIN dbo.Cuota q ON q.CuotaId = tp.CuotaId
               WHERE q.CreditoId = @CreditoId)
        THROW 50001, 'El crédito ya tiene pagos registrados y no puede modificarse.', 1;
    IF NOT EXISTS (SELECT 1 FROM dbo.Vendedor WHERE VendedorId = @VendedorId AND Activo = 1)
        THROW 50001, 'El vendedor no existe o está inactivo.', 1;
    IF @Enganche < 0 OR @Enganche >= @Precio
        THROW 50001, 'El enganche debe ser mayor o igual a cero y menor al precio de contado.', 1;
    IF @PlazoMeses NOT BETWEEN 1 AND 120
        THROW 50001, 'El plazo debe estar entre 1 y 120 meses.', 1;
    IF @PorcentajeComision NOT BETWEEN 0 AND 100
        THROW 50001, 'El porcentaje de comisión debe estar entre 0 y 100.', 1;

    DECLARE @PctSegVida DECIMAL(12,4) = dbo.fn_Parametro('SEGURO_VIDA_ANUAL');

    BEGIN TRANSACTION;
        UPDATE dbo.Credito
           SET VendedorId = @VendedorId,
               Enganche = @Enganche,
               PlazoMeses = @PlazoMeses,
               PorcentajeComision = @PorcentajeComision,
               SeguroVida = ROUND((@Precio - @Enganche) * @PctSegVida / 100 / 12, 2)
         WHERE CreditoId = @CreditoId;

        EXEC dbo.sp_Credito_GenerarPlan @CreditoId;
    COMMIT TRANSACTION;

    SELECT 'ACTUALIZADO' AS Resultado, 'Crédito actualizado y plan de pagos regenerado.' AS Mensaje;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Credito_Eliminar
    @CreditoId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @VIN CHAR(17), @Fecha DATE;
    SELECT @VIN = VIN, @Fecha = FechaAprobacion FROM dbo.Credito WHERE CreditoId = @CreditoId;

    IF @VIN IS NULL
        THROW 50001, 'El crédito no existe.', 1;
    IF EXISTS (SELECT 1 FROM dbo.TransaccionPago tp
               JOIN dbo.Cuota q ON q.CuotaId = tp.CuotaId
               WHERE q.CreditoId = @CreditoId)
        THROW 50001, 'No se puede eliminar: el crédito ya tiene pagos registrados.', 1;

    BEGIN TRANSACTION;
        DELETE FROM dbo.CreditoFiador WHERE CreditoId = @CreditoId;
        DELETE FROM dbo.Cuota         WHERE CreditoId = @CreditoId;
        DELETE FROM dbo.HistorialValorVehiculo
         WHERE VIN = @VIN AND Fecha = @Fecha
           AND Concepto = 'Depreciación por rodaje al salir de la agencia';
        DELETE FROM dbo.Credito       WHERE CreditoId = @CreditoId;
    COMMIT TRANSACTION;

    SELECT 'ELIMINADO' AS Resultado, 'Crédito eliminado; el vehículo quedó disponible.' AS Mensaje;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Credito_Listar
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM dbo.vw_Credito ORDER BY CreditoId DESC;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Credito_Buscar
    @CreditoId         INT          = NULL,
    @NumeroObligacion  VARCHAR(12)  = NULL,
    @ClienteId         INT          = NULL,
    @DPI               CHAR(13)     = NULL,
    @Cliente           VARCHAR(160) = NULL,
    @VIN               VARCHAR(17)  = NULL,
    @VendedorId        INT          = NULL,
    @Estado            VARCHAR(10)  = NULL,
    @Desde             DATE         = NULL,
    @Hasta             DATE         = NULL,
    @ConAtraso         BIT          = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT *
    FROM dbo.vw_Credito
    WHERE (@CreditoId        IS NULL OR CreditoId = @CreditoId)
      AND (@NumeroObligacion IS NULL OR NumeroObligacion LIKE '%' + @NumeroObligacion + '%')
      AND (@ClienteId        IS NULL OR ClienteId = @ClienteId)
      AND (@DPI              IS NULL OR DPI = @DPI)
      AND (@Cliente          IS NULL OR Cliente LIKE '%' + @Cliente + '%')
      AND (@VIN              IS NULL OR VIN LIKE '%' + @VIN + '%')
      AND (@VendedorId       IS NULL OR VendedorId = @VendedorId)
      AND (@Estado           IS NULL OR Estado = @Estado)
      AND (@Desde            IS NULL OR FechaAprobacion >= @Desde)
      AND (@Hasta            IS NULL OR FechaAprobacion <= @Hasta)
      AND (@ConAtraso        IS NULL OR @ConAtraso = 0 OR CuotasVencidas > 0)
    ORDER BY CreditoId DESC;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_CreditoFiador_Insertar
    @CreditoId  INT,
    @FiadorId   INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @PersonaCliente INT, @Estado VARCHAR(10);

    SELECT @PersonaCliente = c.PersonaId, @Estado = cr.Estado
    FROM dbo.Credito cr
    JOIN dbo.Cliente c ON c.ClienteId = cr.ClienteId
    WHERE cr.CreditoId = @CreditoId;

    IF @Estado IS NULL
        THROW 50001, 'El crédito no existe.', 1;
    IF @Estado <> 'ACTIVO'
        THROW 50001, 'Solo se pueden asignar fiadores a créditos activos.', 1;
    IF NOT EXISTS (SELECT 1 FROM dbo.Fiador WHERE FiadorId = @FiadorId AND Activo = 1)
        THROW 50001, 'El fiador no existe o está inactivo.', 1;
    IF EXISTS (SELECT 1 FROM dbo.Fiador WHERE FiadorId = @FiadorId AND PersonaId = @PersonaCliente)
        THROW 50001, 'El cliente no puede ser fiador de su propio crédito.', 1;
    IF EXISTS (SELECT 1 FROM dbo.CreditoFiador WHERE CreditoId = @CreditoId AND FiadorId = @FiadorId)
        THROW 50001, 'Ese fiador ya está asignado a este crédito.', 1;

    INSERT INTO dbo.CreditoFiador (CreditoId, FiadorId) VALUES (@CreditoId, @FiadorId);
    SELECT * FROM dbo.vw_CreditoFiador WHERE CreditoId = @CreditoId AND FiadorId = @FiadorId;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_CreditoFiador_Actualizar
    @CreditoId         INT,
    @FiadorIdAnterior  INT,
    @FiadorIdNuevo     INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.CreditoFiador WHERE CreditoId = @CreditoId AND FiadorId = @FiadorIdAnterior)
        THROW 50001, 'El fiador anterior no está asignado a este crédito.', 1;

    BEGIN TRANSACTION;
        DELETE FROM dbo.CreditoFiador WHERE CreditoId = @CreditoId AND FiadorId = @FiadorIdAnterior;
        EXEC dbo.sp_CreditoFiador_Insertar @CreditoId, @FiadorIdNuevo;
    COMMIT TRANSACTION;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_CreditoFiador_Eliminar
    @CreditoId  INT,
    @FiadorId   INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM dbo.CreditoFiador WHERE CreditoId = @CreditoId AND FiadorId = @FiadorId;
    IF @@ROWCOUNT = 0
        THROW 50001, 'Ese fiador no está asignado a este crédito.', 1;

    SELECT 'ELIMINADO' AS Resultado, 'Fiador retirado del crédito.' AS Mensaje;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_CreditoFiador_Listar
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM dbo.vw_CreditoFiador ORDER BY CreditoId, FiadorId;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_CreditoFiador_Buscar
    @CreditoId  INT          = NULL,
    @FiadorId   INT          = NULL,
    @DPIFiador  CHAR(13)     = NULL,
    @Fiador     VARCHAR(160) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT *
    FROM dbo.vw_CreditoFiador
    WHERE (@CreditoId IS NULL OR CreditoId = @CreditoId)
      AND (@FiadorId  IS NULL OR FiadorId = @FiadorId)
      AND (@DPIFiador IS NULL OR DPIFiador = @DPIFiador)
      AND (@Fiador    IS NULL OR Fiador LIKE '%' + @Fiador + '%')
    ORDER BY CreditoId, FiadorId;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Cuota_Generar
    @CreditoId INT
AS
BEGIN
    SET NOCOUNT ON;
    EXEC dbo.sp_Credito_GenerarPlan @CreditoId;
    SELECT * FROM dbo.vw_Cuota WHERE CreditoId = @CreditoId ORDER BY NumeroCuota;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Cuota_Actualizar
    @CuotaId           INT,
    @FechaVencimiento  DATE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Estado VARCHAR(10);
    SELECT @Estado = Estado FROM dbo.Cuota WHERE CuotaId = @CuotaId;

    IF @Estado IS NULL
        THROW 50001, 'La cuota no existe.', 1;
    IF @Estado <> 'PENDIENTE'
        THROW 50001, 'Solo se puede reprogramar una cuota que no tiene pagos.', 1;

    UPDATE dbo.Cuota SET FechaVencimiento = @FechaVencimiento WHERE CuotaId = @CuotaId;
    SELECT 'ACTUALIZADO' AS Resultado, 'Fecha de vencimiento reprogramada.' AS Mensaje;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Cuota_EliminarPlan
    @CreditoId INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.Credito WHERE CreditoId = @CreditoId)
        THROW 50001, 'El crédito no existe.', 1;
    IF EXISTS (SELECT 1 FROM dbo.TransaccionPago tp
               JOIN dbo.Cuota q ON q.CuotaId = tp.CuotaId
               WHERE q.CreditoId = @CreditoId)
        THROW 50001, 'No se puede eliminar el plan: el crédito ya tiene pagos registrados.', 1;

    DELETE FROM dbo.Cuota WHERE CreditoId = @CreditoId;
    SELECT 'ELIMINADO' AS Resultado, 'Plan de pagos eliminado. Use sp_Cuota_Generar para crearlo de nuevo.' AS Mensaje;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Cuota_Listar
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM dbo.vw_Cuota ORDER BY CreditoId, NumeroCuota;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Cuota_Buscar
    @CreditoId         INT          = NULL,
    @NumeroObligacion  VARCHAR(12)  = NULL,
    @ClienteId         INT          = NULL,
    @NumeroCuota       SMALLINT     = NULL,
    @Estado            VARCHAR(10)  = NULL,
    @Desde             DATE         = NULL,
    @Hasta             DATE         = NULL,
    @SoloVencidas      BIT          = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT *
    FROM dbo.vw_Cuota
    WHERE (@CreditoId        IS NULL OR CreditoId = @CreditoId)
      AND (@NumeroObligacion IS NULL OR NumeroObligacion LIKE '%' + @NumeroObligacion + '%')
      AND (@ClienteId        IS NULL OR ClienteId = @ClienteId)
      AND (@NumeroCuota      IS NULL OR NumeroCuota = @NumeroCuota)
      AND (@Estado           IS NULL OR Estado = @Estado)
      AND (@Desde            IS NULL OR FechaVencimiento >= @Desde)
      AND (@Hasta            IS NULL OR FechaVencimiento <= @Hasta)
      AND (@SoloVencidas     IS NULL OR @SoloVencidas = 0 OR DiasAtraso > 0)
    ORDER BY CreditoId, NumeroCuota;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Pago_Registrar
    @CreditoId           INT,
    @NumeroCuota         SMALLINT      = NULL,
    @Monto               DECIMAL(12,2),
    @MedioPagoId         TINYINT,
    @ReferenciaBancaria  VARCHAR(40)   = NULL,
    @FechaHora           DATETIME2(0)  = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Msg NVARCHAR(300), @EstadoCredito VARCHAR(10), @Comision DECIMAL(5,2),
            @RequiereRef BIT, @CuotaId INT, @NumCuota SMALLINT, @SaldoCuota DECIMAL(12,2),
            @TransaccionId INT;

    SET @FechaHora = ISNULL(@FechaHora, SYSDATETIME());
    SET @ReferenciaBancaria = NULLIF(LTRIM(RTRIM(@ReferenciaBancaria)), '');

    SELECT @EstadoCredito = Estado, @Comision = PorcentajeComision
    FROM dbo.Credito WHERE CreditoId = @CreditoId;

    IF @EstadoCredito IS NULL
        THROW 50001, 'El crédito no existe.', 1;
    IF @EstadoCredito <> 'ACTIVO'
        THROW 50001, 'Solo se pueden registrar pagos a créditos activos.', 1;

    SELECT @RequiereRef = RequiereReferencia FROM dbo.MedioPago WHERE MedioPagoId = @MedioPagoId;
    IF @RequiereRef IS NULL
        THROW 50001, 'El medio de pago no existe.', 1;
    IF @RequiereRef = 1 AND @ReferenciaBancaria IS NULL
        THROW 50001, 'Este medio de pago requiere la referencia bancaria (número de autorización o de boleta).', 1;
    IF @Monto IS NULL OR @Monto <= 0
        THROW 50001, 'El monto del pago debe ser mayor a cero.', 1;

    BEGIN TRANSACTION;
        SELECT TOP (1) @CuotaId = CuotaId, @NumCuota = NumeroCuota, @SaldoCuota = TotalCuota - MontoPagado
        FROM dbo.Cuota WITH (UPDLOCK, HOLDLOCK)
        WHERE CreditoId = @CreditoId
          AND Estado <> 'PAGADA'
          AND (@NumeroCuota IS NULL OR NumeroCuota = @NumeroCuota)
        ORDER BY NumeroCuota;

        IF @CuotaId IS NULL
            THROW 50001, 'La cuota indicada no existe o ya está pagada.', 1;
        IF @Monto > @SaldoCuota
        BEGIN
            SET @Msg = CONCAT('El monto excede el saldo de la cuota ', @NumCuota,
                              '. Saldo pendiente: Q', CAST(@SaldoCuota AS VARCHAR(20)), '.');
            THROW 50001, @Msg, 1;
        END

        INSERT INTO dbo.TransaccionPago (CuotaId, FechaHora, Monto, MedioPagoId, ReferenciaBancaria, PorcentajeComision)
        VALUES (@CuotaId, @FechaHora, @Monto, @MedioPagoId, @ReferenciaBancaria, @Comision);
        SET @TransaccionId = SCOPE_IDENTITY();

        UPDATE dbo.Cuota
           SET MontoPagado      = MontoPagado + @Monto,
               Estado           = CASE WHEN MontoPagado + @Monto >= TotalCuota THEN 'PAGADA' ELSE 'PARCIAL' END,
               FechaCancelacion = CASE WHEN MontoPagado + @Monto >= TotalCuota THEN @FechaHora ELSE NULL END
         WHERE CuotaId = @CuotaId;

        IF NOT EXISTS (SELECT 1 FROM dbo.Cuota WHERE CreditoId = @CreditoId AND Estado <> 'PAGADA')
            UPDATE dbo.Credito SET Estado = 'CANCELADO' WHERE CreditoId = @CreditoId;
    COMMIT TRANSACTION;

    SELECT * FROM dbo.vw_TransaccionPago WHERE TransaccionId = @TransaccionId;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Pago_Actualizar
    @TransaccionId       INT,
    @MedioPagoId         TINYINT,
    @ReferenciaBancaria  VARCHAR(40) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Anulada BIT, @RequiereRef BIT;
    SET @ReferenciaBancaria = NULLIF(LTRIM(RTRIM(@ReferenciaBancaria)), '');

    SELECT @Anulada = Anulada FROM dbo.TransaccionPago WHERE TransaccionId = @TransaccionId;
    IF @Anulada IS NULL
        THROW 50001, 'El pago no existe.', 1;
    IF @Anulada = 1
        THROW 50001, 'No se puede modificar un pago anulado.', 1;

    SELECT @RequiereRef = RequiereReferencia FROM dbo.MedioPago WHERE MedioPagoId = @MedioPagoId;
    IF @RequiereRef IS NULL
        THROW 50001, 'El medio de pago no existe.', 1;
    IF @RequiereRef = 1 AND @ReferenciaBancaria IS NULL
        THROW 50001, 'Este medio de pago requiere la referencia bancaria.', 1;

    UPDATE dbo.TransaccionPago
       SET MedioPagoId = @MedioPagoId, ReferenciaBancaria = @ReferenciaBancaria
     WHERE TransaccionId = @TransaccionId;

    SELECT 'ACTUALIZADO' AS Resultado, 'Pago actualizado.' AS Mensaje;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Pago_Eliminar
    @TransaccionId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @CuotaId INT, @Monto DECIMAL(12,2), @Anulada BIT,
            @CreditoId INT, @VIN CHAR(17), @EstadoCredito VARCHAR(10);

    SELECT @CuotaId = tp.CuotaId, @Monto = tp.Monto, @Anulada = tp.Anulada, @CreditoId = q.CreditoId
    FROM dbo.TransaccionPago tp
    JOIN dbo.Cuota q ON q.CuotaId = tp.CuotaId
    WHERE tp.TransaccionId = @TransaccionId;

    IF @CuotaId IS NULL
        THROW 50001, 'El pago no existe.', 1;
    IF @Anulada = 1
        THROW 50001, 'El pago ya estaba anulado.', 1;

    SELECT @VIN = VIN, @EstadoCredito = Estado FROM dbo.Credito WHERE CreditoId = @CreditoId;
    IF @EstadoCredito = 'CANCELADO'
       AND EXISTS (SELECT 1 FROM dbo.Credito WHERE VIN = @VIN AND Estado = 'ACTIVO' AND CreditoId <> @CreditoId)
        THROW 50001, 'No se puede anular: el vehículo ya respalda otro crédito activo.', 1;

    BEGIN TRANSACTION;
        UPDATE dbo.TransaccionPago SET Anulada = 1 WHERE TransaccionId = @TransaccionId;

        UPDATE dbo.Cuota
           SET MontoPagado      = MontoPagado - @Monto,
               Estado           = CASE WHEN MontoPagado - @Monto <= 0 THEN 'PENDIENTE' ELSE 'PARCIAL' END,
               FechaCancelacion = NULL
         WHERE CuotaId = @CuotaId;

        IF @EstadoCredito = 'CANCELADO'
            UPDATE dbo.Credito SET Estado = 'ACTIVO' WHERE CreditoId = @CreditoId;
    COMMIT TRANSACTION;

    SELECT 'ANULADO' AS Resultado, 'Pago anulado; el saldo de la cuota fue restablecido.' AS Mensaje;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Pago_Listar
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM dbo.vw_TransaccionPago ORDER BY FechaHora DESC, TransaccionId DESC;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Pago_Buscar
    @TransaccionId    INT          = NULL,
    @NumeroRecibo     VARCHAR(13)  = NULL,
    @CreditoId        INT          = NULL,
    @ClienteId        INT          = NULL,
    @Cliente          VARCHAR(160) = NULL,
    @MedioPagoId      TINYINT      = NULL,
    @VendedorId       INT          = NULL,
    @Desde            DATE         = NULL,
    @Hasta            DATE         = NULL,
    @IncluirAnulados  BIT          = 0
AS
BEGIN
    SET NOCOUNT ON;
    SELECT *
    FROM dbo.vw_TransaccionPago
    WHERE (@TransaccionId IS NULL OR TransaccionId = @TransaccionId)
      AND (@NumeroRecibo  IS NULL OR NumeroRecibo LIKE '%' + @NumeroRecibo + '%')
      AND (@CreditoId     IS NULL OR CreditoId = @CreditoId)
      AND (@ClienteId     IS NULL OR ClienteId = @ClienteId)
      AND (@Cliente       IS NULL OR Cliente LIKE '%' + @Cliente + '%')
      AND (@MedioPagoId   IS NULL OR MedioPagoId = @MedioPagoId)
      AND (@VendedorId    IS NULL OR VendedorId = @VendedorId)
      AND (@Desde         IS NULL OR CAST(FechaHora AS DATE) >= @Desde)
      AND (@Hasta         IS NULL OR CAST(FechaHora AS DATE) <= @Hasta)
      AND (ISNULL(@IncluirAnulados, 0) = 1 OR Anulada = 0)
    ORDER BY FechaHora DESC, TransaccionId DESC;
END
GO

PRINT 'Procedimientos del Script 03 creados correctamente.';
GO
