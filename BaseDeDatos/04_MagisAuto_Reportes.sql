USE MagisAuto;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Rpt_Catalogo
AS
BEGIN
    SET NOCOUNT ON;
    SELECT Numero, Nombre, Procedimiento, Parametros, Razon
    FROM (VALUES
    (1,  'Créditos emitidos por período', 'sp_Rpt01_CreditosPorPeriodo', '@Desde, @Hasta',
         'Analiza el volumen de ventas (créditos colocados, montos financiados e intereses a generar) en un período específico.'),
    (2,  'Cartera en mora', 'sp_Rpt02_CarteraMora', '@DiasMinimo, @FechaCorte',
         'Muestra los créditos con cuotas vencidas y sin pagar con X o más días de atraso, para priorizar la gestión de cobro.'),
    (3,  'Pagos por medio de pago', 'sp_Rpt03_PagosPorMedio', '@Desde, @Hasta',
         'Muestra el movimiento de pagos por tipo de pago y determina cuál es el medio de pago más utilizado en un período.'),
    (4,  'Ventas por vendedor', 'sp_Rpt04_VentasPorVendedor', '@Desde, @Hasta',
         'Totaliza los créditos colocados por cada vendedor y los ordena para determinar al mejor vendedor de créditos.'),
    (5,  'Cumpleañeros del mes', 'sp_Rpt05_Cumpleaneros', '@Mes',
         'Lista a los clientes que cumplen años en el mes y genera una carta de felicitación personalizada para cada uno (fidelización).'),
    (6,  'Estado de cuenta por cliente', 'sp_Rpt06_EstadoCuentaCliente', '@ClienteId',
         'Presenta al cliente sus créditos, lo pagado, el saldo pendiente, el atraso y el detalle de cada pago realizado.'),
    (7,  'Plan de pagos por crédito', 'sp_Rpt07_PlanPagos', '@CreditoId',
         'Muestra la tabla de amortización completa con el desglose de cada cuota: interés, capital, manejo de cuenta y seguros.'),
    (8,  'Comisiones de vendedores', 'sp_Rpt08_ComisionesVendedor', '@Desde, @Hasta, @VendedorId',
         'Calcula la comisión que corresponde a cada vendedor sobre los pagos efectivos recibidos en el período (no por adelantado).'),
    (9,  'Costo real vs. depreciación del vehículo', 'sp_Rpt09_CostoRealVsDepreciacion', '@CreditoId',
         'Compara lo que el cliente pagará en total contra el valor que tendrá el vehículo; evidencia el costo real del financiamiento.'),
    (10, 'Proyección de recaudación', 'sp_Rpt10_ProyeccionRecaudacion', '@Desde, @Hasta',
         'Proyecta mes a mes el dinero que se espera recibir de las cuotas pendientes; sirve para planificar el flujo de caja.'),
    (11, 'Intereses devengados', 'sp_Rpt11_InteresesDevengados', '@Desde, @Hasta',
         'Controla los intereses que se generaron por mes, cuánto se cobró y cuánto falta; apoya la auditoría de tasas de interés.'),
    (12, 'Saldos de cartera', 'sp_Rpt12_SaldosCartera', '(ninguno)',
         'Muestra el saldo de capital y el saldo total pendiente de cada crédito activo y el resumen de la cartera por estado.'),
    (13, 'Antigüedad de la mora', 'sp_Rpt13_AntiguedadMora', '@FechaCorte',
         'Clasifica la cartera vencida en rangos de días de atraso (1-30, 31-60, 61-90, más de 90) para medir el riesgo regulatorio.'),
    (14, 'Créditos por marca y línea', 'sp_Rpt14_CreditosPorMarca', '@Desde, @Hasta',
         'Indica qué marcas y líneas de vehículos se financian más; sirve para negociar con las agencias aliadas.'),
    (15, 'Exposición de fiadores', 'sp_Rpt15_ExposicionFiadores', '(ninguno)',
         'Mide cuántos créditos y qué saldo respalda cada fiador, y lista los créditos activos sin fiador (riesgo solo con prenda).'),
    (16, 'Directorio de cobros', 'sp_Rpt16_DirectorioCobros', '@DiasMinimo',
         'Reúne teléfonos y direcciones del cliente moroso, de sus referencias personales y de sus fiadores para localizarlo.'),
    (17, 'Cuotas con abonos parciales', 'sp_Rpt17_CuotasParciales', '(ninguno)',
         'Da seguimiento a las cuotas que recibieron abonos pero aún no se liquidan, con el número de abonos y el último pago.'),
    (18, 'Cierre de caja diario', 'sp_Rpt18_CierreCaja', '@Desde, @Hasta',
         'Totaliza lo recaudado por día y por medio de pago para cuadrar la caja contra los depósitos bancarios.'),
    (19, 'Colocación por agencia y región', 'sp_Rpt19_VentasPorAgencia', '@Desde, @Hasta',
         'Compara el desempeño de cada agencia y región: créditos, monto financiado, cartera vigente y créditos en mora.'),
    (20, 'Puntualidad de clientes', 'sp_Rpt20_PuntualidadClientes', '(ninguno)',
         'Califica a cada cliente según el porcentaje de cuotas pagadas a tiempo; apoya el análisis de riesgo para nuevos créditos.'),
    (21, 'Cuotas por vencer', 'sp_Rpt21_CuotasPorVencer', '@Dias',
         'Lista las cuotas que vencen en los próximos días con los datos de contacto del cliente, para un cobro preventivo.'),
    (22, 'Resumen ejecutivo', 'sp_Rpt22_ResumenEjecutivo', '(ninguno)',
         'Indicadores clave para gerencia: cartera total, cartera vencida, índice de mora, recaudación y colocación del mes.'),
    (23, 'Pagos anulados', 'sp_Rpt23_PagosAnulados', '@Desde, @Hasta',
         'Lista los recibos anulados en el período; es un control de auditoría sobre las correcciones en caja.'),
    (24, 'Simulador de crédito', 'sp_Rpt24_SimuladorCredito', '@PrecioContado, @Enganche, @PlazoMeses, @TasaAnual',
         'Calcula la cuota y el costo total de un crédito antes de solicitarlo; muestra al estudiante cuánto paga de más y cuánto vale el auto al terminar.')
    ) AS r (Numero, Nombre, Procedimiento, Parametros, Razon)
    ORDER BY Numero;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Rpt01_CreditosPorPeriodo
    @Desde DATE,
    @Hasta DATE
