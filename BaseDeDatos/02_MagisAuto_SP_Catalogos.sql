USE MagisAuto;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Parametro_Insertar
    @Codigo       VARCHAR(30),
    @Valor        DECIMAL(12,4),
    @Descripcion  VARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;
    SET @Codigo = UPPER(LTRIM(RTRIM(@Codigo)));
    IF EXISTS (SELECT 1 FROM dbo.Parametro WHERE Codigo = @Codigo)
        THROW 50001, 'Ya existe un parámetro con ese código.', 1;

    INSERT INTO dbo.Parametro (Codigo, Valor, Descripcion)
    VALUES (@Codigo, @Valor, @Descripcion);

    SELECT * FROM dbo.Parametro WHERE Codigo = @Codigo;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Parametro_Actualizar
    @Codigo       VARCHAR(30),
    @Valor        DECIMAL(12,4),
    @Descripcion  VARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.Parametro
       SET Valor = @Valor,
           Descripcion = @Descripcion,
           FechaModificacion = SYSDATETIME()
     WHERE Codigo = @Codigo;

    IF @@ROWCOUNT = 0
        THROW 50001, 'El parámetro no existe.', 1;

    SELECT 'ACTUALIZADO' AS Resultado, 'Parámetro actualizado. Aplica solo a créditos nuevos.' AS Mensaje;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Parametro_Eliminar
    @Codigo VARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;
    IF @Codigo IN ('TASA_INTERES_ANUAL', 'MANEJO_CUENTA', 'PLAZO_MESES', 'DEPRECIACION_RODAJE',
                   'DEPRECIACION_ANUAL', 'SEGURO_AUTO_ANUAL', 'SEGURO_VIDA_ANUAL',
                   'COMISION_VENDEDOR', 'MIN_REFERENCIAS')
        THROW 50001, 'Este parámetro es usado por el sistema y no puede eliminarse; solo modificarse.', 1;

    DELETE FROM dbo.Parametro WHERE Codigo = @Codigo;
    IF @@ROWCOUNT = 0
        THROW 50001, 'El parámetro no existe.', 1;

    SELECT 'ELIMINADO' AS Resultado, 'Parámetro eliminado.' AS Mensaje;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Parametro_Listar
AS
BEGIN
    SET NOCOUNT ON;
    SELECT Codigo, Valor, Descripcion, FechaModificacion
    FROM dbo.Parametro
    ORDER BY Codigo;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Parametro_Buscar
    @Codigo  VARCHAR(30)  = NULL,
    @Texto   VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT Codigo, Valor, Descripcion, FechaModificacion
    FROM dbo.Parametro
    WHERE (@Codigo IS NULL OR Codigo LIKE '%' + @Codigo + '%')
      AND (@Texto  IS NULL OR Descripcion LIKE '%' + @Texto + '%')
    ORDER BY Codigo;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_TipoTelefono_Insertar
    @TipoTelefonoId  TINYINT,
    @Descripcion     VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM dbo.TipoTelefono WHERE TipoTelefonoId = @TipoTelefonoId OR Descripcion = @Descripcion)
        THROW 50001, 'Ya existe un tipo de teléfono con ese código o descripción.', 1;

    INSERT INTO dbo.TipoTelefono (TipoTelefonoId, Descripcion) VALUES (@TipoTelefonoId, @Descripcion);
    SELECT * FROM dbo.TipoTelefono WHERE TipoTelefonoId = @TipoTelefonoId;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_TipoTelefono_Actualizar
    @TipoTelefonoId  TINYINT,
    @Descripcion     VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM dbo.TipoTelefono WHERE Descripcion = @Descripcion AND TipoTelefonoId <> @TipoTelefonoId)
        THROW 50001, 'Ya existe otro tipo de teléfono con esa descripción.', 1;

    UPDATE dbo.TipoTelefono SET Descripcion = @Descripcion WHERE TipoTelefonoId = @TipoTelefonoId;
    IF @@ROWCOUNT = 0
        THROW 50001, 'El tipo de teléfono no existe.', 1;

    SELECT 'ACTUALIZADO' AS Resultado, 'Tipo de teléfono actualizado.' AS Mensaje;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_TipoTelefono_Eliminar
    @TipoTelefonoId TINYINT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM dbo.TelefonoPersona WHERE TipoTelefonoId = @TipoTelefonoId)
       OR EXISTS (SELECT 1 FROM dbo.TelefonoReferencia WHERE TipoTelefonoId = @TipoTelefonoId)
        THROW 50001, 'No se puede eliminar: hay teléfonos registrados con este tipo.', 1;

    DELETE FROM dbo.TipoTelefono WHERE TipoTelefonoId = @TipoTelefonoId;
    IF @@ROWCOUNT = 0
        THROW 50001, 'El tipo de teléfono no existe.', 1;

    SELECT 'ELIMINADO' AS Resultado, 'Tipo de teléfono eliminado.' AS Mensaje;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_TipoTelefono_Listar
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TipoTelefonoId, Descripcion FROM dbo.TipoTelefono ORDER BY TipoTelefonoId;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_TipoTelefono_Buscar
    @TipoTelefonoId  TINYINT     = NULL,
    @Descripcion     VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TipoTelefonoId, Descripcion
    FROM dbo.TipoTelefono
    WHERE (@TipoTelefonoId IS NULL OR TipoTelefonoId = @TipoTelefonoId)
      AND (@Descripcion    IS NULL OR Descripcion LIKE '%' + @Descripcion + '%')
    ORDER BY TipoTelefonoId;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_MedioPago_Insertar
    @MedioPagoId         TINYINT,
    @Codigo              VARCHAR(5),
    @Descripcion         VARCHAR(40),
    @RequiereReferencia  BIT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Codigo = UPPER(LTRIM(RTRIM(@Codigo)));
    IF EXISTS (SELECT 1 FROM dbo.MedioPago
               WHERE MedioPagoId = @MedioPagoId OR Codigo = @Codigo OR Descripcion = @Descripcion)
        THROW 50001, 'Ya existe un medio de pago con ese id, código o descripción.', 1;

    INSERT INTO dbo.MedioPago (MedioPagoId, Codigo, Descripcion, RequiereReferencia)
    VALUES (@MedioPagoId, @Codigo, @Descripcion, @RequiereReferencia);

    SELECT * FROM dbo.MedioPago WHERE MedioPagoId = @MedioPagoId;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_MedioPago_Actualizar
    @MedioPagoId         TINYINT,
    @Codigo              VARCHAR(5),
    @Descripcion         VARCHAR(40),
    @RequiereReferencia  BIT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Codigo = UPPER(LTRIM(RTRIM(@Codigo)));
    IF EXISTS (SELECT 1 FROM dbo.MedioPago
               WHERE (Codigo = @Codigo OR Descripcion = @Descripcion) AND MedioPagoId <> @MedioPagoId)
        THROW 50001, 'Ya existe otro medio de pago con ese código o descripción.', 1;

    UPDATE dbo.MedioPago
       SET Codigo = @Codigo, Descripcion = @Descripcion, RequiereReferencia = @RequiereReferencia
     WHERE MedioPagoId = @MedioPagoId;
    IF @@ROWCOUNT = 0
        THROW 50001, 'El medio de pago no existe.', 1;

    SELECT 'ACTUALIZADO' AS Resultado, 'Medio de pago actualizado.' AS Mensaje;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_MedioPago_Eliminar
    @MedioPagoId TINYINT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM dbo.TransaccionPago WHERE MedioPagoId = @MedioPagoId)
        THROW 50001, 'No se puede eliminar: existen pagos registrados con este medio de pago.', 1;

    DELETE FROM dbo.MedioPago WHERE MedioPagoId = @MedioPagoId;
    IF @@ROWCOUNT = 0
        THROW 50001, 'El medio de pago no existe.', 1;

    SELECT 'ELIMINADO' AS Resultado, 'Medio de pago eliminado.' AS Mensaje;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_MedioPago_Listar
