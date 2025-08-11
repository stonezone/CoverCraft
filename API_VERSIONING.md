# API Versioning Strategy

## Overview
CoverCraft follows semantic versioning (SemVer) for all DTOs and public APIs to ensure backward compatibility and smooth upgrades.

## Versioning Scheme
- **MAJOR.MINOR.PATCH** (e.g., 1.2.3)
- **MAJOR**: Breaking changes to DTOs or public APIs
- **MINOR**: New features, backward-compatible additions
- **PATCH**: Bug fixes, internal improvements

## Current Versions
- **CoverCraftDTO**: v1.0.0
- **CoverCraftCore**: v1.0.0  
- **Overall API**: v1.0.0

## DTO Versioning Rules

### 1. Breaking Changes (MAJOR version bump)
- Removing fields from DTOs
- Changing field types
- Renaming DTOs or fields
- Changing validation rules that make previously valid data invalid

### 2. Non-Breaking Changes (MINOR version bump)
- Adding optional fields with default values
- Adding new DTOs
- Adding new validation (that doesn't invalidate existing data)
- Adding computed properties

### 3. Patch Changes
- Bug fixes in validation logic
- Performance improvements
- Internal implementation changes

## Migration Strategy

### Contract Tests
- Snapshot tests ensure serialization format doesn't change unexpectedly
- Located in `Tests/ContractTests/DTOContractTests.swift`
- Run automatically in CI/CD pipeline

### Version Migration
When breaking changes are required:

1. **Create new DTO version**: `MeshDTO_v2`
2. **Maintain old version**: Keep `MeshDTO` for compatibility
3. **Add migration logic**: `MeshDTOMigrator.migrate(from: v1, to: v2)`
4. **Update version string**: Bump version in DTO struct
5. **Update contract tests**: Add new snapshots for v2

### Example Migration

```swift
// Old version (v1.0.0)
public struct MeshDTO: Codable {
    public let version = "1.0.0"
    public let vertices: [SIMD3<Float>]
    public let triangleIndices: [Int]
}

// New version (v2.0.0) - Breaking change
public struct MeshDTO: Codable {
    public let version = "2.0.0" 
    public let vertices: [SIMD3<Float>]
    public let faces: [Face] // Changed from triangleIndices
    public let normals: [SIMD3<Float>] // New required field
}

// Migration utility
public enum MeshDTOMigrator {
    public static func migrate(_ v1: MeshDTO_v1) -> MeshDTO {
        return MeshDTO(
            vertices: v1.vertices,
            faces: Face.fromTriangleIndices(v1.triangleIndices),
            normals: computeNormals(from: v1.vertices, indices: v1.triangleIndices)
        )
    }
}
```

## API Compatibility Matrix

| App Version | DTO v1.0 | DTO v1.1 | DTO v2.0 |
|-------------|----------|----------|----------|
| 1.0.x       | ✅       | ✅       | ❌       |
| 1.1.x       | ✅       | ✅       | ❌       |  
| 2.0.x       | ✅*      | ✅       | ✅       |

*With migration support

## Release Process

### 1. Pre-Release Checklist
- [ ] Contract tests pass
- [ ] Version numbers updated
- [ ] Migration guides written
- [ ] Changelog updated
- [ ] Breaking changes documented

### 2. Release Tagging
```bash
git tag -a v1.2.0 -m "Release v1.2.0: Added pattern validation"
git push origin v1.2.0
```

### 3. Documentation Update
- Update README.md with new version
- Generate API documentation with DocC
- Update migration guides

## Deprecation Policy

### Timeline
- **Immediate**: Mark as deprecated with `@available(*, deprecated)`
- **3 months**: Add compiler warnings
- **6 months**: Remove in next major version

### Example
```swift
@available(*, deprecated, message: "Use newMethod() instead")
public func oldMethod() { }

@available(iOS 18.0, *, deprecated, renamed: "improvedInit()")
public init(legacyParameter: String) { }
```

## Version Detection

### Runtime Version Check
```swift
public extension MeshDTO {
    var apiVersion: Version {
        return Version(version) ?? Version(1, 0, 0)
    }
    
    var isCompatible: Bool {
        return apiVersion.major == 1
    }
}
```

### Build-Time Compatibility
```swift
#if COVERCRAFT_API_VERSION >= 20000 // v2.0.0
    // Use new API
#else
    // Use legacy API
#endif
```

## Monitoring

### Metrics Collection
- Track DTO version usage in MetricsService
- Monitor migration success rates
- Alert on compatibility issues

### Contract Validation
- CI/CD pipeline validates all contract tests
- Automatic snapshot updates for approved changes
- Breaking change detection in PR reviews

## Best Practices

1. **Design for Evolution**: Use optional fields when possible
2. **Validate Early**: Catch breaking changes in development
3. **Document Everything**: Every change needs migration notes
4. **Test Thoroughly**: Contract tests are mandatory
5. **Communicate Changes**: Breaking changes require team approval