# Authentication hardening — Phase 1A

## Implemented on this branch

- Per-IP request throttling for sign-in and password-reset endpoints using Rails controller rate limiting.
- Account lockout after 10 failed password attempts, with a 15-minute lock window.
- Password reset tokens generated with cryptographically secure randomness; only SHA-256 digests are stored.
- Password reset links expire after 30 minutes and are single-use.
- Password reset requests use a generic response to reduce account enumeration.
- Password reset clears failed-login lockout state.
- Production email delivery can be enabled through SMTP environment variables.
- Existing bcrypt password hashing and 12-character minimum remain in place.

## Required deployment configuration

Set these secrets in the production environment before enabling password recovery email:

- APP_HOST
- MAILER_FROM (a sender address on a domain you control and have authorized with your email provider)
- SMTP_ADDRESS
- SMTP_PORT (defaults to 587)
- SMTP_DOMAIN
- SMTP_USERNAME
- SMTP_PASSWORD

Do not commit credentials. Until SMTP is configured and a delivery test succeeds, password reset email delivery is not verified.

## Still required before commercial use

- Email verification before enabling an account.
- Multi-factor authentication (TOTP or passkeys), recovery codes, and enrollment enforcement.
- Session rotation and revocation on password change, account disable, and membership removal.
- Centralized rate limiting shared across web instances (the Rails cache-backed limiter must use a shared production cache).
- Security review of authentication flows, mail delivery, cookie settings, and account recovery.
- Automated tests and a successful CI run for this branch.

This branch is an incremental security improvement, not a production security certification.
