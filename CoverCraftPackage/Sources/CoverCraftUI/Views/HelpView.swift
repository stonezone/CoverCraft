import SwiftUI

@available(iOS 18.0, macOS 15.0, *)
@MainActor
public struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How to Use CoverCraft")
                            .font(.largeTitle)
                            .bold()
                        
                        Text("Generate slipcover or fitted sewing patterns from a LiDAR scan or manual dimensions.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Step 1
                    helpStep(
                        number: "1",
                        title: "Choose Input",
                        description: "Use Manual Dimensions for rectangular furniture when you already know width, depth, and height. Use LiDAR Scan when you need scan-derived geometry.",
                        systemImage: "camera.viewfinder",
                        tips: [
                            "Manual Dimensions is the fastest path for slipcover patterns",
                            "Fitted mode requires a LiDAR scan",
                            "Dimensions are entered in millimeters"
                        ]
                    )
                    
                    Divider()
                    
                    // Step 2
                    helpStep(
                        number: "2",
                        title: "Capture or Enter Dimensions",
                        description: "For scan mode, capture the object from multiple angles and calibrate the mesh. For manual mode, enter width, depth, and height directly.",
                        systemImage: "ruler",
                        tips: [
                            "Move slowly and keep the full silhouette in frame",
                            "Use two clear points when calibrating a scan",
                            "Manual mode skips calibration entirely",
                            "Measure the widest real-world dimensions"
                        ]
                    )
                    
                    Divider()
                    
                    // Step 3
                    helpStep(
                        number: "3",
                        title: "Choose Pattern Type",
                        description: "Slipcover mode is the stable path for boxy covers. Fitted mode uses experimental segmentation and may require retries.",
                        systemImage: "square.grid.3x3",
                        tips: [
                            "Slipcover patterns are bottom-open and gravity-based",
                            "Fitted mode is still experimental",
                            "Higher fitted resolution creates more panels",
                            "Check ease and seam allowance before generating"
                        ]
                    )
                    
                    Divider()
                    
                    // Step 4
                    helpStep(
                        number: "4",
                        title: "Generate and Export",
                        description: "Generate the pattern, review the export screen, and save it as PDF, SVG, or PNG.",
                        systemImage: "square.and.arrow.up",
                        tips: [
                            "Exports are saved in Documents/CoverCraft Patterns",
                            "PDF is best for printing at full scale",
                            "SVG is best for downstream editing",
                            "PNG is best for quick previews"
                        ]
                    )
                    
                    Divider()
                    
                    // Requirements
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Requirements")
                            .font(.title2)
                            .bold()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            requirementRow(
                                icon: "iphone",
                                text: "LiDAR-capable iPhone or iPad only for scan workflows"
                            )
                            
                            requirementRow(
                                icon: "square.3.layers.3d",
                                text: "Manual mode works without a scan"
                            )
                            
                            requirementRow(
                                icon: "ruler",
                                text: "Tape measure or ruler for manual entry or scan calibration"
                            )
                            
                            requirementRow(
                                icon: "printer",
                                text: "Printer for physical patterns (optional)"
                            )
                        }
                    }
                    
                    Divider()
                    
                    // Tips
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Pro Tips")
                            .font(.title2)
                            .bold()
                        
                        VStack(alignment: .leading, spacing: 12) {
                            tipRow(
                                icon: "lightbulb",
                                title: "Start With Slipcover",
                                description: "Use slipcover mode first when you need a reliable pattern path."
                            )
                            
                            tipRow(
                                icon: "ruler.fill",
                                title: "Measure Real Extents",
                                description: "Manual mode works best when width, depth, and height reflect the outermost points of the object."
                            )
                            
                            tipRow(
                                icon: "scissors",
                                title: "Check Export Scale",
                                description: "Print PDF exports at 100% and verify the calibration bar before cutting fabric."
                            )
                            
                            tipRow(
                                icon: "doc.text",
                                title: "Keep Exports",
                                description: "Export to PDF and SVG if you want both print-ready output and editable geometry."
                            )
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Help")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func helpStep(number: String, title: String, description: String, systemImage: String, tips: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(.blue)
                        .frame(width: 32, height: 32)
                    
                    Text(number)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(tips, id: \.self) { tip in
                    HStack(alignment: .top) {
                        Text("•")
                            .foregroundColor(.blue)
                            .fontWeight(.bold)
                        Text(tip)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
            .padding(.leading, 40)
        }
    }
    
    private func requirementRow(icon: String, text: String) -> some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundColor(.blue)
            Text(text)
                .font(.subheadline)
            Spacer()
        }
    }
    
    private func tipRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top) {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundColor(.orange)
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}
