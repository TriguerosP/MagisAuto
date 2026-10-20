USE master;
GO

IF DB_ID('MagisAuto') IS NOT NULL
BEGIN
    ALTER DATABASE MagisAuto SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE MagisAuto;
END
GO

CREATE DATABASE MagisAuto;
GO

USE MagisAuto;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE TABLE dbo.Parametro (
    Codigo             VARCHAR(30)    NOT NULL CONSTRAINT PK_Parametro PRIMARY KEY,
    Valor              DECIMAL(12,4)  NOT NULL,
    Descripcion        VARCHAR(200)   NOT NULL,
    FechaModificacion  DATETIME2(0)   NOT NULL CONSTRAINT DF_Parametro_Fecha DEFAULT SYSDATETIME(),
    CONSTRAINT CK_Parametro_Valor CHECK (Valor >= 0)
);
GO

CREATE TABLE dbo.TipoTelefono (
    TipoTelefonoId  TINYINT      NOT NULL CONSTRAINT PK_TipoTelefono PRIMARY KEY,
    Descripcion     VARCHAR(20)  NOT NULL CONSTRAINT UQ_TipoTelefono_Descripcion UNIQUE
);
GO

CREATE TABLE dbo.Persona (
    PersonaId        INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Persona PRIMARY KEY,
    DPI              CHAR(13)      NOT NULL CONSTRAINT UQ_Persona_DPI UNIQUE,
    NIT              VARCHAR(15)   NOT NULL CONSTRAINT UQ_Persona_NIT UNIQUE,
    Nombres          VARCHAR(80)   NOT NULL,
    Apellidos        VARCHAR(80)   NOT NULL,
    FechaNacimiento  DATE          NOT NULL,
    Correo           VARCHAR(120)  NOT NULL,
    FechaRegistro    DATETIME2(0)  NOT NULL CONSTRAINT DF_Persona_FechaRegistro DEFAULT SYSDATETIME(),
    CONSTRAINT CK_Persona_DPI    CHECK (LEN(DPI) = 13 AND DPI NOT LIKE '%[^0-9]%'),
    CONSTRAINT CK_Persona_NIT    CHECK (NIT NOT LIKE '%[^0-9Kk]%'),
    CONSTRAINT CK_Persona_Correo CHECK (Correo LIKE '%_@_%._%'),
    CONSTRAINT CK_Persona_FechaNacimiento CHECK (FechaNacimiento > '1900-01-01')
);
GO

CREATE TABLE dbo.TelefonoPersona (
    TelefonoPersonaId  INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_TelefonoPersona PRIMARY KEY,
    PersonaId          INT          NOT NULL,
    TipoTelefonoId     TINYINT      NOT NULL,
    Numero             VARCHAR(15)  NOT NULL,
    CONSTRAINT FK_TelefonoPersona_Persona FOREIGN KEY (PersonaId) REFERENCES dbo.Persona(PersonaId),
    CONSTRAINT FK_TelefonoPersona_Tipo    FOREIGN KEY (TipoTelefonoId) REFERENCES dbo.TipoTelefono(TipoTelefonoId),
    CONSTRAINT UQ_TelefonoPersona UNIQUE (PersonaId, Numero),
    CONSTRAINT CK_TelefonoPersona_Numero CHECK (LEN(Numero) >= 8 AND Numero NOT LIKE '%[^0-9+ -]%')
);
GO

CREATE TABLE dbo.DireccionPersona (
    DireccionPersonaId  INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_DireccionPersona PRIMARY KEY,
    PersonaId           INT           NOT NULL,
    Direccion           VARCHAR(200)  NOT NULL,
    Municipio           VARCHAR(60)   NOT NULL,
    Departamento        VARCHAR(40)   NOT NULL,
    CONSTRAINT FK_DireccionPersona_Persona FOREIGN KEY (PersonaId) REFERENCES dbo.Persona(PersonaId)
);
GO