AS
BEGIN
    SET NOCOUNT ON;
    SELECT MedioPagoId, Codigo, Descripcion, RequiereReferencia
    FROM dbo.MedioPago ORDER BY MedioPagoId;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_MedioPago_Buscar
    @MedioPagoId         TINYINT     = NULL,
    @Codigo              VARCHAR(5)  = NULL,
    @Descripcion         VARCHAR(40) = NULL,
    @RequiereReferencia  BIT         = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT MedioPagoId, Codigo, Descripcion, RequiereReferencia
    FROM dbo.MedioPago
    WHERE (@MedioPagoId        IS NULL OR MedioPagoId = @MedioPagoId)
      AND (@Codigo             IS NULL OR Codigo = @Codigo)
      AND (@Descripcion        IS NULL OR Descripcion LIKE '%' + @Descripcion + '%')
      AND (@RequiereReferencia IS NULL OR RequiereReferencia = @RequiereReferencia)
    ORDER BY MedioPagoId;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Marca_Insertar
    @CodigoMarca  VARCHAR(10),
    @Nombre       VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    SET @CodigoMarca = UPPER(LTRIM(RTRIM(@CodigoMarca)));
    IF EXISTS (SELECT 1 FROM dbo.Marca WHERE CodigoMarca = @CodigoMarca OR Nombre = @Nombre)
        THROW 50001, 'Ya existe una marca con ese código o nombre.', 1;

    INSERT INTO dbo.Marca (CodigoMarca, Nombre) VALUES (@CodigoMarca, @Nombre);
    SELECT * FROM dbo.Marca WHERE MarcaId = SCOPE_IDENTITY();
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Marca_Actualizar
    @MarcaId      INT,
    @CodigoMarca  VARCHAR(10),
    @Nombre       VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    SET @CodigoMarca = UPPER(LTRIM(RTRIM(@CodigoMarca)));
    IF EXISTS (SELECT 1 FROM dbo.Marca WHERE (CodigoMarca = @CodigoMarca OR Nombre = @Nombre) AND MarcaId <> @MarcaId)
        THROW 50001, 'Ya existe otra marca con ese código o nombre.', 1;

    UPDATE dbo.Marca SET CodigoMarca = @CodigoMarca, Nombre = @Nombre WHERE MarcaId = @MarcaId;
    IF @@ROWCOUNT = 0
        THROW 50001, 'La marca no existe.', 1;

    SELECT 'ACTUALIZADO' AS Resultado, 'Marca actualizada.' AS Mensaje;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Marca_Eliminar
    @MarcaId INT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM dbo.Vehiculo WHERE MarcaId = @MarcaId)
        THROW 50001, 'No se puede eliminar: hay vehículos registrados con esta marca.', 1;

    DELETE FROM dbo.Marca WHERE MarcaId = @MarcaId;
    IF @@ROWCOUNT = 0
        THROW 50001, 'La marca no existe.', 1;

    SELECT 'ELIMINADO' AS Resultado, 'Marca eliminada.' AS Mensaje;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Marca_Listar
AS
BEGIN
    SET NOCOUNT ON;
    SELECT m.MarcaId, m.CodigoMarca, m.Nombre,
           (SELECT COUNT(*) FROM dbo.Vehiculo v WHERE v.MarcaId = m.MarcaId) AS Vehiculos
    FROM dbo.Marca m
    ORDER BY m.Nombre;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Marca_Buscar
    @MarcaId      INT         = NULL,
    @CodigoMarca  VARCHAR(10) = NULL,
    @Nombre       VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT m.MarcaId, m.CodigoMarca, m.Nombre,
           (SELECT COUNT(*) FROM dbo.Vehiculo v WHERE v.MarcaId = m.MarcaId) AS Vehiculos
    FROM dbo.Marca m
    WHERE (@MarcaId     IS NULL OR m.MarcaId = @MarcaId)
      AND (@CodigoMarca IS NULL OR m.CodigoMarca = @CodigoMarca)
      AND (@Nombre      IS NULL OR m.Nombre LIKE '%' + @Nombre + '%')
    ORDER BY m.Nombre;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Agencia_Insertar
    @Nombre  VARCHAR(80),
    @Region  VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM dbo.Agencia WHERE Nombre = @Nombre)
        THROW 50001, 'Ya existe una agencia con ese nombre.', 1;

    INSERT INTO dbo.Agencia (Nombre, Region) VALUES (@Nombre, @Region);
    SELECT * FROM dbo.Agencia WHERE AgenciaId = SCOPE_IDENTITY();
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Agencia_Actualizar
    @AgenciaId  INT,
    @Nombre     VARCHAR(80),
    @Region     VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM dbo.Agencia WHERE Nombre = @Nombre AND AgenciaId <> @AgenciaId)
        THROW 50001, 'Ya existe otra agencia con ese nombre.', 1;

    UPDATE dbo.Agencia SET Nombre = @Nombre, Region = @Region WHERE AgenciaId = @AgenciaId;
    IF @@ROWCOUNT = 0
        THROW 50001, 'La agencia no existe.', 1;

    SELECT 'ACTUALIZADO' AS Resultado, 'Agencia actualizada.' AS Mensaje;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Agencia_Eliminar
    @AgenciaId INT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM dbo.Vendedor WHERE AgenciaId = @AgenciaId)
        THROW 50001, 'No se puede eliminar: la agencia tiene vendedores asignados.', 1;

    DELETE FROM dbo.Agencia WHERE AgenciaId = @AgenciaId;
    IF @@ROWCOUNT = 0
        THROW 50001, 'La agencia no existe.', 1;

    SELECT 'ELIMINADO' AS Resultado, 'Agencia eliminada.' AS Mensaje;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Agencia_Listar
AS
BEGIN
    SET NOCOUNT ON;
    SELECT a.AgenciaId, a.Nombre, a.Region,
           (SELECT COUNT(*) FROM dbo.Vendedor v WHERE v.AgenciaId = a.AgenciaId AND v.Activo = 1) AS VendedoresActivos
    FROM dbo.Agencia a
    ORDER BY a.Region, a.Nombre;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Agencia_Buscar
    @AgenciaId  INT         = NULL,
    @Nombre     VARCHAR(80) = NULL,
    @Region     VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT a.AgenciaId, a.Nombre, a.Region,
           (SELECT COUNT(*) FROM dbo.Vendedor v WHERE v.AgenciaId = a.AgenciaId AND v.Activo = 1) AS VendedoresActivos
    FROM dbo.Agencia a
    WHERE (@AgenciaId IS NULL OR a.AgenciaId = @AgenciaId)
      AND (@Nombre    IS NULL OR a.Nombre LIKE '%' + @Nombre + '%')
      AND (@Region    IS NULL OR a.Region LIKE '%' + @Region + '%')
    ORDER BY a.Region, a.Nombre;
END
GO

CREATE OR ALTER VIEW dbo.vw_Vendedor
AS
SELECT v.VendedorId, v.CodigoEmpleado, v.DPI, v.Nombres, v.Apellidos,
       v.Nombres + ' ' + v.Apellidos AS NombreCompleto,
       v.AgenciaId, a.Nombre AS Agencia, a.Region, v.Activo,
       (SELECT COUNT(*) FROM dbo.Credito c WHERE c.VendedorId = v.VendedorId) AS CreditosColocados
