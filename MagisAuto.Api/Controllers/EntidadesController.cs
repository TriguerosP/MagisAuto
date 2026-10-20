using System.Text.Json;
using MagisAuto.Api.Datos;
using Microsoft.AspNetCore.Mvc;

namespace MagisAuto.Api.Controllers;

[ApiController]
[Route("api")]
public sealed class EntidadesController : ApiBaseController
{
    public EntidadesController(EjecutorSp sp) : base(sp) { }

    [HttpGet("entidades")]
    public IActionResult Catalogo() => Ok(Entidades.Todas.Select(e => new
    {
        Ruta = "/api/" + e.Key,
        e.Value.Listar,
        e.Value.Buscar,
        e.Value.Insertar,
        e.Value.Actualizar,
        e.Value.Eliminar
    }));

    [HttpGet("{entidad}")]
    public Task<IActionResult> Listar(string entidad) =>
        Ejecutar(entidad, e => e.Listar, new Dictionary<string, object?>());

    [HttpGet("{entidad}/buscar")]
    public Task<IActionResult> Buscar(string entidad) =>
        Ejecutar(entidad, e => e.Buscar, ParametrosDeConsulta());

    [HttpPost("{entidad}")]
    public Task<IActionResult> Insertar(string entidad, [FromBody] Dictionary<string, JsonElement>? cuerpo) =>
        Ejecutar(entidad, e => e.Insertar, DeCuerpo(cuerpo));

    [HttpPut("{entidad}/{id}")]
    public Task<IActionResult> Actualizar(string entidad, string id, [FromBody] Dictionary<string, JsonElement>? cuerpo)
    {
        var valores = DeCuerpo(cuerpo);
        if (Entidades.Todas.TryGetValue(entidad, out var e))
            valores[e.Id] = id;
        return Ejecutar(entidad, x => x.Actualizar, valores);
    }

    [HttpDelete("{entidad}/{id}")]
    public Task<IActionResult> Eliminar(string entidad, string id)
    {
        var valores = ParametrosDeConsulta();
        if (Entidades.Todas.TryGetValue(entidad, out var e))
            valores[e.ParametroEliminar] = id;
        return Ejecutar(entidad, x => x.Eliminar, valores);
    }

    private async Task<IActionResult> Ejecutar(string entidad, Func<EntidadSp, string?> operacion,
                                               IDictionary<string, object?> valores)
    {
        if (!Entidades.Todas.TryGetValue(entidad, out var e))
            return NotFound(new { mensaje = $"La entidad '{entidad}' no existe." });

        var procedimiento = operacion(e);
        if (procedimiento is null)
            return StatusCode(405, new { mensaje = $"La operación no está disponible para {e.Nombre}." });

        return await EjecutarAsync(procedimiento, valores);
    }

    private static IDictionary<string, object?> DeCuerpo(Dictionary<string, JsonElement>? cuerpo)
    {
        var valores = new Dictionary<string, object?>(StringComparer.OrdinalIgnoreCase);
        if (cuerpo is not null)
            foreach (var (clave, valor) in cuerpo)
                valores[clave] = valor;
        return valores;
    }
}
