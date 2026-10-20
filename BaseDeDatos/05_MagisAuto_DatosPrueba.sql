USE MagisAuto;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF EXISTS (SELECT 1 FROM dbo.Vendedor WHERE CodigoEmpleado = 'V002')
BEGIN
    PRINT 'Los datos de prueba ya fueron cargados. No se ejecutó nada.';
    SET NOEXEC ON;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Demo_SimularPagos
    @CreditoId       INT,
    @Perfil          VARCHAR(10),
    @CuotasSinPagar  INT = 0
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Hoy DATE = CAST(GETDATE() AS DATE);
    DECLARE @HoyHora DATETIME2(0) = DATEADD(HOUR, 9, CAST(@Hoy AS DATETIME2(0)));

    SELECT TOP 0 * INTO #Sink FROM dbo.vw_TransaccionPago;

    DECLARE @Ultima INT;
    SELECT @Ultima = ISNULL(MAX(NumeroCuota), 0)
    FROM dbo.Cuota
    WHERE CreditoId = @CreditoId AND FechaVencimiento <= @Hoy;

    IF @Perfil = 'MORA'
        SET @Ultima = @Ultima - @CuotasSinPagar;

    DECLARE @n SMALLINT, @Venc DATE, @Total DECIMAL(12,2), @Fecha DATETIME2(0),
            @Medio TINYINT, @Ref VARCHAR(40);

    DECLARE c CURSOR LOCAL FAST_FORWARD FOR
        SELECT NumeroCuota, FechaVencimiento, TotalCuota
        FROM dbo.Cuota
        WHERE CreditoId = @CreditoId AND NumeroCuota <= @Ultima
        ORDER BY NumeroCuota;

    OPEN c;
    FETCH NEXT FROM c INTO @n, @Venc, @Total;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @Medio = (@n % 5) + 1;
        SET @Ref = CASE WHEN @Medio = 5 THEN NULL ELSE CONCAT('AUT', @CreditoId, '-', @n) END;

        IF @Perfil = 'PARCIAL' AND @n = @Ultima
        BEGIN
            SET @Fecha = DATEADD(HOUR, 10, CAST(DATEADD(DAY, 1, @Venc) AS DATETIME2(0)));
            IF @Fecha > @HoyHora SET @Fecha = @HoyHora;
            INSERT INTO #Sink EXEC dbo.sp_Pago_Registrar
                 @CreditoId = @CreditoId, @NumeroCuota = @n, @Monto = 1000,
                 @MedioPagoId = 5, @FechaHora = @Fecha;

            SET @Fecha = DATEADD(DAY, 4, @Fecha);
            IF @Fecha > @HoyHora SET @Fecha = @HoyHora;
            SET @Ref = CONCAT('BOL', @CreditoId, '-', @n);
            INSERT INTO #Sink EXEC dbo.sp_Pago_Registrar
                 @CreditoId = @CreditoId, @NumeroCuota = @n, @Monto = 800,
                 @MedioPagoId = 1, @ReferenciaBancaria = @Ref, @FechaHora = @Fecha;
        END
        ELSE
        BEGIN
            SET @Fecha = DATEADD(HOUR, 9 + (@n % 8),
                         CAST(DATEADD(DAY, CASE WHEN @Perfil = 'ATRASADO' THEN 8 ELSE -2 END, @Venc) AS DATETIME2(0)));
            IF @Fecha > @HoyHora BREAK;

            INSERT INTO #Sink EXEC dbo.sp_Pago_Registrar
                 @CreditoId = @CreditoId, @NumeroCuota = @n, @Monto = @Total,
                 @MedioPagoId = @Medio, @ReferenciaBancaria = @Ref, @FechaHora = @Fecha;
        END

        FETCH NEXT FROM c INTO @n, @Venc, @Total;
    END
    CLOSE c;
    DEALLOCATE c;
END
GO

SET NOCOUNT ON;
DECLARE @Hoy DATE = CAST(GETDATE() AS DATE);