CREATE TABLE dbo.Cliente (
    ClienteId  INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Cliente PRIMARY KEY,
    PersonaId  INT           NOT NULL CONSTRAINT UQ_Cliente_Persona UNIQUE,
    FechaAlta  DATETIME2(0)  NOT NULL CONSTRAINT DF_Cliente_FechaAlta DEFAULT SYSDATETIME(),
    Activo     BIT           NOT NULL CONSTRAINT DF_Cliente_Activo DEFAULT 1,
    CONSTRAINT FK_Cliente_Persona FOREIGN KEY (PersonaId) REFERENCES dbo.Persona(PersonaId)
);
GO

CREATE TABLE dbo.Fiador (
    FiadorId   INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Fiador PRIMARY KEY,
    PersonaId  INT           NOT NULL CONSTRAINT UQ_Fiador_Persona UNIQUE,
    FechaAlta  DATETIME2(0)  NOT NULL CONSTRAINT DF_Fiador_FechaAlta DEFAULT SYSDATETIME(),
    Activo     BIT           NOT NULL CONSTRAINT DF_Fiador_Activo DEFAULT 1,
    CONSTRAINT FK_Fiador_Persona FOREIGN KEY (PersonaId) REFERENCES dbo.Persona(PersonaId)
);
GO

CREATE TABLE dbo.Referencia (
    ReferenciaId    INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Referencia PRIMARY KEY,
    ClienteId       INT           NOT NULL,
    NombreCompleto  VARCHAR(160)  NOT NULL,
    LugarTrabajo    VARCHAR(120)  NULL,
    Parentesco      VARCHAR(40)   NOT NULL,
    Activo          BIT           NOT NULL CONSTRAINT DF_Referencia_Activo DEFAULT 1,
    CONSTRAINT FK_Referencia_Cliente FOREIGN KEY (ClienteId) REFERENCES dbo.Cliente(ClienteId)
);
GO

CREATE TABLE dbo.TelefonoReferencia (
    TelefonoReferenciaId  INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_TelefonoReferencia PRIMARY KEY,
    ReferenciaId          INT          NOT NULL,
    TipoTelefonoId        TINYINT      NOT NULL,
    Numero                VARCHAR(15)  NOT NULL,
    CONSTRAINT FK_TelefonoReferencia_Referencia FOREIGN KEY (ReferenciaId) REFERENCES dbo.Referencia(ReferenciaId),
    CONSTRAINT FK_TelefonoReferencia_Tipo       FOREIGN KEY (TipoTelefonoId) REFERENCES dbo.TipoTelefono(TipoTelefonoId),
    CONSTRAINT UQ_TelefonoReferencia UNIQUE (ReferenciaId, Numero),
    CONSTRAINT CK_TelefonoReferencia_Numero CHECK (LEN(Numero) >= 8 AND Numero NOT LIKE '%[^0-9+ -]%')
);
GO

CREATE TABLE dbo.DireccionReferencia (
    DireccionReferenciaId  INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_DireccionReferencia PRIMARY KEY,
    ReferenciaId           INT           NOT NULL,
    Direccion              VARCHAR(200)  NOT NULL,
    Municipio              VARCHAR(60)   NOT NULL,
    Departamento           VARCHAR(40)   NOT NULL,
    CONSTRAINT FK_DireccionReferencia_Referencia FOREIGN KEY (ReferenciaId) REFERENCES dbo.Referencia(ReferenciaId)
);
GO

CREATE TABLE dbo.Marca (
    MarcaId      INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Marca PRIMARY KEY,
    CodigoMarca  VARCHAR(10)  NOT NULL CONSTRAINT UQ_Marca_Codigo UNIQUE,
    Nombre       VARCHAR(50)  NOT NULL CONSTRAINT UQ_Marca_Nombre UNIQUE
);
GO

