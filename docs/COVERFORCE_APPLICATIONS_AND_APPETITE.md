# CoverForce Applications and Appetite

This document records the provider contract supplied for the CoverForce API integration.

## Carrier appetite

- Method/path: `POST /api/check-appetite`
- Required JSON: `carriers` (one or more provider carrier IDs), `naicsCode` (six digits), `policyType`, and two-letter `state`.
- Supported appetite outcomes: `IN_APPETITE`, `NOT_IN_APPETITE`, `MAYBE_IN_APPETITE`.
- The integration sends an `x-request-id` and retains the provider's response request ID in provider errors.
- An appetite result is not a quote, approval, bind authorization, or promise of coverage.

Use `CoverForce::AppetiteChecker` with the agency's actual NAICS code, state, policy type, and selected carrier IDs. Do not infer a NAICS code.

## Create application

- Method/path: `POST /api/application`
- Required fields: `policyType`, `businessName`, `email`, `phone`, `carriers`, and `brokerConfigurations`.
- The response is HTTP 201 with an `applicationId`.
- `x-api-client-id` identifies the API client issued at onboarding.
- Every selected carrier must have exactly one broker configuration ID supplied from the agency's actual appointment setup.
- Application carrier selections are fixed at creation. Later updates may remove carriers but cannot add them.
- Locations are separate resources and must be added after application creation. Exactly one location must be primary before requesting quotes.

Use `CoverForce::ApplicationCreator`. It validates the payload and returns the parsed provider response. It does not invent broker codes or persist credentials.

## Updating

CoverForce Update Application is a full document replacement (`PUT`), not a patch. Fetch the current application, modify the complete document, then send it back. Omitted fields are cleared. Do not send a partial locally-built object. `insuranceInfo.carriers` is the documented exception: omit it to keep the existing carrier list.

## Validation

`POST /api/application/{applicationId}/validate` validates requested scopes and returns HTTP 200 even when `isValid` is false. Missing required fields and unanswered underwriting questions must be completed before quote requests. Validate again after answering questions because answers can reveal further questions.

## Still not implemented

This contract layer does not yet persist application IDs, create locations, fetch application field configuration, answer underwriting questions, update full application documents, request quotes, refer quotes, or bind policies. Those operations require their own verified endpoint schemas and workflow tests.