IF NOT EXISTS (SELECT 1 FROM dbo.Vendedor WHERE CodigoEmpleado = 'V001')
    INSERT INTO dbo.Vendedor (CodigoEmpleado, DPI, Nombres, Apellidos, AgenciaId)
    SELECT 'V001', '2345678901101', 'Ana Lucía', 'Morales', AgenciaId
    FROM dbo.Agencia WHERE Nombre = 'Agencia Jalapa Centro';

INSERT INTO dbo.Vendedor (CodigoEmpleado, DPI, Nombres, Apellidos, AgenciaId)
SELECT v.Codigo, v.DPI, v.Nombres, v.Apellidos, a.AgenciaId
FROM (VALUES
    ('V002', '2345678902101', 'Carlos Eduardo',   'Ramírez Solís',  'Agencia Chiquimula'),
    ('V003', '2345678903101', 'Sofía Alejandra',  'Méndez Pineda',  'Agencia Guatemala Zona 10'),
    ('V004', '2345678904101', 'Diego Andrés',     'Herrera Lima',   'Agencia Mixco'),
    ('V005', '2345678905101', 'Mariela Fernanda', 'Cruz Velásquez', 'Agencia Quetzaltenango')
) v (Codigo, DPI, Nombres, Apellidos, Agencia)
JOIN dbo.Agencia a ON a.Nombre = v.Agencia;

DECLARE @Cli TABLE (
    Idx INT, DPI CHAR(13), NIT VARCHAR(15), Nombres VARCHAR(80), Apellidos VARCHAR(80),
    AnioNac INT, MesNac INT, DiaNac INT, Correo VARCHAR(120), Telefono VARCHAR(15),
    Direccion VARCHAR(200), Municipio VARCHAR(60), Departamento VARCHAR(40));

INSERT INTO @Cli
SELECT Idx,
       CONCAT('3001000', RIGHT('0' + CAST(Idx AS VARCHAR(2)), 2), '2101'),
       CONCAT('8100', RIGHT('0' + CAST(Idx AS VARCHAR(2)), 2), '7'),
       Nombres, Apellidos, AnioNac, MesNac, DiaNac, Correo, Telefono, Direccion, Municipio, Departamento
FROM (VALUES
    (1,  'María José',        'García Hernández',  2000, NULL, 5,  'mariajose.garcia@correo.com',  '55102030', 'Barrio La Democracia, 2a avenida 4-21', 'Jalapa',               'Jalapa'),
    (2,  'Kevin Alexander',   'López Morales',     1999, 3,    14, 'kevin.lopez@correo.com',       '55203040', 'Aldea Las Tunas, casa 15',              'Monjas',               'Jalapa'),
    (3,  'Andrea Sofía',      'Pérez Castillo',    2001, 7,    22, 'andrea.perez@correo.com',      '55304050', 'Barrio El Calvario, 5a calle 3-10',     'San Pedro Pinula',     'Jalapa'),
    (4,  'José Manuel',       'Ortiz Recinos',     1998, NULL, 18, 'jose.ortiz@correo.com',        '55405060', 'Colonia Lindavista, lote 22',           'Jalapa',               'Jalapa'),
    (5,  'Daniela Alejandra', 'Ruiz Marroquín',    2002, 1,    9,  'daniela.ruiz@correo.com',      '55506070', 'Barrio San Francisco, 1a calle 1-05',   'Mataquescuintla',      'Jalapa'),
    (6,  'Bryan Estuardo',    'Hernández Cabrera', 2000, 12,   3,  'bryan.hernandez@correo.com',   '55607080', 'Barrio Chipilapa, 4a avenida 6-30',     'Jalapa',               'Jalapa'),
    (7,  'Gabriela Isabel',   'Chávez Arana',      1997, 5,    27, 'gabriela.chavez@correo.com',   '55708090', 'Barrio El Centro, 3a calle 7-14',       'Chiquimula',           'Chiquimula'),
    (8,  'Josué David',       'Mejía Portillo',    2001, NULL, 25, 'josue.mejia@correo.com',       '55809010', 'Cantón El Paraíso, casa 8',             'San Luis Jilotepeque', 'Jalapa'),
    (9,  'Fernanda Lucía',    'Salazar Orellana',  1996, 8,    11, 'fernanda.salazar@correo.com',  '55901020', 'Zona 11, 12 avenida 15-40',             'Guatemala',            'Guatemala'),
    (10, 'Pablo Andrés',      'Rodríguez Vásquez', 1995, 2,    16, 'pablo.rodriguez@correo.com',   '56012030', 'Colonia El Milagro, 6a calle 8-21',     'Mixco',                'Guatemala'),
    (11, 'Rodrigo Alberto',   'Monzón Aguirre',    1999, 6,    28, 'rodrigo.monzon@correo.com',    '56123040', 'Barrio La Esperanza, 7a avenida 2-18',  'Jalapa',               'Jalapa')
) v (Idx, Nombres, Apellidos, AnioNac, MesNac, DiaNac, Correo, Telefono, Direccion, Municipio, Departamento);