CREATE TABLE dbo.Vehiculo (
    VIN            CHAR(17)       NOT NULL CONSTRAINT PK_Vehiculo PRIMARY KEY,
    MarcaId        INT            NOT NULL,
    Linea          VARCHAR(60)    NOT NULL,
    Anio           SMALLINT       NOT NULL,
    Color          VARCHAR(30)    NULL,
    ValorAgencia   DECIMAL(12,2)  NOT NULL,
    Placa          VARCHAR(10)    NULL,
    FechaRegistro  DATETIME2(0)   NOT NULL CONSTRAINT DF_Vehiculo_FechaRegistro DEFAULT SYSDATETIME(),
    CONSTRAINT FK_Vehiculo_Marca FOREIGN KEY (MarcaId) REFERENCES dbo.Marca(MarcaId),
    CONSTRAINT CK_Vehiculo_VIN   CHECK (LEN(VIN) = 17 AND VIN NOT LIKE '%[^A-Z0-9]%' AND VIN NOT LIKE '%[IOQ]%'),
    CONSTRAINT CK_Vehiculo_Anio  CHECK (Anio BETWEEN 1990 AND 2100),
    CONSTRAINT CK_Vehiculo_Valor CHECK (ValorAgencia > 0)
);
GO

CREATE UNIQUE INDEX UX_Vehiculo_Placa ON dbo.Vehiculo(Placa) WHERE Placa IS NOT NULL;
GO

CREATE TABLE dbo.HistorialValorVehiculo (
    HistorialValorId        INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_HistorialValorVehiculo PRIMARY KEY,
    VIN                     CHAR(17)       NOT NULL,
    Fecha                   DATE           NOT NULL,
    ValorEstimado           DECIMAL(12,2)  NOT NULL,
    PorcentajeDepreciacion  DECIMAL(5,2)   NOT NULL,
    Concepto                VARCHAR(100)   NOT NULL,
    CONSTRAINT FK_HistorialValor_Vehiculo FOREIGN KEY (VIN) REFERENCES dbo.Vehiculo(VIN),
    CONSTRAINT CK_HistorialValor_Valor    CHECK (ValorEstimado >= 0),
    CONSTRAINT CK_HistorialValor_Pct      CHECK (PorcentajeDepreciacion BETWEEN 0 AND 100)
);
GO

CREATE TABLE dbo.Agencia (
    AgenciaId  INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Agencia PRIMARY KEY,
    Nombre     VARCHAR(80)  NOT NULL CONSTRAINT UQ_Agencia_Nombre UNIQUE,
    Region     VARCHAR(50)  NOT NULL
);
GO

CREATE TABLE dbo.Vendedor (
    VendedorId      INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Vendedor PRIMARY KEY,
    CodigoEmpleado  VARCHAR(10)  NOT NULL CONSTRAINT UQ_Vendedor_Codigo UNIQUE,
    DPI             CHAR(13)     NOT NULL CONSTRAINT UQ_Vendedor_DPI UNIQUE,
    Nombres         VARCHAR(80)  NOT NULL,
    Apellidos       VARCHAR(80)  NOT NULL,
    AgenciaId       INT          NOT NULL,
    Activo          BIT          NOT NULL CONSTRAINT DF_Vendedor_Activo DEFAULT 1,
    CONSTRAINT FK_Vendedor_Agencia FOREIGN KEY (AgenciaId) REFERENCES dbo.Agencia(AgenciaId),
    CONSTRAINT CK_Vendedor_DPI CHECK (LEN(DPI) = 13 AND DPI NOT LIKE '%[^0-9]%')
);
GO

