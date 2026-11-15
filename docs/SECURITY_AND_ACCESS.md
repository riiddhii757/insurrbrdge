# Security and access model

## Account lifecycle

- Agency self-registration creates one agency, one user and one active agency_admin membership in a database transaction.
- Passwords use Rails has_secure_password (bcrypt); plaintext passwords are never persisted.
- Sign-in rotates the session; sign-out invalidates it.
- Email verification is required for new accounts. Verification tokens are random, hashed at rest, expire and are single-use.
- Password-reset tokens are random, hashed at rest, expire after 30 minutes and are single-use.
- Optional TOTP MFA uses Active Record Encryption; recovery codes are hashed and single-use.
- Session version checks revoke sessions after password changes, account disablement or membership suspension/removal.
- Sign-in and MFA endpoints have per-IP rate limits; repeated bad passwords trigger account lockout.

## Tenant boundary

- The active agency is resolved from authenticated membership, not a submitted agency ID.
- Customer and insurance-submission reads/writes are scoped through the active agency association.
- New records assign the agency and creator server-side.
- Customer and insurance-submission models validate tenant-consistent associations.
- Application edits are limited to draft/ready status; market-submitted risk data is locked to preserve a consistent submission snapshot.
- Audit events capture tenant, actor, action, record, request ID and safe metadata for customer/application changes and market responses.

## Roles

- agency_admin: agency administration.
- producer: customer and insurance application workflows.
- account_manager: service and policy lifecycle workflows as those modules are implemented.
- read_only: view-only access.
- Platform administration is a separate account-level capability.

## Remaining production controls

- Add comprehensive authorization tests for every role and controller action, including staff administration and future policy/document endpoints.
- Configure shared rate limiting across web instances.
- Configure production email delivery and verify account recovery end-to-end.
- Use a stable protected SECRET_KEY_BASE; encryption keys are derived from it. Plan key rotation before changing it.
- Configure encrypted object storage, signed short-lived access, malware scanning, file size/type validation and retention/deletion controls before enabling document uploads.
- Add security scanning, dependency updates, database backups/restore drills, monitoring, incident response and privacy notices.
- Complete legal review for state producer licensing, surplus-lines rules, privacy, quote presentation, payments and electronic signatures.

This is an incremental security implementation, not a production security certification.
