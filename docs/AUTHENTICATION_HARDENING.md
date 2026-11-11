# Authentication hardening — Phase 1A

## Implemented on main

- Per-IP request throttling for sign-in and password-reset endpoints using Rails controller rate limiting.
- Account lockout after 10 failed password attempts, with a 15-minute lock window.
- Password reset tokens generated with cryptographically secure randomness; only SHA-256 digests are stored.
- Password reset links expire after 30 minutes and are single-use.
- Password reset requests use a generic response to reduce account enumeration.
- Password reset clears failed-login lockout state.
- New agency registrations receive a one-time email verification link; unverified users cannot sign in.
- Verification tokens are cryptographically random, stored as SHA-256 digests, expire after 24 hours, and are consumed on use.
- Resending verification uses a generic response to reduce account enumeration and is throttled by IP.
- Accounts created before this feature are marked verified by the migration to preserve existing access.
- Production email delivery can be enabled through SMTP environment variables.
- Existing bcrypt password hashing and 12-character minimum remain in place.
- Session version checks invalidate existing sessions after password changes, account disablement, and membership suspension or removal.

## Required deployment configuration

Set these secrets in the production environment before enabling password recovery email:

- APP_HOST
- MAILER_FROM (a sender address on a domain you control and have authorized with your email provider)
- SMTP_ADDRESS
- SMTP_PORT (defaults to 587)
- SMTP_DOMAIN
- SMTP_USERNAME
- SMTP_PASSWORD

Do not commit credentials. Until SMTP is configured and a delivery test succeeds, verification and password-reset email delivery are not verified.

## Still required before commercial use

- Configure SMTP and verify real delivery of signup verification and password-reset messages.
- Multi-factor authentication (TOTP or passkeys), recovery codes, and enrollment enforcement.
- Centralized rate limiting shared across web instances (the Rails cache-backed limiter must use a shared production cache).
- Security review of authentication flows, mail delivery, cookie settings, account recovery, and session invalidation.
- Production deployment configuration, monitoring, backup and restore verification, and an incident-response process.

This is an incremental security improvement, not a production security certification.