CREATE TABLE dbo.Credito (
    CreditoId               INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Credito PRIMARY KEY,
    NumeroObligacion        AS ('MA-' + RIGHT('00000000' + CAST(CreditoId AS VARCHAR(8)), 8)) PERSISTED,
    ClienteId               INT            NOT NULL,
    VIN                     CHAR(17)       NOT NULL,
    VendedorId              INT            NOT NULL,
    FechaAprobacion         DATE           NOT NULL,
    PlazoMeses              SMALLINT       NOT NULL CONSTRAINT DF_Credito_Plazo DEFAULT 60,
    PrecioContado           DECIMAL(12,2)  NOT NULL,
    Enganche                DECIMAL(12,2)  NOT NULL,
    MontoFinanciado         AS (PrecioContado - Enganche) PERSISTED,
    TasaInteresAnual        DECIMAL(5,2)   NOT NULL,
    PorcentajeComision      DECIMAL(5,2)   NOT NULL,
    PorcentajeDepreciacion  DECIMAL(5,2)   NOT NULL,
    CuotaNivelada           DECIMAL(12,2)  NOT NULL CONSTRAINT DF_Credito_CuotaNivelada DEFAULT 0,
    ManejoCuenta            DECIMAL(8,2)   NOT NULL,
    SeguroAuto              DECIMAL(10,2)  NOT NULL,
    SeguroVida              DECIMAL(10,2)  NOT NULL,
    TotalIntereses          DECIMAL(14,2)  NOT NULL CONSTRAINT DF_Credito_TotalIntereses DEFAULT 0,
    TotalRecaudable         DECIMAL(14,2)  NOT NULL CONSTRAINT DF_Credito_TotalRecaudable DEFAULT 0,
    Estado                  VARCHAR(10)    NOT NULL CONSTRAINT DF_Credito_Estado DEFAULT 'ACTIVO',
    FechaRegistro           DATETIME2(0)   NOT NULL CONSTRAINT DF_Credito_FechaRegistro DEFAULT SYSDATETIME(),
    CONSTRAINT FK_Credito_Cliente  FOREIGN KEY (ClienteId)  REFERENCES dbo.Cliente(ClienteId),
    CONSTRAINT FK_Credito_Vehiculo FOREIGN KEY (VIN)        REFERENCES dbo.Vehiculo(VIN),
    CONSTRAINT FK_Credito_Vendedor FOREIGN KEY (VendedorId) REFERENCES dbo.Vendedor(VendedorId),
    CONSTRAINT CK_Credito_Plazo      CHECK (PlazoMeses BETWEEN 1 AND 120),
    CONSTRAINT CK_Credito_Precio     CHECK (PrecioContado > 0),
    CONSTRAINT CK_Credito_Enganche   CHECK (Enganche >= 0 AND Enganche < PrecioContado),
    CONSTRAINT CK_Credito_Tasa       CHECK (TasaInteresAnual > 0 AND TasaInteresAnual <= 100),
    CONSTRAINT CK_Credito_Comision   CHECK (PorcentajeComision BETWEEN 0 AND 100),
    CONSTRAINT CK_Credito_Deprec     CHECK (PorcentajeDepreciacion BETWEEN 0 AND 100),
    CONSTRAINT CK_Credito_Estado     CHECK (Estado IN ('ACTIVO', 'CANCELADO', 'ANULADO'))
);
GO

CREATE UNIQUE INDEX UX_Credito_NumeroObligacion ON dbo.Credito(NumeroObligacion);
GO

CREATE UNIQUE INDEX UX_Credito_VIN_Activo ON dbo.Credito(VIN) WHERE Estado = 'ACTIVO';
GO

CREATE TABLE dbo.CreditoFiador (
    CreditoId        INT           NOT NULL,
    FiadorId         INT           NOT NULL,
    FechaAsignacion  DATETIME2(0)  NOT NULL CONSTRAINT DF_CreditoFiador_Fecha DEFAULT SYSDATETIME(),
    CONSTRAINT PK_CreditoFiador PRIMARY KEY (CreditoId, FiadorId),
    CONSTRAINT FK_CreditoFiador_Credito FOREIGN KEY (CreditoId) REFERENCES dbo.Credito(CreditoId),
    CONSTRAINT FK_CreditoFiador_Fiador  FOREIGN KEY (FiadorId)  REFERENCES dbo.Fiador(FiadorId)
);
GO