INSERT INTO dbo.Persona (DPI, NIT, Nombres, Apellidos, FechaNacimiento, Correo)
SELECT DPI, NIT, Nombres, Apellidos, DATEFROMPARTS(AnioNac, ISNULL(MesNac, MONTH(@Hoy)), DiaNac), Correo
FROM @Cli;

INSERT INTO dbo.Cliente (PersonaId)
SELECT p.PersonaId FROM @Cli c JOIN dbo.Persona p ON p.DPI = c.DPI;

INSERT INTO dbo.TelefonoPersona (PersonaId, TipoTelefonoId, Numero)
SELECT p.PersonaId, 1, c.Telefono FROM @Cli c JOIN dbo.Persona p ON p.DPI = c.DPI;

INSERT INTO dbo.TelefonoPersona (PersonaId, TipoTelefonoId, Numero)
SELECT p.PersonaId, 2, CONCAT('7922', RIGHT('000' + CAST(c.Idx AS VARCHAR(4)), 4))
FROM @Cli c JOIN dbo.Persona p ON p.DPI = c.DPI
WHERE c.Idx % 2 = 0;

INSERT INTO dbo.DireccionPersona (PersonaId, Direccion, Municipio, Departamento)
SELECT p.PersonaId, c.Direccion, c.Municipio, c.Departamento
FROM @Cli c JOIN dbo.Persona p ON p.DPI = c.DPI;

INSERT INTO dbo.Referencia (ClienteId, NombreCompleto, LugarTrabajo, Parentesco)
SELECT cl.ClienteId,
       CASE r.n
           WHEN 1 THEN CONCAT(CHOOSE(c.Idx % 4 + 1, 'Marta Elena', 'Rosa María', 'Gloria Patricia', 'Blanca Estela'),
                              ' ', LTRIM(SUBSTRING(c.Apellidos, CHARINDEX(' ', c.Apellidos) + 1, 80)))
           WHEN 2 THEN CONCAT(CHOOSE(c.Idx % 3 + 1, 'Carlos Roberto', 'Lucía Fernanda', 'Mario Antonio'), ' ', c.Apellidos)
           ELSE CHOOSE(c.Idx % 5 + 1, 'Roberto Aguilar Paz', 'Silvia Monterroso Díaz', 'Héctor Linares Gómez',
                                      'Karla Sandoval Ruiz', 'Óscar Barrios Lemus')
       END,
       CASE r.n WHEN 1 THEN 'Ama de casa'
                WHEN 2 THEN CONCAT('Centro de Salud de ', c.Municipio)
                ELSE 'Comercial El Progreso' END,
       CASE r.n WHEN 1 THEN 'Madre' WHEN 2 THEN 'Hermano(a)' ELSE 'Compañero(a) de trabajo' END
FROM @Cli c
JOIN dbo.Persona p  ON p.DPI = c.DPI
JOIN dbo.Cliente cl ON cl.PersonaId = p.PersonaId
CROSS JOIN (VALUES (1), (2), (3)) r (n);

INSERT INTO dbo.TelefonoReferencia (ReferenciaId, TipoTelefonoId, Numero)
SELECT r.ReferenciaId,
       CASE WHEN r.Parentesco = 'Compañero(a) de trabajo' THEN 3 ELSE 1 END,
       CONCAT('4', RIGHT(CONCAT('0000000', 2000000 + r.ReferenciaId * 731), 7))
