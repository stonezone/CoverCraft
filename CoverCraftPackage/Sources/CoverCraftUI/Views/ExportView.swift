import SwiftUI
import CoverCraftCore
import CoverCraftDTO

@available(iOS 18.0, macOS 15.0, *)
@MainActor
public struct ExportView: View {
    @Environment(\.dependencyContainer) private var container
    
    let flattenedPanels: [FlattenedPanel]?
    
    @State private var selectedFormat = ExportFormat.pdf
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
                    
                    ForEach(supportedFormats, id: \.self) { format in
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
        .onAppear {
            guard let service = exportService else { return }
            let formats = service.getSupportedFormats()
            if !formats.contains(selectedFormat), let first = formats.first {
                selectedFormat = first
            }
        }
    }
    
    private var exportService: PatternExportService? {
        container.resolve(PatternExportService.self)
    }

    private var supportedFormats: [ExportFormat] {
        exportService?.getSupportedFormats() ?? [.pdf, .svg, .png]
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
        
        let selectedFormat = selectedFormat
        let options = ExportOptions()

        Task {
            do {
                enum ExportOutcome: Sendable {
                    case success(message: String, url: URL)
                    case failure(message: String)
                }

                let outcome = try await Task.detached {
                    let validation = service.validateForExport(panels, format: selectedFormat)
                    guard validation.isValid else {
                        let message = validation.errors.joined(separator: "; ")
                        return ExportOutcome.failure(message: message.isEmpty ? "Export validation failed" : message)
                    }

                    let result = try await service.exportPatterns(panels, format: selectedFormat, options: options)

                    // Save to Documents directory for persistence (not temp)
                    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    let patternsFolder = documentsURL.appendingPathComponent("CoverCraft Patterns", isDirectory: true)
                    try FileManager.default.createDirectory(at: patternsFolder, withIntermediateDirectories: true)
                    let fileURL = patternsFolder.appendingPathComponent(result.filename)
                    try result.data.write(to: fileURL, options: .atomic)

                    return ExportOutcome.success(
                        message: "Saved to CoverCraft Patterns/\(result.filename)",
                        url: fileURL
                    )
                }.value

                switch outcome {
                case .success(let message, let url):
                    exportMessage = message
                    isErrorMessage = false
                    lastExportURL = url
                    isExporting = false
                case .failure(let message):
                    exportMessage = message
                    isErrorMessage = true
                    isExporting = false
                }
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
