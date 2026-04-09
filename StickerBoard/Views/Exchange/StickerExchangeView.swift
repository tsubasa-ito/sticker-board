import MultipeerConnectivity
import SwiftData
import SwiftUI

/// 近距離デバイス間でシールを交換するβ版ビュー
struct StickerExchangeView: View {
    @State private var manager = MultipeerConnectivityManager.shared
    @State private var showStickerPicker = false
    @State private var showReceivedSheet = false
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            AppTheme.backgroundPrimary.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    betaBanner
                    statusSection

                    if !manager.discoveredPeers.isEmpty {
                        discoveredPeersSection
                    }

                    if !manager.connectedPeers.isEmpty {
                        connectedPeersSection
                    }

                    howToUseSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("シール交換")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            manager.startAdvertising()
            manager.startBrowsing()
        }
        .onDisappear {
            manager.stopAdvertising()
            manager.stopBrowsing()
        }
        // 招待アラート
        .alert("交換申請", isPresented: Binding(
            get: { manager.pendingInvitation != nil },
            set: { if !$0 { manager.rejectPendingInvitation() } }
        )) {
            Button("承諾") { manager.acceptPendingInvitation() }
            Button("拒否", role: .destructive) { manager.rejectPendingInvitation() }
        } message: {
            if let invitation = manager.pendingInvitation {
                Text("\(invitation.peerId.displayName) からシール交換の申請が届きました")
            }
        }
        .sheet(isPresented: $showStickerPicker) {
            ExchangeStickerPickerView(manager: manager, isPresented: $showStickerPicker)
        }
        .onChange(of: manager.receivedStickers.count) { _, count in
            if count > 0 { showReceivedSheet = true }
        }
        .sheet(isPresented: $showReceivedSheet) {
            ReceivedStickerSheet(manager: manager, modelContext: modelContext)
        }
    }

    // MARK: - βバナー

    private var betaBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "testtube.2")
                .foregroundStyle(AppTheme.accent)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("β版機能")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.accent)
                Text("この機能は試験的に提供しています。仕様が変更される場合があります。")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(AppTheme.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - 接続状態セクション

    private var statusSection: some View {
        VStack(spacing: 0) {
            sectionHeader(title: "接続状態", icon: "antenna.radiowaves.left.and.right")

            VStack(spacing: 0) {
                statusRow(icon: "dot.radiowaves.up.forward", title: "アドバタイズ（発見待機中）", isActive: manager.isAdvertising)
                Divider().padding(.horizontal, 16)
                statusRow(icon: "magnifyingglass", title: "デバイスを検索中", isActive: manager.isBrowsing)
            }
            .stickerCard()
        }
    }

    private func statusRow(icon: String, title: String, isActive: Bool) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(isActive ? AppTheme.accent : AppTheme.textTertiary)
                .frame(width: 24)
                .accessibilityHidden(true)
            Text(title)
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
            Spacer()
            Circle()
                .fill(isActive ? Color.green : AppTheme.textTertiary)
                .frame(width: 8, height: 8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(isActive ? "アクティブ" : "停止中")")
    }

    // MARK: - 発見済みデバイスセクション

    private var discoveredPeersSection: some View {
        VStack(spacing: 0) {
            sectionHeader(title: "近くのデバイス", icon: "iphone.radiowaves.left.and.right")

            VStack(spacing: 0) {
                ForEach(manager.discoveredPeers, id: \.displayName) { peer in
                    peerRow(peer: peer, isConnected: false)
                    if peer.displayName != manager.discoveredPeers.last?.displayName {
                        Divider().padding(.horizontal, 16)
                    }
                }
            }
            .stickerCard()
        }
    }

    // MARK: - 接続済みデバイスセクション

    private var connectedPeersSection: some View {
        VStack(spacing: 16) {
            VStack(spacing: 0) {
                sectionHeader(title: "接続中のデバイス", icon: "checkmark.circle.fill")

                VStack(spacing: 0) {
                    ForEach(manager.connectedPeers, id: \.displayName) { peer in
                        peerRow(peer: peer, isConnected: true)
                        if peer.displayName != manager.connectedPeers.last?.displayName {
                            Divider().padding(.horizontal, 16)
                        }
                    }
                }
                .stickerCard()
            }

            Button {
                showStickerPicker = true
            } label: {
                HStack {
                    Image(systemName: "seal")
                        .font(.system(size: 16, weight: .semibold))
                    Text("シールを送る")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 16))
                .shadow(color: AppTheme.accent.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .accessibilityLabel("シールを選んで送る")
        }
    }

    private func peerRow(peer: MCPeerID, isConnected: Bool) -> some View {
        HStack {
            Image(systemName: isConnected ? "iphone.gen3" : "iphone.gen3.badge.questionmark")
                .font(.system(size: 20))
                .foregroundStyle(isConnected ? AppTheme.accent : AppTheme.textSecondary)
                .frame(width: 36)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(peer.displayName)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(isConnected ? "接続済み" : "タップして接続")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(isConnected ? Color.green : AppTheme.textTertiary)
            }

            Spacer()

            if !isConnected {
                Button("接続") {
                    manager.invitePeer(peer)
                }
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(AppTheme.accent, in: Capsule())
                .accessibilityLabel("\(peer.displayName) に接続申請を送る")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }

    // MARK: - 使い方セクション

    private var howToUseSection: some View {
        VStack(spacing: 0) {
            sectionHeader(title: "使い方", icon: "info.circle")

            VStack(alignment: .leading, spacing: 10) {
                howToRow(step: "1", text: "相手も「シール交換」画面を開く")
                howToRow(step: "2", text: "「近くのデバイス」に相手が表示されたら「接続」をタップ")
                howToRow(step: "3", text: "相手が承諾すると接続完了。「シールを送る」でシールを選択！")
                howToRow(step: "4", text: "受け取ったシールは保存するとライブラリに追加されます")
            }
            .padding(16)
            .stickerCard()
        }
    }

    private func howToRow(step: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(step)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(AppTheme.accent, in: Circle())
                .accessibilityHidden(true)
            Text(text)
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("手順\(step): \(text)")
    }

    // MARK: - ヘルパー

    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.accent)
                .accessibilityHidden(true)
            Text(title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
        .padding(.bottom, 8)
    }
}

// MARK: - シール選択シート

private struct ExchangeStickerPickerView: View {
    let manager: MultipeerConnectivityManager
    @Binding var isPresented: Bool
    @Query(sort: \Sticker.createdAt, order: .reverse) private var stickers: [Sticker]
    @State private var isSending = false
    @State private var sendError: String?

    private let columns = [GridItem(.adaptive(minimum: 90), spacing: 12)]

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundPrimary.ignoresSafeArea()

                if stickers.isEmpty {
                    emptyView
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(stickers) { sticker in
                                stickerCell(sticker)
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("送るシールを選ぶ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { isPresented = false }
                        .foregroundStyle(AppTheme.accent)
                }
            }
            .overlay {
                if isSending {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    ProgressView("送信中...")
                        .padding(24)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
            }
            .alert("送信エラー", isPresented: Binding(
                get: { sendError != nil },
                set: { if !$0 { sendError = nil } }
            )) {
                Button("OK") { sendError = nil }
            } message: {
                Text(sendError ?? "")
            }
        }
    }

    private func stickerCell(_ sticker: Sticker) -> some View {
        Button {
            Task { await sendSticker(sticker) }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.backgroundCard)
                    .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)

                if let image = ImageStorage.load(fileName: sticker.imageFileName) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding(8)
                } else {
                    Image(systemName: "photo")
                        .font(.system(size: 24))
                        .foregroundStyle(AppTheme.textTertiary)
                }
            }
            .frame(width: 90, height: 90)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("このシールを送る")
        .disabled(isSending)
    }

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "seal.fill")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.textTertiary)
                .accessibilityHidden(true)
            Text("シールがありません")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    private func sendSticker(_ sticker: Sticker) async {
        guard let image = ImageStorage.load(fileName: sticker.imageFileName),
              let imageData = image.pngData() else {
            sendError = "シール画像の読み込みに失敗しました"
            return
        }
        isSending = true
        defer { isSending = false }
        do {
            try await manager.sendSticker(imageData: imageData)
            isPresented = false
        } catch {
            sendError = error.localizedDescription
        }
    }
}

