# Dependency Management Policy

## Overview

This document defines the CoverCraft project's approach to dependency management, security, and maintenance.

## Core Principles

### 1. Minimal Dependencies Philosophy
- **Prefer Apple frameworks** over third-party libraries when possible
- **Zero third-party dependencies** is the current target (achieved ✅)
- Every dependency must provide significant value that justifies the added complexity

### 2. Security First
- All dependencies must be actively maintained and security-patched
- Immediate updates required for security vulnerabilities (CVSS ≥ 7.0)
- Regular security audits using automated tools

### 3. Stability and Reliability
- Use exact version pinning for production releases
- Prefer semantic versioning-compliant packages
- Maintain compatibility with latest iOS and Swift versions

## Dependency Categories

### Allowed Dependencies

#### 1. Apple System Frameworks (Always Approved)
- **SwiftUI, UIKit**: User interface frameworks
- **ARKit, SceneKit, RealityKit**: Augmented reality and 3D graphics
- **Foundation, CoreFoundation**: Core system utilities
- **simd, Accelerate**: High-performance computing
- **os, OSLog**: System logging and diagnostics
- **Testing, XCTest**: Testing frameworks

#### 2. High-Quality Third-Party Libraries (Case-by-Case)
Criteria for approval:
- ✅ Active maintenance (commits within 6 months)
- ✅ Security track record (no critical vulnerabilities)
- ✅ Swift 6.0+ compatibility
- ✅ iOS 18.0+ support
- ✅ Comprehensive test coverage
- ✅ Clear documentation
- ✅ Permissive license (MIT, Apache 2.0, BSD)

### Restricted Dependencies

#### 1. Automatically Rejected
- 🚫 Packages with known security vulnerabilities
- 🚫 Unmaintained packages (no updates > 1 year)
- 🚫 Packages with restrictive licenses (GPL, AGPL)
- 🚫 Packages requiring network access at runtime
- 🚫 Packages with large binary sizes (> 50MB)

#### 2. Requires Justification
- ⚠️ Dependencies with dependencies (transitive deps)
- ⚠️ Packages larger than 10MB
- ⚠️ Packages that duplicate Apple framework functionality
- ⚠️ Beta or pre-release packages

## Approval Process

### 1. Proposal Phase
For any new dependency, create a proposal including:
- **Use case**: What problem does this solve?
- **Alternatives**: Why not use Apple frameworks or existing code?
- **Risk assessment**: Security, maintenance, performance implications
- **Exit strategy**: How to remove if needed

### 2. Evaluation Criteria
Score each dependency (0-5 scale):
- **Necessity** (0-5): Is this essential or nice-to-have?
- **Quality** (0-5): Code quality, documentation, testing
- **Maintenance** (0-5): Active development, responsiveness
- **Security** (0-5): Track record, audit history
- **Performance** (0-5): Runtime efficiency, binary size
- **Licensing** (0-5): Compatible with project license

Minimum score: 20/30 for approval

### 3. Trial Period
- Add dependency with exact version pinning
- Monitor for 30 days in development
- Evaluate performance impact and stability
- Final decision after trial period

## Version Management

### 1. Semantic Versioning Strategy
```swift
// Production: Use exact versions for predictability
.package(url: "https://github.com/example/lib.git", exact: "2.1.0")

// Development: Allow patch updates for non-critical deps
.package(url: "https://github.com/example/lib.git", from: "2.1.0")

// Never use: Broad version ranges (too unpredictable)
// .package(url: "https://github.com/example/lib.git", "2.0.0"..<"3.0.0")
```

### 2. Update Schedule
- **Security patches**: Immediate (same day)
- **Bug fixes**: Weekly review, apply within 5 business days
- **Minor updates**: Monthly review, apply after testing
- **Major updates**: Quarterly review, plan migration if beneficial

## Automated Management

### 1. Dependabot Configuration
- **Weekly scans** for all dependency types
- **Automatic PRs** for patch and minor updates
- **Security alerts** for immediate attention
- **Grouped updates** for related dependencies

### 2. Vulnerability Scanning
- **OWASP Dependency Check** integrated into CI/CD
- **GitHub Security Advisories** monitoring
- **Supply chain analysis** for transitive dependencies

### 3. License Compliance
- **Automated license scanning** in CI pipeline
- **License compatibility** verification
- **Attribution generation** for required licenses

## Emergency Procedures

### 1. Security Incident Response
1. **Immediate**: Remove vulnerable dependency if possible
2. **Same day**: Apply security patch if available
3. **24 hours**: Implement workaround if patch unavailable
4. **48 hours**: Complete risk assessment and communicate status

### 2. Dependency Unavailability
1. **Fork and maintain** critical dependencies if original abandoned
2. **Implement replacement** functionality using Apple frameworks
3. **Gradual migration** to alternative solutions
4. **Document** lessons learned and improve selection criteria

## Metrics and Monitoring

### 1. Health Indicators
- **Dependency count**: Target ≤ 5 third-party dependencies
- **Update frequency**: Average time from release to adoption
- **Security issues**: Number and severity of vulnerabilities
- **Build time impact**: Compilation speed degradation
- **Binary size**: Total size contribution of dependencies

### 2. Regular Reviews
- **Monthly**: Dependency health check and update status
- **Quarterly**: Full dependency audit and policy review
- **Annually**: Strategic review of dependency philosophy

## Current Status

### Active Dependencies
| Package | Version | Category | Last Review | Status |
|---------|---------|----------|-------------|--------|
| *No third-party dependencies* | - | - | 2025-01-14 | ✅ Target achieved |

### Apple Framework Dependencies
- SwiftUI, ARKit, SceneKit, Foundation, UIKit, CoreGraphics, simd, os
- All current and supported in iOS 18.0+
- Automatic updates with iOS releases

## Future Considerations

### Potential Additions (Under Consideration)
1. **SwiftData** - Local persistence (if needed)
2. **Core ML** - Machine learning features
3. **CloudKit** - Cloud sync capabilities
4. **Metal** - GPU acceleration for mesh processing

### Exit Strategies
- All potential dependencies have identified Apple framework alternatives
- Custom implementation plans documented for each use case
- No vendor lock-in situations

---

**Policy Version**: 1.0  
**Effective Date**: 2025-01-14  
**Next Review**: 2025-04-14  
**Owner**: Development Team  
**Approvers**: Technical Lead, Security Team