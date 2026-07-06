# Use case 09 — Event hooks & inline hooks

Pattern source: developer.okta.com event-hook-implementation + token-inline-hook guides. Concepts and payload shapes: `references/hooks-events.md`.

## Files

- `okta.tf` — registers an event hook (user lifecycle) and a token inline hook
- `node/receiver.js` — Express receiver handling: verification handshake, event delivery, token-hook claim patching

## Requirements

- HTTPS, publicly reachable, fast (<3 s for inline hooks — do slow work async).
- Authenticate Okta's calls (shared-secret header configured on the hook).
- Event hooks must complete the one-time verification handshake before activation.
