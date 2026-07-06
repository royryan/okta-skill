# Protect a FastAPI service with okta-jwt-verifier.
# Source pattern: developer.okta.com/docs/guides/protect-your-api/ + okta/okta-jwt-verifier-python
# pip install fastapi uvicorn okta-jwt-verifier

import os
from fastapi import FastAPI, Depends, HTTPException, Request
from okta_jwt_verifier import AccessTokenVerifier, BaseJWTVerifier

ISSUER = os.environ["OKTA_OAUTH2_ISSUER"]        # https://{org}.okta.com/oauth2/default
AUDIENCE = os.environ.get("OKTA_OAUTH2_AUDIENCE", "api://default")

app = FastAPI()
verifier = AccessTokenVerifier(issuer=ISSUER, audience=AUDIENCE)


async def require_token(request: Request) -> dict:
    auth = request.headers.get("authorization", "")
    if not auth.startswith("Bearer "):
        raise HTTPException(401, "missing bearer token")
    token = auth.removeprefix("Bearer ")
    try:
        await verifier.verify(token)  # signature, iss, aud, exp
    except Exception as exc:
        raise HTTPException(401, f"invalid token: {exc}")
    claims = BaseJWTVerifier.parse_token(token)[1]  # decoded payload
    return claims


def require_scopes(*needed):
    async def checker(claims: dict = Depends(require_token)) -> dict:
        scopes = claims.get("scp", [])
        if not all(s in scopes for s in needed):
            raise HTTPException(403, "insufficient scope")
        return claims
    return checker


@app.get("/api/orders")
async def list_orders(claims: dict = Depends(require_scopes("orders:read"))):
    return {"orders": [], "sub": claims["sub"]}


@app.post("/api/orders", status_code=201)
async def create_order(claims: dict = Depends(require_scopes("orders:write"))):
    return {"created": True}