AS
BEGIN
    SET NOCOUNT ON;
    SELECT NumeroObligacion, FechaAprobacion, Cliente, DPI, Marca, Linea, Anio, Vendedor, Agencia,
           PrecioContado, Enganche, MontoFinanciado, PlazoMeses, TasaInteresAnual,
           CuotaMensualTotal, TotalIntereses, TotalRecaudable, Estado
    FROM dbo.vw_Credito
    WHERE FechaAprobacion BETWEEN @Desde AND @Hasta
    ORDER BY FechaAprobacion, CreditoId;

    SELECT COUNT(*)                        AS CreditosEmitidos,
           ISNULL(SUM(PrecioContado), 0)   AS TotalVentasVehiculos,
           ISNULL(SUM(Enganche), 0)        AS TotalEnganches,
           ISNULL(SUM(MontoFinanciado), 0) AS TotalFinanciado,
           ISNULL(SUM(TotalIntereses), 0)  AS InteresesAGenerar,
           ISNULL(AVG(MontoFinanciado), 0) AS PromedioFinanciado
    FROM dbo.vw_Credito
    WHERE FechaAprobacion BETWEEN @Desde AND @Hasta;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Rpt02_CarteraMora
    @DiasMinimo  INT  = 1,
    @FechaCorte  DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Corte DATE = ISNULL(@FechaCorte, CAST(GETDATE() AS DATE));

    SELECT q.CreditoId,
           COUNT(*)                          AS CuotasVencidas,
           MIN(q.FechaVencimiento)           AS PrimerVencimiento,
           SUM(q.TotalCuota - q.MontoPagado) AS MontoVencido
    INTO #Mora
    FROM dbo.Cuota q
    JOIN dbo.Credito cr ON cr.CreditoId = q.CreditoId
    WHERE cr.Estado = 'ACTIVO'
      AND q.Estado <> 'PAGADA'
      AND q.FechaVencimiento < @Corte
    GROUP BY q.CreditoId
    HAVING DATEDIFF(DAY, MIN(q.FechaVencimiento), @Corte) >= @DiasMinimo;

    SELECT c.NumeroObligacion, c.Cliente, c.DPI,
           (SELECT STRING_AGG(t.Numero, ', ')
              FROM dbo.Cliente cl
              JOIN dbo.TelefonoPersona t ON t.PersonaId = cl.PersonaId
             WHERE cl.ClienteId = c.ClienteId) AS Telefonos,
           c.Vendedor, c.CuotaMensualTotal,
           m.CuotasVencidas, m.PrimerVencimiento,
           DATEDIFF(DAY, m.PrimerVencimiento, @Corte) AS DiasAtraso,
           m.MontoVencido,
           c.SaldoPendiente AS SaldoTotalCredito
    FROM #Mora m
    JOIN dbo.vw_Credito c ON c.CreditoId = m.CreditoId
    ORDER BY DiasAtraso DESC;

    SELECT COUNT(*)                     AS CreditosEnMora,
           ISNULL(SUM(CuotasVencidas), 0) AS CuotasVencidas,
           ISNULL(SUM(MontoVencido), 0)   AS MontoTotalVencido
    FROM #Mora;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Rpt03_PagosPorMedio
    @Desde DATE,
    @Hasta DATE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Total DECIMAL(14,2);
    SELECT @Total = SUM(Monto)
    FROM dbo.TransaccionPago
    WHERE Anulada = 0 AND CAST(FechaHora AS DATE) BETWEEN @Desde AND @Hasta;

    SELECT RANK() OVER (ORDER BY COUNT(tp.TransaccionId) DESC) AS Ranking,
           mp.Codigo, mp.Descripcion AS MedioPago,
           COUNT(tp.TransaccionId)  AS Transacciones,
           ISNULL(SUM(tp.Monto), 0) AS TotalRecaudado,
           CAST(ISNULL(SUM(tp.Monto), 0) * 100.0 / NULLIF(@Total, 0) AS DECIMAL(5,2)) AS PorcentajeDelTotal
    FROM dbo.MedioPago mp
    LEFT JOIN dbo.TransaccionPago tp
           ON tp.MedioPagoId = mp.MedioPagoId
          AND tp.Anulada = 0
          AND CAST(tp.FechaHora AS DATE) BETWEEN @Desde AND @Hasta
    GROUP BY mp.Codigo, mp.Descripcion
    ORDER BY Ranking, TotalRecaudado DESC;

    SELECT NumeroRecibo, FechaHora, MedioPago, ReferenciaBancaria, Monto,
           NumeroObligacion, Cliente, NumeroCuota
    FROM dbo.vw_TransaccionPago
    WHERE Anulada = 0 AND CAST(FechaHora AS DATE) BETWEEN @Desde AND @Hasta
    ORDER BY MedioPago, FechaHora;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Rpt04_VentasPorVendedor
    @Desde DATE,
    @Hasta DATE