FROM dbo.Vendedor v
JOIN dbo.Agencia a ON a.AgenciaId = v.AgenciaId;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Vendedor_Insertar
    @CodigoEmpleado  VARCHAR(10),
    @DPI             CHAR(13),
    @Nombres         VARCHAR(80),
    @Apellidos       VARCHAR(80),
    @AgenciaId       INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.Agencia WHERE AgenciaId = @AgenciaId)
        THROW 50001, 'La agencia indicada no existe.', 1;
    IF EXISTS (SELECT 1 FROM dbo.Vendedor WHERE CodigoEmpleado = @CodigoEmpleado)
        THROW 50001, 'Ya existe un vendedor con ese código de empleado.', 1;
    IF EXISTS (SELECT 1 FROM dbo.Vendedor WHERE DPI = @DPI)
        THROW 50001, 'Ya existe un vendedor con ese DPI.', 1;

    INSERT INTO dbo.Vendedor (CodigoEmpleado, DPI, Nombres, Apellidos, AgenciaId)
    VALUES (@CodigoEmpleado, @DPI, @Nombres, @Apellidos, @AgenciaId);

    SELECT * FROM dbo.vw_Vendedor WHERE VendedorId = SCOPE_IDENTITY();
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Vendedor_Actualizar
    @VendedorId      INT,
    @CodigoEmpleado  VARCHAR(10),
    @DPI             CHAR(13),
    @Nombres         VARCHAR(80),
    @Apellidos       VARCHAR(80),
    @AgenciaId       INT,
    @Activo          BIT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.Agencia WHERE AgenciaId = @AgenciaId)
        THROW 50001, 'La agencia indicada no existe.', 1;
    IF EXISTS (SELECT 1 FROM dbo.Vendedor WHERE (CodigoEmpleado = @CodigoEmpleado OR DPI = @DPI) AND VendedorId <> @VendedorId)
        THROW 50001, 'Ya existe otro vendedor con ese código de empleado o DPI.', 1;

    UPDATE dbo.Vendedor
       SET CodigoEmpleado = @CodigoEmpleado, DPI = @DPI, Nombres = @Nombres,
           Apellidos = @Apellidos, AgenciaId = @AgenciaId, Activo = @Activo
     WHERE VendedorId = @VendedorId;
    IF @@ROWCOUNT = 0
        THROW 50001, 'El vendedor no existe.', 1;

    SELECT 'ACTUALIZADO' AS Resultado, 'Vendedor actualizado.' AS Mensaje;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Vendedor_Eliminar
    @VendedorId INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.Vendedor WHERE VendedorId = @VendedorId)
        THROW 50001, 'El vendedor no existe.', 1;

    IF EXISTS (SELECT 1 FROM dbo.Credito WHERE VendedorId = @VendedorId)
    BEGIN
        UPDATE dbo.Vendedor SET Activo = 0 WHERE VendedorId = @VendedorId;
        SELECT 'DESACTIVADO' AS Resultado,
               'El vendedor tiene créditos colocados; se desactivó para conservar el historial de comisiones.' AS Mensaje;
        RETURN;
    END

    DELETE FROM dbo.Vendedor WHERE VendedorId = @VendedorId;
    SELECT 'ELIMINADO' AS Resultado, 'Vendedor eliminado.' AS Mensaje;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Vendedor_Listar
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM dbo.vw_Vendedor ORDER BY Apellidos, Nombres;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Vendedor_Buscar
    @VendedorId      INT         = NULL,
    @CodigoEmpleado  VARCHAR(10) = NULL,
    @DPI             CHAR(13)    = NULL,
    @Nombre          VARCHAR(80) = NULL,
    @AgenciaId       INT         = NULL,
    @Region          VARCHAR(50) = NULL,
    @Activo          BIT         = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT *
    FROM dbo.vw_Vendedor
    WHERE (@VendedorId     IS NULL OR VendedorId = @VendedorId)
      AND (@CodigoEmpleado IS NULL OR CodigoEmpleado = @CodigoEmpleado)
      AND (@DPI            IS NULL OR DPI = @DPI)
      AND (@Nombre         IS NULL OR NombreCompleto LIKE '%' + @Nombre + '%')
      AND (@AgenciaId      IS NULL OR AgenciaId = @AgenciaId)
      AND (@Region         IS NULL OR Region LIKE '%' + @Region + '%')
      AND (@Activo         IS NULL OR Activo = @Activo)
    ORDER BY Apellidos, Nombres;
END
GO

CREATE OR ALTER VIEW dbo.vw_Persona
AS
SELECT p.PersonaId, p.DPI, p.NIT, p.Nombres, p.Apellidos,
       p.Nombres + ' ' + p.Apellidos AS NombreCompleto,
       p.FechaNacimiento, p.Correo, p.FechaRegistro,
       (SELECT STRING_AGG(t.Numero, ', ') FROM dbo.TelefonoPersona t WHERE t.PersonaId = p.PersonaId) AS Telefonos,
       c.ClienteId, f.FiadorId,
       CAST(CASE WHEN c.ClienteId IS NOT NULL THEN 1 ELSE 0 END AS BIT) AS EsCliente,
       CAST(CASE WHEN f.FiadorId  IS NOT NULL THEN 1 ELSE 0 END AS BIT) AS EsFiador
FROM dbo.Persona p
LEFT JOIN dbo.Cliente c ON c.PersonaId = p.PersonaId
LEFT JOIN dbo.Fiador  f ON f.PersonaId = p.PersonaId;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Persona_Listar
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM dbo.vw_Persona ORDER BY Apellidos, Nombres;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Persona_Buscar
    @PersonaId  INT          = NULL,
    @DPI        CHAR(13)     = NULL,
    @NIT        VARCHAR(15)  = NULL,
    @Nombre     VARCHAR(160) = NULL,
    @EsCliente  BIT          = NULL,
    @EsFiador   BIT          = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT *
    FROM dbo.vw_Persona
    WHERE (@PersonaId IS NULL OR PersonaId = @PersonaId)
      AND (@DPI       IS NULL OR DPI = @DPI)
      AND (@NIT       IS NULL OR NIT = @NIT)
      AND (@Nombre    IS NULL OR NombreCompleto LIKE '%' + @Nombre + '%')
      AND (@EsCliente IS NULL OR EsCliente = @EsCliente)
      AND (@EsFiador  IS NULL OR EsFiador = @EsFiador)
    ORDER BY Apellidos, Nombres;
END
GO

CREATE OR ALTER VIEW dbo.vw_Cliente
AS
SELECT c.ClienteId, p.PersonaId, p.DPI, p.NIT, p.Nombres, p.Apellidos,
       p.Nombres + ' ' + p.Apellidos AS NombreCompleto,
       p.FechaNacimiento, p.Correo,
       (SELECT STRING_AGG(t.Numero, ', ') FROM dbo.TelefonoPersona t WHERE t.PersonaId = p.PersonaId) AS Telefonos,
       (SELECT COUNT(*) FROM dbo.DireccionPersona d WHERE d.PersonaId = p.PersonaId) AS Direcciones,
       (SELECT COUNT(*) FROM dbo.Referencia r WHERE r.ClienteId = c.ClienteId AND r.Activo = 1) AS Referencias,
       (SELECT COUNT(*) FROM dbo.Credito cr WHERE cr.ClienteId = c.ClienteId AND cr.Estado = 'ACTIVO') AS CreditosActivos,
       c.FechaAlta, c.Activo
