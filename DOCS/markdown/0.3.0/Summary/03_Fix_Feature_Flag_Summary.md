codex
You’re right — that test failed because missing flags were treated as false and
matched expected: false. I fixed FeatureFlagSpec to require the flag to be prese
nt.

- Root cause: FeatureFlagSpec used EvaluationContext.flag(for:) which returns fa
lse for missing keys, so “expected: false” passed even when the flag was absent.
- Fix: Check presence explicitly and only compare if the key exists.

Change
- File: Sources/SpecificationKit/Specs/FeatureFlagSpec.swift
- New logic:
  - guard let value = candidate.flags[flagKey] else { return false }
  - return value == expected

Status
- Ran tests: test_FeatureFlagSpec_matchesExpectedValue now passes.
- Entire suite green locally.

Let me know if you want similar “missing means fail” semantics applied to other
specs (e.g., treating missing userData or events consistently), or if you prefer
 a configurable policy.
