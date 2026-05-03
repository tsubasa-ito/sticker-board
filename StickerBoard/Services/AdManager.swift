import AppTrackingTransparency
import GoogleMobileAds
import OSLog
import UIKit

// MARK: - AdManager

/// 広告表示を一元管理するシングルトン。Pro ユーザーには一切広告を表示しない。
@Observable
@MainActor
final class AdManager {
    static let shared: AdManager = {
        let manager = AdManager()
        manager.setupDelegates()
        return manager
    }()

    /// グリッドに挿入するネイティブ広告（ロード完了後に非 nil になる）
    private(set) var nativeAd: GADNativeAd?

    @ObservationIgnored private var interstitialAd: GADInterstitialAd?
    @ObservationIgnored private var adLoader: GADAdLoader?
    @ObservationIgnored private var exportActionCount = 0
    @ObservationIgnored private var interstitialDelegate: AdInterstitialDelegate!
    @ObservationIgnored private var nativeAdDelegate: AdNativeDelegate!

    private static let showInterval = 3
    private let logger = Logger(subsystem: "com.tebasaki.StickerBoard", category: "AdManager")

    private init() {}

    private func setupDelegates() {
        interstitialDelegate = AdInterstitialDelegate { [weak self] in
            self?.preloadInterstitial()
        }
        nativeAdDelegate = AdNativeDelegate(
            onReceive: { [weak self] ad in
                self?.logger.info("Native ad received: \(ad.headline ?? "-")")
                self?.nativeAd = ad
            },
            onError: { [weak self] error in
                self?.logger.error("Native ad load failed: \(error)")
            }
        )
    }

    // MARK: - Public API

    func preloadAll() {
        let isPro = SubscriptionManager.shared.isProUser
        logger.info("preloadAll: called, isProUser=\(isPro)")
        guard !isPro else {
            logger.info("preloadAll: skipped (Pro user)")
            return
        }
        // ATT 許可が確定してから SDK を初期化することで IDFA を適切に取得する
        GADMobileAds.sharedInstance().start()
        preloadInterstitial()
        preloadNativeAd()
    }

    /// ATT 許可ダイアログを初回のみ表示する（オンボーディング完了後に呼ぶ）
    func requestTrackingPermissionIfNeeded() async {
        let key = "hasRequestedATT"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.set(true, forKey: key)
        _ = await ATTrackingManager.requestTrackingAuthorization()
    }

    /// エクスポート or 写真保存が 1 回完了するたびに呼ぶ。
    /// 累計 showInterval 回ごとにインタースティシャルを表示する。
    func recordExportAndShowIfNeeded() {
        guard !SubscriptionManager.shared.isProUser else { return }
        exportActionCount += 1
        guard exportActionCount % Self.showInterval == 0 else { return }
        showInterstitial()
    }

    // MARK: - Preload

    func preloadInterstitial() {
        guard !SubscriptionManager.shared.isProUser else { return }
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let ad = try await GADInterstitialAd.load(
                    withAdUnitID: AdUnitID.interstitial,
                    request: GADRequest()
                )
                ad.fullScreenContentDelegate = self.interstitialDelegate
                self.interstitialAd = ad
            } catch {
                self.logger.error("Interstitial load failed: \(error)")
            }
        }
    }

    func preloadNativeAd() {
        guard !SubscriptionManager.shared.isProUser else { return }
        logger.info("preloadNativeAd called")
        adLoader = GADAdLoader(
            adUnitID: AdUnitID.native,
            rootViewController: nil,
            adTypes: [.native],
            options: nil
        )
        adLoader?.delegate = nativeAdDelegate
        adLoader?.load(GADRequest())
    }

    // MARK: - Private

    private func showInterstitial() {
        guard let ad = interstitialAd,
              let scene = UIApplication.shared.connectedScenes
                  .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let rootVC = scene.keyWindow?.rootViewController
        else { return }
        var topVC = rootVC
        while let presented = topVC.presentedViewController { topVC = presented }
        ad.present(fromRootViewController: topVC)
        interstitialAd = nil
    }
}

// MARK: - Ad Unit IDs

private extension AdManager {
    enum AdUnitID {
        static let interstitial = "ca-app-pub-3940256099942544/4411468910"  // TODO: 本番インタースティシャルIDに差し替えること
        static let native = "ca-app-pub-6267199278067658/3000803125"
    }
}

// MARK: - Delegate Helpers

private final class AdInterstitialDelegate: NSObject, GADFullScreenContentDelegate, @unchecked Sendable {
    private let onDismiss: () -> Void
    init(onDismiss: @escaping () -> Void) { self.onDismiss = onDismiss }

    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        Task { @MainActor in self.onDismiss() }
    }
}

private final class AdNativeDelegate: NSObject, GADNativeAdLoaderDelegate, @unchecked Sendable {
    private let onReceive: (GADNativeAd) -> Void
    private let onError: (Error) -> Void

    init(onReceive: @escaping (GADNativeAd) -> Void, onError: @escaping (Error) -> Void) {
        self.onReceive = onReceive
        self.onError = onError
    }

    func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADNativeAd) {
        Task { @MainActor in self.onReceive(nativeAd) }
    }

    func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: Error) {
        Task { @MainActor in self.onError(error) }
    }
}
