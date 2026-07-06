// Protect an ASP.NET Core API — JWT validation is built into the framework;
// Okta's guidance for .NET is the standard JwtBearer middleware.
// Source pattern: developer.okta.com/code/dotnet/jwt-validation/
// dotnet add package Microsoft.AspNetCore.Authentication.JwtBearer

using Microsoft.AspNetCore.Authentication.JwtBearer;

var builder = WebApplication.CreateBuilder(args);

var issuer = Environment.GetEnvironmentVariable("OKTA_OAUTH2_ISSUER"); // https://{org}.okta.com/oauth2/default
var audience = Environment.GetEnvironmentVariable("OKTA_OAUTH2_AUDIENCE") ?? "api://default";

builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.Authority = issuer;   // discovers JWKS via /.well-known
        options.Audience = audience;  // validates aud; iss/exp/signature automatic
    });

builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("orders:read", p => p.RequireClaim("scp", "orders:read"));
    options.AddPolicy("orders:write", p => p.RequireClaim("scp", "orders:write"));
});

var app = builder.Build();
app.UseAuthentication();
app.UseAuthorization();

app.MapGet("/api/orders", () => new { orders = Array.Empty<object>() })
   .RequireAuthorization("orders:read");
app.MapPost("/api/orders", () => Results.Created("/api/orders/1", new { created = true }))
   .RequireAuthorization("orders:write");

app.Run();
