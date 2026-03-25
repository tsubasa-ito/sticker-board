import SwiftUI
import SwiftData
import Photos

struct BoardEditorView: View {
    @Bindable var board: Board
    @Query(sort: \Sticker.createdAt, order: .reverse) private var allStickers: [Sticker]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.displayScale) private var displayScale
    @Environment(\.dismiss) private var dismiss

    @State private var placements: [StickerPlacement] = []
    @State private var selectedPlacementId: UUID?
    @State private var showingStickerPicker = false
    @State private var showingSaveResult = false
    @State private var saveResultSuccess = false
    @State private var canvasSize: CGSize = .zero
    @State private var showHint = true
    @State private var bottomBarExpanded = true
    @State private var showQuickPicks = false
    @State private var showingBackgroundPicker = false
    @State private var backgroundConfig: BackgroundPatternConfig = .default

    var body: some View {
        ZStack {
            // 背景（グレー + 微細ドットグリッド）
            editorBackground

            // メインコンテンツ
            VStack(spacing: 0) {
                editorTopBar
                canvasArea
            }

            // フローティングUI（折りたたみ可能）
            VStack(spacing: 0) {
                Spacer()

                if bottomBarExpanded {
                    // 折りたたみハンドル
                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            bottomBarExpanded = false
                            showQuickPicks = false
                        }
                    } label: {
                        VStack(spacing: 2) {
                            Capsule()
                                .fill(AppTheme.textTertiary.opacity(0.4))
                                .frame(width: 36, height: 4)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(AppTheme.textTertiary)
                        }
                        .frame(height: 24)
                        .frame(maxWidth: .infinity)
                    }

                    if showQuickPicks && !allStickers.isEmpty {
                        stickerQuickPicks
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    floatingToolbar
                        .padding(.horizontal, 16)
                        .padding(.bottom, 10)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    // 折りたたみ時: 小さな展開ボタン
                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            bottomBarExpanded = true
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.up")
                                .font(.system(size: 12, weight: .bold))
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 14))
                        }
                        .foregroundStyle(AppTheme.textSecondary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
                    }
                    .padding(.bottom, 16)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(duration: 0.3), value: bottomBarExpanded)
            .animation(.spring(duration: 0.3), value: showQuickPicks)

            // ヒントトースト
            if showHint && !placements.isEmpty {
                VStack {
                    hintToast
                        .padding(.top, 76)
                    Spacer()
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingStickerPicker) {
            StickerPickerSheet(stickers: allStickers) { sticker in
                addStickerToBoard(sticker)
            }
        }
        .sheet(isPresented: $showingBackgroundPicker) {
            BackgroundPatternPickerView(config: $backgroundConfig) {
                board.backgroundPattern = backgroundConfig
                saveBoard()
            }
            .presentationDetents([.medium, .large])
        }
        .alert(
            saveResultSuccess ? "保存完了" : "エラー",
            isPresented: $showingSaveResult
        ) {
            Button("OK") {}
        } message: {
            Text(saveResultSuccess
                 ? "ボードを写真に保存しました"
                 : "写真の保存に失敗しました。設定から写真へのアクセスを許可してください。")
        }
        .onAppear {
            placements = board.placements
            backgroundConfig = board.backgroundPattern
        }
        .onDisappear {
            saveBoard()
        }
        .task {
            try? await Task.sleep(for: .seconds(3))
            withAnimation(.easeOut(duration: 0.5)) { showHint = false }
        }
    }

    // MARK: - 背景

    private var editorBackground: some View {
        ZStack {
            Color(hex: 0xF0F1EF)
                .ignoresSafeArea()

            Canvas { context, size in
                let spacing: CGFloat = 40
                let dotSize: CGFloat = 1.5
                let rows = Int(size.height / spacing) + 1
                let cols = Int(size.width / spacing) + 1

                for row in 0..<rows {
                    for col in 0..<cols {
                        let point = CGPoint(
                            x: CGFloat(col) * spacing + spacing / 2,
                            y: CGFloat(row) * spacing + spacing / 2
                        )
                        context.fill(
                            Path(ellipseIn: CGRect(
                                x: point.x - dotSize / 2,
                                y: point.y - dotSize / 2,
                                width: dotSize,
                                height: dotSize
                            )),
                            with: .color(Color(hex: 0x2D2F2E).opacity(0.03))
                        )
                    }
                }
            }
            .ignoresSafeArea()
        }
    }

    // MARK: - トップバー

    private var editorTopBar: some View {
        HStack {
            // 左: 閉じるボタン + タイトル
            HStack(spacing: 16) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(AppTheme.textPrimary)
                        .frame(width: 40, height: 40)
                        .background(Color(hex: 0xF0F1EF))
                        .clipShape(Circle())
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(board.title)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.accent)
                        .lineLimit(1)

                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Text("閉じる")
                                .font(.system(size: 10, weight: .medium))
                            Image(systemName: "xmark")
                                .font(.system(size: 10))
                        }
                        .foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }

            Spacer()

            // 右: ダウンロード（画像として保存）
            Button {
                saveBoardAsImage()
            } label: {
                Image(systemName: "arrow.down.to.line")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
                    .frame(width: 40, height: 40)
                    .background(Color(hex: 0xF0F1EF))
                    .clipShape(Circle())
            }
            .disabled(placements.isEmpty)
            .opacity(placements.isEmpty ? 0.4 : 1)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(hex: 0xF6F6F4))
    }

    // MARK: - キャンバスエリア

    private var canvasArea: some View {
        ZStack {
            // ボードカード（背景パターン付き）
            BoardBackgroundView(config: backgroundConfig)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.08), radius: 20, y: 4)
                .padding(24)

            // タップで選択解除
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedPlacementId = nil
                    }
                }

            // 空の場合のヒント
            if placements.isEmpty {
                emptyCanvasHint
            }

            // 配置されたシール
            ForEach(sortedPlacements) { placement in
                StickerItemView(
                    placement: binding(for: placement),
                    image: loadImage(for: placement),
                    isSelected: selectedPlacementId == placement.id,
                    onTap: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedPlacementId = placement.id
                        }
                    },
                    onGestureEnded: {
                        saveBoard()
                    }
                )
                .zIndex(Double(placement.zIndex))
            }
        }
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        } action: { newSize in
            canvasSize = newSize
        }
    }

    // MARK: - 空のヒント

    private var emptyCanvasHint: some View {
        VStack(spacing: 12) {
            Image(systemName: "hand.tap")
                .font(.system(size: 36))
                .foregroundStyle(AppTheme.textTertiary)

            Text("下の＋からシールを追加")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textTertiary)
        }
    }

    // MARK: - ヒントトースト

    private var hintToast: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 12))
            Text("ドラッグで移動。ピンチでサイズ変更")
                .font(.system(size: 12, weight: .medium, design: .rounded))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color(hex: 0x2D2F2E).opacity(0.9))
        )
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
    }

    // MARK: - シールクイックピック

    private var stickerQuickPicks: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(allStickers) { sticker in
                    Button {
                        addStickerToBoard(sticker)
                    } label: {
                        QuickPickThumbnail(fileName: sticker.imageFileName)
                    }
                }

                // 全て見るボタン
                Button {
                    showQuickPicks = false
                    showingStickerPicker = true
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "square.grid.2x2")
                            .font(.system(size: 18))
                        Text("全て")
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                    }
                    .foregroundStyle(AppTheme.textSecondary)
                    .frame(width: 64, height: 64)
                    .background(Color(hex: 0xF0F1EF))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
        }
        .frame(height: 80)
    }

    // MARK: - フローティングツールバー

    private var floatingToolbar: some View {
        HStack(spacing: 0) {
            // 追加ボタン（タップ: クイックピック表示、長押し: 全シール一覧）
            Button {
                withAnimation(.spring(duration: 0.3)) {
                    showQuickPicks.toggle()
                }
            } label: {
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.accent.opacity(0.15))
                            .frame(width: 44, height: 44)
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(AppTheme.accent)
                    }
                    Text("追加")
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .textCase(.uppercase)
                        .tracking(1.5)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            Spacer()

            // 背景パターンボタン
            Button {
                showingBackgroundPicker = true
            } label: {
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.secondary.opacity(0.15))
                            .frame(width: 44, height: 44)
                        Image(systemName: "paintpalette.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(AppTheme.secondary)
                    }
                    Text("背景")
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .textCase(.uppercase)
                        .tracking(1.5)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            Spacer()

            // レイヤー操作グループ
            HStack(spacing: 16) {
                Button {
                    applyToSelected { bringToFront($0) }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "square.2.layers.3d.top.filled")
                            .font(.system(size: 20))
                            .foregroundStyle(selectedPlacementId != nil ? AppTheme.textPrimary : AppTheme.textTertiary)
                        Text("前面へ")
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                            .tracking(1)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                .disabled(selectedPlacementId == nil)

                Divider()
                    .frame(height: 32)

                Button {
                    applyToSelected { sendToBack($0) }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "square.2.layers.3d.bottom.filled")
                            .font(.system(size: 20))
                            .foregroundStyle(selectedPlacementId != nil ? AppTheme.textPrimary : AppTheme.textTertiary)
                        Text("背面へ")
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                            .tracking(1)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                .disabled(selectedPlacementId == nil)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(hex: 0xF0F1EF).opacity(0.5))
            )

            Spacer()

            // 削除ボタン
            Button {
                if let id = selectedPlacementId,
                   let placement = placements.first(where: { $0.id == id }) {
                    withAnimation {
                        removeFromBoard(placement)
                        selectedPlacementId = nil
                    }
                }
            } label: {
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(selectedPlacementId != nil ? Color.red.opacity(0.1) : Color.clear)
                            .frame(width: 44, height: 44)
                        Image(systemName: "trash")
                            .font(.system(size: 20))
                            .foregroundStyle(selectedPlacementId != nil ? .red : AppTheme.textTertiary)
                    }
                    Text("削除")
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .textCase(.uppercase)
                        .tracking(1.5)
                        .foregroundStyle(selectedPlacementId != nil ? .red : AppTheme.textSecondary)
                }
            }
            .disabled(selectedPlacementId == nil)
        }
        .padding(.horizontal, 28)
        .frame(height: 72)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.12), radius: 16, y: 4)
                .overlay(
                    Capsule()
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - ロジック

    private var sortedPlacements: [StickerPlacement] {
        placements.sorted { $0.zIndex < $1.zIndex }
    }

    private func binding(for placement: StickerPlacement) -> Binding<StickerPlacement> {
        guard let index = placements.firstIndex(where: { $0.id == placement.id }) else {
            fatalError("Placement not found")
        }
        return $placements[index]
    }

    private func loadImage(for placement: StickerPlacement) -> UIImage? {
        ImageStorage.load(fileName: placement.imageFileName)
    }

    private func addStickerToBoard(_ sticker: Sticker) {
        let maxZ = placements.map(\.zIndex).max() ?? -1
        let placement = StickerPlacement(
            stickerId: sticker.id,
            imageFileName: sticker.imageFileName,
            positionX: 0,
            positionY: 0,
            scale: 1.0,
            rotation: 0,
            zIndex: maxZ + 1
        )
        placements.append(placement)
        selectedPlacementId = placement.id
        saveBoard()
    }

    private func applyToSelected(_ action: (StickerPlacement) -> Void) {
        guard let id = selectedPlacementId,
              let placement = placements.first(where: { $0.id == id }) else { return }
        action(placement)
    }

    // MARK: - Z軸操作

    private func bringToFront(_ placement: StickerPlacement) {
        guard let index = placements.firstIndex(where: { $0.id == placement.id }) else { return }
        let maxZ = placements.map(\.zIndex).max() ?? 0
        placements[index].zIndex = maxZ + 1
        saveBoard()
    }

    private func sendToBack(_ placement: StickerPlacement) {
        guard let index = placements.firstIndex(where: { $0.id == placement.id }) else { return }
        let minZ = placements.map(\.zIndex).min() ?? 0
        placements[index].zIndex = minZ - 1
        saveBoard()
    }

    private func removeFromBoard(_ placement: StickerPlacement) {
        placements.removeAll { $0.id == placement.id }
        saveBoard()
    }

    private func saveBoard() {
        board.placements = placements
        board.updatedAt = Date()
        try? modelContext.save()
    }

    // MARK: - 画像として保存

    private func saveBoardAsImage() {
        let content = BoardSnapshotView(placements: sortedPlacements, size: canvasSize, backgroundConfig: backgroundConfig)

        let renderer = ImageRenderer(content: content)
        renderer.scale = displayScale

        guard let image = renderer.uiImage else {
            saveResultSuccess = false
            showingSaveResult = true
            return
        }

        Task {
            let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            guard status == .authorized else {
                saveResultSuccess = false
                showingSaveResult = true
                return
            }
            do {
                try await PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                }
                saveResultSuccess = true
            } catch {
                saveResultSuccess = false
            }
            showingSaveResult = true
        }
    }
}

