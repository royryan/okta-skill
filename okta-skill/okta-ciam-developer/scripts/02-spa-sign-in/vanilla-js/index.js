// Framework-agnostic SPA sign-in with okta-auth-js (redirect model).
// Source pattern: developer.okta.com/docs/guides/auth-js-redirect/
// npm i @okta/okta-auth-js

import { OktaAuth } from '@okta/okta-auth-js';

const authClient = new OktaAuth({
  issuer: process.env.OKTA_ISSUER,       // https://{org}.okta.com/oauth2/default
  clientId: process.env.OKTA_CLIENT_ID,
  redirectUri: `${window.location.origin}/login/callback`,
  scopes: ['openid', 'profile', 'email'],
});

async function main() {
  if (authClient.isLoginRedirect()) {
    // We're on /login/callback — exchange code for tokens (PKCE handled internally)
    const { tokens } = await authClient.token.parseFromUrl();
    authClient.tokenManager.setTokens(tokens);
    window.history.replaceState({}, '', '/');
  }

  authClient.start(); // token auto-renew, cross-tab sync

  if (await authClient.isAuthenticated()) {
    const user = await authClient.getUser();
    document.body.textContent = `Hello, ${user.name}`;
    // API calls: const accessToken = authClient.getAccessToken();
  } else {
    document.body.innerHTML = '<button id="si">Sign in with Okta</button>';
    document.getElementById('si').onclick = () => authClient.signInWithRedirect();
  }
}

main();