AS
BEGIN
    SET NOCOUNT ON;
    SELECT RANK() OVER (ORDER BY ISNULL(SUM(c.MontoFinanciado), 0) DESC) AS Posicion,
           v.CodigoEmpleado, v.Nombres + ' ' + v.Apellidos AS Vendedor,
           a.Nombre AS Agencia, a.Region,
           COUNT(c.CreditoId)                AS CreditosColocados,
           ISNULL(SUM(c.PrecioContado), 0)   AS TotalVentas,
           ISNULL(SUM(c.MontoFinanciado), 0) AS TotalFinanciado,
           ISNULL(AVG(c.MontoFinanciado), 0) AS PromedioPorCredito
    FROM dbo.Vendedor v
    JOIN dbo.Agencia a ON a.AgenciaId = v.AgenciaId
    LEFT JOIN dbo.Credito c
           ON c.VendedorId = v.VendedorId
          AND c.Estado <> 'ANULADO'
          AND c.FechaAprobacion BETWEEN @Desde AND @Hasta
    GROUP BY v.VendedorId, v.CodigoEmpleado, v.Nombres, v.Apellidos, a.Nombre, a.Region
    ORDER BY Posicion, Vendedor;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Rpt05_Cumpleaneros
    @Mes TINYINT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET @Mes = ISNULL(@Mes, MONTH(GETDATE()));
    IF @Mes NOT BETWEEN 1 AND 12
        THROW 50001, 'El mes debe estar entre 1 y 12.', 1;

    DECLARE @NombreMes VARCHAR(12) = CHOOSE(@Mes, 'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
                                            'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre');
    DECLARE @Anio INT = YEAR(GETDATE());
    DECLARE @Salto CHAR(2) = CHAR(13) + CHAR(10);

    SELECT c.ClienteId, p.Nombres + ' ' + p.Apellidos AS Cliente,
           p.FechaNacimiento, DAY(p.FechaNacimiento) AS Dia,
           @Anio - YEAR(p.FechaNacimiento) AS EdadQueCumple,
           p.Correo,
           (SELECT STRING_AGG(t.Numero, ', ') FROM dbo.TelefonoPersona t WHERE t.PersonaId = p.PersonaId) AS Telefonos,
           CONCAT('Jalapa, ', DAY(p.FechaNacimiento), ' de ', @NombreMes, ' de ', @Anio, @Salto, @Salto,
                  'Estimado(a) ', p.Nombres, ' ', p.Apellidos, ':', @Salto, @Salto,
                  'Reciba un cordial saludo de parte de todo el equipo de MAGIS-AUTO, S.A. ',
                  'En este día tan especial queremos felicitarle por sus ', @Anio - YEAR(p.FechaNacimiento),
                  ' años de vida y agradecerle la confianza que ha depositado en nosotros.', @Salto, @Salto,
                  'Le deseamos que este nuevo año esté lleno de salud, metas cumplidas y decisiones financieras inteligentes.',
                  @Salto, @Salto,
                  '¡Feliz cumpleaños!', @Salto, @Salto,
                  'Atentamente,', @Salto,
                  'Gerencia General', @Salto,
                  'MAGIS-AUTO, S.A. - Crédito Financiero Automotriz') AS Carta
    FROM dbo.Cliente c
    JOIN dbo.Persona p ON p.PersonaId = c.PersonaId
    WHERE c.Activo = 1
      AND MONTH(p.FechaNacimiento) = @Mes
    ORDER BY DAY(p.FechaNacimiento), Cliente;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Rpt06_EstadoCuentaCliente
    @ClienteId INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.Cliente WHERE ClienteId = @ClienteId)
        THROW 50001, 'El cliente no existe.', 1;

    SELECT ClienteId, NombreCompleto AS Cliente, DPI, NIT, Correo, Telefonos,
           CAST(GETDATE() AS DATE) AS FechaEstadoCuenta
    FROM dbo.vw_Cliente
    WHERE ClienteId = @ClienteId;

    SELECT NumeroObligacion, Marca + ' ' + Linea + ' ' + CAST(Anio AS VARCHAR(4)) AS Vehiculo,
           FechaAprobacion, MontoFinanciado, CuotaMensualTotal,
           CONCAT(CuotasPagadas, ' de ', PlazoMeses) AS CuotasPagadas,
           TotalRecaudable, TotalPagado, SaldoPendiente,
           CuotasVencidas, DiasAtraso, Estado
    FROM dbo.vw_Credito
    WHERE ClienteId = @ClienteId
    ORDER BY FechaAprobacion;

    SELECT FechaHora, NumeroRecibo, NumeroObligacion, NumeroCuota,
           MedioPago, ReferenciaBancaria, Monto
    FROM dbo.vw_TransaccionPago
    WHERE ClienteId = @ClienteId AND Anulada = 0
    ORDER BY FechaHora;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Rpt07_PlanPagos
    @CreditoId INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.Credito WHERE CreditoId = @CreditoId)
        THROW 50001, 'El crédito no existe.', 1;

    SELECT NumeroObligacion, Cliente, DPI, Marca, Linea, Anio, VIN,
           FechaAprobacion, PrecioContado, Enganche, MontoFinanciado,
           TasaInteresAnual, PlazoMeses, CuotaNivelada, ManejoCuenta, SeguroAuto, SeguroVida,
           CuotaMensualTotal, TotalIntereses, TotalRecaudable, Estado
    FROM dbo.vw_Credito
    WHERE CreditoId = @CreditoId;

    SELECT NumeroCuota, FechaVencimiento, SaldoInicial, Interes, Capital,
           ManejoCuenta, SeguroAuto, SeguroVida, TotalCuota, SaldoFinal,
           MontoPagado, SaldoCuota, Estado, DiasAtraso
    FROM dbo.vw_Cuota
    WHERE CreditoId = @CreditoId
    ORDER BY NumeroCuota;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Rpt08_ComisionesVendedor
    @Desde       DATE,
    @Hasta       DATE,
    @VendedorId  INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT tp.VendedorId, v.CodigoEmpleado, tp.Vendedor,
           COUNT(*)                 AS PagosRecibidos,
           SUM(tp.Monto)            AS MontoBaseComision,
           SUM(tp.ComisionVendedor) AS ComisionAPagar
    FROM dbo.vw_TransaccionPago tp
    JOIN dbo.Vendedor v ON v.VendedorId = tp.VendedorId
    WHERE tp.Anulada = 0
      AND CAST(tp.FechaHora AS DATE) BETWEEN @Desde AND @Hasta
      AND (@VendedorId IS NULL OR tp.VendedorId = @VendedorId)
    GROUP BY tp.VendedorId, v.CodigoEmpleado, tp.Vendedor
    ORDER BY ComisionAPagar DESC;

    SELECT Vendedor, FechaHora, NumeroRecibo, NumeroObligacion, Cliente, NumeroCuota,
           Monto, PorcentajeComision, ComisionVendedor
    FROM dbo.vw_TransaccionPago
    WHERE Anulada = 0
      AND CAST(FechaHora AS DATE) BETWEEN @Desde AND @Hasta
      AND (@VendedorId IS NULL OR VendedorId = @VendedorId)
    ORDER BY Vendedor, FechaHora;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Rpt09_CostoRealVsDepreciacion
    @CreditoId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @DepAnual FLOAT = CAST(dbo.fn_Parametro('DEPRECIACION_ANUAL') AS FLOAT) / 100.0;

    SELECT x.NumeroObligacion, x.Cliente, x.Marca, x.Linea, x.Anio, x.PlazoMeses,
           x.PrecioContado, x.Enganche, x.MontoFinanciado, x.TotalIntereses,
           x.CostoTotal AS CostoTotalParaCliente,
           x.CostoTotal - x.PrecioContado AS SobrecostoPagado,
           CAST((x.CostoTotal - x.PrecioContado) * 100.0 / x.PrecioContado AS DECIMAL(7,2)) AS PorcentajeSobrecosto,
           x.PorcentajeDepreciacion AS DepreciacionRodajePct,
           x.ValorDespuesRodaje,
           x.ValorAlFinalizar AS ValorEstimadoAlFinalizar,
           x.CostoTotal - x.ValorAlFinalizar AS PerdidaPatrimonial
    FROM (
        SELECT c.*,
               c.Enganche + c.TotalRecaudable AS CostoTotal,
               CAST(ROUND(c.ValorDespuesRodaje * POWER(1.0 - @DepAnual, c.PlazoMeses / 12.0), 2) AS DECIMAL(12,2)) AS ValorAlFinalizar
        FROM dbo.vw_Credito c
        WHERE c.Estado <> 'ANULADO'
          AND (@CreditoId IS NULL OR c.CreditoId = @CreditoId)
    ) x
    ORDER BY PorcentajeSobrecosto DESC;

    SELECT h.VIN, h.Marca, h.Linea, h.Fecha, h.ValorEstimado, h.PerdidaValor,
           h.PorcentajeDepreciacion, h.Concepto
    FROM dbo.vw_HistorialValorVehiculo h
    WHERE h.VIN IN (SELECT VIN FROM dbo.Credito
                    WHERE Estado <> 'ANULADO' AND (@CreditoId IS NULL OR CreditoId = @CreditoId))
    ORDER BY h.VIN, h.Fecha, h.HistorialValorId;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Rpt10_ProyeccionRecaudacion
    @Desde DATE = NULL,
    @Hasta DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET @Desde = ISNULL(@Desde, CAST(GETDATE() AS DATE));
    SET @Hasta = ISNULL(@Hasta, DATEADD(MONTH, 12, @Desde));

    SELECT YEAR(q.FechaVencimiento)  AS Anio,
           MONTH(q.FechaVencimiento) AS Mes,
           COUNT(*)                  AS CuotasPorCobrar,
           SUM(q.Capital)            AS Capital,
           SUM(q.Interes)            AS Intereses,
           SUM(q.ManejoCuenta)       AS ManejoCuenta,
           SUM(q.SeguroAuto + q.SeguroVida)  AS Seguros,
           SUM(q.TotalCuota - q.MontoPagado) AS TotalEsperado
    FROM dbo.Cuota q
    JOIN dbo.Credito cr ON cr.CreditoId = q.CreditoId
    WHERE cr.Estado = 'ACTIVO'
      AND q.Estado <> 'PAGADA'
      AND q.FechaVencimiento BETWEEN @Desde AND @Hasta
    GROUP BY YEAR(q.FechaVencimiento), MONTH(q.FechaVencimiento)
    ORDER BY Anio, Mes;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Rpt11_InteresesDevengados
    @Desde DATE,
    @Hasta DATE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Hoy DATE = CAST(GETDATE() AS DATE);

    SELECT YEAR(q.FechaVencimiento)  AS Anio,
           MONTH(q.FechaVencimiento) AS Mes,
           SUM(q.Interes) AS InteresDevengado,
           SUM(CASE WHEN q.Estado = 'PAGADA'  THEN q.Interes ELSE 0 END) AS InteresCobrado,
           SUM(CASE WHEN q.Estado <> 'PAGADA' THEN q.Interes ELSE 0 END) AS InteresPendiente
    FROM dbo.Cuota q
    JOIN dbo.Credito cr ON cr.CreditoId = q.CreditoId
    WHERE cr.Estado <> 'ANULADO'
      AND q.FechaVencimiento BETWEEN @Desde AND @Hasta
    GROUP BY YEAR(q.FechaVencimiento), MONTH(q.FechaVencimiento)
    ORDER BY Anio, Mes;

    SELECT cr.NumeroObligacion, cr.Cliente, cr.TasaInteresAnual, cr.TotalIntereses,
           SUM(CASE WHEN q.FechaVencimiento <= @Hoy THEN q.Interes ELSE 0 END) AS InteresDevengadoAlDia,
           SUM(CASE WHEN q.FechaVencimiento >  @Hoy THEN q.Interes ELSE 0 END) AS InteresPorDevengar
    FROM dbo.vw_Credito cr
    JOIN dbo.Cuota q ON q.CreditoId = cr.CreditoId
    WHERE cr.Estado = 'ACTIVO'
    GROUP BY cr.CreditoId, cr.NumeroObligacion, cr.Cliente, cr.TasaInteresAnual, cr.TotalIntereses
    ORDER BY cr.NumeroObligacion;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Rpt12_SaldosCartera
