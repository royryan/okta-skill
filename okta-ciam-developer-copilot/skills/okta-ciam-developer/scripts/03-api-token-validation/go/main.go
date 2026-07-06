// Protect a Go API with okta-jwt-verifier-golang.
// Source pattern: developer.okta.com/docs/guides/protect-your-api/go/main/
// go get github.com/okta/okta-jwt-verifier-golang/v2

package main

import (
	"fmt"
	"net/http"
	"os"
	"strings"

	jwtverifier "github.com/okta/okta-jwt-verifier-golang/v2"
)

var verifier *jwtverifier.JwtVerifier

func main() {
	issuer := os.Getenv("OKTA_OAUTH2_ISSUER") // https://{org}.okta.com/oauth2/default
	audience := os.Getenv("OKTA_OAUTH2_AUDIENCE")
	if audience == "" {
		audience = "api://default"
	}

	v := jwtverifier.JwtVerifier{
		Issuer: issuer,
		ClaimsToValidate: map[string]string{
			"aud": audience,
		},
	}
	var err error
	verifier, err = v.New()
	if err != nil {
		panic(err)
	}

	http.HandleFunc("/api/orders", authRequired("orders:read", listOrders))
	http.ListenAndServe(":8000", nil)
}

func authRequired(scope string, next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		raw := strings.TrimPrefix(r.Header.Get("Authorization"), "Bearer ")
		if raw == "" {
			http.Error(w, "missing bearer token", http.StatusUnauthorized)
			return
		}
		token, err := verifier.VerifyAccessToken(raw)
		if err != nil {
			http.Error(w, "invalid token", http.StatusUnauthorized)
			return
		}
		scopes, _ := token.Claims["scp"].([]interface{})
		for _, s := range scopes {
			if s == scope {
				next(w, r)
				return
			}
		}
		http.Error(w, "insufficient scope", http.StatusForbidden)
	}
}

func listOrders(w http.ResponseWriter, r *http.Request) {
	fmt.Fprint(w, `{"orders": []}`)
}