// MARK: - クイックピックサムネイル（非同期画像読み込み）

private struct QuickPickThumbnail: View {
    let fileName: String
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: 0xF0F1EF))
                    .frame(width: 56, height: 56)
            }
        }
        .padding(4)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        .task {
            image = await Task.detached {
                ImageStorage.load(fileName: fileName)
            }.value
        }
    }
}

// MARK: - ボードスナップショット（画像書き出し用）

private struct BoardSnapshotView: View {
    let placements: [StickerPlacement]
    let size: CGSize
    var backgroundConfig: BackgroundPatternConfig = .default

    var body: some View {
        ZStack {
            BoardBackgroundView(config: backgroundConfig)

            ForEach(placements) { placement in
                if let image = ImageStorage.load(fileName: placement.imageFileName) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
                        .scaleEffect(placement.scale)
                        .rotationEffect(.radians(placement.rotation))
                        .offset(x: placement.positionX, y: placement.positionY)
                }
            }
        }
        .frame(width: size.width, height: size.height)
        .clipped()
    }
}

// MARK: - シール選択シート

struct StickerPickerSheet: View {
    let stickers: [Sticker]
    let onSelect: (Sticker) -> Void
    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.adaptive(minimum: 80), spacing: 14)]

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundPrimary
                    .ignoresSafeArea()

                Group {
                    if stickers.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "star.slash")
                                .font(.system(size: 36))
                                .foregroundStyle(AppTheme.textTertiary)

                            Text("シールがありません")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)

                            Text("先にホームからシールを追加してください")
                                .font(.system(size: 13, design: .rounded))
                                .foregroundStyle(AppTheme.textTertiary)
                        }
                    } else {
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 14) {
                                ForEach(stickers) { sticker in
                                    Button {
                                        onSelect(sticker)
                                        dismiss()
                                    } label: {
                                        StickerThumbnailView(sticker: sticker)
                                    }
                                }
                            }
                            .padding(20)
                        }
                    }
                }
            }
            .navigationTitle("シールを選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.backgroundPrimary, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                        .foregroundStyle(AppTheme.accent)
                }
            }
        }
    }
}
