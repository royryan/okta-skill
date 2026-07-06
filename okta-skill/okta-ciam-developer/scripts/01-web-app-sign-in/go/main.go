// Okta sign-in for Go using standard OIDC + Gorilla sessions (Okta's
// recommended pattern — okta-idx-golang is ARCHIVED, do not use it).
// Source pattern: developer.okta.com/docs/guides/sign-into-web-app-redirect/go/main/
// go get github.com/coreos/go-oidc/v3/oidc golang.org/x/oauth2 github.com/gorilla/sessions

package main

import (
	"context"
	"crypto/rand"
	"encoding/base64"
	"fmt"
	"log"
	"net/http"
	"os"

	"github.com/coreos/go-oidc/v3/oidc"
	"github.com/gorilla/sessions"
	"golang.org/x/oauth2"
)

var (
	store        = sessions.NewCookieStore([]byte(os.Getenv("SESSION_SECRET")))
	provider     *oidc.Provider
	oauth2Config oauth2.Config
	verifier     *oidc.IDTokenVerifier
)

func randString() string {
	b := make([]byte, 32)
	rand.Read(b)
	return base64.RawURLEncoding.EncodeToString(b)
}

func main() {
	ctx := context.Background()
	issuer := os.Getenv("OKTA_OAUTH2_ISSUER") // https://{org}.okta.com/oauth2/default

	var err error
	provider, err = oidc.NewProvider(ctx, issuer)
	if err != nil {
		log.Fatal(err)
	}
	clientID := os.Getenv("OKTA_OAUTH2_CLIENT_ID")
	oauth2Config = oauth2.Config{
		ClientID:     clientID,
		ClientSecret: os.Getenv("OKTA_OAUTH2_CLIENT_SECRET"),
		RedirectURL:  "http://localhost:8080/authorization-code/callback",
		Endpoint:     provider.Endpoint(),
		Scopes:       []string{oidc.ScopeOpenID, "profile", "email"},
	}
	verifier = provider.Verifier(&oidc.Config{ClientID: clientID})

	http.HandleFunc("/signin", signin)
	http.HandleFunc("/authorization-code/callback", callback)
	http.HandleFunc("/profile", profile)
	log.Fatal(http.ListenAndServe(":8080", nil))
}

func signin(w http.ResponseWriter, r *http.Request) {
	state, nonce := randString(), randString()
	sess, _ := store.Get(r, "okta")
	sess.Values["state"], sess.Values["nonce"] = state, nonce
	sess.Save(r, w)
	// PKCE via oauth2 v0.17+: oauth2.S256ChallengeOption / VerifierOption
	pkce := oauth2.GenerateVerifier()
	sess.Values["pkce"] = pkce
	sess.Save(r, w)
	http.Redirect(w, r, oauth2Config.AuthCodeURL(state,
		oidc.Nonce(nonce), oauth2.S256ChallengeOption(pkce)), http.StatusFound)
}

func callback(w http.ResponseWriter, r *http.Request) {
	sess, _ := store.Get(r, "okta")
	if r.URL.Query().Get("state") != sess.Values["state"] {
		http.Error(w, "state mismatch", http.StatusForbidden)
		return
	}
	token, err := oauth2Config.Exchange(r.Context(), r.URL.Query().Get("code"),
		oauth2.VerifierOption(sess.Values["pkce"].(string)))
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	rawID, _ := token.Extra("id_token").(string)
	idToken, err := verifier.Verify(r.Context(), rawID)
	if err != nil || idToken.Nonce != sess.Values["nonce"] {
		http.Error(w, "invalid id_token", http.StatusForbidden)
		return
	}
	var claims map[string]interface{}
	idToken.Claims(&claims)
	sess.Values["email"] = fmt.Sprint(claims["email"])
	sess.Save(r, w)
	http.Redirect(w, r, "/profile", http.StatusFound)
}

func profile(w http.ResponseWriter, r *http.Request) {
	sess, _ := store.Get(r, "okta")
	email, ok := sess.Values["email"].(string)
	if !ok {
		http.Redirect(w, r, "/signin", http.StatusFound)
		return
	}
	fmt.Fprintf(w, "Hello, %s", email)
}