FROM dbo.Cliente c
JOIN dbo.Persona p ON p.PersonaId = c.PersonaId;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Cliente_Insertar
    @DPI              CHAR(13),
    @NIT              VARCHAR(15),
    @Nombres          VARCHAR(80),
    @Apellidos        VARCHAR(80),
    @FechaNacimiento  DATE,
    @Correo           VARCHAR(120)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @PersonaId INT, @ClienteId INT;
    SELECT @PersonaId = PersonaId FROM dbo.Persona WHERE DPI = @DPI;

    IF @PersonaId IS NOT NULL AND EXISTS (SELECT 1 FROM dbo.Cliente WHERE PersonaId = @PersonaId)
        THROW 50001, 'Ya existe un cliente registrado con ese DPI.', 1;
    IF EXISTS (SELECT 1 FROM dbo.Persona WHERE NIT = @NIT AND (@PersonaId IS NULL OR PersonaId <> @PersonaId))
        THROW 50001, 'Ese NIT ya pertenece a otra persona.', 1;

    BEGIN TRANSACTION;
        IF @PersonaId IS NULL
        BEGIN
            INSERT INTO dbo.Persona (DPI, NIT, Nombres, Apellidos, FechaNacimiento, Correo)
            VALUES (@DPI, @NIT, @Nombres, @Apellidos, @FechaNacimiento, @Correo);
            SET @PersonaId = SCOPE_IDENTITY();
        END
        ELSE
        BEGIN
            UPDATE dbo.Persona
               SET NIT = @NIT, Nombres = @Nombres, Apellidos = @Apellidos,
                   FechaNacimiento = @FechaNacimiento, Correo = @Correo
             WHERE PersonaId = @PersonaId;
        END

        INSERT INTO dbo.Cliente (PersonaId) VALUES (@PersonaId);
        SET @ClienteId = SCOPE_IDENTITY();
    COMMIT TRANSACTION;

    SELECT * FROM dbo.vw_Cliente WHERE ClienteId = @ClienteId;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Cliente_Actualizar
    @ClienteId        INT,
    @DPI              CHAR(13),
    @NIT              VARCHAR(15),
    @Nombres          VARCHAR(80),
    @Apellidos        VARCHAR(80),
    @FechaNacimiento  DATE,
    @Correo           VARCHAR(120),
    @Activo           BIT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @PersonaId INT;
    SELECT @PersonaId = PersonaId FROM dbo.Cliente WHERE ClienteId = @ClienteId;
    IF @PersonaId IS NULL
        THROW 50001, 'El cliente no existe.', 1;
    IF EXISTS (SELECT 1 FROM dbo.Persona WHERE DPI = @DPI AND PersonaId <> @PersonaId)
        THROW 50001, 'Ese DPI ya pertenece a otra persona.', 1;
    IF EXISTS (SELECT 1 FROM dbo.Persona WHERE NIT = @NIT AND PersonaId <> @PersonaId)
        THROW 50001, 'Ese NIT ya pertenece a otra persona.', 1;

    BEGIN TRANSACTION;
        UPDATE dbo.Persona
           SET DPI = @DPI, NIT = @NIT, Nombres = @Nombres, Apellidos = @Apellidos,
               FechaNacimiento = @FechaNacimiento, Correo = @Correo
         WHERE PersonaId = @PersonaId;

        UPDATE dbo.Cliente SET Activo = @Activo WHERE ClienteId = @ClienteId;
    COMMIT TRANSACTION;

    SELECT 'ACTUALIZADO' AS Resultado, 'Cliente actualizado.' AS Mensaje;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Cliente_Eliminar
    @ClienteId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @PersonaId INT;
    SELECT @PersonaId = PersonaId FROM dbo.Cliente WHERE ClienteId = @ClienteId;
    IF @PersonaId IS NULL
        THROW 50001, 'El cliente no existe.', 1;

    IF EXISTS (SELECT 1 FROM dbo.Credito WHERE ClienteId = @ClienteId)
    BEGIN
        UPDATE dbo.Cliente SET Activo = 0 WHERE ClienteId = @ClienteId;
        SELECT 'DESACTIVADO' AS Resultado,
               'El cliente tiene créditos registrados; se desactivó para conservar el historial.' AS Mensaje;
        RETURN;
    END

    BEGIN TRANSACTION;
        DELETE tr FROM dbo.TelefonoReferencia tr
        JOIN dbo.Referencia r ON r.ReferenciaId = tr.ReferenciaId
        WHERE r.ClienteId = @ClienteId;

        DELETE dr FROM dbo.DireccionReferencia dr
        JOIN dbo.Referencia r ON r.ReferenciaId = dr.ReferenciaId
        WHERE r.ClienteId = @ClienteId;

        DELETE FROM dbo.Referencia WHERE ClienteId = @ClienteId;
        DELETE FROM dbo.Cliente    WHERE ClienteId = @ClienteId;

        IF NOT EXISTS (SELECT 1 FROM dbo.Fiador WHERE PersonaId = @PersonaId)
        BEGIN
            DELETE FROM dbo.TelefonoPersona  WHERE PersonaId = @PersonaId;
            DELETE FROM dbo.DireccionPersona WHERE PersonaId = @PersonaId;
            DELETE FROM dbo.Persona          WHERE PersonaId = @PersonaId;
        END
    COMMIT TRANSACTION;

    SELECT 'ELIMINADO' AS Resultado, 'Cliente eliminado.' AS Mensaje;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Cliente_Listar
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM dbo.vw_Cliente ORDER BY ClienteId;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Cliente_Buscar
    @ClienteId  INT          = NULL,
    @DPI        CHAR(13)     = NULL,
    @NIT        VARCHAR(15)  = NULL,
    @Nombre     VARCHAR(160) = NULL,
    @Correo     VARCHAR(120) = NULL,
    @Telefono   VARCHAR(15)  = NULL,
    @Activo     BIT          = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT *
    FROM dbo.vw_Cliente
    WHERE (@ClienteId IS NULL OR ClienteId = @ClienteId)
      AND (@DPI       IS NULL OR DPI = @DPI)
      AND (@NIT       IS NULL OR NIT = @NIT)
      AND (@Nombre    IS NULL OR NombreCompleto LIKE '%' + @Nombre + '%')
      AND (@Correo    IS NULL OR Correo LIKE '%' + @Correo + '%')
      AND (@Telefono  IS NULL OR Telefonos LIKE '%' + @Telefono + '%')
      AND (@Activo    IS NULL OR Activo = @Activo)
    ORDER BY ClienteId;
END
GO

CREATE OR ALTER VIEW dbo.vw_Fiador
AS
SELECT f.FiadorId, p.PersonaId, p.DPI, p.NIT, p.Nombres, p.Apellidos,
       p.Nombres + ' ' + p.Apellidos AS NombreCompleto,
       p.FechaNacimiento, p.Correo,
       (SELECT STRING_AGG(t.Numero, ', ') FROM dbo.TelefonoPersona t WHERE t.PersonaId = p.PersonaId) AS Telefonos,
       (SELECT COUNT(*) FROM dbo.CreditoFiador cf WHERE cf.FiadorId = f.FiadorId) AS CreditosRespaldados,
       f.FechaAlta, f.Activo
