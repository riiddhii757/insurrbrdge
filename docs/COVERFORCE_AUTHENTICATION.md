# CoverForce authentication

This implementation follows the authentication instructions supplied from the CoverForce API documentation.

## Environments

- Sandbox API root: `https://sandbox.api.coverforce.com`
- Production API root: `https://production.api.coverforce.com`
- Token endpoint: `POST /auth` at the API root (not under `/api`).

The token request uses HTTP Basic authentication with the onboarding ClientId and ClientSecret. Its form body is `grant_type=client_credentials`. The successful response must contain `access_token`, `expires_in`, and `token_type: Bearer`.

## Configuration

Set these variables in the deployment secret manager, not in source control:

```text
COVERFORCE_ENV=sandbox
COVERFORCE_SANDBOX_CLIENT_ID=<issued-client-id>
COVERFORCE_SANDBOX_CLIENT_SECRET=<issued-client-secret>
```

For an explicitly authorized production deployment, use `COVERFORCE_ENV=production` and separately provision:

```text
COVERFORCE_PRODUCTION_CLIENT_ID=<issued-production-client-id>
COVERFORCE_PRODUCTION_CLIENT_SECRET=<issued-production-client-secret>
```

Do not reuse sandbox credentials in production. Do not commit credentials, bearer tokens, or real customer data to Git.

## Usage

```ruby
token_client = CoverForce::TokenClient.new
authorization = token_client.authorization_header
# => "Bearer <short-lived-access-token>"
```

Pass that header to subsequent protected API requests. The client caches the token in process memory and refreshes it early using the provider's `expires_in` value. It does not persist tokens to the database or logs.

The client sends an `x-request-id` UUID on the token request. CoverForce echoes it in the response header; retain that request ID when diagnosing provider-side errors. The token client exposes the request ID on its internal token value, but never logs the access token.

## Important note about the published curl example

The authentication prose specifies HTTP Basic using the onboarding ClientId and ClientSecret. The curl example shown in the supplied documentation excerpt omits the Basic Authorization header. This implementation follows the explicit Basic-authentication requirement. Confirm the discrepancy with CoverForce if their live docs continue to show a curl sample without it.

## Scope and safety

This is the authentication foundation only. It does not yet call application, appetite, quote, referral, proposal, webhook, or bind endpoints. Those operations must be implemented from their exact current API schemas and provider-issued sandbox examples. Production must remain disabled until CoverForce approves production credentials and the agency's carrier access and contractual permissions are confirmed.