FROM dbo.Referencia r
JOIN dbo.Cliente cl ON cl.ClienteId = r.ClienteId
JOIN dbo.Persona p  ON p.PersonaId = cl.PersonaId
JOIN @Cli c         ON c.DPI = p.DPI;

INSERT INTO dbo.DireccionReferencia (ReferenciaId, Direccion, Municipio, Departamento)
SELECT r.ReferenciaId, CONCAT('Barrio El Porvenir, casa ', r.ReferenciaId), c.Municipio, c.Departamento
FROM dbo.Referencia r
JOIN dbo.Cliente cl ON cl.ClienteId = r.ClienteId
JOIN dbo.Persona p  ON p.PersonaId = cl.PersonaId
JOIN @Cli c         ON c.DPI = p.DPI;

DECLARE @Fia TABLE (DPI CHAR(13), NIT VARCHAR(15), Nombres VARCHAR(80), Apellidos VARCHAR(80),
                    FechaNac DATE, Correo VARCHAR(120), Telefono VARCHAR(15));
INSERT INTO @Fia VALUES
    ('3101000012101', '8200017', 'Héctor Rolando', 'Paiz Guzmán',       '1970-04-12', 'hector.paiz@correo.com',      '55901122'),
    ('3101000022101', '8200027', 'Silvia Marina',  'Contreras de León', '1975-09-30', 'silvia.contreras@correo.com', '55902233'),
    ('3101000032101', '8200037', 'Edgar Mauricio', 'Barrios Solares',   '1968-11-02', 'edgar.barrios@correo.com',    '55903344');

INSERT INTO dbo.Persona (DPI, NIT, Nombres, Apellidos, FechaNacimiento, Correo)
SELECT DPI, NIT, Nombres, Apellidos, FechaNac, Correo FROM @Fia;

INSERT INTO dbo.Fiador (PersonaId)
SELECT p.PersonaId FROM @Fia f JOIN dbo.Persona p ON p.DPI = f.DPI;

INSERT INTO dbo.TelefonoPersona (PersonaId, TipoTelefonoId, Numero)
SELECT p.PersonaId, 1, f.Telefono FROM @Fia f JOIN dbo.Persona p ON p.DPI = f.DPI;

INSERT INTO dbo.DireccionPersona (PersonaId, Direccion, Municipio, Departamento)
SELECT p.PersonaId, 'Barrio El Centro, 1a avenida 2-50', 'Jalapa', 'Jalapa'
FROM @Fia f JOIN dbo.Persona p ON p.DPI = f.DPI;

DECLARE @Cred TABLE (
    Orden INT, ClienteIdx INT, VIN CHAR(17), CodigoMarca VARCHAR(10), Linea VARCHAR(60),
    Anio SMALLINT, Color VARCHAR(30), Valor DECIMAL(12,2), Placa VARCHAR(10), Vendedor VARCHAR(10),
    Enganche DECIMAL(12,2), MesesAtras INT, DiasExtra INT, Plazo SMALLINT, Comision DECIMAL(5,2),
    FiadoresDPI VARCHAR(100), Perfil VARCHAR(10), SinPagar INT);

