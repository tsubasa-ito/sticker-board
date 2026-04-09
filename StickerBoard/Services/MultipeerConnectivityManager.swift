import MultipeerConnectivity
import Observation
import os
import UIKit

/// MultipeerConnectivity を使った近距離P2Pシール交換マネージャー (β版)
///
/// MotionManager と同様の参照カウント方式ではなく、View の onAppear/onDisappear で
/// startAdvertising/stopAdvertising を直接呼び出す設計。
@MainActor
@Observable
final class MultipeerConnectivityManager: NSObject {
    static let shared = MultipeerConnectivityManager()
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.tebasaki.StickerBoard",
        category: "MultipeerConnectivityManager"
    )

    /// Bonjour サービスタイプ（project.yml の NSBonjourServices と一致させる）
    nonisolated static let serviceType = "stickerboard"
    /// 受信画像の最大サイズ（10MB）
    nonisolated static let maxImageDataSize = 10 * 1024 * 1024

    private let myPeerId = MCPeerID(displayName: UIDevice.current.name)
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?

    // MARK: - UIバインディング用プロパティ

    private(set) var connectedPeers: [MCPeerID] = []
    private(set) var discoveredPeers: [MCPeerID] = []
    private(set) var isAdvertising = false
    private(set) var isBrowsing = false
    private(set) var receivedStickers: [ReceivedStickerData] = []
    private(set) var pendingInvitation: (peerId: MCPeerID, invitationHandler: (Bool, MCSession?) -> Void)?

    private override init() {
        super.init()
        resetSession()
    }

    // MARK: - セッション管理

    private func resetSession() {
        session?.disconnect()
        let newSession = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .required)
        newSession.delegate = self
        session = newSession
    }

    // MARK: - アドバタイズ（相手から発見される側）

    func startAdvertising() {
        guard advertiser == nil else { return }
        let newAdvertiser = MCNearbyServiceAdvertiser(
            peer: myPeerId,
            discoveryInfo: nil,
            serviceType: Self.serviceType
        )
        newAdvertiser.delegate = self
        newAdvertiser.startAdvertisingPeer()
        advertiser = newAdvertiser
        isAdvertising = true
        Self.logger.info("Advertising 開始: \(self.myPeerId.displayName)")
    }

    func stopAdvertising() {
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        isAdvertising = false
        Self.logger.info("Advertising 停止")
    }

    // MARK: - ブラウズ（相手を探す側）

    func startBrowsing() {
        guard browser == nil else { return }
        let newBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: Self.serviceType)
        newBrowser.delegate = self
        newBrowser.startBrowsingForPeers()
        browser = newBrowser
        isBrowsing = true
        Self.logger.info("Browsing 開始")
    }

    func stopBrowsing() {
        browser?.stopBrowsingForPeers()
        browser = nil
        isBrowsing = false
        discoveredPeers.removeAll()
        Self.logger.info("Browsing 停止")
    }

    // MARK: - 接続操作

    /// 発見済みピアに接続申請を送る
    func invitePeer(_ peerId: MCPeerID) {
        guard let session else { return }
        browser?.invitePeer(peerId, to: session, withContext: nil, timeout: 30)
        Self.logger.info("招待送信: \(peerId.displayName)")
    }

    /// 受信した招待を承諾する
    func acceptPendingInvitation() {
        guard let (_, handler) = pendingInvitation, let session else { return }
        handler(true, session)
        pendingInvitation = nil
    }

    /// 受信した招待を拒否する
    func rejectPendingInvitation() {
        pendingInvitation?.invitationHandler(false, nil)
        pendingInvitation = nil
    }

    /// 全ての接続を切断しセッションをリセット
    func disconnect() {
        stopAdvertising()
        stopBrowsing()
        session?.disconnect()
        connectedPeers.removeAll()
        pendingInvitation = nil
        resetSession()
        Self.logger.info("全接続を切断")
    }

    // MARK: - データ送受信

    /// シール画像データを全接続ピアに送信する
    func sendSticker(imageData: Data) async throws {
        guard let session, !session.connectedPeers.isEmpty else {
            throw MultipeerError.notConnected
        }
        let message = ExchangeMessage(
            senderName: myPeerId.displayName,
            imageData: imageData
        )
        let data = try JSONEncoder().encode(message)
        try session.send(data, toPeers: session.connectedPeers, with: .reliable)
        Self.logger.info("シール送信: \(session.connectedPeers.count)台に送信")
    }

    /// 受信済みシールをリストから削除する
    func dismissReceivedSticker(_ id: UUID) {
        receivedStickers.removeAll { $0.id == id }
    }

    // MARK: - バリデーション

    /// 受信データのサイズ検証（空・超過を弾く）
    nonisolated static func isValidImageData(_ data: Data) -> Bool {
        !data.isEmpty && data.count <= maxImageDataSize
    }
}

// MARK: - MultipeerError

enum MultipeerError: LocalizedError {
    case notConnected
    case invalidData

    var errorDescription: String? {
        switch self {
        case .notConnected: return "デバイスが接続されていません"
        case .invalidData: return "受信データが無効です"
        }
    }
}

// MARK: - MCSessionDelegate

extension MultipeerConnectivityManager: MCSessionDelegate {
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Task { @MainActor in
            switch state {
            case .connected:
                if !connectedPeers.contains(peerID) {
                    connectedPeers.append(peerID)
                }
                discoveredPeers.removeAll { $0 == peerID }
                Self.logger.info("接続完了: \(peerID.displayName)")
            case .notConnected:
                connectedPeers.removeAll { $0 == peerID }
                Self.logger.info("切断: \(peerID.displayName)")
            case .connecting:
                Self.logger.info("接続中: \(peerID.displayName)")
            @unknown default:
                break
            }
        }
    }

    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        Task { @MainActor in
            guard MultipeerConnectivityManager.isValidImageData(data) else {
                Self.logger.warning("受信データが無効: \(data.count) bytes")
                return
            }
            guard let message = try? JSONDecoder().decode(ExchangeMessage.self, from: data) else {
                Self.logger.error("デコード失敗: \(data.count) bytes")
                return
            }
            guard MultipeerConnectivityManager.isValidImageData(message.imageData) else {
                Self.logger.warning("受信画像データが無効: \(message.imageData.count) bytes")
                return
            }
            let received = ReceivedStickerData(
                senderName: message.senderName,
                imageData: message.imageData
            )
            receivedStickers.append(received)
            Self.logger.info("シール受信: \(peerID.displayName) から")
        }
    }

    nonisolated func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension MultipeerConnectivityManager: MCNearbyServiceAdvertiserDelegate {
    nonisolated func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        Task { @MainActor in
            pendingInvitation = (peerId: peerID, invitationHandler: invitationHandler)
            Self.logger.info("招待受信: \(peerID.displayName)")
        }
    }

    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        Task { @MainActor in
            Self.logger.error("Advertising 失敗: \(error.localizedDescription)")
            isAdvertising = false
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension MultipeerConnectivityManager: MCNearbyServiceBrowserDelegate {
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        Task { @MainActor in
            guard !discoveredPeers.contains(peerID), !connectedPeers.contains(peerID) else { return }
            discoveredPeers.append(peerID)
            Self.logger.info("Peer 発見: \(peerID.displayName)")
        }
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        Task { @MainActor in
            discoveredPeers.removeAll { $0 == peerID }
            Self.logger.info("Peer 消失: \(peerID.displayName)")
        }
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        Task { @MainActor in
            Self.logger.error("Browsing 失敗: \(error.localizedDescription)")
            isBrowsing = false
        }
    }
}