FROM dbo.Fiador f
JOIN dbo.Persona p ON p.PersonaId = f.PersonaId;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Fiador_Insertar
    @DPI              CHAR(13),
    @NIT              VARCHAR(15),
    @Nombres          VARCHAR(80),
    @Apellidos        VARCHAR(80),
    @FechaNacimiento  DATE,
    @Correo           VARCHAR(120)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @PersonaId INT, @FiadorId INT;
    SELECT @PersonaId = PersonaId FROM dbo.Persona WHERE DPI = @DPI;

    IF @PersonaId IS NOT NULL AND EXISTS (SELECT 1 FROM dbo.Fiador WHERE PersonaId = @PersonaId)
        THROW 50001, 'Ya existe un fiador registrado con ese DPI.', 1;
    IF EXISTS (SELECT 1 FROM dbo.Persona WHERE NIT = @NIT AND (@PersonaId IS NULL OR PersonaId <> @PersonaId))
        THROW 50001, 'Ese NIT ya pertenece a otra persona.', 1;

    BEGIN TRANSACTION;
        IF @PersonaId IS NULL
        BEGIN
            INSERT INTO dbo.Persona (DPI, NIT, Nombres, Apellidos, FechaNacimiento, Correo)
            VALUES (@DPI, @NIT, @Nombres, @Apellidos, @FechaNacimiento, @Correo);
            SET @PersonaId = SCOPE_IDENTITY();
        END
        ELSE
        BEGIN
            UPDATE dbo.Persona
               SET NIT = @NIT, Nombres = @Nombres, Apellidos = @Apellidos,
                   FechaNacimiento = @FechaNacimiento, Correo = @Correo
             WHERE PersonaId = @PersonaId;
        END

        INSERT INTO dbo.Fiador (PersonaId) VALUES (@PersonaId);
        SET @FiadorId = SCOPE_IDENTITY();
    COMMIT TRANSACTION;

    SELECT * FROM dbo.vw_Fiador WHERE FiadorId = @FiadorId;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Fiador_Actualizar
    @FiadorId         INT,
    @DPI              CHAR(13),
    @NIT              VARCHAR(15),
    @Nombres          VARCHAR(80),
    @Apellidos        VARCHAR(80),
    @FechaNacimiento  DATE,
    @Correo           VARCHAR(120),
    @Activo           BIT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @PersonaId INT;
    SELECT @PersonaId = PersonaId FROM dbo.Fiador WHERE FiadorId = @FiadorId;
    IF @PersonaId IS NULL
        THROW 50001, 'El fiador no existe.', 1;
    IF EXISTS (SELECT 1 FROM dbo.Persona WHERE DPI = @DPI AND PersonaId <> @PersonaId)
        THROW 50001, 'Ese DPI ya pertenece a otra persona.', 1;
    IF EXISTS (SELECT 1 FROM dbo.Persona WHERE NIT = @NIT AND PersonaId <> @PersonaId)
        THROW 50001, 'Ese NIT ya pertenece a otra persona.', 1;

    BEGIN TRANSACTION;
        UPDATE dbo.Persona
           SET DPI = @DPI, NIT = @NIT, Nombres = @Nombres, Apellidos = @Apellidos,
               FechaNacimiento = @FechaNacimiento, Correo = @Correo
         WHERE PersonaId = @PersonaId;

        UPDATE dbo.Fiador SET Activo = @Activo WHERE FiadorId = @FiadorId;
    COMMIT TRANSACTION;

    SELECT 'ACTUALIZADO' AS Resultado, 'Fiador actualizado.' AS Mensaje;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Fiador_Eliminar
    @FiadorId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @PersonaId INT;
    SELECT @PersonaId = PersonaId FROM dbo.Fiador WHERE FiadorId = @FiadorId;
    IF @PersonaId IS NULL
        THROW 50001, 'El fiador no existe.', 1;

    IF EXISTS (SELECT 1 FROM dbo.CreditoFiador WHERE FiadorId = @FiadorId)
    BEGIN
        UPDATE dbo.Fiador SET Activo = 0 WHERE FiadorId = @FiadorId;
        SELECT 'DESACTIVADO' AS Resultado,
               'El fiador respalda créditos registrados; se desactivó para conservar el historial.' AS Mensaje;
        RETURN;
    END

    BEGIN TRANSACTION;
        DELETE FROM dbo.Fiador WHERE FiadorId = @FiadorId;

        IF NOT EXISTS (SELECT 1 FROM dbo.Cliente WHERE PersonaId = @PersonaId)
        BEGIN
            DELETE FROM dbo.TelefonoPersona  WHERE PersonaId = @PersonaId;
            DELETE FROM dbo.DireccionPersona WHERE PersonaId = @PersonaId;
            DELETE FROM dbo.Persona          WHERE PersonaId = @PersonaId;
        END
    COMMIT TRANSACTION;

    SELECT 'ELIMINADO' AS Resultado, 'Fiador eliminado.' AS Mensaje;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Fiador_Listar
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM dbo.vw_Fiador ORDER BY FiadorId;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Fiador_Buscar
    @FiadorId  INT          = NULL,
    @DPI       CHAR(13)     = NULL,
    @NIT       VARCHAR(15)  = NULL,
    @Nombre    VARCHAR(160) = NULL,
    @Correo    VARCHAR(120) = NULL,
    @Activo    BIT          = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT *
    FROM dbo.vw_Fiador
    WHERE (@FiadorId IS NULL OR FiadorId = @FiadorId)
      AND (@DPI      IS NULL OR DPI = @DPI)
      AND (@NIT      IS NULL OR NIT = @NIT)
      AND (@Nombre   IS NULL OR NombreCompleto LIKE '%' + @Nombre + '%')
      AND (@Correo   IS NULL OR Correo LIKE '%' + @Correo + '%')
      AND (@Activo   IS NULL OR Activo = @Activo)
    ORDER BY FiadorId;
END
GO

CREATE OR ALTER VIEW dbo.vw_TelefonoPersona
AS
SELECT t.TelefonoPersonaId, t.PersonaId, p.Nombres + ' ' + p.Apellidos AS NombreCompleto,
       t.TipoTelefonoId, tt.Descripcion AS TipoTelefono, t.Numero
FROM dbo.TelefonoPersona t
JOIN dbo.Persona p       ON p.PersonaId = t.PersonaId
JOIN dbo.TipoTelefono tt ON tt.TipoTelefonoId = t.TipoTelefonoId;
GO

CREATE OR ALTER PROCEDURE dbo.sp_TelefonoPersona_Insertar
    @PersonaId       INT,
    @TipoTelefonoId  TINYINT,
    @Numero          VARCHAR(15)
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.Persona WHERE PersonaId = @PersonaId)
        THROW 50001, 'La persona no existe.', 1;
    IF NOT EXISTS (SELECT 1 FROM dbo.TipoTelefono WHERE TipoTelefonoId = @TipoTelefonoId)
        THROW 50001, 'El tipo de teléfono no existe.', 1;
    IF EXISTS (SELECT 1 FROM dbo.TelefonoPersona WHERE PersonaId = @PersonaId AND Numero = @Numero)
        THROW 50001, 'Ese número ya está registrado para esta persona.', 1;

    INSERT INTO dbo.TelefonoPersona (PersonaId, TipoTelefonoId, Numero)
    VALUES (@PersonaId, @TipoTelefonoId, @Numero);

    SELECT * FROM dbo.vw_TelefonoPersona WHERE TelefonoPersonaId = SCOPE_IDENTITY();
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_TelefonoPersona_Actualizar
    @TelefonoPersonaId  INT,
    @TipoTelefonoId     TINYINT,
    @Numero             VARCHAR(15)
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.TipoTelefono WHERE TipoTelefonoId = @TipoTelefonoId)
        THROW 50001, 'El tipo de teléfono no existe.', 1;
    IF EXISTS (SELECT 1 FROM dbo.TelefonoPersona t
               WHERE t.Numero = @Numero AND t.TelefonoPersonaId <> @TelefonoPersonaId
                 AND t.PersonaId = (SELECT PersonaId FROM dbo.TelefonoPersona WHERE TelefonoPersonaId = @TelefonoPersonaId))
        THROW 50001, 'Ese número ya está registrado para esta persona.', 1;

    UPDATE dbo.TelefonoPersona
       SET TipoTelefonoId = @TipoTelefonoId, Numero = @Numero
     WHERE TelefonoPersonaId = @TelefonoPersonaId;
    IF @@ROWCOUNT = 0
        THROW 50001, 'El teléfono no existe.', 1;

    SELECT 'ACTUALIZADO' AS Resultado, 'Teléfono actualizado.' AS Mensaje;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_TelefonoPersona_Eliminar
    @TelefonoPersonaId INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM dbo.TelefonoPersona WHERE TelefonoPersonaId = @TelefonoPersonaId;
    IF @@ROWCOUNT = 0
        THROW 50001, 'El teléfono no existe.', 1;

    SELECT 'ELIMINADO' AS Resultado, 'Teléfono eliminado.' AS Mensaje;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_TelefonoPersona_Listar
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM dbo.vw_TelefonoPersona ORDER BY PersonaId, TipoTelefonoId;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_TelefonoPersona_Buscar
    @PersonaId       INT         = NULL,
    @TipoTelefonoId  TINYINT     = NULL,
    @Numero          VARCHAR(15) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT *
    FROM dbo.vw_TelefonoPersona
    WHERE (@PersonaId      IS NULL OR PersonaId = @PersonaId)
      AND (@TipoTelefonoId IS NULL OR TipoTelefonoId = @TipoTelefonoId)
      AND (@Numero         IS NULL OR Numero LIKE '%' + @Numero + '%')
    ORDER BY PersonaId, TipoTelefonoId;
END
GO

CREATE OR ALTER VIEW dbo.vw_DireccionPersona
AS
SELECT d.DireccionPersonaId, d.PersonaId, p.Nombres + ' ' + p.Apellidos AS NombreCompleto,
       d.Direccion, d.Municipio, d.Departamento
FROM dbo.DireccionPersona d
JOIN dbo.Persona p ON p.PersonaId = d.PersonaId;
GO

