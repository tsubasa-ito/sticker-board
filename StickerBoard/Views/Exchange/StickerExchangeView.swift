import MultipeerConnectivity
import SwiftData
import SwiftUI

/// 近距離デバイス間でシールを交換するβ版ビュー
struct StickerExchangeView: View {
    @State private var manager = MultipeerConnectivityManager.shared
    @State private var showStickerPicker = false
    @State private var showReceivedSheet = false
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            AppTheme.backgroundPrimary.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    betaBanner
                    statusPills

                    if manager.discoveredPeers.isEmpty && manager.connectedPeers.isEmpty {
                        scanningHero
                    }

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

    // MARK: - βバナー（ダッシュ枠 + アイコン背景）

    private var betaBanner: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppTheme.accent.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: "testtube.2")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("β版機能")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.accent)
                    Text("試験的")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppTheme.accent, in: Capsule())
                        .accessibilityHidden(true)
                }
                Text("仕様が変更される場合があります")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(AppTheme.backgroundCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    style: StrokeStyle(lineWidth: 1.5, dash: [6, 3])
                )
                .foregroundStyle(AppTheme.accent.opacity(0.35))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("β版機能: 試験的提供のため仕様が変更される場合があります")
    }

    // MARK: - ステータス Pill（横並び + パルスアニメーション）

    private var statusPills: some View {
        HStack(spacing: 10) {
            StatusPillView(
                icon: "dot.radiowaves.up.forward",
                title: "発見待機",
                isActive: manager.isAdvertising,
                reduceMotion: reduceMotion
            )
            StatusPillView(
                icon: "magnifyingglass",
                title: "デバイス検索",
                isActive: manager.isBrowsing,
                reduceMotion: reduceMotion
            )
        }
    }

    // MARK: - スキャン中ヒーロー（デバイス未発見時）

    private var scanningHero: some View {
        VStack(spacing: 16) {
            ScanningRingsView(reduceMotion: reduceMotion)
                .frame(height: 140)
                .accessibilityHidden(true)

            Text("近くのデバイスを探しています…")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            Text("相手も同じ画面を開いてください")
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 16)
        .stickerCard()
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
                HStack(spacing: 8) {
                    Image(systemName: "seal.fill")
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
            .accessibilityLabel("シールを選んで接続中のデバイスに送る")
        }
    }

    private func peerRow(peer: MCPeerID, isConnected: Bool) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(isConnected ? AppTheme.accent.opacity(0.1) : AppTheme.borderSubtle)
                    .frame(width: 40, height: 40)
                Image(systemName: isConnected ? "iphone.gen3" : "iphone.gen3.badge.questionmark")
                    .font(.system(size: 18))
                    .foregroundStyle(isConnected ? AppTheme.accent : AppTheme.textSecondary)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(peer.displayName)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(isConnected ? "接続済み" : "接続待機中")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(isConnected ? AppTheme.softOrange : AppTheme.textTertiary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(peer.displayName), \(isConnected ? "接続済み" : "未接続")")

            Spacer()

            if !isConnected {
                Button("接続") {
                    manager.invitePeer(peer)
                }
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(AppTheme.accent, in: Capsule())
                .accessibilityLabel("\(peer.displayName) に接続申請を送る")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - 使い方（2×2 ステップカード）

    private var howToUseSection: some View {
        VStack(spacing: 0) {
            sectionHeader(title: "使い方", icon: "info.circle")

            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    stepCard(step: "1", text: "相手も\nこの画面を開く", icon: "iphone.gen3")
                    stepCard(step: "2", text: "「接続」を\nタップ", icon: "hand.tap.fill")
                }
                HStack(spacing: 8) {
                    stepCard(step: "3", text: "シールを\n選んで送る", icon: "seal.fill")
                    stepCard(step: "4", text: "受け取って\nライブラリに保存", icon: "square.and.arrow.down.fill")
                }
            }
        }
    }

    private func stepCard(step: String, text: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(step)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 22, height: 22)
                    .background(AppTheme.accent, in: Circle())
                    .accessibilityHidden(true)
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(AppTheme.accent.opacity(0.4))
                    .accessibilityHidden(true)
            }
            Text(text)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .stickerCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("手順\(step): \(text.replacingOccurrences(of: "\n", with: ""))")
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

// MARK: - ステータス Pill（独立アニメーション状態）

private struct StatusPillView: View {
    let icon: String
    let title: String
    let isActive: Bool
    let reduceMotion: Bool

    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isActive ? AppTheme.accent : AppTheme.textTertiary)
                .frame(width: 20)
                .accessibilityHidden(true)

            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(isActive ? AppTheme.textPrimary : AppTheme.textTertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Spacer(minLength: 4)

            ZStack {
                if isActive && !reduceMotion {
                    Circle()
                        .fill(AppTheme.softOrange)
                        .frame(width: 16, height: 16)
                        .scaleEffect(isAnimating ? 2.4 : 1.0)
                        .opacity(isAnimating ? 0.0 : 0.45)
                }
                Circle()
                    .fill(isActive ? AppTheme.softOrange : AppTheme.borderSubtle)
                    .frame(width: 8, height: 8)
            }
            .frame(width: 20, height: 20)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(
            isActive ? AppTheme.accent.opacity(0.06) : AppTheme.backgroundCard
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    isActive ? AppTheme.accent.opacity(0.25) : AppTheme.borderSubtle,
                    lineWidth: 1
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(isActive ? "アクティブ" : "停止中")")
        .onAppear {
            guard isActive && !reduceMotion else { return }
            withAnimation(
                .easeOut(duration: 1.4).repeatForever(autoreverses: false)
            ) {
                isAnimating = true
            }
        }
    }
}

// MARK: - スキャン中リングアニメーション

private struct ScanningRingsView: View {
    let reduceMotion: Bool
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            ForEach([0, 1, 2], id: \.self) { index in
                Circle()
                    .stroke(AppTheme.accent.opacity(0.12 - Double(index) * 0.03), lineWidth: 1)
                    .frame(
                        width: CGFloat(60 + index * 30),
                        height: CGFloat(60 + index * 30)
                    )
                    .scaleEffect(isAnimating && !reduceMotion ? 1.25 : 1.0)
                    .opacity(isAnimating && !reduceMotion ? 0.4 : 1.0)
                    .animation(
                        reduceMotion ? nil :
                            .easeOut(duration: 2.0)
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * 0.5),
                        value: isAnimating
                    )
            }

            Circle()
                .fill(AppTheme.accent.opacity(0.1))
                .frame(width: 60, height: 60)

            Image(systemName: "iphone.radiowaves.left.and.right")
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(AppTheme.accent)
        }
        .onAppear {
            guard !reduceMotion else { return }
            isAnimating = true
        }
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
                    ProgressView("送信中…")
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

                if let image = ImageStorage.loadThumbnail(fileName: sticker.imageFileName, size: 90) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding(8)
                } else {
                    Image(systemName: "photo")
                        .font(.system(size: 24))
                        .foregroundStyle(AppTheme.textTertiary)
                        .accessibilityHidden(true)
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

// MARK: - 受信シート

private struct ReceivedStickerSheet: View {
    let manager: MultipeerConnectivityManager
    let modelContext: ModelContext
    @State private var isSaving = false
    @State private var saveError: String?

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
            .alert("保存エラー", isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("OK") { saveError = nil }
            } message: {
                Text(saveError ?? "")
            }
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
                    Group {
                        if isSaving {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("ライブラリに保存")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
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
        } catch {
            saveError = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        StickerExchangeView()
    }
}
