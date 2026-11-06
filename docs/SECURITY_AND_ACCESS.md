# Security and access model

## Account lifecycle
- Agency self-registration creates one agency, one user and one active agency_admin membership in a single database transaction.
- Passwords are stored through Rails has_secure_password (bcrypt); plaintext passwords are never persisted.
- Sign-in rotates the session after successful authentication.
- Disabled accounts and users without an active agency membership cannot enter the workspace.
- Sign-out invalidates the session.

## Tenant boundary
- The active agency is resolved from the authenticated user's active membership, not accepted from an arbitrary request parameter.
- Workspace queries are scoped through the resolved agency association.
- New customer, submission, quote and document endpoints must use current_agency as the tenant boundary and must never trust a submitted agency_id.
- Cross-tenant foreign-key consistency must be validated at the model/service layer as well as controller scope.

## Roles
- agency_admin: agency administration and user management.
- producer: create and manage submissions and customer relationships.
- account_manager: service and policy lifecycle workflows.
- read_only: view-only access.
- Platform administration is a separate account-level capability and must be audited.

## Production hardening still required
Before accepting real customer data, add and verify:
- Login throttling, password reset with expiring single-use tokens, email verification and MFA.
- Secure cookie settings, HTTPS, CSP review, secrets management and encrypted file storage.
- Authorization policy tests for every controller/action and cross-tenant association tests.
- Security scanning, dependency updates, backup/restore drills, incident response and privacy/legal review.
- Staff invitation flow with single-use expiring tokens; never create staff accounts by accepting a public role parameter.

This foundation is an early development implementation, not a security certification or production readiness claim.
