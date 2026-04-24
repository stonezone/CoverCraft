import SwiftUI
import CoverCraftCore
import CoverCraftDTO

@available(iOS 18.0, macOS 15.0, *)
@MainActor
public struct ExportView: View {
    @Environment(\.dependencyContainer) private var container

    let flattenedPanels: [FlattenedPanelDTO]?

    @State private var selectedFormat = ExportFormat.pdf
    @State private var isExporting = false
    @State private var exportMessage: String?
    @State private var isErrorMessage = false
    @State private var lastExportURL: URL?
    @State private var didRunUITestAutoExport = false

    public init(flattenedPanels: [FlattenedPanelDTO]?) {
        self.flattenedPanels = flattenedPanels
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                heroCard

                if let panels = flattenedPanels {
                    previewCard(panels)
                    formatCard
                    exportActionCard
                    detailsCard(panels)
                } else {
                    unavailableCard
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .background(CoverCraftScreenBackground().ignoresSafeArea())
        .accessibilityIdentifier("covercraft.exportView")
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

            if ProcessInfo.processInfo.arguments.contains("UITEST_AUTO_EXPORT"), !didRunUITestAutoExport {
                didRunUITestAutoExport = true
                exportPattern()
            }
        }
    }

    private var exportService: PatternExportService? {
        container.resolve(PatternExportService.self)
    }

    private var supportedFormats: [ExportFormat] {
        exportService?.getSupportedFormats() ?? [.pdf, .svg, .png]
    }