CREATE TABLE dbo.Cuota (
    CuotaId           INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Cuota PRIMARY KEY,
    CreditoId         INT            NOT NULL,
    NumeroCuota       SMALLINT       NOT NULL,
    FechaVencimiento  DATE           NOT NULL,
    SaldoInicial      DECIMAL(12,2)  NOT NULL,
    Capital           DECIMAL(12,2)  NOT NULL,
    Interes           DECIMAL(12,2)  NOT NULL,
    ManejoCuenta      DECIMAL(8,2)   NOT NULL,
    SeguroAuto        DECIMAL(10,2)  NOT NULL,
    SeguroVida        DECIMAL(10,2)  NOT NULL,
    TotalCuota        AS (Capital + Interes + ManejoCuenta + SeguroAuto + SeguroVida) PERSISTED,
    SaldoFinal        AS (SaldoInicial - Capital) PERSISTED,
    MontoPagado       DECIMAL(12,2)  NOT NULL CONSTRAINT DF_Cuota_MontoPagado DEFAULT 0,
    Estado            VARCHAR(10)    NOT NULL CONSTRAINT DF_Cuota_Estado DEFAULT 'PENDIENTE',
    FechaCancelacion  DATETIME2(0)   NULL,
    CONSTRAINT FK_Cuota_Credito FOREIGN KEY (CreditoId) REFERENCES dbo.Credito(CreditoId),
    CONSTRAINT UQ_Cuota_Credito_Numero UNIQUE (CreditoId, NumeroCuota),
    CONSTRAINT CK_Cuota_Numero  CHECK (NumeroCuota > 0),
    CONSTRAINT CK_Cuota_Montos  CHECK (SaldoInicial >= 0 AND Capital >= 0 AND Interes >= 0
                                       AND ManejoCuenta >= 0 AND SeguroAuto >= 0 AND SeguroVida >= 0),
    CONSTRAINT CK_Cuota_Pagado  CHECK (MontoPagado >= 0),
    CONSTRAINT CK_Cuota_Estado  CHECK (Estado IN ('PENDIENTE', 'PARCIAL', 'PAGADA'))
);
GO

CREATE TABLE dbo.MedioPago (
    MedioPagoId         TINYINT      NOT NULL CONSTRAINT PK_MedioPago PRIMARY KEY,
    Codigo              VARCHAR(5)   NOT NULL CONSTRAINT UQ_MedioPago_Codigo UNIQUE,
    Descripcion         VARCHAR(40)  NOT NULL CONSTRAINT UQ_MedioPago_Descripcion UNIQUE,
    RequiereReferencia  BIT          NOT NULL
);
GO

CREATE TABLE dbo.TransaccionPago (
    TransaccionId       INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_TransaccionPago PRIMARY KEY,
    NumeroRecibo        AS ('RC-' + RIGHT('0000000000' + CAST(TransaccionId AS VARCHAR(10)), 10)) PERSISTED,
    CuotaId             INT            NOT NULL,
    FechaHora           DATETIME2(0)   NOT NULL CONSTRAINT DF_TransaccionPago_FechaHora DEFAULT SYSDATETIME(),
    Monto               DECIMAL(12,2)  NOT NULL,
    MedioPagoId         TINYINT        NOT NULL,
    ReferenciaBancaria  VARCHAR(40)    NULL,
    PorcentajeComision  DECIMAL(5,2)   NOT NULL,
    ComisionVendedor    AS (CAST(ROUND(Monto * PorcentajeComision / 100.0, 2) AS DECIMAL(12,2))) PERSISTED,
    Anulada             BIT            NOT NULL CONSTRAINT DF_TransaccionPago_Anulada DEFAULT 0,
    CONSTRAINT FK_TransaccionPago_Cuota     FOREIGN KEY (CuotaId)     REFERENCES dbo.Cuota(CuotaId),
    CONSTRAINT FK_TransaccionPago_MedioPago FOREIGN KEY (MedioPagoId) REFERENCES dbo.MedioPago(MedioPagoId),
    CONSTRAINT CK_TransaccionPago_Monto     CHECK (Monto > 0),
    CONSTRAINT CK_TransaccionPago_Comision  CHECK (PorcentajeComision BETWEEN 0 AND 100)
);
GO

CREATE UNIQUE INDEX UX_TransaccionPago_NumeroRecibo ON dbo.TransaccionPago(NumeroRecibo);
GO

