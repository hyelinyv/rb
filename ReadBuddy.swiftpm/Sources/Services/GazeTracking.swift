import Foundation
import CoreGraphics
import Combine
import ARKit
import AVFoundation
import simd

struct GazeSample {
    let normalizedPoint: CGPoint
    let timestamp: TimeInterval
    let isReliable: Bool
}

enum GazeTrackingStatus: Equatable {
    case idle
    case requestingPermission
    case tracking
    case limited(String)
    case unavailable(String)

    var label: String {
        switch self {
        case .idle: return "尚未启动"
        case .requestingPermission: return "等待相机授权"
        case .tracking: return "追踪中"
        case .limited(let reason): return "受限：\(reason)"
        case .unavailable(let reason): return "不可用：\(reason)"
        }
    }
}

protocol GazeTrackingService: AnyObject {
    var isSupported: Bool { get }
    var sampleHandler: ((GazeSample) -> Void)? { get set }
    var statusHandler: ((GazeTrackingStatus) -> Void)? { get set }
    func start()
    func stop()
    func setCalibrationOffset(_ offset: CGPoint)
}

final class ARKitGazeTracker: NSObject, GazeTrackingService, ARSessionDelegate {
    let session = ARSession()
    var sampleHandler: ((GazeSample) -> Void)?
    var statusHandler: ((GazeTrackingStatus) -> Void)?
    private var calibrationOffset: CGPoint = .zero
    private var smoothedPoint = CGPoint(x: 0.5, y: 0.5)

    var isSupported: Bool {
        ARFaceTrackingConfiguration.isSupported
    }

    override init() {
        super.init()
        session.delegate = self
    }

    func start() {
        guard isSupported else {
            statusHandler?(.unavailable("此设备不支持 ARKit 前摄人脸追踪"))
            return
        }
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = false
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        statusHandler?(.tracking)
    }

    func stop() {
        session.pause()
        statusHandler?(.idle)
    }

    func setCalibrationOffset(_ offset: CGPoint) {
        calibrationOffset = offset
    }

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard let face = anchors.compactMap({ $0 as? ARFaceAnchor }).first else { return }

        // ARFaceAnchor.lookAtPoint is expressed in face coordinates. Projecting the
        // x/y direction provides a light-weight paragraph-level estimate. Five-point
        // calibration compensates for device angle and how the user holds the iPad.
        let look = face.lookAtPoint
        let depth = max(abs(CGFloat(look.z)), 0.08)
        let rawX = 0.5 + (CGFloat(look.x) / depth) * 0.62
        let rawY = 0.5 - (CGFloat(look.y) / depth) * 0.62
        let corrected = CGPoint(
            x: min(max(rawX + calibrationOffset.x, -0.15), 1.15),
            y: min(max(rawY + calibrationOffset.y, -0.15), 1.15)
        )
        let alpha: CGFloat = 0.18
        smoothedPoint = CGPoint(
            x: smoothedPoint.x + (corrected.x - smoothedPoint.x) * alpha,
            y: smoothedPoint.y + (corrected.y - smoothedPoint.y) * alpha
        )

        let sample = GazeSample(
            normalizedPoint: smoothedPoint,
            timestamp: session.currentFrame?.timestamp ?? ProcessInfo.processInfo.systemUptime,
            isReliable: face.isTracked
        )
        DispatchQueue.main.async { [weak self] in
            self?.sampleHandler?(sample)
        }
    }

    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        let newStatus: GazeTrackingStatus
        switch camera.trackingState {
        case .normal:
            newStatus = .tracking
        case .notAvailable:
            newStatus = .limited("相机追踪暂不可用")
        case .limited(let reason):
            newStatus = .limited(reason.readBuddyDescription)
        }
        DispatchQueue.main.async { [weak self] in
            self?.statusHandler?(newStatus)
        }
    }

    func session(_ session: ARSession, didFailWithError error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.statusHandler?(.unavailable(error.localizedDescription))
        }
    }
}

private extension ARCamera.TrackingState.Reason {
    var readBuddyDescription: String {
        switch self {
        case .initializing: return "正在初始化"
        case .excessiveMotion: return "设备移动过快"
        case .insufficientFeatures: return "面部特征不足或光线较暗"
        case .relocalizing: return "正在重新定位"
        @unknown default: return "追踪质量较低"
        }
    }
}