// MARK: - 受信シートシート

private struct ReceivedStickerSheet: View {
    let manager: MultipeerConnectivityManager
    let modelContext: ModelContext
    @State private var isSaving = false
    @State private var savedCount = 0

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(manager.receivedStickers) { received in
                            receivedCard(received)
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("受け取ったシール")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func receivedCard(_ received: ReceivedStickerData) -> some View {
        VStack(spacing: 16) {
            if let image = UIImage(data: received.imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .accessibilityLabel("\(received.senderName) から受け取ったシール")
            }

            Text("\(received.senderName) から")
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)

            HStack(spacing: 12) {
                Button("受け取らない") {
                    manager.dismissReceivedSticker(received.id)
                }
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppTheme.textTertiary.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))

                Button {
                    Task { await saveSticker(received) }
                } label: {
                    if isSaving {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    } else {
                        Text("ライブラリに保存")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                }
                .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 12))
                .disabled(isSaving)
                .accessibilityValue(isSaving ? "保存中" : "")
            }
        }
        .padding(16)
        .stickerCard()
    }

    private func saveSticker(_ received: ReceivedStickerData) async {
        guard let image = UIImage(data: received.imageData) else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            let fileName = try ImageStorage.save(image)
            let sticker = Sticker(imageFileName: fileName)
            modelContext.insert(sticker)
            manager.dismissReceivedSticker(received.id)
            savedCount += 1
        } catch {
            // 保存失敗はサイレントに処理（ユーザーが再試行可能）
        }
    }
}

#Preview {
    NavigationStack {
        StickerExchangeView()
    }
}
