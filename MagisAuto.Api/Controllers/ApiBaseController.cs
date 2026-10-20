using MagisAuto.Api.Datos;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace MagisAuto.Api.Controllers;

public abstract class ApiBaseController : ControllerBase
{
    protected readonly EjecutorSp Sp;

    protected ApiBaseController(EjecutorSp sp) => Sp = sp;

    protected async Task<IActionResult> EjecutarAsync(string procedimiento, IDictionary<string, object?> valores)
    {
        try
        {
            var tablas = await Sp.EjecutarAsync(procedimiento, valores);
            return Ok(new { tablas });
        }
        catch (SqlException ex) when (ex.Number >= 50000)
        {
            return BadRequest(new { mensaje = ex.Message });
        }
        catch (SqlException ex) when (MensajeAmigable(ex) is { } mensaje)
        {
            return BadRequest(new { mensaje });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { mensaje = ex.Message });
        }
        catch (SqlException ex)
        {
            return StatusCode(500, new { mensaje = "Error de base de datos: " + ex.Message });
        }
    }

    private static string? MensajeAmigable(SqlException ex) => ex.Number switch
    {
        2627 or 2601 => "Ya existe un registro con ese valor único. " + ex.Message,
        547          => "La operación no cumple una regla de la base de datos (dato relacionado o valor fuera de rango). " + ex.Message,
        515          => "Falta un dato obligatorio. " + ex.Message,
        201          => "Falta un parámetro obligatorio. " + ex.Message,
        8114 or 245  => "Uno de los valores no tiene el formato correcto. " + ex.Message,
        8152 or 2628 => "Uno de los textos excede el tamaño permitido. " + ex.Message,
        _ => null
    };

    protected IDictionary<string, object?> ParametrosDeConsulta()
    {
        var valores = new Dictionary<string, object?>(StringComparer.OrdinalIgnoreCase);
        foreach (var (clave, valor) in Request.Query)
            valores[clave] = valor.ToString();
        return valores;
    }
}
