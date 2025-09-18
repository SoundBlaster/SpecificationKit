# Security Policy

## Supported Versions

We actively support the following versions of SpecificationKit with security updates:

| Version | Supported          |
| ------- | ------------------ |
| 3.0.x   | :white_check_mark: |
| 2.x.x   | :white_check_mark: |
| < 2.0   | :x:                |

## Reporting a Vulnerability

If you discover a security vulnerability in SpecificationKit, please report it responsibly:

### For Critical Security Issues

For critical security vulnerabilities that could affect users' applications:

1. **Do NOT** create a public GitHub issue
2. Email security reports to: [egor.merkushev@yandex.ru](mailto:egor.merkushev@yandex.ru)
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

### For Non-Critical Security Issues

For lower-severity security concerns:

1. Create a GitHub issue with the `security` label
2. Provide detailed information about the concern
3. Follow responsible disclosure practices

## Security Considerations

### Thread Safety

SpecificationKit is designed with thread safety in mind:

- All public APIs are concurrency-safe
- Context providers use appropriate synchronization
- Property wrappers handle concurrent access safely

### Memory Safety

- All specifications are memory-safe by design
- No unsafe operations in the public API
- Proper resource management for context providers

### Input Validation

- Specifications validate input parameters appropriately
- Context providers sanitize external data
- Macro implementations include proper validation

## Response Timeline

- **Critical vulnerabilities**: Response within 24 hours, fix within 7 days
- **High severity**: Response within 72 hours, fix within 14 days
- **Medium/Low severity**: Response within 1 week, fix in next release

## Security Updates

Security updates will be released as patch versions and communicated through:

- GitHub Security Advisories
- Release notes
- Package manager updates

Thank you for helping keep SpecificationKit secure!
