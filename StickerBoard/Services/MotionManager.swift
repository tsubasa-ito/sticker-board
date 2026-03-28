import CoreMotion
import Observation
import UIKit

/// デバイスの傾きを検知してホログラフィック効果に利用するマネージャー
/// 参照カウント方式: start() と同数の stop() を呼ぶ必要がある。
/// シミュレータではフォールバックとして自動アニメーションを使用する。
@MainActor
@Observable
final class MotionManager {
    static let shared = MotionManager()

    private let motionManager = CMMotionManager()
    private var referenceCount = 0
    private var wasPausedInBackground = false

    /// デバイスの傾き（実機: 0.0〜1.0に正規化、シミュレータ: 自動アニメーション。中央が0.5）
    private(set) var tiltX: Double = 0.5
    /// デバイスの傾き（実機: 0.0〜1.0に正規化、シミュレータ: 自動アニメーション。中央が0.5）
    private(set) var tiltY: Double = 0.5

    #if targetEnvironment(simulator)
    private var simulatorTimer: Timer?
    private var phase: Double = 0
    #endif

    private init() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.pauseIfActive() }
        }
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.resumeIfNeeded() }
        }
    }

    /// モーション検知を開始する（参照カウント方式: start() と同数の stop() を呼ぶ必要がある）
    func start() {
        referenceCount += 1
        guard referenceCount == 1 else { return }
        beginUpdates()
    }

    /// モーション検知を停止する（参照カウントが0になった時点で実際に停止し、傾きを中央にリセット）
    func stop() {
        guard referenceCount > 0 else { return }
        referenceCount -= 1
        guard referenceCount == 0 else { return }
        endUpdates()
    }

    // MARK: - アプリライフサイクル

    private func pauseIfActive() {
        guard referenceCount > 0 else { return }
        wasPausedInBackground = true
        endUpdates()
    }

    private func resumeIfNeeded() {
        guard wasPausedInBackground else { return }
        wasPausedInBackground = false
        beginUpdates()
    }

    private func beginUpdates() {
        #if targetEnvironment(simulator)
        startSimulator()
        #else
        startDevice()
        #endif
    }

    private func endUpdates() {
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
        guard motionManager.isDeviceMotionAvailable else {
            print("[MotionManager] デバイスモーション非対応 — エフェクトは静止状態で表示")
            return
        }
        motionManager.deviceMotionUpdateInterval = 1.0 / 30.0
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            Task { @MainActor in
                guard let self else { return }
                if let error {
                    print("[MotionManager] モーション更新エラー: \(error.localizedDescription)")
                    self.tiltX = 0.5
                    self.tiltY = 0.5
                    return
                }
                guard let motion else { return }
                let roll = motion.attitude.roll
                let pitch = motion.attitude.pitch
                let maxAngle = Double.pi / 4
                let newX = max(0, min(1, 0.5 + (roll / maxAngle) * 0.5))
                // pi/6 オフセット: ユーザーの自然な持ち方（約30度傾斜）を中央値とする
                let newY = max(0, min(1, 0.5 + ((pitch - Double.pi / 6) / maxAngle) * 0.5))
                // しきい値(≒角度0.1°相当)を超えた場合のみ更新（微小な揺れでSwiftUI再描画を防ぐ）
                if abs(newX - self.tiltX) > 0.003 || abs(newY - self.tiltY) > 0.003 {
                    self.tiltX = newX
                    self.tiltY = newY
                }
            }
        }
    }
    #endif

    // MARK: - シミュレータ: 自動アニメーション

    #if targetEnvironment(simulator)
    private func startSimulator() {
        simulatorTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.phase += 0.015
                self.tiltX = 0.5 + sin(self.phase) * 0.35
                self.tiltY = 0.5 + cos(self.phase * 0.7) * 0.35
            }
        }
    }
    #endif
}
