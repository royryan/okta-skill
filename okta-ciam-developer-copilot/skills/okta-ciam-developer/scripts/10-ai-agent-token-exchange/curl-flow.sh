#!/usr/bin/env bash
# XAA / ID-JAG token exchange as raw curl, for debugging.
# Source: developer.okta.com/docs/guides/ai-agent-token-exchange/-/main/ (verified 2026-07-05)
set -euo pipefail

ORG_URL="${OKTA_ORG_URL:?e.g. https://example.okta.com}"
RESOURCE_ISSUER="${RESOURCE_ISSUER:-$ORG_URL/oauth2/default}"
USER_ID_TOKEN="${USER_ID_TOKEN:?ID token from the web app sign-in (org auth server)}"
CLIENT_ASSERTION_1="${CLIENT_ASSERTION_1:?JWT signed with agent key, aud=$ORG_URL/oauth2/v1/token}"
CLIENT_ASSERTION_2="${CLIENT_ASSERTION_2:?JWT signed with agent key, aud=$RESOURCE_ISSUER/v1/token}"

echo "== Step 1: ID token -> ID-JAG (org authorization server) =="
ID_JAG=$(curl -sf "$ORG_URL/oauth2/v1/token" \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  --data-urlencode 'grant_type=urn:ietf:params:oauth:grant-type:token-exchange' \
  --data-urlencode 'requested_token_type=urn:ietf:params:oauth:token-type:id-jag' \
  --data-urlencode "subject_token=$USER_ID_TOKEN" \
  --data-urlencode 'subject_token_type=urn:ietf:params:oauth:token-type:id_token' \
  --data-urlencode 'client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer' \
  --data-urlencode "client_assertion=$CLIENT_ASSERTION_1" \
  --data-urlencode "audience=$RESOURCE_ISSUER" \
  --data-urlencode 'scope=chat.read chat.history' \
  | python3 -c 'import json,sys; print(json.load(sys.stdin)["access_token"])')

echo "== Step 2: ID-JAG -> access token (resource custom auth server) =="
curl -sf "$RESOURCE_ISSUER/v1/token" \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  --data-urlencode 'grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer' \
  --data-urlencode "assertion=$ID_JAG" \
  --data-urlencode 'client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer' \
  --data-urlencode "client_assertion=$CLIENT_ASSERTION_2" \
  | python3 -m json.tool