CREATE INDEX IX_Persona_Apellidos          ON dbo.Persona(Apellidos, Nombres);
CREATE INDEX IX_TelefonoPersona_Persona    ON dbo.TelefonoPersona(PersonaId);
CREATE INDEX IX_DireccionPersona_Persona   ON dbo.DireccionPersona(PersonaId);
CREATE INDEX IX_Referencia_Cliente         ON dbo.Referencia(ClienteId);
CREATE INDEX IX_TelefonoReferencia_Ref     ON dbo.TelefonoReferencia(ReferenciaId);
CREATE INDEX IX_DireccionReferencia_Ref    ON dbo.DireccionReferencia(ReferenciaId);
CREATE INDEX IX_Vehiculo_Marca             ON dbo.Vehiculo(MarcaId);
CREATE INDEX IX_HistorialValor_VIN         ON dbo.HistorialValorVehiculo(VIN, Fecha);
CREATE INDEX IX_Vendedor_Agencia           ON dbo.Vendedor(AgenciaId);
CREATE INDEX IX_Credito_Cliente            ON dbo.Credito(ClienteId);
CREATE INDEX IX_Credito_Vendedor           ON dbo.Credito(VendedorId);
CREATE INDEX IX_Credito_FechaAprobacion    ON dbo.Credito(FechaAprobacion);
CREATE INDEX IX_CreditoFiador_Fiador       ON dbo.CreditoFiador(FiadorId);
CREATE INDEX IX_Cuota_Vencimiento_Estado   ON dbo.Cuota(FechaVencimiento, Estado);
CREATE INDEX IX_TransaccionPago_Cuota      ON dbo.TransaccionPago(CuotaId);
CREATE INDEX IX_TransaccionPago_FechaHora  ON dbo.TransaccionPago(FechaHora);
CREATE INDEX IX_TransaccionPago_MedioPago  ON dbo.TransaccionPago(MedioPagoId);
GO

INSERT INTO dbo.Parametro (Codigo, Valor, Descripcion) VALUES
('TASA_INTERES_ANUAL',   12.5000, 'Tasa de interés anual sobre saldos para vehículos nuevos (%)'),
('MANEJO_CUENTA',        25.0000, 'Cargo mensual por manejo de cuenta (Q)'),
('PLAZO_MESES',          60.0000, 'Plazo estándar del financiamiento (meses)'),
('DEPRECIACION_RODAJE',  17.5000, 'Depreciación inmediata al salir de la agencia, rango 15 % - 20 % (%)'),
('DEPRECIACION_ANUAL',   10.0000, 'Depreciación estimada por cada año posterior, para proyecciones (%)'),
('SEGURO_AUTO_ANUAL',     2.5000, 'Prima anual del seguro de daños del vehículo sobre valor de agencia (%)'),
('SEGURO_VIDA_ANUAL',     0.5000, 'Prima anual del seguro de vida sobre monto financiado (%)'),
('COMISION_VENDEDOR',     1.5000, 'Porcentaje de comisión por defecto sobre cada pago efectivo (%)'),
('MIN_REFERENCIAS',       3.0000, 'Número mínimo de referencias personales por cliente');
GO

INSERT INTO dbo.TipoTelefono (TipoTelefonoId, Descripcion) VALUES
(1, 'Celular'),
(2, 'Casa'),
(3, 'Trabajo');
GO

INSERT INTO dbo.MedioPago (MedioPagoId, Codigo, Descripcion, RequiereReferencia) VALUES
(1, 'DEP', 'Depósito Bancario',     1),
(2, 'ACH', 'Transferencia ACH',     1),
(3, 'TC',  'Tarjeta de Crédito',    1),
(4, 'TD',  'Tarjeta de Débito',     1),
(5, 'EFE', 'Efectivo en Ventanilla', 0);
GO

INSERT INTO dbo.Marca (CodigoMarca, Nombre) VALUES
('TOY', 'Toyota'),
('NIS', 'Nissan'),
('HYU', 'Hyundai'),
('KIA', 'Kia'),
('MAZ', 'Mazda'),
('SUZ', 'Suzuki'),
('MIT', 'Mitsubishi'),
('HON', 'Honda'),
('CHE', 'Chevrolet'),
('ISU', 'Isuzu');
GO

INSERT INTO dbo.Agencia (Nombre, Region) VALUES
('Agencia Jalapa Centro',        'Oriente'),
('Agencia Chiquimula',           'Oriente'),
('Agencia Guatemala Zona 10',    'Metropolitana'),
('Agencia Mixco',                'Metropolitana'),
('Agencia Quetzaltenango',       'Occidente');
GO

PRINT 'Base de datos MagisAuto creada correctamente.';
GO
