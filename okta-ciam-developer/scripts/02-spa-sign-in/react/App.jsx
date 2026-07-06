// Okta React SPA sign-in (redirect model).
// Source pattern: developer.okta.com/docs/guides/sign-into-spa-redirect/react/main/
// npm i @okta/okta-react @okta/okta-auth-js react-router-dom

import { BrowserRouter as Router, Routes, Route, useNavigate } from 'react-router-dom';
import { OktaAuth, toRelativeUrl } from '@okta/okta-auth-js';
import { Security, LoginCallback, useOktaAuth } from '@okta/okta-react';

const oktaAuth = new OktaAuth({
  issuer: import.meta.env.VITE_OKTA_ISSUER,       // https://{org}.okta.com/oauth2/default
  clientId: import.meta.env.VITE_OKTA_CLIENT_ID,
  redirectUri: `${window.location.origin}/login/callback`,
  scopes: ['openid', 'profile', 'email'],
  pkce: true,
});

function Home() {
  const { oktaAuth, authState } = useOktaAuth();
  if (!authState) return <p>Loading…</p>;
  return authState.isAuthenticated ? (
    <div>
      <p>Hello, {authState.idToken.claims.name}</p>
      <button onClick={() => oktaAuth.signOut()}>Sign out</button>
    </div>
  ) : (
    <button onClick={() => oktaAuth.signInWithRedirect()}>Sign in with Okta</button>
  );
}

// Protect a route: redirect to Okta if unauthenticated
function RequiredAuth({ children }) {
  const { oktaAuth, authState } = useOktaAuth();
  if (!authState) return <p>Loading…</p>;
  if (!authState.isAuthenticated) {
    oktaAuth.setOriginalUri(window.location.href);
    oktaAuth.signInWithRedirect();
    return null;
  }
  return children;
}

function Profile() {
  const { authState } = useOktaAuth();
  return <pre>{JSON.stringify(authState.idToken.claims, null, 2)}</pre>;
}

export default function App() {
  const navigate = useNavigate();
  const restoreOriginalUri = (_oktaAuth, originalUri) =>
    navigate(toRelativeUrl(originalUri || '/', window.location.origin), { replace: true });

  return (
    <Security oktaAuth={oktaAuth} restoreOriginalUri={restoreOriginalUri}>
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/login/callback" element={<LoginCallback />} />
        <Route path="/profile" element={<RequiredAuth><Profile /></RequiredAuth>} />
      </Routes>
    </Security>
  );
}

// Calling your API with the access token:
//   const token = oktaAuth.getAccessToken();
//   fetch('/api/orders', { headers: { Authorization: `Bearer ${token}` } });
