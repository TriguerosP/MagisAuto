namespace MagisAuto.Api.Datos;

public sealed record EntidadSp(
    string Nombre,
    string? Listar,
    string? Buscar,
    string? Insertar,
    string? Actualizar,
    string? Eliminar,
    string Id,
    string? IdEliminar = null)
{
    public string ParametroEliminar => IdEliminar ?? Id;
}

public static class Entidades
{
    private static EntidadSp Crud(string prefijo, string id) => new(
        prefijo,
        $"sp_{prefijo}_Listar",
        $"sp_{prefijo}_Buscar",
        $"sp_{prefijo}_Insertar",
        $"sp_{prefijo}_Actualizar",
        $"sp_{prefijo}_Eliminar",
        id);

    public static readonly IReadOnlyDictionary<string, EntidadSp> Todas =
        new Dictionary<string, EntidadSp>(StringComparer.OrdinalIgnoreCase)
        {
            ["parametros"]       = Crud("Parametro", "Codigo"),
            ["tipos-telefono"]   = Crud("TipoTelefono", "TipoTelefonoId"),
            ["medios-pago"]      = Crud("MedioPago", "MedioPagoId"),
            ["marcas"]           = Crud("Marca", "MarcaId"),
            ["agencias"]         = Crud("Agencia", "AgenciaId"),
            ["vendedores"]       = Crud("Vendedor", "VendedorId"),

            ["personas"]               = new("Persona", "sp_Persona_Listar", "sp_Persona_Buscar", null, null, null, "PersonaId"),
            ["clientes"]               = Crud("Cliente", "ClienteId"),
            ["fiadores"]               = Crud("Fiador", "FiadorId"),
            ["telefonos-persona"]      = Crud("TelefonoPersona", "TelefonoPersonaId"),
            ["direcciones-persona"]    = Crud("DireccionPersona", "DireccionPersonaId"),
            ["referencias"]            = Crud("Referencia", "ReferenciaId"),
            ["telefonos-referencia"]   = Crud("TelefonoReferencia", "TelefonoReferenciaId"),
            ["direcciones-referencia"] = Crud("DireccionReferencia", "DireccionReferenciaId"),

            ["vehiculos"]       = Crud("Vehiculo", "VIN"),
            ["historial-valor"] = Crud("HistorialValor", "HistorialValorId"),

            ["creditos"]          = Crud("Credito", "CreditoId") with { Insertar = "sp_Credito_Emitir" },
            ["creditos-fiadores"] = Crud("CreditoFiador", "CreditoId"),

            ["cuotas"] = new("Cuota", "sp_Cuota_Listar", "sp_Cuota_Buscar", "sp_Cuota_Generar",
                             "sp_Cuota_Actualizar", "sp_Cuota_EliminarPlan", "CuotaId", IdEliminar: "CreditoId"),
            ["pagos"]  = new("TransaccionPago", "sp_Pago_Listar", "sp_Pago_Buscar", "sp_Pago_Registrar",
                             "sp_Pago_Actualizar", "sp_Pago_Eliminar", "TransaccionId"),
        };

    public static readonly IReadOnlyDictionary<int, string> Reportes = new Dictionary<int, string>
    {
        [1]  = "sp_Rpt01_CreditosPorPeriodo",
        [2]  = "sp_Rpt02_CarteraMora",
        [3]  = "sp_Rpt03_PagosPorMedio",
        [4]  = "sp_Rpt04_VentasPorVendedor",
        [5]  = "sp_Rpt05_Cumpleaneros",
        [6]  = "sp_Rpt06_EstadoCuentaCliente",
        [7]  = "sp_Rpt07_PlanPagos",
        [8]  = "sp_Rpt08_ComisionesVendedor",
        [9]  = "sp_Rpt09_CostoRealVsDepreciacion",
        [10] = "sp_Rpt10_ProyeccionRecaudacion",
        [11] = "sp_Rpt11_InteresesDevengados",
        [12] = "sp_Rpt12_SaldosCartera",
        [13] = "sp_Rpt13_AntiguedadMora",
        [14] = "sp_Rpt14_CreditosPorMarca",
        [15] = "sp_Rpt15_ExposicionFiadores",
        [16] = "sp_Rpt16_DirectorioCobros",
        [17] = "sp_Rpt17_CuotasParciales",
        [18] = "sp_Rpt18_CierreCaja",
        [19] = "sp_Rpt19_VentasPorAgencia",
        [20] = "sp_Rpt20_PuntualidadClientes",
        [21] = "sp_Rpt21_CuotasPorVencer",
        [22] = "sp_Rpt22_ResumenEjecutivo",
        [23] = "sp_Rpt23_PagosAnulados",
        [24] = "sp_Rpt24_SimuladorCredito",
    };
}