final class SimulatedGazeTracker: GazeTrackingService {
    var sampleHandler: ((GazeSample) -> Void)?
    var statusHandler: ((GazeTrackingStatus) -> Void)?
    private var timer: Timer?
    private var calibrationOffset: CGPoint = .zero
    private(set) var isDrifting = false
    let isSupported = true

    func start() {
        stopTimer()
        statusHandler?(.tracking)
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self else { return }
            let base = self.isDrifting ? CGPoint(x: -0.12, y: 0.5) : CGPoint(x: 0.5, y: 0.46)
            self.sampleHandler?(
                GazeSample(
                    normalizedPoint: CGPoint(
                        x: base.x + self.calibrationOffset.x,
                        y: base.y + self.calibrationOffset.y
                    ),
                    timestamp: ProcessInfo.processInfo.systemUptime,
                    isReliable: true
                )
            )
        }
    }

    func stop() {
        stopTimer()
        statusHandler?(.idle)
    }

    func setCalibrationOffset(_ offset: CGPoint) {
        calibrationOffset = offset
    }

    func toggleDrift() {
        isDrifting.toggle()
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

@MainActor
final class GazeTrackingCoordinator: ObservableObject {
    @Published private(set) var sample = GazeSample(
        normalizedPoint: CGPoint(x: 0.5, y: 0.5),
        timestamp: 0,
        isReliable: false
    )
    @Published private(set) var status: GazeTrackingStatus = .idle
    @Published private(set) var isUsingSimulation = false
    @Published private(set) var calibrationOffset: CGPoint = .zero

    private let arTracker = ARKitGazeTracker()
    private let simulatedTracker = SimulatedGazeTracker()
    private var activeService: GazeTrackingService?

    init() {
        bind(arTracker)
        bind(simulatedTracker)
    }

    var hardwareSupportsFaceTracking: Bool {
        arTracker.isSupported
    }

    func start() {
        guard arTracker.isSupported else {
            activateSimulation(reason: "设备不支持 ARKit 前摄追踪，已进入模拟模式")
            return
        }

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            activate(arTracker, simulation: false)
        case .notDetermined:
            status = .requestingPermission
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                Task { @MainActor in
                    guard let self else { return }
                    if granted {
                        self.activate(self.arTracker, simulation: false)
                    } else {
                        self.activateSimulation(reason: "相机权限被拒绝，已进入模拟模式")
                    }
                }
            }
        case .denied, .restricted:
            activateSimulation(reason: "相机权限不可用，已进入模拟模式")
        @unknown default:
            activateSimulation(reason: "无法确认相机权限，已进入模拟模式")
        }
    }

    func stop() {
        activeService?.stop()
        activeService = nil
    }

    func useSimulation() {
        activateSimulation(reason: "手动启用模拟模式")
    }

    func toggleSimulatedDrift() {
        guard isUsingSimulation else { return }
        simulatedTracker.toggleDrift()
    }

    func applyCalibration(expectedPoints: [CGPoint], samples: [CGPoint]) {
        guard expectedPoints.count == samples.count, !samples.isEmpty else { return }
        let total = zip(expectedPoints, samples).reduce(CGPoint.zero) { partial, pair in
            CGPoint(
                x: partial.x + pair.0.x - pair.1.x,
                y: partial.y + pair.0.y - pair.1.y
            )
        }
        let offset = CGPoint(
            x: total.x / CGFloat(samples.count),
            y: total.y / CGFloat(samples.count)
        )
        calibrationOffset = offset
        activeService?.setCalibrationOffset(offset)
    }

    func resetCalibration() {
        calibrationOffset = .zero
        activeService?.setCalibrationOffset(.zero)
    }

    private func activateSimulation(reason: String) {
        activate(simulatedTracker, simulation: true)
        status = .limited(reason)
    }

    private func activate(_ service: GazeTrackingService, simulation: Bool) {
        activeService?.stop()
        activeService = service
        isUsingSimulation = simulation
        service.setCalibrationOffset(calibrationOffset)
        service.start()
    }

    private func bind(_ service: GazeTrackingService) {
        service.sampleHandler = { [weak self] sample in
            Task { @MainActor in self?.sample = sample }
        }
        service.statusHandler = { [weak self] status in
            Task { @MainActor in
                guard let self else { return }
                if ObjectIdentifier(service) == ObjectIdentifier(self.arTracker),
                   case .unavailable(let reason) = status {
                    self.activateSimulation(reason: "ARKit 启动失败（\(reason)），已进入模拟模式")
                } else {
                    self.status = status
                }
            }
        }
    }
}
