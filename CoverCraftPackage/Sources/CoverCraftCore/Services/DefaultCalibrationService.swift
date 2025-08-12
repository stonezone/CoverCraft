import Foundation
import simd
import Logging
import CoverCraftDTO

@available(iOS 18.0, macOS 15.0, *)
public final class DefaultCalibrationService: CalibrationService, Sendable {
    
    private let logger = Logger(label: "com.covercraft.calibration")
    
    public init() {
        logger.info("Calibration Service initialized")
    }
    
    public func createCalibration() -> CalibrationDTO {
        return CalibrationDTO.empty()
    }
    
    public func setFirstPoint(_ calibration: CalibrationDTO, point: SIMD3<Float>) -> CalibrationDTO {
        return calibration.settingFirstPoint(point)
    }
    
    public func setSecondPoint(_ calibration: CalibrationDTO, point: SIMD3<Float>) -> CalibrationDTO {
        return calibration.settingSecondPoint(point)
    }
    
    public func setRealWorldDistance(_ calibration: CalibrationDTO, distance: Double) -> CalibrationDTO {
        return calibration.settingRealWorldDistance(distance)
    }
    
    public func validateCalibration(_ calibration: CalibrationDTO) -> Bool {
        return calibration.isComplete
    }
}

// Service Registration
@available(iOS 18.0, macOS 15.0, *)
public extension DefaultDependencyContainer {
    func registerCalibrationServices() {
        let logger = Logger(label: "com.covercraft.calibration-registration")
        logger.info("Registering calibration services")
        registerSingleton({
            DefaultCalibrationService()
        }, for: CalibrationService.self)
        logger.info("Calibration services registration completed")
    }
}