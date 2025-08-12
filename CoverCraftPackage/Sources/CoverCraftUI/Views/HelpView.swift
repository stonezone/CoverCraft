import SwiftUI

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
                        
                        Text("Create custom sewing patterns from 3D scans")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Step 1
                    helpStep(
                        number: "1",
                        title: "Scan Object",
                        description: "Use your iPhone's LiDAR sensor to scan the object you want to create a cover for. Move slowly around the object for best results.",
                        systemImage: "camera.viewfinder",
                        tips: [
                            "Ensure good lighting",
                            "Move slowly and steadily",
                            "Capture all sides of the object",
                            "Works best with objects 0.5m - 5m in size"
                        ]
                    )
                    
                    Divider()
                    
                    // Step 2
                    helpStep(
                        number: "2",
                        title: "Set Scale",
                        description: "Calibrate the real-world scale by selecting two points on the mesh and entering the actual distance between them.",
                        systemImage: "ruler",
                        tips: [
                            "Choose two easily identifiable points",
                            "Measure the distance accurately",
                            "Use meters as the unit",
                            "This ensures your pattern is the correct size"
                        ]
                    )
                    
                    Divider()
                    
                    // Step 3
                    helpStep(
                        number: "3",
                        title: "Configure Panels",
                        description: "Choose the resolution for your sewing pattern. Higher resolution creates more panels for better fit but increases complexity.",
                        systemImage: "square.grid.3x3",
                        tips: [
                            "Low (5 panels): Simple shapes",
                            "Medium (8 panels): Most objects",
                            "High (15 panels): Complex shapes",
                            "Preview before generating"
                        ]
                    )
                    
                    Divider()
                    
                    // Step 4
                    helpStep(
                        number: "4",
                        title: "Export Pattern",
                        description: "Generate and export your sewing pattern in various formats including PDF, PNG, or SVG.",
                        systemImage: "square.and.arrow.up",
                        tips: [
                            "PDF formats include crop marks",
                            "Print at 100% scale",
                            "SVG files are scalable",
                            "PNG files are high resolution"
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
                                text: "iPhone with LiDAR sensor (iPhone 12 Pro or later)"
                            )
                            
                            requirementRow(
                                icon: "light.max",
                                text: "Good lighting conditions"
                            )
                            
                            requirementRow(
                                icon: "ruler",
                                text: "Ability to measure reference distances"
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
                                title: "Best Scanning Practice",
                                description: "Scan in a well-lit environment and move slowly around the object in a spiral pattern."
                            )
                            
                            tipRow(
                                icon: "ruler.fill",
                                title: "Accurate Calibration",
                                description: "Use a ruler or measuring tape to get precise measurements for calibration."
                            )
                            
                            tipRow(
                                icon: "scissors",
                                title: "Pattern Assembly",
                                description: "Cut out each panel and add seam allowances when sewing your cover."
                            )
                            
                            tipRow(
                                icon: "doc.text",
                                title: "Save Your Work",
                                description: "Export patterns in multiple formats to ensure you always have a backup."
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