INSERT INTO @Cred VALUES
 (1,  1,  'KMHCT41DAFU000101', 'HYU', 'Accent',         2025, 'Blanco',      155000, 'P512FGH', 'V002', 31000, 20, 5,  60, 1.50, NULL,                          'PUNTUAL',  0),
 (2,  2,  'KNADM5A35H6000102', 'KIA', 'Rio Hatchback',  2025, 'Rojo',        148000, 'P738HJK', 'V003', 30000, 19, 12, 60, 2.00, NULL,                          'ATRASADO', 0),
 (3,  3,  '3N1CN7AD5KL000103', 'NIS', 'Versa',          2025, 'Gris',        162000, 'P219JKL', 'V001', 35000, 18, 10, 60, 1.50, '3101000012101',               'MORA',     4),
 (4,  4,  'JM1BPAC75L1000104', 'MAZ', 'Mazda 3 Sedán',  2025, 'Azul',        215000, 'P904KLM', 'V004', 50000, 17, 26, 60, 1.75, '3101000022101',               'PUNTUAL',  0),
 (5,  5,  'MA3FB32S5K0000105', 'SUZ', 'Swift',          2025, 'Plateado',    128000, 'P346LMN', 'V005', 25000, 16, 10, 48, 1.50, NULL,                          'MORA',     2),
 (6,  6,  'ML32A4HJ5KH000106', 'MIT', 'Mirage G4',      2025, 'Negro',       112000, 'P571MNP', 'V002', 22000, 15, 8,  60, 1.50, NULL,                          'PARCIAL',  0),
 (7,  7,  '2HGFC2F59LH000107', 'HON', 'Civic Touring',  2025, 'Blanco',      245000, 'P682NPR', 'V003', 60000, 14, 10, 60, 2.00, '3101000032101',               'MORA',     3),
 (8,  8,  'KL1MJ6A43LC000108', 'CHE', 'Beat',           2025, 'Rojo',        105000, 'P123PRS', 'V001', 20000, 13, 27, 36, 1.50, NULL,                          'PUNTUAL',  0),
 (9,  9,  'MPATFS86JLT000109', 'ISU', 'D-Max 4x4',      2026, 'Gris',        285000, 'P845RST', 'V004', 70000, 11, 10, 60, 1.75, NULL,                          'MORA',     1),
 (10, 10, 'JTMW1RFV0LD000110', 'TOY', 'RAV4',           2026, 'Negro',       335000, 'P467STV', 'V005', 90000, 9,  3,  60, 2.00, '3101000012101,3101000022101', 'PUNTUAL',  0),
 (11, 11, 'MHKA4DE30LJ000112', 'KIA', 'Picanto',        2024, 'Amarillo',     98000, 'P290TVW', 'V001', 30000, 22, 15, 12, 1.50, NULL,                          'PUNTUAL',  0),
 (12, 11, '5YFBURHE7LP000111', 'TOY', 'Corolla',        2026, 'Gris Oscuro', 225000, NULL,      'V002', 55000, 6,  12, 60, 1.50, NULL,                          'ATRASADO', 0);

INSERT INTO dbo.Vehiculo (VIN, MarcaId, Linea, Anio, Color, ValorAgencia, Placa)
SELECT c.VIN, m.MarcaId, c.Linea, c.Anio, c.Color, c.Valor, c.Placa
FROM @Cred c JOIN dbo.Marca m ON m.CodigoMarca = c.CodigoMarca;

INSERT INTO dbo.HistorialValorVehiculo (VIN, Fecha, ValorEstimado, PorcentajeDepreciacion, Concepto)
SELECT VIN, DATEADD(DAY, -DiasExtra - 3, DATEADD(MONTH, -MesesAtras, @Hoy)), Valor, 0,
       'Valor de agencia (precio de contado)'
FROM @Cred;

SELECT TOP 0 * INTO #SinkCredito FROM dbo.vw_Credito;

DECLARE @Orden INT, @ClienteId INT, @VIN CHAR(17), @VendedorId INT, @Eng DECIMAL(12,2),
        @M INT, @D INT, @Plazo SMALLINT, @Com DECIMAL(5,2), @FDPI VARCHAR(100),
        @Perfil VARCHAR(10), @SinPagar INT, @FechaAprob DATE, @Fiad VARCHAR(500), @CreditoId INT;

DECLARE cc CURSOR LOCAL FAST_FORWARD FOR
    SELECT c.Orden, cl.ClienteId, c.VIN, v.VendedorId, c.Enganche, c.MesesAtras, c.DiasExtra,
           c.Plazo, c.Comision, c.FiadoresDPI, c.Perfil, c.SinPagar
    FROM @Cred c
    JOIN @Cli k         ON k.Idx = c.ClienteIdx
    JOIN dbo.Persona p  ON p.DPI = k.DPI
    JOIN dbo.Cliente cl ON cl.PersonaId = p.PersonaId
    JOIN dbo.Vendedor v ON v.CodigoEmpleado = c.Vendedor
    ORDER BY c.Orden;

