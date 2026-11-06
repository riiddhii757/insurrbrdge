# EZer-inspired risk contract and CoverForce sandbox plan

## Why EZer

InsurrBrdge uses the open-source [EZer](https://github.com/k3nnyw0lf/EZer) project as a design reference for an agency-direct insurance integration contract. EZer is licensed under MIT; its upstream copyright and license are retained in this repository's integration documentation. The upstream project describes itself as an early reference implementation and explicitly says no carrier has yet adopted its contract.

This repository does **not** copy EZer's implementation or claim that the current mapper conforms to the upstream OpenAPI contract. The first Rails mapper at `app/services/carrier_adapters/ezer_contract.rb` maps only fields that InsurrBrdge currently collects. It deliberately does not invent exposures, limits, deductibles, premiums, coverages or carrier decisions.

Before claiming conformance, compare the mapper with the current upstream `spec/` definitions and run the upstream conformance suite against an authorized implementation.

## Current mapping boundary

The existing InsurrBrdge application currently has a business legal name, commercial line of business, risk state, effective date, expiration date and internal submission reference. It does not yet collect the complete ACORD commercial application. The mapper therefore emits only those known values in a canonical commercial risk envelope.

The next intake expansion must add structured, validated fields for:
- named insureds, DBA and entity type
- mailing and risk locations, including multiple locations
- industry description, NAICS/SIC and class codes
- annual revenue, payroll, employee counts and subcontractor exposure
- operations and prior carrier/loss history
- requested limits, deductibles and coverage selections
- vehicles, drivers, property schedules and supporting documents where applicable

Each field should have provenance (broker-entered, document-extracted, or carrier-adjusted), validation and an audit trail. Missing required information should produce a needs-information state, not a guessed value.

## CoverForce: free evaluation path

CoverForce publicly advertises a free API sandbox for developers and a separate custom-priced production API plan. Its published pricing page describes production API usage as negotiated/usage-based; the free sandbox is not a free production quote service.

- Developer information: https://www.coverforce.com/developers
- Integration/carrier information: https://www.coverforce.com/integration
- Pricing: https://www.coverforce.click/pricing

The agency or startup must register with CoverForce and receive its own sandbox credentials and current API documentation. InsurrBrdge has not been granted access, and no API credentials have been provided. Do not paste credentials into source code, GitHub issues or ChatGPT. Store them only in the deployment's approved secret manager.

## Integration release gates

1. Obtain written confirmation that the CoverForce sandbox is available to this software vendor and learn whether test submissions can be made without active carrier appointments.
2. Obtain the current OpenAPI/schema, authentication instructions, supported products and sandbox test cases from CoverForce.
3. Implement only documented routes and payloads; do not guess URLs, auth flows, headers or response shapes.
4. Add request/response contract tests using provider-issued examples and sanitized fixtures.
5. Keep all sandbox calls disabled until credentials and the provider schema are configured.
6. Keep production configuration separate and fail closed unless production access is explicitly approved.
7. Confirm the agency's appointments, state/product authority and contractual right to display/store quote information before production quoting.
8. Treat quote status, carrier messages, premium, fees, limits, deductibles, forms, exclusions and carrier-adjusted values as separate structured data. A referral or decline must never be represented as a quote.

## Zero-cost development boundary

The local mapper, intake validation, tests, demo workflow and adapter framework can be developed without paying a carrier API fee. The CoverForce sandbox may be free subject to its current signup and program terms. Real production carrier quotes, binding, issuance and servicing are not promised to be free and require provider authorization, agency appointments and potentially paid usage.
