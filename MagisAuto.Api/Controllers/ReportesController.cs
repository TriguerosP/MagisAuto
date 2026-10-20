using MagisAuto.Api.Datos;
using Microsoft.AspNetCore.Mvc;

namespace MagisAuto.Api.Controllers;

[ApiController]
[Route("api/reportes")]
public sealed class ReportesController : ApiBaseController
{
    public ReportesController(EjecutorSp sp) : base(sp) { }

    [HttpGet]
    public Task<IActionResult> Catalogo() =>
        EjecutarAsync("sp_Rpt_Catalogo", new Dictionary<string, object?>());

    [HttpGet("{numero:int}")]
    public async Task<IActionResult> Ejecutar(int numero)
    {
        if (!Entidades.Reportes.TryGetValue(numero, out var procedimiento))
            return NotFound(new { mensaje = $"El reporte {numero} no existe." });

        return await EjecutarAsync(procedimiento, ParametrosDeConsulta());
    }
}
