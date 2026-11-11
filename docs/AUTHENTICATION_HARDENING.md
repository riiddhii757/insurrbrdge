# Authentication hardening — Phase 1A

## Implemented on main

- Per-IP request throttling for sign-in, password-reset, verification-resend, and MFA challenge endpoints using Rails controller rate limiting.
- Account lockout after 10 failed password attempts, with a 15-minute lock window.
- Password reset tokens generated with cryptographically secure randomness; only SHA-256 digests are stored.
- Password reset links expire after 30 minutes and are single-use.
- Password reset requests use a generic response to reduce account enumeration.
- Password reset clears failed-login lockout state.
- New agency registrations receive a one-time email verification link; unverified users cannot sign in.
- Verification tokens are cryptographically random, stored as SHA-256 digests, expire after 24 hours, and are consumed only after an explicit POST confirmation.
- Resending verification uses a generic response to reduce account enumeration and is throttled by IP.
- Accounts created before email verification was introduced are marked verified by migration to preserve existing access.
- Production email delivery can be enabled through SMTP environment variables.
- Existing bcrypt password hashing and 12-character minimum remain in place.
- Session version checks invalidate existing sessions after password changes, account disablement, and membership suspension or removal.
- Optional authenticator-app MFA uses time-based one-time passwords (TOTP); MFA secrets use Rails Active Record Encryption.
- Password authentication starts a separate, five-minute MFA challenge when MFA is enabled; the application session is not established until the second factor succeeds.
- Ten one-time recovery codes are generated when MFA is enabled. Only their SHA-256 digests are stored, and each code is consumed once.

## MFA deployment notes

- Keep `SECRET_KEY_BASE` stable and protected across deployments. The Active Record Encryption keys are derived from it; rotating it without a planned encryption-key migration can make stored MFA secrets unreadable.
- Users must save their recovery codes when they are displayed. They are not shown again.
- MFA enrollment and sign-in flows still require a production security review and testing with the chosen authenticator applications.

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
- Centralized rate limiting shared across web instances (the Rails cache-backed limiter must use a shared production cache).
- Security review of authentication flows, encryption-key management, mail delivery, account recovery, cookie settings, and session invalidation.
- Production deployment configuration, monitoring, backup and restore verification, and an incident-response process.
- Staff invitation flow and broader authorization tests for agency roles and tenant isolation.

This is an incremental security improvement, not a production security certification.
