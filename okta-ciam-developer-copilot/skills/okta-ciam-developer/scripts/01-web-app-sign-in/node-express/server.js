// Okta sign-in for Express using passport-openidconnect (Okta's recommended
// pattern for Node — no dedicated Okta server SDK).
// Source pattern: developer.okta.com/docs/guides/sign-into-web-app-redirect/node-express/main/
// npm i express express-session passport passport-openidconnect

const express = require('express');
const session = require('express-session');
const passport = require('passport');
const { Strategy } = require('passport-openidconnect');

const ISSUER = process.env.OKTA_OAUTH2_ISSUER; // https://{org}.okta.com/oauth2/default
const BASE_URL = process.env.APP_BASE_URL || 'http://localhost:3000';

const app = express();

app.use(
  session({
    secret: process.env.SESSION_SECRET || 'change-me',
    resave: false,
    saveUninitialized: false,
    cookie: { httpOnly: true, sameSite: 'lax' }, // + secure: true behind HTTPS
  })
);
app.use(passport.initialize());
app.use(passport.session());

passport.use(
  'oidc',
  new Strategy(
    {
      issuer: ISSUER,
      authorizationURL: `${ISSUER}/v1/authorize`,
      tokenURL: `${ISSUER}/v1/token`,
      userInfoURL: `${ISSUER}/v1/userinfo`,
      clientID: process.env.OKTA_OAUTH2_CLIENT_ID,
      clientSecret: process.env.OKTA_OAUTH2_CLIENT_SECRET,
      callbackURL: `${BASE_URL}/authorization-code/callback`,
      scope: 'openid profile email',
    },
    (issuer, profile, done) => done(null, profile)
  )
);

passport.serializeUser((user, done) => done(null, user));
passport.deserializeUser((obj, done) => done(null, obj));

function ensureLoggedIn(req, res, next) {
  if (req.isAuthenticated()) return next();
  res.redirect('/signin');
}

app.get('/', (req, res) =>
  res.send(req.user ? `Hello, ${req.user.displayName}. <a href="/signout">Sign out</a>` : '<a href="/signin">Sign in</a>')
);

app.get('/signin', passport.authenticate('oidc'));

app.get(
  '/authorization-code/callback',
  passport.authenticate('oidc', { failureRedirect: '/error' }),
  (req, res) => res.redirect('/profile')
);

app.get('/profile', ensureLoggedIn, (req, res) => res.json(req.user));

app.get('/signout', (req, res, next) => {
  req.logout(err => {
    if (err) return next(err);
    // For full Okta session logout, redirect to `${ISSUER}/v1/logout?id_token_hint=...&post_logout_redirect_uri=${BASE_URL}`
    res.redirect('/');
  });
});

app.listen(3000, () => console.log(`Listening on ${BASE_URL}`));
