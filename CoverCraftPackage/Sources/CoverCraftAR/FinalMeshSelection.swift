// Version: 1.0.0
// CoverCraft AR Module - Final Mesh Selection

import CoverCraftDTO

/// Selects the final mesh handed from AR capture into the app workflow.
///
/// Camera-distance filtered meshes can be useful for diagnostics, but they are
/// not a reliable object boundary. Prefer the full raw captured mesh whenever
/// it is valid so the later review/crop step owns object isolation.
@available(iOS 18.0, macOS 15.0, *)
public enum FinalMeshSelection {

    public static func preferredFinalMesh(filtered: MeshDTO, raw: MeshDTO) -> MeshDTO {
        if raw.isValid {
            return raw
        }

        if filtered.isValid {
            return filtered
        }

        return filtered
    }
}
