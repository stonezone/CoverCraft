import SwiftUI

@MainActor
public struct ExportView: View {
    let flattenedPanels: [FlattenedPanel]?
    
    @State private var selectedFormat = ExportFormat.png
    @State private var isExporting = false
    @State private var exportMessage: String?
    
    public init(flattenedPanels: [FlattenedPanel]?) {
        self.flattenedPanels = flattenedPanels
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            Text("Export Pattern")
                .font(.largeTitle)
                .bold()
            
            Text("Export your sewing pattern in various formats.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
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
                                    .fill(Color(uiColor: panel.sourcePanel.color))
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
                        .foregroundColor(.green)
                        .padding(.horizontal)
                }
                
                // Pattern details
                VStack(alignment: .leading, spacing: 8) {
                    Text("Pattern Details:")
                        .font(.headline)
                    
                    ForEach(Array(panels.enumerated()), id: \.offset) { index, panel in
                        HStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(uiColor: panel.sourcePanel.color))
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
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func formatDescription(for format: ExportFormat) -> String {
        switch format {
        case .png:
            return "High quality image"
        case .gif:
            return "Web-friendly"
        case .svg:
            return "Scalable vector"
        case .pdfLetter:
            return "US Letter size"
        case .pdfA4:
            return "A4 size"
        }
    }
    
    private func exportPattern() {
        guard let panels = flattenedPanels else { return    }
}
}