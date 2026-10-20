using System.Collections.Concurrent;
using System.Data;
using System.Globalization;
using System.Text.Json;
using Microsoft.Data.SqlClient;

namespace MagisAuto.Api.Datos;

public sealed class EjecutorSp
{
    private readonly string _cadenaConexion;

    private readonly ConcurrentDictionary<string, ParametroSp[]> _parametros = new(StringComparer.OrdinalIgnoreCase);

    public EjecutorSp(IConfiguration configuracion)
    {
        _cadenaConexion = configuracion.GetConnectionString("MagisAuto")
            ?? throw new InvalidOperationException("Falta la cadena de conexión 'MagisAuto' en appsettings.json.");
    }

    public async Task<List<List<Dictionary<string, object?>>>> EjecutarAsync(
        string procedimiento, IDictionary<string, object?> valores)
    {
        await using var conexion = new SqlConnection(_cadenaConexion);
        await conexion.OpenAsync();

        var definicion = ObtenerParametros(conexion, procedimiento);

        await using var comando = new SqlCommand("dbo." + procedimiento, conexion)
        {
            CommandType = CommandType.StoredProcedure,
            CommandTimeout = 120
        };

        foreach (var p in definicion)
        {
            if (!valores.TryGetValue(p.Nombre, out var valor))
                continue;

            var parametro = new SqlParameter("@" + p.Nombre, p.Tipo)
            {
                Size = p.Tamano,
                Precision = p.Precision,
                Scale = p.Escala,
                Value = Convertir(valor, p)
            };
            comando.Parameters.Add(parametro);
        }

        var tablas = new List<List<Dictionary<string, object?>>>();
        await using var lector = await comando.ExecuteReaderAsync();
        do
        {
            if (lector.FieldCount == 0) continue;
            var filas = new List<Dictionary<string, object?>>();
            while (await lector.ReadAsync())
            {
                var fila = new Dictionary<string, object?>(lector.FieldCount);
                for (var i = 0; i < lector.FieldCount; i++)
                    fila[lector.GetName(i)] = lector.IsDBNull(i) ? null : lector.GetValue(i);
                filas.Add(fila);
            }
            tablas.Add(filas);
        } while (await lector.NextResultAsync());

        return tablas;
    }

    private ParametroSp[] ObtenerParametros(SqlConnection conexion, string procedimiento)
    {
        return _parametros.GetOrAdd(procedimiento, nombre =>
        {
            using var comando = new SqlCommand("dbo." + nombre, conexion) { CommandType = CommandType.StoredProcedure };
            SqlCommandBuilder.DeriveParameters(comando);
            return comando.Parameters.Cast<SqlParameter>()
                .Where(x => x.Direction is ParameterDirection.Input or ParameterDirection.InputOutput)
                .Select(x => new ParametroSp(x.ParameterName.TrimStart('@'), x.SqlDbType, x.Size, x.Precision, x.Scale))
                .ToArray();
        });
    }

    private static object Convertir(object? valor, ParametroSp p)
    {
        if (valor is JsonElement json)
        {
            valor = json.ValueKind switch
            {
                JsonValueKind.Null or JsonValueKind.Undefined => null,
                JsonValueKind.String => json.GetString(),
                JsonValueKind.True => "true",
                JsonValueKind.False => "false",
                _ => json.GetRawText()
            };
        }

        var texto = valor is null ? null : Convert.ToString(valor, CultureInfo.InvariantCulture)?.Trim();
        if (string.IsNullOrEmpty(texto))
            return DBNull.Value;

        var ci = CultureInfo.InvariantCulture;
        try
        {
            return p.Tipo switch
            {
                SqlDbType.Int => int.Parse(texto, NumberStyles.Integer, ci),
                SqlDbType.SmallInt => short.Parse(texto, NumberStyles.Integer, ci),
                SqlDbType.TinyInt => byte.Parse(texto, NumberStyles.Integer, ci),
                SqlDbType.BigInt => long.Parse(texto, NumberStyles.Integer, ci),
                SqlDbType.Decimal or SqlDbType.Money or SqlDbType.SmallMoney
                    => decimal.Parse(texto, NumberStyles.Number, ci),
                SqlDbType.Float or SqlDbType.Real => double.Parse(texto, NumberStyles.Float, ci),
                SqlDbType.Bit => texto is "1"
                    || texto.Equals("true", StringComparison.OrdinalIgnoreCase)
                    || texto.Equals("si", StringComparison.OrdinalIgnoreCase)
                    || texto.Equals("sí", StringComparison.OrdinalIgnoreCase),
                SqlDbType.Date or SqlDbType.DateTime or SqlDbType.DateTime2 or SqlDbType.SmallDateTime
                    => DateTime.Parse(texto, ci, DateTimeStyles.AssumeLocal),
                _ => texto
            };
        }
        catch (Exception ex) when (ex is FormatException or OverflowException)
        {
            throw new ArgumentException($"El valor '{texto}' no es válido para el campo {p.Nombre}.");
        }
    }

    private sealed record ParametroSp(string Nombre, SqlDbType Tipo, int Tamano, byte Precision, byte Escala);
}