AS
BEGIN
    SET NOCOUNT ON;
    SELECT NumeroObligacion, Cliente, FechaAprobacion, MontoFinanciado,
           CapitalPendiente, TotalPagado, SaldoPendiente,
           CONCAT(CuotasPagadas, ' de ', PlazoMeses) AS Avance,
           CAST(CuotasPagadas * 100.0 / PlazoMeses AS DECIMAL(5,2)) AS PorcentajeAvance,
           CuotasVencidas, DiasAtraso
    FROM dbo.vw_Credito
    WHERE Estado = 'ACTIVO'
    ORDER BY SaldoPendiente DESC;

    SELECT Estado,
           COUNT(*)             AS Creditos,
           SUM(MontoFinanciado) AS MontoFinanciado,
           SUM(TotalPagado)     AS TotalPagado,
           SUM(SaldoPendiente)  AS SaldoPendiente
    FROM dbo.vw_Credito
    GROUP BY Estado
    ORDER BY Estado;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Rpt13_AntiguedadMora
    @FechaCorte DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Corte DATE = ISNULL(@FechaCorte, CAST(GETDATE() AS DATE));
    DECLARE @CarteraTotal DECIMAL(14,2);

    SELECT @CarteraTotal = SUM(q.TotalCuota - q.MontoPagado)
    FROM dbo.Cuota q
    JOIN dbo.Credito cr ON cr.CreditoId = q.CreditoId
    WHERE cr.Estado = 'ACTIVO';

    SELECT q.CreditoId,
           DATEDIFF(DAY, MIN(q.FechaVencimiento), @Corte) AS DiasAtraso,
           SUM(q.TotalCuota - q.MontoPagado) AS MontoVencido
    INTO #Mora
    FROM dbo.Cuota q
    JOIN dbo.Credito cr ON cr.CreditoId = q.CreditoId
    WHERE cr.Estado = 'ACTIVO' AND q.Estado <> 'PAGADA' AND q.FechaVencimiento < @Corte
    GROUP BY q.CreditoId;

    SELECT r.Orden, r.Rango,
           COUNT(m.CreditoId)            AS Creditos,
           ISNULL(SUM(m.MontoVencido), 0) AS MontoVencido,
           CAST(ISNULL(SUM(m.MontoVencido), 0) * 100.0 / NULLIF(@CarteraTotal, 0) AS DECIMAL(5,2)) AS PorcentajeDeCartera
    FROM (VALUES (1, '1 a 30 días', 1, 30),
                 (2, '31 a 60 días', 31, 60),
                 (3, '61 a 90 días', 61, 90),
                 (4, 'Más de 90 días', 91, 99999)) AS r (Orden, Rango, Desde, Hasta)
    LEFT JOIN #Mora m ON m.DiasAtraso BETWEEN r.Desde AND r.Hasta
    GROUP BY r.Orden, r.Rango
    ORDER BY r.Orden;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Rpt14_CreditosPorMarca
    @Desde DATE = NULL,
    @Hasta DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT m.CodigoMarca, m.Nombre AS Marca, v.Linea,
           COUNT(*)              AS Creditos,
           SUM(c.PrecioContado)  AS TotalVentas,
           SUM(c.MontoFinanciado) AS TotalFinanciado,
           AVG(c.PrecioContado)  AS PrecioPromedio,
           CAST(AVG(c.Enganche * 100.0 / c.PrecioContado) AS DECIMAL(5,2)) AS EnganchePromedioPct
    FROM dbo.Credito c
    JOIN dbo.Vehiculo v ON v.VIN = c.VIN
    JOIN dbo.Marca m    ON m.MarcaId = v.MarcaId
    WHERE c.Estado <> 'ANULADO'
      AND (@Desde IS NULL OR c.FechaAprobacion >= @Desde)
      AND (@Hasta IS NULL OR c.FechaAprobacion <= @Hasta)
    GROUP BY m.CodigoMarca, m.Nombre, v.Linea
    ORDER BY TotalFinanciado DESC;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Rpt15_ExposicionFiadores