CREATE OR ALTER PROCEDURE dbo.sp_DireccionPersona_Insertar
    @PersonaId     INT,
    @Direccion     VARCHAR(200),
    @Municipio     VARCHAR(60),
    @Departamento  VARCHAR(40)
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.Persona WHERE PersonaId = @PersonaId)
        THROW 50001, 'La persona no existe.', 1;

    INSERT INTO dbo.DireccionPersona (PersonaId, Direccion, Municipio, Departamento)
    VALUES (@PersonaId, @Direccion, @Municipio, @Departamento);

    SELECT * FROM dbo.vw_DireccionPersona WHERE DireccionPersonaId = SCOPE_IDENTITY();
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_DireccionPersona_Actualizar
    @DireccionPersonaId  INT,
    @Direccion           VARCHAR(200),
    @Municipio           VARCHAR(60),
    @Departamento        VARCHAR(40)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.DireccionPersona
       SET Direccion = @Direccion, Municipio = @Municipio, Departamento = @Departamento
     WHERE DireccionPersonaId = @DireccionPersonaId;
    IF @@ROWCOUNT = 0
        THROW 50001, 'La dirección no existe.', 1;

    SELECT 'ACTUALIZADO' AS Resultado, 'Dirección actualizada.' AS Mensaje;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_DireccionPersona_Eliminar
    @DireccionPersonaId INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM dbo.DireccionPersona WHERE DireccionPersonaId = @DireccionPersonaId;
    IF @@ROWCOUNT = 0
        THROW 50001, 'La dirección no existe.', 1;

    SELECT 'ELIMINADO' AS Resultado, 'Dirección eliminada.' AS Mensaje;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_DireccionPersona_Listar
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM dbo.vw_DireccionPersona ORDER BY PersonaId;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_DireccionPersona_Buscar
    @PersonaId     INT          = NULL,
    @Texto         VARCHAR(200) = NULL,
    @Municipio     VARCHAR(60)  = NULL,
    @Departamento  VARCHAR(40)  = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT *
    FROM dbo.vw_DireccionPersona
    WHERE (@PersonaId    IS NULL OR PersonaId = @PersonaId)
      AND (@Texto        IS NULL OR Direccion LIKE '%' + @Texto + '%')
      AND (@Municipio    IS NULL OR Municipio LIKE '%' + @Municipio + '%')
      AND (@Departamento IS NULL OR Departamento LIKE '%' + @Departamento + '%')
    ORDER BY PersonaId;
END
GO

CREATE OR ALTER VIEW dbo.vw_Referencia
AS
SELECT r.ReferenciaId, r.ClienteId, p.Nombres + ' ' + p.Apellidos AS Cliente,
       r.NombreCompleto, r.LugarTrabajo, r.Parentesco, r.Activo,
       (SELECT STRING_AGG(tt.Descripcion + ': ' + t.Numero, ', ')
          FROM dbo.TelefonoReferencia t
          JOIN dbo.TipoTelefono tt ON tt.TipoTelefonoId = t.TipoTelefonoId
         WHERE t.ReferenciaId = r.ReferenciaId) AS Telefonos,
       (SELECT STRING_AGG(d.Direccion + ', ' + d.Municipio + ', ' + d.Departamento, ' | ')
          FROM dbo.DireccionReferencia d
         WHERE d.ReferenciaId = r.ReferenciaId) AS Direcciones
FROM dbo.Referencia r
JOIN dbo.Cliente c ON c.ClienteId = r.ClienteId
JOIN dbo.Persona p ON p.PersonaId = c.PersonaId;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Referencia_Insertar
    @ClienteId       INT,
    @NombreCompleto  VARCHAR(160),
    @LugarTrabajo    VARCHAR(120) = NULL,
    @Parentesco      VARCHAR(40)
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.Cliente WHERE ClienteId = @ClienteId)
        THROW 50001, 'El cliente no existe.', 1;

    INSERT INTO dbo.Referencia (ClienteId, NombreCompleto, LugarTrabajo, Parentesco)
    VALUES (@ClienteId, @NombreCompleto, @LugarTrabajo, @Parentesco);

    SELECT * FROM dbo.vw_Referencia WHERE ReferenciaId = SCOPE_IDENTITY();
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Referencia_Actualizar
    @ReferenciaId    INT,
    @NombreCompleto  VARCHAR(160),
    @LugarTrabajo    VARCHAR(120) = NULL,
    @Parentesco      VARCHAR(40)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.Referencia
       SET NombreCompleto = @NombreCompleto, LugarTrabajo = @LugarTrabajo, Parentesco = @Parentesco
     WHERE ReferenciaId = @ReferenciaId;
    IF @@ROWCOUNT = 0
        THROW 50001, 'La referencia no existe.', 1;

    SELECT 'ACTUALIZADO' AS Resultado, 'Referencia actualizada.' AS Mensaje;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Referencia_Eliminar
    @ReferenciaId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @ClienteId INT, @Minimo INT, @Restantes INT;
    SELECT @ClienteId = ClienteId FROM dbo.Referencia WHERE ReferenciaId = @ReferenciaId;
    IF @ClienteId IS NULL
        THROW 50001, 'La referencia no existe.', 1;

    SELECT @Minimo = CAST(Valor AS INT) FROM dbo.Parametro WHERE Codigo = 'MIN_REFERENCIAS';
    SELECT @Restantes = COUNT(*) FROM dbo.Referencia
     WHERE ClienteId = @ClienteId AND Activo = 1 AND ReferenciaId <> @ReferenciaId;

    IF EXISTS (SELECT 1 FROM dbo.Credito WHERE ClienteId = @ClienteId AND Estado = 'ACTIVO')
       AND @Restantes < @Minimo
        THROW 50001, 'No se puede eliminar: el cliente tiene un crédito activo y quedaría con menos referencias del mínimo requerido.', 1;

    BEGIN TRANSACTION;
        DELETE FROM dbo.TelefonoReferencia  WHERE ReferenciaId = @ReferenciaId;
        DELETE FROM dbo.DireccionReferencia WHERE ReferenciaId = @ReferenciaId;
        DELETE FROM dbo.Referencia          WHERE ReferenciaId = @ReferenciaId;
    COMMIT TRANSACTION;

    SELECT 'ELIMINADO' AS Resultado, 'Referencia eliminada.' AS Mensaje;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Referencia_Listar
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM dbo.vw_Referencia ORDER BY ClienteId, ReferenciaId;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Referencia_Buscar
    @ReferenciaId  INT          = NULL,
    @ClienteId     INT          = NULL,
    @Nombre        VARCHAR(160) = NULL,
    @Parentesco    VARCHAR(40)  = NULL,
    @LugarTrabajo  VARCHAR(120) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT *
    FROM dbo.vw_Referencia
    WHERE (@ReferenciaId IS NULL OR ReferenciaId = @ReferenciaId)
      AND (@ClienteId    IS NULL OR ClienteId = @ClienteId)
      AND (@Nombre       IS NULL OR NombreCompleto LIKE '%' + @Nombre + '%')
      AND (@Parentesco   IS NULL OR Parentesco LIKE '%' + @Parentesco + '%')
      AND (@LugarTrabajo IS NULL OR LugarTrabajo LIKE '%' + @LugarTrabajo + '%')
    ORDER BY ClienteId, ReferenciaId;
END
GO

CREATE OR ALTER VIEW dbo.vw_TelefonoReferencia
AS
SELECT t.TelefonoReferenciaId, t.ReferenciaId, r.NombreCompleto AS Referencia, r.ClienteId,
       t.TipoTelefonoId, tt.Descripcion AS TipoTelefono, t.Numero
FROM dbo.TelefonoReferencia t
JOIN dbo.Referencia r    ON r.ReferenciaId = t.ReferenciaId
JOIN dbo.TipoTelefono tt ON tt.TipoTelefonoId = t.TipoTelefonoId;
GO

