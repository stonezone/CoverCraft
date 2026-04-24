import SwiftUI

@available(iOS 18.0, macOS 15.0, *)
@MainActor
public struct HelpView: View {
    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    introCard
                    stepCard(
                        step: "1",
                        title: "Choose Input",
                        description: "Manual dimensions are faster for rectangular furniture. LiDAR is the better route when you need geometry from a real object.",
                        systemImage: "square.and.pencil",
                        tips: [
                            "Manual dimensions use millimeters.",
                            "Fitted mode requires a LiDAR scan.",
                            "Slipcover mode works with either input path."
                        ],
                        tone: .accent
                    )
                    stepCard(
                        step: "2",
                        title: "Capture or Measure",
                        description: "Scan slowly from multiple angles or enter width, depth, and height directly.",
                        systemImage: "camera.viewfinder",
                        tips: [
                            "Keep the full silhouette in frame while scanning.",
                            "Measure the widest real-world extents for manual mode.",
                            "Cleanup is optional but helps if the scan includes the floor."
                        ],
                        tone: .neutral
                    )
                    stepCard(
                        step: "3",
                        title: "Calibrate and Configure",
                        description: "Scale the mesh from one known reference, then set slipcover or fitted panel options.",
                        systemImage: "ruler",
                        tips: [
                            "Slipcover is the stable path.",
                            "Fitted mode is experimental and can require retries.",
                            "Check ease and seam allowance before generating."
                        ],
                        tone: .warning
                    )
                    stepCard(
                        step: "4",
                        title: "Generate and Export",
                        description: "Generate the panels, review the export preview, and write the output to a file format that fits the next step.",
                        systemImage: "square.and.arrow.up",
                        tips: [
                            "PDF is best for printing.",
                            "SVG is best for editing.",
                            "Exports are written to Documents/CoverCraft Patterns."
                        ],
                        tone: .success
                    )
                    requirementsCard
                    tipsCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .background(CoverCraftScreenBackground().ignoresSafeArea())
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

    private var introCard: some View {
        CoverCraftCard(tone: .accent) {
            CoverCraftSectionHeading(
                step: "Guide",
                title: "How CoverCraft Works",
                subtitle: "The shortest path is manual dimensions plus slipcover. Use LiDAR when you need the object’s real geometry.",
                statusTitle: "4 steps",
                statusImage: "list.number",
                tone: .accent
            )
        }
    }

    private func stepCard(
        step: String,
        title: String,
        description: String,
        systemImage: String,
        tips: [String],
        tone: CoverCraftTone
    ) -> some View {
        CoverCraftCard(tone: tone) {
            CoverCraftSectionHeading(
                step: "Step \(step)",
                title: title,
                subtitle: description,
                statusTitle: title,
                statusImage: systemImage,
                tone: tone
            )

            VStack(alignment: .leading, spacing: 10) {
                ForEach(tips, id: \.self) { tip in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(tone == .warning ? Color.orange : Color.blue)
                            .font(.caption)
                            .padding(.top, 2)

                        Text(tip)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var requirementsCard: some View {
        CoverCraftCard(tone: .neutral) {
            CoverCraftSectionHeading(
                step: "Requirements",
                title: "What You Need",
                subtitle: "Keep the supporting tools minimal and specific.",
                tone: .neutral
            )

            VStack(alignment: .leading, spacing: 10) {
                helpRow(icon: "iphone", text: "LiDAR-capable iPhone or iPad for scan workflows")
                helpRow(icon: "square.3.layers.3d", text: "Manual mode works without a scan")
                helpRow(icon: "ruler", text: "A real measuring tool for calibration or manual entry")
                helpRow(icon: "printer", text: "Printer optional for physical patterns")
            }
        }
    }

    private var tipsCard: some View {
        CoverCraftCard(tone: .success) {
            CoverCraftSectionHeading(
                step: "Tips",
                title: "Keep the Output Usable",
                subtitle: "These are the highest-value checks before fabric is cut.",
                tone: .success
            )

            VStack(alignment: .leading, spacing: 10) {
                helpRow(icon: "shield.checkered", text: "Start with slipcover when reliability matters more than contour detail")
                helpRow(icon: "ruler.fill", text: "Measure the true outer extents of the object, not the average surface")
                helpRow(icon: "doc.text", text: "Export both PDF and SVG if you need a print file plus editable geometry")
                helpRow(icon: "scissors", text: "Print PDFs at 100% scale and verify any reference bar before cutting")
            }
        }
    }

    private func helpRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 20)
                .padding(.top, 2)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
