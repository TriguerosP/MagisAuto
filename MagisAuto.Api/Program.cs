using MagisAuto.Api.Datos;

var builder = WebApplication.CreateBuilder(new WebApplicationOptions
{
    Args = args,
    WebRootPath = "MagisWeb"
});

builder.Services.AddSingleton<EjecutorSp>();

builder.Services.AddControllers().AddJsonOptions(o =>
{
    o.JsonSerializerOptions.PropertyNamingPolicy = null;
    o.JsonSerializerOptions.DictionaryKeyPolicy = null;
});

builder.Services.AddCors(o => o.AddDefaultPolicy(p => p.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod()));

#if !STUB
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new() { Title = "MAGIS-AUTO API", Version = "v1",
        Description = "API de créditos automotrices. Cada operación ejecuta un procedimiento almacenado." });
});
#endif

var app = builder.Build();

#if !STUB
app.UseSwagger();
app.UseSwaggerUI();
#endif

app.UseCors();
app.UseDefaultFiles();
app.UseStaticFiles();
app.MapControllers();

app.Run();
