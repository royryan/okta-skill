# Client Credentials with private-key JWT (recommended client auth).
# Source pattern: developer.okta.com/docs/guides/implement-grant-type/clientcreds/main/
# pip install requests pyjwt cryptography

import os
import time
import uuid
import jwt
import requests

ISSUER = os.environ["OKTA_OAUTH2_ISSUER"]
CLIENT_ID = os.environ["OKTA_CLIENT_ID"]
PRIVATE_KEY = os.environ["OKTA_PRIVATE_KEY"]  # PEM
KEY_ID = os.environ.get("OKTA_KEY_ID")        # kid registered in the app JWKS

_cache = {"token": None, "exp": 0}


def _client_assertion() -> str:
    now = int(time.time())
    return jwt.encode(
        {
            "iss": CLIENT_ID,
            "sub": CLIENT_ID,
            "aud": f"{ISSUER}/v1/token",
            "iat": now,
            "exp": now + 300,
            "jti": str(uuid.uuid4()),
        },
        PRIVATE_KEY,
        algorithm="RS256",
        headers={"kid": KEY_ID} if KEY_ID else None,
    )


def get_token(scope: str = "orders:read") -> str:
    if _cache["token"] and _cache["exp"] > time.time() + 30:
        return _cache["token"]

    resp = requests.post(
        f"{ISSUER}/v1/token",
        data={
            "grant_type": "client_credentials",
            "scope": scope,
            "client_assertion_type": "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
            "client_assertion": _client_assertion(),
        },
        timeout=10,
    )
    resp.raise_for_status()
    body = resp.json()
    _cache.update(token=body["access_token"], exp=time.time() + body["expires_in"])
    return _cache["token"]


if __name__ == "__main__":
    token = get_token()
    print("Got token:", token[:40], "...")
    # requests.get("https://api.example.com/orders",
    #              headers={"Authorization": f"Bearer {token}"})
