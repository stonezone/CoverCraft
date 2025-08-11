import SwiftUI
import simd

#if canImport(UIKit)
import UIKit
#endif

@MainActor
public struct CalibrationView: View {
    let mesh: Mesh?
    let calibrationData: CalibrationData
    
    @State private var realWorldDistanceText: String = "1.0"
    @State private var selectedPoints: [SIMD3<Float>] = []
    
    public init(mesh: Mesh?, calibrationData: CalibrationData) {
        self.mesh = mesh
        self.calibrationData = calibrationData
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            Text("Calibration")
                .font(.largeTitle)
                .bold()
            
            Text("Select two points on the mesh and enter the real-world distance between them.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if let mesh = mesh {
                // Simple mesh visualization (placeholder)
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.gray.opacity(0.2))
                        .frame(height: 300)
                    
                    VStack {
                        Image(systemName: "cube.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("\(mesh.vertices.count) vertices")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                
                // Point selection status
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: calibrationData.firstPoint != nil ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(calibrationData.firstPoint != nil ? .green : .gray)
                        Text("First point selected")
                    }
                    
                    HStack {
                        Image(systemName: calibrationData.secondPoint != nil ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(calibrationData.secondPoint != nil ? .green : .gray)
                        Text("Second point selected")
                    }
                }
                .padding(.horizontal)
                
                // Distance input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Real-world distance (meters):")
                        .font(.headline)
                    
                    TextField("Distance in meters", text: $realWorldDistanceText)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.decimalPad)
                        .onChange(of: realWorldDistanceText) { _, newValue in
                            if let distance = Float(newValue), distance > 0 {
                                calibrationData.realWorldDistance = distance
                            }
                        }
                }
                .padding(.horizontal)
                
                if calibrationData.isComplete {
                    VStack {
                        Text("Calibration Complete!")
                            .font(.headline)
                            .foregroundColor(.green)
                        
                        Text("Scale factor: \(String(format: "%.3f", calibrationData.scaleFactor))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(.green.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
            } else {
                Text("No mesh available for calibration")
                    .foregroundColor(.secondary)
                    .italic()
            }
            
            Spacer()
            
            // Reset button
            Button("Reset Calibration") {
                calibrationData.reset()
                realWorldDistanceText = "1.0"
            }
            .buttonStyle(.bordered)
            .disabled(mesh == nil)
        }
        .padding()
        .navigationTitle("Calibration")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            realWorldDistanceText = String(calibrationData.realWorldDistance)
            
            // Simulate point selection for demo purposes
            if let mesh = mesh, calibrationData.firstPoint == nil {
                if mesh.vertices.count >= 2 {
                    calibrationData.firstPoint = mesh.vertices[0]
                    calibrationData.secondPoint = mesh.vertices[min(1, mesh.vertices.count - 1)]
                }
            }
        }
    }
}