AS
BEGIN
    SET NOCOUNT ON;
    SELECT f.FiadorId, pf.DPI, pf.Nombres + ' ' + pf.Apellidos AS Fiador,
           COUNT(*) AS CreditosRespaldados,
           SUM(CASE WHEN cr.Estado = 'ACTIVO' THEN 1 ELSE 0 END) AS CreditosActivos,
           SUM(CASE WHEN cr.Estado = 'ACTIVO' THEN cr.SaldoPendiente ELSE 0 END) AS SaldoRespaldado,
           SUM(CASE WHEN cr.Estado = 'ACTIVO' AND cr.CuotasVencidas > 0 THEN 1 ELSE 0 END) AS CreditosEnMora
    FROM dbo.CreditoFiador cf
    JOIN dbo.Fiador f       ON f.FiadorId = cf.FiadorId
    JOIN dbo.Persona pf     ON pf.PersonaId = f.PersonaId
    JOIN dbo.vw_Credito cr  ON cr.CreditoId = cf.CreditoId
    GROUP BY f.FiadorId, pf.DPI, pf.Nombres, pf.Apellidos
    ORDER BY SaldoRespaldado DESC;

    SELECT NumeroObligacion, Cliente, MontoFinanciado, SaldoPendiente, CuotasVencidas, DiasAtraso
    FROM dbo.vw_Credito
    WHERE Estado = 'ACTIVO' AND Fiadores = 0
    ORDER BY SaldoPendiente DESC;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Rpt16_DirectorioCobros
    @DiasMinimo INT = 1
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Hoy DATE = CAST(GETDATE() AS DATE);

    SELECT DISTINCT cr.CreditoId, cr.ClienteId
    INTO #Mora
    FROM dbo.Cuota q
    JOIN dbo.Credito cr ON cr.CreditoId = q.CreditoId
    WHERE cr.Estado = 'ACTIVO'
      AND q.Estado <> 'PAGADA'
      AND DATEDIFF(DAY, q.FechaVencimiento, @Hoy) >= @DiasMinimo;

    SELECT c.NumeroObligacion, c.Cliente, c.DPI, p.Correo,
           (SELECT STRING_AGG(t.Numero, ', ') FROM dbo.TelefonoPersona t WHERE t.PersonaId = p.PersonaId) AS Telefonos,
           (SELECT STRING_AGG(d.Direccion + ', ' + d.Municipio + ', ' + d.Departamento, ' | ')
              FROM dbo.DireccionPersona d WHERE d.PersonaId = p.PersonaId) AS Direcciones,
           c.DiasAtraso, c.SaldoPendiente
    FROM #Mora m
    JOIN dbo.vw_Credito c ON c.CreditoId = m.CreditoId
    JOIN dbo.Cliente cl   ON cl.ClienteId = m.ClienteId
    JOIN dbo.Persona p    ON p.PersonaId = cl.PersonaId
    ORDER BY c.DiasAtraso DESC;

    SELECT r.Cliente, r.NombreCompleto AS Referencia, r.Parentesco, r.LugarTrabajo,
           r.Telefonos, r.Direcciones
    FROM dbo.vw_Referencia r
    WHERE r.Activo = 1 AND r.ClienteId IN (SELECT ClienteId FROM #Mora)
    ORDER BY r.Cliente, r.NombreCompleto;

    SELECT NumeroObligacion, Cliente, Fiador, DPIFiador, CorreoFiador, TelefonosFiador
    FROM dbo.vw_CreditoFiador
    WHERE CreditoId IN (SELECT CreditoId FROM #Mora)
    ORDER BY NumeroObligacion;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Rpt17_CuotasParciales
AS
BEGIN
    SET NOCOUNT ON;
    SELECT q.NumeroObligacion, q.Cliente, q.NumeroCuota, q.FechaVencimiento,
           q.TotalCuota, q.MontoPagado, q.SaldoCuota, q.DiasAtraso,
           a.Abonos, a.UltimoAbono
    FROM dbo.vw_Cuota q
    CROSS APPLY (SELECT COUNT(*) AS Abonos, MAX(tp.FechaHora) AS UltimoAbono
                 FROM dbo.TransaccionPago tp
                 WHERE tp.CuotaId = q.CuotaId AND tp.Anulada = 0) a
    WHERE q.Estado = 'PARCIAL'
    ORDER BY q.DiasAtraso DESC, q.NumeroObligacion;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Rpt18_CierreCaja
    @Desde DATE,
    @Hasta DATE
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(tp.FechaHora AS DATE) AS Fecha,
           CASE WHEN GROUPING(mp.Descripcion) = 1 THEN '*** TOTAL DEL DÍA' ELSE mp.Descripcion END AS MedioPago,
           COUNT(*)      AS Transacciones,
           SUM(tp.Monto) AS Total
    FROM dbo.TransaccionPago tp
    JOIN dbo.MedioPago mp ON mp.MedioPagoId = tp.MedioPagoId
    WHERE tp.Anulada = 0
      AND CAST(tp.FechaHora AS DATE) BETWEEN @Desde AND @Hasta
    GROUP BY GROUPING SETS ((CAST(tp.FechaHora AS DATE), mp.Descripcion),
                            (CAST(tp.FechaHora AS DATE)))
    ORDER BY Fecha, GROUPING(mp.Descripcion), MedioPago;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Rpt19_VentasPorAgencia
    @Desde DATE = NULL,
    @Hasta DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT a.Region, a.Nombre AS Agencia,
           (SELECT COUNT(*) FROM dbo.Vendedor x WHERE x.AgenciaId = a.AgenciaId AND x.Activo = 1) AS VendedoresActivos,
           COUNT(c.CreditoId) AS Creditos,
           ISNULL(SUM(c.MontoFinanciado), 0) AS MontoFinanciado,
           ISNULL(SUM(CASE WHEN c.Estado = 'ACTIVO' THEN c.SaldoPendiente END), 0) AS CarteraVigente,
           ISNULL(SUM(CASE WHEN c.Estado = 'ACTIVO' AND c.CuotasVencidas > 0 THEN 1 ELSE 0 END), 0) AS CreditosEnMora
    FROM dbo.Agencia a
    LEFT JOIN dbo.Vendedor v   ON v.AgenciaId = a.AgenciaId
    LEFT JOIN dbo.vw_Credito c ON c.VendedorId = v.VendedorId
                              AND c.Estado <> 'ANULADO'
                              AND (@Desde IS NULL OR c.FechaAprobacion >= @Desde)
                              AND (@Hasta IS NULL OR c.FechaAprobacion <= @Hasta)
    GROUP BY a.AgenciaId, a.Region, a.Nombre
    ORDER BY MontoFinanciado DESC, a.Region, a.Nombre;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Rpt20_PuntualidadClientes
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Hoy DATE = CAST(GETDATE() AS DATE);

    SELECT c.ClienteId, c.NombreCompleto AS Cliente, c.DPI,
           e.CuotasPagadas, e.PagadasATiempo,
           e.CuotasPagadas - e.PagadasATiempo AS PagadasConAtraso,
           e.VencidasPendientes,
           x.Puntualidad AS PorcentajePuntualidad,
           CASE WHEN x.Puntualidad >= 95 THEN 'EXCELENTE'
                WHEN x.Puntualidad >= 80 THEN 'BUENO'
                WHEN x.Puntualidad >= 60 THEN 'REGULAR'
                ELSE 'DEFICIENTE' END AS Calificacion
    FROM (
        SELECT cr.ClienteId,
               SUM(CASE WHEN q.Estado = 'PAGADA' THEN 1 ELSE 0 END) AS CuotasPagadas,
               SUM(CASE WHEN q.Estado = 'PAGADA' AND CAST(q.FechaCancelacion AS DATE) <= q.FechaVencimiento
                        THEN 1 ELSE 0 END) AS PagadasATiempo,
               SUM(CASE WHEN q.Estado <> 'PAGADA' AND q.FechaVencimiento < @Hoy THEN 1 ELSE 0 END) AS VencidasPendientes
        FROM dbo.Cuota q
        JOIN dbo.Credito cr ON cr.CreditoId = q.CreditoId
        WHERE cr.Estado <> 'ANULADO'
        GROUP BY cr.ClienteId
    ) e
    JOIN dbo.vw_Cliente c ON c.ClienteId = e.ClienteId
    CROSS APPLY (SELECT CAST(e.PagadasATiempo * 100.0
                             / NULLIF(e.CuotasPagadas + e.VencidasPendientes, 0) AS DECIMAL(5,2)) AS Puntualidad) x
    WHERE e.CuotasPagadas + e.VencidasPendientes > 0
    ORDER BY PorcentajePuntualidad DESC, Cliente;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Rpt21_CuotasPorVencer
    @Dias INT = 7
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Hoy DATE = CAST(GETDATE() AS DATE);

    SELECT q.FechaVencimiento,
           DATEDIFF(DAY, @Hoy, q.FechaVencimiento) AS DiasParaVencer,
           q.NumeroObligacion, q.Cliente, q.NumeroCuota, q.SaldoCuota,
           p.Correo,
           (SELECT STRING_AGG(t.Numero, ', ') FROM dbo.TelefonoPersona t WHERE t.PersonaId = p.PersonaId) AS Telefonos
    FROM dbo.vw_Cuota q
    JOIN dbo.Credito cr ON cr.CreditoId = q.CreditoId
    JOIN dbo.Cliente cl ON cl.ClienteId = q.ClienteId
    JOIN dbo.Persona p  ON p.PersonaId  = cl.PersonaId
    WHERE cr.Estado = 'ACTIVO'
      AND q.Estado <> 'PAGADA'
      AND q.FechaVencimiento BETWEEN @Hoy AND DATEADD(DAY, @Dias, @Hoy)
    ORDER BY q.FechaVencimiento, q.Cliente;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Rpt22_ResumenEjecutivo
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Hoy DATE = CAST(GETDATE() AS DATE);
    DECLARE @InicioMes DATE = DATEFROMPARTS(YEAR(@Hoy), MONTH(@Hoy), 1);
    DECLARE @Cartera DECIMAL(14,2), @Vencido DECIMAL(14,2);

    SELECT @Cartera = ISNULL(SUM(q.TotalCuota - q.MontoPagado), 0)
    FROM dbo.Cuota q JOIN dbo.Credito cr ON cr.CreditoId = q.CreditoId
    WHERE cr.Estado = 'ACTIVO';

    SELECT @Vencido = ISNULL(SUM(q.TotalCuota - q.MontoPagado), 0)
    FROM dbo.Cuota q JOIN dbo.Credito cr ON cr.CreditoId = q.CreditoId
    WHERE cr.Estado = 'ACTIVO' AND q.Estado <> 'PAGADA' AND q.FechaVencimiento < @Hoy;

    SELECT
        (SELECT COUNT(*) FROM dbo.Cliente WHERE Activo = 1)                AS ClientesActivos,
        (SELECT COUNT(*) FROM dbo.Credito WHERE Estado = 'ACTIVO')         AS CreditosActivos,
        (SELECT COUNT(*) FROM dbo.Credito WHERE Estado = 'CANCELADO')      AS CreditosCancelados,
        (SELECT COUNT(DISTINCT q.CreditoId)
           FROM dbo.Cuota q JOIN dbo.Credito cr ON cr.CreditoId = q.CreditoId
          WHERE cr.Estado = 'ACTIVO' AND q.Estado <> 'PAGADA' AND q.FechaVencimiento < @Hoy) AS CreditosEnMora,
        @Cartera AS CarteraTotal,
        @Vencido AS CarteraVencida,
        CAST(@Vencido * 100.0 / NULLIF(@Cartera, 0) AS DECIMAL(5,2)) AS IndiceMoraPct,
        (SELECT COUNT(*) FROM dbo.Credito
          WHERE Estado <> 'ANULADO' AND FechaAprobacion >= @InicioMes)     AS CreditosEmitidosMes,
        (SELECT ISNULL(SUM(MontoFinanciado), 0) FROM dbo.Credito
          WHERE Estado <> 'ANULADO' AND FechaAprobacion >= @InicioMes)     AS MontoColocadoMes,
        (SELECT ISNULL(SUM(Monto), 0) FROM dbo.TransaccionPago
          WHERE Anulada = 0 AND FechaHora >= @InicioMes)                   AS RecaudacionMes,
        (SELECT ISNULL(SUM(ComisionVendedor), 0) FROM dbo.TransaccionPago
          WHERE Anulada = 0 AND FechaHora >= @InicioMes)                   AS ComisionesMes,
        (SELECT ISNULL(SUM(q.Interes), 0)
           FROM dbo.Cuota q JOIN dbo.Credito cr ON cr.CreditoId = q.CreditoId
          WHERE cr.Estado = 'ACTIVO' AND q.FechaVencimiento >= @Hoy)       AS InteresesPorDevengar;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Rpt23_PagosAnulados
    @Desde DATE,
    @Hasta DATE
AS
BEGIN
    SET NOCOUNT ON;
    SELECT NumeroRecibo, FechaHora, Monto, MedioPago, ReferenciaBancaria,
           NumeroObligacion, Cliente, NumeroCuota, Vendedor
    FROM dbo.vw_TransaccionPago
    WHERE Anulada = 1
      AND CAST(FechaHora AS DATE) BETWEEN @Desde AND @Hasta
    ORDER BY FechaHora;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Rpt24_SimuladorCredito
    @PrecioContado  DECIMAL(12,2),
    @Enganche       DECIMAL(12,2),
    @PlazoMeses     SMALLINT     = NULL,
    @TasaAnual      DECIMAL(5,2) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET @PlazoMeses = ISNULL(@PlazoMeses, CAST(dbo.fn_Parametro('PLAZO_MESES') AS SMALLINT));
    SET @TasaAnual  = ISNULL(@TasaAnual, dbo.fn_Parametro('TASA_INTERES_ANUAL'));

    IF @PrecioContado IS NULL OR @PrecioContado <= 0
        THROW 50001, 'El precio de contado debe ser mayor a cero.', 1;
    IF @Enganche IS NULL OR @Enganche < 0 OR @Enganche >= @PrecioContado
        THROW 50001, 'El enganche debe ser mayor o igual a cero y menor al precio de contado.', 1;
    IF @PlazoMeses NOT BETWEEN 1 AND 120
        THROW 50001, 'El plazo debe estar entre 1 y 120 meses.', 1;
    IF @TasaAnual <= 0
        THROW 50001, 'La tasa de interés debe ser mayor a cero.', 1;

    DECLARE @Monto    DECIMAL(12,2) = @PrecioContado - @Enganche;
    DECLARE @Manejo   DECIMAL(8,2)  = dbo.fn_Parametro('MANEJO_CUENTA');
    DECLARE @SegAuto  DECIMAL(10,2) = ROUND(@PrecioContado * dbo.fn_Parametro('SEGURO_AUTO_ANUAL') / 100 / 12, 2);
    DECLARE @SegVida  DECIMAL(10,2) = ROUND(@Monto * dbo.fn_Parametro('SEGURO_VIDA_ANUAL') / 100 / 12, 2);
    DECLARE @Deprec   FLOAT = CAST(dbo.fn_Parametro('DEPRECIACION_RODAJE') AS FLOAT) / 100.0;
    DECLARE @DepAnual FLOAT = CAST(dbo.fn_Parametro('DEPRECIACION_ANUAL') AS FLOAT) / 100.0;
    DECLARE @i        FLOAT = CAST(@TasaAnual AS FLOAT) / 100.0 / 12.0;
    DECLARE @Cuota    DECIMAL(12,2) =
        ROUND(CAST(@Monto AS FLOAT) * @i / (1.0 - POWER(1.0 + @i, -CAST(@PlazoMeses AS FLOAT))), 2);

    DECLARE @Tabla TABLE (
        NumeroCuota SMALLINT, SaldoInicial DECIMAL(12,2), Interes DECIMAL(12,2), Capital DECIMAL(12,2),
        ManejoCuenta DECIMAL(8,2), SeguroAuto DECIMAL(10,2), SeguroVida DECIMAL(10,2),
        TotalCuota DECIMAL(12,2), SaldoFinal DECIMAL(12,2));

    DECLARE @Saldo DECIMAL(12,2) = @Monto, @n SMALLINT = 1, @Interes DECIMAL(12,2), @Capital DECIMAL(12,2);
    WHILE @n <= @PlazoMeses
    BEGIN
        SET @Interes = ROUND(CAST(@Saldo AS FLOAT) * @i, 2);
        SET @Capital = CASE WHEN @n = @PlazoMeses THEN @Saldo ELSE @Cuota - @Interes END;
        IF @Capital > @Saldo SET @Capital = @Saldo;

        INSERT INTO @Tabla VALUES (@n, @Saldo, @Interes, @Capital, @Manejo, @SegAuto, @SegVida,
                                   @Capital + @Interes + @Manejo + @SegAuto + @SegVida, @Saldo - @Capital);
        SET @Saldo = @Saldo - @Capital;
        SET @n += 1;
    END

    DECLARE @TotalCuotas DECIMAL(14,2), @TotalInteres DECIMAL(14,2), @TotalSeguros DECIMAL(14,2), @TotalManejo DECIMAL(14,2);
    SELECT @TotalCuotas = SUM(TotalCuota), @TotalInteres = SUM(Interes),
           @TotalSeguros = SUM(SeguroAuto + SeguroVida), @TotalManejo = SUM(ManejoCuenta)
    FROM @Tabla;

    DECLARE @CostoTotal DECIMAL(14,2) = @Enganche + @TotalCuotas;
    DECLARE @ValorRodaje DECIMAL(12,2) = ROUND(@PrecioContado * (1 - @Deprec), 2);
    DECLARE @ValorFinal  DECIMAL(12,2) = ROUND(@ValorRodaje * POWER(1.0 - @DepAnual, @PlazoMeses / 12.0), 2);

    SELECT @PrecioContado AS PrecioContado, @Enganche AS Enganche, @Monto AS MontoFinanciado,
           @TasaAnual AS TasaAnual, @PlazoMeses AS PlazoMeses,
           @Cuota AS CuotaNivelada,
           @Cuota + @Manejo + @SegAuto + @SegVida AS CuotaMensualTotal,
           @TotalInteres AS TotalIntereses, @TotalSeguros AS TotalSeguros, @TotalManejo AS TotalManejoCuenta,
           @TotalCuotas AS TotalPagadoEnCuotas,
           @CostoTotal AS CostoTotalDelVehiculo,
           @CostoTotal - @PrecioContado AS PagaDeMas,
           CAST((@CostoTotal - @PrecioContado) * 100.0 / @PrecioContado AS DECIMAL(7,2)) AS PorcentajeDeMas,
           @ValorRodaje AS ValorAlSalirDeAgencia,
           @ValorFinal AS ValorEstimadoAlTerminar,
           CONCAT('Por cada Q1.00 del precio de contado pagará Q',
                  CAST(CAST(@CostoTotal / @PrecioContado AS DECIMAL(6,2)) AS VARCHAR(10)),
                  ' y al terminar el auto valdrá aproximadamente Q',
                  CAST(CAST(@ValorFinal / @PrecioContado AS DECIMAL(6,2)) AS VARCHAR(10)), '.') AS Conclusion;

    SELECT * FROM @Tabla ORDER BY NumeroCuota;
END
GO

PRINT 'Reportes del Script 04 creados correctamente.';
GO
