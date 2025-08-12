# CoverCraft API Versioning

## Versioning Philosophy
- Semantic Versioning (SemVer) 2.0.0
- Backwards compatibility is a priority
- Clear migration paths for breaking changes

## Current Versions

### Data Transfer Objects (DTO) Compatibility

| DTO           | V1 Compatibility | V2 Compatibility | Migration Status |
|---------------|------------------|------------------|-----------------|
| MeshDTO       | Fully Supported  | Partial          | In Progress     |
| CalibrationDTO| Fully Supported  | Partial          | In Progress     |
| PanelDTO      | Fully Supported  | Partial          | In Progress     |
| FlattenedPanelDTO | Fully Supported | Partial       | In Progress     |

## Compatibility Matrix

### Version 1.0.0 Compatibility

| Component               | Minimum Version | Maximum Version | Status      |
|-------------------------|-----------------|-----------------|-------------|
| Swift Language         | 6.1.0           | 7.0.0           | Full Support|
| iOS                    | 18.0            | 19.0            | Full Support|
| ARKit                  | 18.0            | 19.0            | Full Support|
| RealityKit             | 18.0            | 19.0            | Full Support|

## Breaking Change Policy

### What Constitutes a Breaking Change
- Removing public methods or properties
- Changing method signatures
- Modifying enum cases
- Altering core protocol requirements
- Changing semantic behavior of existing methods

### Migration Guarantees
- Minimum 3-month deprecation window for major changes
- Comprehensive migration guides
- Automated migration tools when possible
- Detailed changelog with upgrade instructions

## Deprecation Strategy

### Deprecation Stages
1. **Annotation Stage**
   - Add `@available(*, deprecated, message: "Replacement details")` to deprecated APIs
   - Provide clear migration path in documentation

2. **Warning Stage**
   - Compiler warnings triggered for deprecated usage
   - Detailed migration hints provided

3. **Removal Stage**
   - Complete removal of deprecated APIs
   - Typically 3-6 months after initial deprecation

## API Evolution Principles

- Prefer additive changes
- Maintain backward compatibility
- Use protocol extensions for default implementations
- Leverage Swift's `@available` attribute for versioning

## Example of API Versioning

```swift
// V1 Protocol
protocol MeshProcessing {
    func processMesh(_ mesh: MeshDTO) -> ProcessedMeshDTO
}

// V2 Enhanced Protocol
protocol MeshProcessing {
    // Original method marked as deprecated
    @available(*, deprecated, message: "Use processMesh(_:options:) instead")
    func processMesh(_ mesh: MeshDTO) -> ProcessedMeshDTO
    
    // New method with enhanced capabilities
    func processMesh(_ mesh: MeshDTO, options: ProcessingOptions) -> ProcessedMeshDTO
}
```

## Migration Guidelines

### Migrating from V1 to V2
1. Update dependencies to latest version
2. Review changelog for breaking changes
3. Run swift-migration-tool (coming soon)
4. Update deprecated method calls
5. Recompile and test thoroughly

## Future API Considerations
- Continued focus on type safety
- Enhanced error handling
- More granular configuration options
- Performance optimizations
- Expanded platform support