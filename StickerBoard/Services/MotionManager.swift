import CoreMotion
import Observation

/// デバイスの傾きを検知してホログラフィック効果に利用するマネージャー
@MainActor
@Observable
final class MotionManager {
    static let shared = MotionManager()

    private let motionManager = CMMotionManager()
    private var referenceCount = 0

    /// デバイスの傾き位置（0.0〜1.0、中央が0.5）
    private(set) var tiltX: Double = 0.5
    private(set) var tiltY: Double = 0.5

    #if targetEnvironment(simulator)
    private var simulatorTimer: Timer?
    private var phase: Double = 0
    #endif

    private init() {}

    func start() {
        referenceCount += 1
        guard referenceCount == 1 else { return }
        #if targetEnvironment(simulator)
        startSimulator()
        #else
        startDevice()
        #endif
    }

    func stop() {
        referenceCount -= 1
        guard referenceCount <= 0 else { return }
        referenceCount = 0
        #if targetEnvironment(simulator)
        simulatorTimer?.invalidate()
        simulatorTimer = nil
        #else
        motionManager.stopDeviceMotionUpdates()
        #endif
        tiltX = 0.5
        tiltY = 0.5
    }

    // MARK: - 実機: デバイスモーション

    #if !targetEnvironment(simulator)
    private func startDevice() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 1.0 / 30.0
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            let roll = motion.attitude.roll
            let pitch = motion.attitude.pitch
            let maxAngle = Double.pi / 4
            let newX = max(0, min(1, 0.5 + (roll / maxAngle) * 0.5))
            let newY = max(0, min(1, 0.5 + ((pitch - Double.pi / 6) / maxAngle) * 0.5))
            // しきい値を超えた場合のみ更新（パフォーマンス最適化）
            if abs(newX - self.tiltX) > 0.003 || abs(newY - self.tiltY) > 0.003 {
                self.tiltX = newX
                self.tiltY = newY
            }
        }
    }
    #endif

    // MARK: - シミュレータ: 自動アニメーション

    #if targetEnvironment(simulator)
    private func startSimulator() {
        simulatorTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.phase += 0.015
            self.tiltX = 0.5 + sin(self.phase) * 0.35
            self.tiltY = 0.5 + cos(self.phase * 0.7) * 0.35
        }
    }
    #endif
}