    private var heroCard: some View {
        CoverCraftCard(tone: flattenedPanels == nil ? .warning : .success) {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 10) {
                    CoverCraftStatusChip(
                        flattenedPanels == nil ? "No pattern loaded" : "Pattern ready to export",
                        systemImage: flattenedPanels == nil ? "exclamationmark.triangle.fill" : "square.and.arrow.up.fill",
                        tone: flattenedPanels == nil ? .warning : .success
                    )

                    Text("Export the generated panels to print, edit, or share.")
                        .font(.title3.weight(.semibold))

                    Text("PDF is best for printing, SVG is best for editing, and PNG is best for quick previews.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                Image(systemName: "doc.text.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(flattenedPanels == nil ? Color.orange : Color.green)
                    .frame(width: 58, height: 58)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill((flattenedPanels == nil ? Color.orange : Color.green).opacity(0.12))
                    )
            }
        }
    }

    private func previewCard(_ panels: [FlattenedPanelDTO]) -> some View {
        CoverCraftCard(tone: .success) {
            CoverCraftSectionHeading(
                step: "Preview",
                title: "Pattern Summary",
                subtitle: "Quick visual confirmation before writing files to disk.",
                statusTitle: "\(panels.count) pieces",
                statusImage: "square.grid.3x3.fill",
                tone: .success
            )

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                CoverCraftMetricTile(
                    title: "Pieces",
                    value: "\(panels.count)",
                    subtitle: "Flattened panels",
                    systemImage: "square.grid.3x3.fill",
                    tone: .success
                )
                CoverCraftMetricTile(
                    title: "Default format",
                    value: selectedFormat.rawValue,
                    subtitle: formatDescription(for: selectedFormat),
                    systemImage: "doc.richtext",
                    tone: .accent
                )
            }

            LazyVGrid(
                columns: Array(repeating: GridItem(.fixed(42), spacing: 8), count: min(max(panels.count, 1), 6)),
                spacing: 8
            ) {
                ForEach(Array(panels.prefix(6).enumerated()), id: \.offset) { index, panel in
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(
                            red: panel.color.red,
                            green: panel.color.green,
                            blue: panel.color.blue,
                            opacity: panel.color.alpha
                        ))
                        .frame(width: 42, height: 42)
                        .overlay(
                            Text("\(index + 1)")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                        )
                }

                if panels.count > 6 {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.black.opacity(0.15))
                        .frame(width: 42, height: 42)
                        .overlay(
                            Text("+\(panels.count - 6)")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.primary)
                        )
                }
            }
            .accessibilityIdentifier("covercraft.exportPieceCountLabel")
        }
    }

    private var formatCard: some View {
        CoverCraftCard(tone: .accent) {
            CoverCraftSectionHeading(
                step: "Step 1",
                title: "Choose Format",
                subtitle: "Select the destination format based on how the pattern will be used next.",
                statusTitle: selectedFormat.rawValue,
                statusImage: "checkmark.circle.fill",
                tone: .accent
            )

            VStack(spacing: 10) {
                ForEach(supportedFormats, id: \.self) { format in
                    Button {
                        selectedFormat = format
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: selectedFormat == format ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selectedFormat == format ? Color.blue : .secondary)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(format.rawValue)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text(formatDescription(for: format))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(selectedFormat == format ? Color.blue.opacity(0.12) : Color.white.opacity(0.5))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .strokeBorder(selectedFormat == format ? Color.blue.opacity(0.24) : Color.black.opacity(0.05), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var exportActionCard: some View {
        CoverCraftCard(tone: isErrorMessage ? .warning : .accent) {
            CoverCraftSectionHeading(
                step: "Step 2",
                title: "Export Files",
                subtitle: "Write the selected format to Documents/CoverCraft Patterns.",
                tone: isErrorMessage ? .warning : .accent
            )

            Button(action: exportPattern) {
                if isExporting {
                    HStack {
                        ProgressView()
                            .progressViewStyle(.circular)
                        Text("Exporting...")
                            .frame(maxWidth: .infinity)
                    }
                } else {
                    Label("Export Pattern", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
            }
            .accessibilityIdentifier("covercraft.exportActionButton")
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.blue)
            .disabled(isExporting || flattenedPanels == nil)

            if let exportMessage {
                Text(exportMessage)
                    .accessibilityIdentifier("covercraft.exportStatusMessage")
                    .font(.subheadline)
                    .foregroundStyle(isErrorMessage ? Color.red : Color.green)
            }

            #if os(iOS)
            if let lastExportURL {
                ShareLink(item: lastExportURL) {
                    Label("Share Exported Pattern", systemImage: "square.and.arrow.up.on.square")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            #endif
        }
    }

    private func detailsCard(_ panels: [FlattenedPanelDTO]) -> some View {
        CoverCraftCard(tone: .neutral) {
            CoverCraftSectionHeading(
                step: "Details",
                title: "Panel Dimensions",
                subtitle: "Quick size check before print or further editing.",
                tone: .neutral
            )

            VStack(spacing: 10) {
                ForEach(Array(panels.enumerated()), id: \.offset) { index, panel in
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color(
                                red: panel.color.red,
                                green: panel.color.green,
                                blue: panel.color.blue,
                                opacity: panel.color.alpha
                            ))
                            .frame(width: 18, height: 18)

                        Text("Piece \(index + 1)")
                            .font(.subheadline.weight(.semibold))

                        Spacer()

                        let bbox = panel.boundingBox
                        Text("\(Int(bbox.width)) × \(Int(bbox.height))")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white.opacity(0.45))
                    )
                }
            }
        }
    }

    private var unavailableCard: some View {
        CoverCraftCard(tone: .warning) {
            CoverCraftSectionHeading(
                step: "Unavailable",
                title: "No Pattern Available",
                subtitle: "Generate a pattern first, then return here to export it.",
                statusTitle: "Blocked",
                statusImage: "exclamationmark.triangle.fill",
                tone: .warning
            )
        }
    }

    private func formatDescription(for format: ExportFormat) -> String {
        switch format {
        case .png:
            return "High quality image"
        case .gif:
            return "Web-friendly preview"
        case .svg:
            return "Editable vector"
        case .pdf:
            return "Print-ready document"
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
}
