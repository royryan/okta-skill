// Okta sign-in for ASP.NET Core using Okta.AspNetCore middleware.
// Source pattern: developer.okta.com/docs/guides/sign-into-web-app-redirect/asp-net-core-3/main/
// dotnet add package Okta.AspNetCore
// Register redirect URI: https://localhost:5001/authorization-code/callback

using Microsoft.AspNetCore.Authentication.Cookies;
using Okta.AspNetCore;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = CookieAuthenticationDefaults.AuthenticationScheme;
    options.DefaultSignInScheme = CookieAuthenticationDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = OktaDefaults.MvcAuthenticationScheme;
})
.AddCookie()
.AddOktaMvc(new OktaMvcOptions
{
    // OktaDomain is the org URL; the middleware uses the org authorization server
    // by default — set AuthorizationServerId = "default" for the custom server.
    OktaDomain = Environment.GetEnvironmentVariable("OKTA_ORG_URL"), // https://{org}.okta.com
    AuthorizationServerId = "default",
    ClientId = Environment.GetEnvironmentVariable("OKTA_OAUTH2_CLIENT_ID"),
    ClientSecret = Environment.GetEnvironmentVariable("OKTA_OAUTH2_CLIENT_SECRET"),
    Scope = new List<string> { "openid", "profile", "email" },
});

builder.Services.AddAuthorization();

var app = builder.Build();
app.UseAuthentication();
app.UseAuthorization();

app.MapGet("/", () => "Anonymous — visit /profile to sign in");
app.MapGet("/profile", (System.Security.Claims.ClaimsPrincipal user) =>
        user.Claims.ToDictionary(c => c.Type, c => c.Value))
    .RequireAuthorization();

app.Run();