OPEN cc;
FETCH NEXT FROM cc INTO @Orden, @ClienteId, @VIN, @VendedorId, @Eng, @M, @D, @Plazo, @Com, @FDPI, @Perfil, @SinPagar;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @FechaAprob = DATEADD(DAY, -@D, DATEADD(MONTH, -@M, @Hoy));

    SET @Fiad = NULL;
    IF @FDPI IS NOT NULL
        SELECT @Fiad = STRING_AGG(CAST(f.FiadorId AS VARCHAR(10)), ',')
        FROM dbo.Fiador f
        JOIN dbo.Persona p ON p.PersonaId = f.PersonaId
        WHERE p.DPI IN (SELECT LTRIM(RTRIM(value)) FROM STRING_SPLIT(@FDPI, ','));

    UPDATE dbo.Cliente SET FechaAlta = DATEADD(DAY, -5, CAST(@FechaAprob AS DATETIME2(0)))
    WHERE ClienteId = @ClienteId AND FechaAlta > @FechaAprob;

    INSERT INTO #SinkCredito
    EXEC dbo.sp_Credito_Emitir @ClienteId = @ClienteId, @VIN = @VIN, @VendedorId = @VendedorId,
                               @Enganche = @Eng, @FechaAprobacion = @FechaAprob, @PlazoMeses = @Plazo,
                               @PorcentajeComision = @Com, @Fiadores = @Fiad;

    SELECT @CreditoId = CreditoId FROM dbo.Credito WHERE VIN = @VIN AND FechaAprobacion = @FechaAprob;

    EXEC dbo.sp_Demo_SimularPagos @CreditoId = @CreditoId, @Perfil = @Perfil, @CuotasSinPagar = @SinPagar;

    FETCH NEXT FROM cc INTO @Orden, @ClienteId, @VIN, @VendedorId, @Eng, @M, @D, @Plazo, @Com, @FDPI, @Perfil, @SinPagar;
END
CLOSE cc;
DEALLOCATE cc;

DECLARE @CredAnular INT = (SELECT CreditoId FROM dbo.Credito WHERE VIN = 'MPATFS86JLT000109');
DECLARE @HoraPago DATETIME2(0) = DATEADD(HOUR, -2, CAST(SYSDATETIME() AS DATETIME2(0)));
DECLARE @TxAnular INT;

SELECT TOP 0 * INTO #SinkPago FROM dbo.vw_TransaccionPago;
CREATE TABLE #SinkMsg (Resultado VARCHAR(20), Mensaje VARCHAR(300));

INSERT INTO #SinkPago
EXEC dbo.sp_Pago_Registrar @CreditoId = @CredAnular, @Monto = 500, @MedioPagoId = 5, @FechaHora = @HoraPago;

SELECT @TxAnular = MAX(TransaccionId) FROM #SinkPago;
INSERT INTO #SinkMsg EXEC dbo.sp_Pago_Eliminar @TransaccionId = @TxAnular;

SELECT 'Clientes'              AS Concepto, COUNT(*) AS Total FROM dbo.Cliente
UNION ALL SELECT 'Fiadores',              COUNT(*) FROM dbo.Fiador
UNION ALL SELECT 'Vendedores',            COUNT(*) FROM dbo.Vendedor
UNION ALL SELECT 'Vehículos',             COUNT(*) FROM dbo.Vehiculo
UNION ALL SELECT 'Créditos activos',      COUNT(*) FROM dbo.Credito WHERE Estado = 'ACTIVO'
UNION ALL SELECT 'Créditos cancelados',   COUNT(*) FROM dbo.Credito WHERE Estado = 'CANCELADO'
UNION ALL SELECT 'Cuotas generadas',      COUNT(*) FROM dbo.Cuota
UNION ALL SELECT 'Cuotas pagadas',        COUNT(*) FROM dbo.Cuota WHERE Estado = 'PAGADA'
UNION ALL SELECT 'Pagos registrados',     COUNT(*) FROM dbo.TransaccionPago WHERE Anulada = 0
UNION ALL SELECT 'Pagos anulados',        COUNT(*) FROM dbo.TransaccionPago WHERE Anulada = 1;
GO

DROP PROCEDURE IF EXISTS dbo.sp_Demo_SimularPagos;
GO

SET NOEXEC OFF;
GO