CREATE OR ALTER PROCEDURE dbo.sp_TelefonoReferencia_Insertar
    @ReferenciaId    INT,
    @TipoTelefonoId  TINYINT,
    @Numero          VARCHAR(15)
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.Referencia WHERE ReferenciaId = @ReferenciaId)
        THROW 50001, 'La referencia no existe.', 1;
    IF NOT EXISTS (SELECT 1 FROM dbo.TipoTelefono WHERE TipoTelefonoId = @TipoTelefonoId)
        THROW 50001, 'El tipo de teléfono no existe.', 1;
    IF EXISTS (SELECT 1 FROM dbo.TelefonoReferencia WHERE ReferenciaId = @ReferenciaId AND Numero = @Numero)
        THROW 50001, 'Ese número ya está registrado para esta referencia.', 1;

    INSERT INTO dbo.TelefonoReferencia (ReferenciaId, TipoTelefonoId, Numero)
    VALUES (@ReferenciaId, @TipoTelefonoId, @Numero);

    SELECT * FROM dbo.vw_TelefonoReferencia WHERE TelefonoReferenciaId = SCOPE_IDENTITY();
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_TelefonoReferencia_Actualizar
    @TelefonoReferenciaId  INT,
    @TipoTelefonoId        TINYINT,
    @Numero                VARCHAR(15)
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.TipoTelefono WHERE TipoTelefonoId = @TipoTelefonoId)
        THROW 50001, 'El tipo de teléfono no existe.', 1;

    UPDATE dbo.TelefonoReferencia
       SET TipoTelefonoId = @TipoTelefonoId, Numero = @Numero
     WHERE TelefonoReferenciaId = @TelefonoReferenciaId;
    IF @@ROWCOUNT = 0
        THROW 50001, 'El teléfono no existe.', 1;

    SELECT 'ACTUALIZADO' AS Resultado, 'Teléfono de referencia actualizado.' AS Mensaje;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_TelefonoReferencia_Eliminar
    @TelefonoReferenciaId INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM dbo.TelefonoReferencia WHERE TelefonoReferenciaId = @TelefonoReferenciaId;
    IF @@ROWCOUNT = 0
        THROW 50001, 'El teléfono no existe.', 1;

    SELECT 'ELIMINADO' AS Resultado, 'Teléfono de referencia eliminado.' AS Mensaje;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_TelefonoReferencia_Listar
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM dbo.vw_TelefonoReferencia ORDER BY ReferenciaId, TipoTelefonoId;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_TelefonoReferencia_Buscar
    @ReferenciaId    INT         = NULL,
    @ClienteId       INT         = NULL,
    @TipoTelefonoId  TINYINT     = NULL,
    @Numero          VARCHAR(15) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT *
    FROM dbo.vw_TelefonoReferencia
    WHERE (@ReferenciaId   IS NULL OR ReferenciaId = @ReferenciaId)
      AND (@ClienteId      IS NULL OR ClienteId = @ClienteId)
      AND (@TipoTelefonoId IS NULL OR TipoTelefonoId = @TipoTelefonoId)
      AND (@Numero         IS NULL OR Numero LIKE '%' + @Numero + '%')
    ORDER BY ReferenciaId, TipoTelefonoId;
END
GO

CREATE OR ALTER VIEW dbo.vw_DireccionReferencia
AS
SELECT d.DireccionReferenciaId, d.ReferenciaId, r.NombreCompleto AS Referencia, r.ClienteId,
       d.Direccion, d.Municipio, d.Departamento
FROM dbo.DireccionReferencia d
JOIN dbo.Referencia r ON r.ReferenciaId = d.ReferenciaId;
GO

CREATE OR ALTER PROCEDURE dbo.sp_DireccionReferencia_Insertar
    @ReferenciaId  INT,
    @Direccion     VARCHAR(200),
    @Municipio     VARCHAR(60),
    @Departamento  VARCHAR(40)
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.Referencia WHERE ReferenciaId = @ReferenciaId)
        THROW 50001, 'La referencia no existe.', 1;

    INSERT INTO dbo.DireccionReferencia (ReferenciaId, Direccion, Municipio, Departamento)
    VALUES (@ReferenciaId, @Direccion, @Municipio, @Departamento);

    SELECT * FROM dbo.vw_DireccionReferencia WHERE DireccionReferenciaId = SCOPE_IDENTITY();
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_DireccionReferencia_Actualizar
    @DireccionReferenciaId  INT,
    @Direccion              VARCHAR(200),
    @Municipio              VARCHAR(60),
    @Departamento           VARCHAR(40)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.DireccionReferencia
       SET Direccion = @Direccion, Municipio = @Municipio, Departamento = @Departamento
     WHERE DireccionReferenciaId = @DireccionReferenciaId;
    IF @@ROWCOUNT = 0
        THROW 50001, 'La dirección no existe.', 1;

    SELECT 'ACTUALIZADO' AS Resultado, 'Dirección de referencia actualizada.' AS Mensaje;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_DireccionReferencia_Eliminar
    @DireccionReferenciaId INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM dbo.DireccionReferencia WHERE DireccionReferenciaId = @DireccionReferenciaId;
    IF @@ROWCOUNT = 0
        THROW 50001, 'La dirección no existe.', 1;

    SELECT 'ELIMINADO' AS Resultado, 'Dirección de referencia eliminada.' AS Mensaje;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_DireccionReferencia_Listar
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM dbo.vw_DireccionReferencia ORDER BY ReferenciaId;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_DireccionReferencia_Buscar
    @ReferenciaId  INT          = NULL,
    @ClienteId     INT          = NULL,
    @Texto         VARCHAR(200) = NULL,
    @Municipio     VARCHAR(60)  = NULL,
    @Departamento  VARCHAR(40)  = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT *
    FROM dbo.vw_DireccionReferencia
    WHERE (@ReferenciaId IS NULL OR ReferenciaId = @ReferenciaId)
      AND (@ClienteId    IS NULL OR ClienteId = @ClienteId)
      AND (@Texto        IS NULL OR Direccion LIKE '%' + @Texto + '%')
      AND (@Municipio    IS NULL OR Municipio LIKE '%' + @Municipio + '%')
      AND (@Departamento IS NULL OR Departamento LIKE '%' + @Departamento + '%')
    ORDER BY ReferenciaId;
END
GO

CREATE OR ALTER VIEW dbo.vw_Vehiculo
AS
SELECT v.VIN, v.MarcaId, m.CodigoMarca, m.Nombre AS Marca, v.Linea, v.Anio, v.Color,
       v.ValorAgencia, v.Placa, v.FechaRegistro,
       ca.CreditoId AS CreditoActivoId,
       ca.NumeroObligacion AS CreditoActivo,
       CASE WHEN ca.CreditoId IS NULL THEN 'DISPONIBLE' ELSE 'EN GARANTIA' END AS EstadoGarantia
FROM dbo.Vehiculo v
JOIN dbo.Marca m ON m.MarcaId = v.MarcaId
LEFT JOIN dbo.Credito ca ON ca.VIN = v.VIN AND ca.Estado = 'ACTIVO';
GO

