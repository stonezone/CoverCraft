import SwiftUI
import CoverCraftCore
import CoverCraftDTO

@available(iOS 18.0, macOS 15.0, *)
@MainActor
public struct ExportView: View {
    @Environment(\.dependencyContainer) private var container
    
    let flattenedPanels: [FlattenedPanel]?
    
    @State private var selectedFormat = ExportFormat.png
    @State private var isExporting = false
    @State private var exportMessage: String?
    @State private var isErrorMessage = false
    @State private var lastExportURL: URL?
    
    public init(flattenedPanels: [FlattenedPanel]?) {
        self.flattenedPanels = flattenedPanels
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            headerView
            descriptionView
            
            if let panels = flattenedPanels {
                // Pattern preview
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.gray.opacity(0.2))
                        .frame(height: 300)
                    
                    VStack {
                        Image(systemName: "doc.text")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("\(panels.count) pattern pieces")
                            .font(.headline)
                            .foregroundColor(.green)
                        
                        // Panel previews
                        LazyVGrid(columns: Array(repeating: GridItem(.fixed(40)), count: min(panels.count, 6)), spacing: 4) {
                            ForEach(Array(panels.prefix(6).enumerated()), id: \.offset) { index, panel in
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(red: panel.color.red, green: panel.color.green, blue: panel.color.blue, opacity: panel.color.alpha))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Text("\(index + 1)")
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                    )
                            }
                            
                            if panels.count > 6 {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(.gray.opacity(0.5))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Text("+\(panels.count - 6)")
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                    )
                            }
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(.horizontal)
                
                // Format selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Export Format:")
                        .font(.headline)
                    
                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        HStack {
                            Button(action: { selectedFormat = format }) {
                                HStack {
                                    Image(systemName: selectedFormat == format ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedFormat == format ? .blue : .gray)
                                    
                                    Text(format.rawValue)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    // Format description
                                    Text(formatDescription(for: format))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding(.horizontal)
                .padding()
                .background(.blue.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Export button
                Button(action: exportPattern) {
                    if isExporting {
                        HStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                            Text("Exporting...")
                        }
                    } else {
                        Text("Export Pattern")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isExporting)
                
                if let message = exportMessage {
                    Text(message)
                        .foregroundColor(isErrorMessage ? .red : .green)
                        .padding(.horizontal)
                }
                
                #if os(iOS)
                if let url = lastExportURL {
                    ShareLink(item: url) {
                        Text("Share Exported Pattern")
                    }
                    .padding(.top, 4)
                }
                #endif
                
                // Pattern details
                VStack(alignment: .leading, spacing: 8) {
                    Text("Pattern Details:")
                        .font(.headline)
                    
                    ForEach(Array(panels.enumerated()), id: \.offset) { index, panel in
                        HStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(red: panel.color.red, green: panel.color.green, blue: panel.color.blue, opacity: panel.color.alpha))
                                .frame(width: 16, height: 16)
                            
                            Text("Piece \(index + 1)")
                                .font(.subheadline)
                            
                            Spacer()
                            
                            let bbox = panel.boundingBox
                            Text("\(Int(bbox.width)) × \(Int(bbox.height))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(.gray.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
                
            } else {
                Text("No pattern available for export")
                    .foregroundColor(.secondary)
                    .italic()
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Export")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
    
    private var exportService: PatternExportService? {
        container.resolve(PatternExportService.self)
    }
    
    private func formatDescription(for format: ExportFormat) -> String {
        switch format {
        case .png:
            return "High quality image"
        case .gif:
            return "Web-friendly"
        case .svg:
            return "Scalable vector"
        case .pdf:
            return "PDF document"
        case .dxf:
            return "CAD format"
        }
    }
    
    private func exportPattern() {
        guard let panels = flattenedPanels, !panels.isEmpty else { return }
        guard let service = exportService else {
            exportMessage = "Export service not available"
            isErrorMessage = true
            return
        }
        
        isExporting = true
        exportMessage = nil
        isErrorMessage = false
        lastExportURL = nil
        
        Task {
            do {
                let validation = service.validateForExport(panels, format: selectedFormat)
                guard validation.isValid else {
                    let message = validation.errors.joined(separator: "; ")
                    exportMessage = message.isEmpty ? "Export validation failed" : message
                    isErrorMessage = true
                    isExporting = false
                    return
                }
                
                let options = ExportOptions()
                let result = try await service.exportPatterns(panels, format: selectedFormat, options: options)
                
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(result.filename)
                try result.data.write(to: tempURL, options: .atomic)
                
                exportMessage = "Exported pattern to \(result.filename)"
                isErrorMessage = false
                lastExportURL = tempURL
                isExporting = false
            } catch {
                exportMessage = "Export failed: \(error.localizedDescription)"
                isErrorMessage = true
                isExporting = false
            }
        }
    }
    
    private var headerView: some View {
        Text("Export Pattern")
            .font(.largeTitle)
            .bold()
    }
    
    private var descriptionView: some View {
        Text("Export your sewing pattern in various formats.")
            .multilineTextAlignment(.center)
            .padding(.horizontal)
    }
}
