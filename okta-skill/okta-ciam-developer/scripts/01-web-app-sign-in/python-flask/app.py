# Okta sign-in for Flask using a generic OIDC client (Okta's recommended
# pattern for Python — no dedicated Okta server SDK).
# Source pattern: developer.okta.com/docs/guides/sign-into-web-app-redirect/python/main/
# and okta-samples/okta-flask-sample.
# pip install flask flask-login requests pyjwt

import os
import secrets
import base64
import hashlib
import requests
from flask import Flask, redirect, request, session, url_for, jsonify
from flask_login import LoginManager, UserMixin, login_user, logout_user, login_required, current_user

ISSUER = os.environ["OKTA_OAUTH2_ISSUER"]          # https://{org}.okta.com/oauth2/default
CLIENT_ID = os.environ["OKTA_OAUTH2_CLIENT_ID"]
CLIENT_SECRET = os.environ["OKTA_OAUTH2_CLIENT_SECRET"]
BASE_URL = os.environ.get("APP_BASE_URL", "http://localhost:5000")
REDIRECT_URI = f"{BASE_URL}/authorization-code/callback"

app = Flask(__name__)
app.secret_key = os.environ.get("SESSION_SECRET", secrets.token_hex(32))
login_manager = LoginManager(app)

USERS = {}  # replace with a real user store


class User(UserMixin):
    def __init__(self, id_, claims):
        self.id = id_
        self.claims = claims


@login_manager.user_loader
def load_user(user_id):
    return USERS.get(user_id)


@app.route("/signin")
def signin():
    # PKCE
    verifier = secrets.token_urlsafe(64)
    challenge = base64.urlsafe_b64encode(
        hashlib.sha256(verifier.encode()).digest()
    ).rstrip(b"=").decode()
    state = secrets.token_urlsafe(32)
    session["pkce_verifier"], session["oauth_state"] = verifier, state

    from urllib.parse import urlencode
    params = urlencode({
        "client_id": CLIENT_ID,
        "response_type": "code",
        "scope": "openid profile email",
        "redirect_uri": REDIRECT_URI,
        "state": state,
        "code_challenge": challenge,
        "code_challenge_method": "S256",
    })
    return redirect(f"{ISSUER}/v1/authorize?{params}")


@app.route("/authorization-code/callback")
def callback():
    if request.args.get("state") != session.pop("oauth_state", None):
        return "state mismatch", 403
    resp = requests.post(
        f"{ISSUER}/v1/token",
        auth=(CLIENT_ID, CLIENT_SECRET),
        data={
            "grant_type": "authorization_code",
            "code": request.args["code"],
            "redirect_uri": REDIRECT_URI,
            "code_verifier": session.pop("pkce_verifier"),
        },
        timeout=10,
    )
    resp.raise_for_status()
    tokens = resp.json()

    userinfo = requests.get(
        f"{ISSUER}/v1/userinfo",
        headers={"Authorization": f"Bearer {tokens['access_token']}"},
        timeout=10,
    ).json()

    user = User(userinfo["sub"], userinfo)
    USERS[user.id] = user
    login_user(user)
    return redirect(url_for("profile"))


@app.route("/profile")
@login_required
def profile():
    return jsonify(current_user.claims)


@app.route("/signout")
def signout():
    logout_user()
    return redirect("/")


@app.route("/")
def index():
    return '<a href="/signin">Sign in with Okta</a>'


if __name__ == "__main__":
    app.run(port=5000)