CREATE OR ALTER PROCEDURE dbo.sp_Vehiculo_Insertar
    @VIN           CHAR(17),
    @MarcaId       INT,
    @Linea         VARCHAR(60),
    @Anio          SMALLINT,
    @Color         VARCHAR(30)   = NULL,
    @ValorAgencia  DECIMAL(12,2),
    @Placa         VARCHAR(10)   = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @VIN = UPPER(LTRIM(RTRIM(@VIN)));
    SET @Placa = NULLIF(UPPER(LTRIM(RTRIM(@Placa))), '');

    IF EXISTS (SELECT 1 FROM dbo.Vehiculo WHERE VIN = @VIN)
        THROW 50001, 'Ya existe un vehículo registrado con ese VIN.', 1;
    IF NOT EXISTS (SELECT 1 FROM dbo.Marca WHERE MarcaId = @MarcaId)
        THROW 50001, 'La marca indicada no existe.', 1;
    IF @Placa IS NOT NULL AND EXISTS (SELECT 1 FROM dbo.Vehiculo WHERE Placa = @Placa)
        THROW 50001, 'Ya existe un vehículo registrado con esa placa.', 1;

    BEGIN TRANSACTION;
        INSERT INTO dbo.Vehiculo (VIN, MarcaId, Linea, Anio, Color, ValorAgencia, Placa)
        VALUES (@VIN, @MarcaId, @Linea, @Anio, @Color, @ValorAgencia, @Placa);

        INSERT INTO dbo.HistorialValorVehiculo (VIN, Fecha, ValorEstimado, PorcentajeDepreciacion, Concepto)
        VALUES (@VIN, CAST(SYSDATETIME() AS DATE), @ValorAgencia, 0, 'Valor de agencia (precio de contado)');
    COMMIT TRANSACTION;

    SELECT * FROM dbo.vw_Vehiculo WHERE VIN = @VIN;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Vehiculo_Actualizar
    @VIN           CHAR(17),
    @MarcaId       INT,
    @Linea         VARCHAR(60),
    @Anio          SMALLINT,
    @Color         VARCHAR(30)   = NULL,
    @ValorAgencia  DECIMAL(12,2),
    @Placa         VARCHAR(10)   = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET @VIN = UPPER(LTRIM(RTRIM(@VIN)));
    SET @Placa = NULLIF(UPPER(LTRIM(RTRIM(@Placa))), '');

    DECLARE @ValorActual DECIMAL(12,2);
    SELECT @ValorActual = ValorAgencia FROM dbo.Vehiculo WHERE VIN = @VIN;
    IF @ValorActual IS NULL
        THROW 50001, 'El vehículo no existe.', 1;
    IF NOT EXISTS (SELECT 1 FROM dbo.Marca WHERE MarcaId = @MarcaId)
        THROW 50001, 'La marca indicada no existe.', 1;
    IF @Placa IS NOT NULL AND EXISTS (SELECT 1 FROM dbo.Vehiculo WHERE Placa = @Placa AND VIN <> @VIN)
        THROW 50001, 'Esa placa ya pertenece a otro vehículo.', 1;
    IF @ValorAgencia <> @ValorActual AND EXISTS (SELECT 1 FROM dbo.Credito WHERE VIN = @VIN)
        THROW 50001, 'No se puede cambiar el valor de agencia: el vehículo ya tiene créditos registrados.', 1;

    UPDATE dbo.Vehiculo
       SET MarcaId = @MarcaId, Linea = @Linea, Anio = @Anio, Color = @Color,
           ValorAgencia = @ValorAgencia, Placa = @Placa
     WHERE VIN = @VIN;

    SELECT 'ACTUALIZADO' AS Resultado, 'Vehículo actualizado.' AS Mensaje;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Vehiculo_Eliminar
    @VIN CHAR(17)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @VIN = UPPER(LTRIM(RTRIM(@VIN)));

    IF NOT EXISTS (SELECT 1 FROM dbo.Vehiculo WHERE VIN = @VIN)
        THROW 50001, 'El vehículo no existe.', 1;
    IF EXISTS (SELECT 1 FROM dbo.Credito WHERE VIN = @VIN)
        THROW 50001, 'No se puede eliminar: el vehículo es o fue garantía de un crédito.', 1;

    BEGIN TRANSACTION;
        DELETE FROM dbo.HistorialValorVehiculo WHERE VIN = @VIN;
        DELETE FROM dbo.Vehiculo WHERE VIN = @VIN;
    COMMIT TRANSACTION;

    SELECT 'ELIMINADO' AS Resultado, 'Vehículo eliminado.' AS Mensaje;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Vehiculo_Listar
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM dbo.vw_Vehiculo ORDER BY Marca, Linea, Anio;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Vehiculo_Buscar
    @VIN             VARCHAR(17)   = NULL,
    @Placa           VARCHAR(10)   = NULL,
    @MarcaId         INT           = NULL,
    @Linea           VARCHAR(60)   = NULL,
    @Anio            SMALLINT      = NULL,
    @ValorMinimo     DECIMAL(12,2) = NULL,
    @ValorMaximo     DECIMAL(12,2) = NULL,
    @SoloDisponibles BIT           = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT *
    FROM dbo.vw_Vehiculo
    WHERE (@VIN             IS NULL OR VIN LIKE '%' + @VIN + '%')
      AND (@Placa           IS NULL OR Placa LIKE '%' + @Placa + '%')
      AND (@MarcaId         IS NULL OR MarcaId = @MarcaId)
      AND (@Linea           IS NULL OR Linea LIKE '%' + @Linea + '%')
      AND (@Anio            IS NULL OR Anio = @Anio)
      AND (@ValorMinimo     IS NULL OR ValorAgencia >= @ValorMinimo)
      AND (@ValorMaximo     IS NULL OR ValorAgencia <= @ValorMaximo)
      AND (@SoloDisponibles IS NULL OR @SoloDisponibles = 0 OR EstadoGarantia = 'DISPONIBLE')
    ORDER BY Marca, Linea, Anio;
END
GO

CREATE OR ALTER VIEW dbo.vw_HistorialValorVehiculo
AS
SELECT h.HistorialValorId, h.VIN, m.Nombre AS Marca, v.Linea, v.Anio,
       v.ValorAgencia, h.Fecha, h.ValorEstimado,
       v.ValorAgencia - h.ValorEstimado AS PerdidaValor,
       h.PorcentajeDepreciacion, h.Concepto
FROM dbo.HistorialValorVehiculo h
JOIN dbo.Vehiculo v ON v.VIN = h.VIN
JOIN dbo.Marca m    ON m.MarcaId = v.MarcaId;
GO

CREATE OR ALTER PROCEDURE dbo.sp_HistorialValor_Insertar
    @VIN            CHAR(17),
    @Fecha          DATE,
    @ValorEstimado  DECIMAL(12,2),
    @Concepto       VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @ValorAgencia DECIMAL(12,2);
    SET @VIN = UPPER(LTRIM(RTRIM(@VIN)));
    SELECT @ValorAgencia = ValorAgencia FROM dbo.Vehiculo WHERE VIN = @VIN;

    IF @ValorAgencia IS NULL
        THROW 50001, 'El vehículo no existe.', 1;
    IF @ValorEstimado < 0 OR @ValorEstimado > @ValorAgencia
        THROW 50001, 'El valor estimado debe estar entre 0 y el valor de agencia del vehículo.', 1;

    INSERT INTO dbo.HistorialValorVehiculo (VIN, Fecha, ValorEstimado, PorcentajeDepreciacion, Concepto)
    VALUES (@VIN, @Fecha, @ValorEstimado,
            CAST(ROUND((1 - @ValorEstimado / @ValorAgencia) * 100, 2) AS DECIMAL(5,2)), @Concepto);

    SELECT * FROM dbo.vw_HistorialValorVehiculo WHERE HistorialValorId = SCOPE_IDENTITY();
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_HistorialValor_Actualizar
    @HistorialValorId  INT,
    @Fecha             DATE,
    @ValorEstimado     DECIMAL(12,2),
    @Concepto          VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @ValorAgencia DECIMAL(12,2);
    SELECT @ValorAgencia = v.ValorAgencia
    FROM dbo.HistorialValorVehiculo h
    JOIN dbo.Vehiculo v ON v.VIN = h.VIN
    WHERE h.HistorialValorId = @HistorialValorId;

    IF @ValorAgencia IS NULL
        THROW 50001, 'El registro de historial no existe.', 1;
    IF @ValorEstimado < 0 OR @ValorEstimado > @ValorAgencia
        THROW 50001, 'El valor estimado debe estar entre 0 y el valor de agencia del vehículo.', 1;

    UPDATE dbo.HistorialValorVehiculo
       SET Fecha = @Fecha, ValorEstimado = @ValorEstimado, Concepto = @Concepto,
           PorcentajeDepreciacion = CAST(ROUND((1 - @ValorEstimado / @ValorAgencia) * 100, 2) AS DECIMAL(5,2))
     WHERE HistorialValorId = @HistorialValorId;

    SELECT 'ACTUALIZADO' AS Resultado, 'Registro de valor actualizado.' AS Mensaje;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_HistorialValor_Eliminar
    @HistorialValorId INT
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM dbo.HistorialValorVehiculo WHERE HistorialValorId = @HistorialValorId;
    IF @@ROWCOUNT = 0
        THROW 50001, 'El registro de historial no existe.', 1;

    SELECT 'ELIMINADO' AS Resultado, 'Registro de valor eliminado.' AS Mensaje;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_HistorialValor_Listar
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM dbo.vw_HistorialValorVehiculo ORDER BY VIN, Fecha, HistorialValorId;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_HistorialValor_Buscar
    @VIN    VARCHAR(17) = NULL,
    @Desde  DATE        = NULL,
    @Hasta  DATE        = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT *
    FROM dbo.vw_HistorialValorVehiculo
    WHERE (@VIN   IS NULL OR VIN LIKE '%' + @VIN + '%')
      AND (@Desde IS NULL OR Fecha >= @Desde)
      AND (@Hasta IS NULL OR Fecha <= @Hasta)
    ORDER BY VIN, Fecha, HistorialValorId;
END
GO

PRINT 'Procedimientos del Script 02 creados correctamente.';
GO
