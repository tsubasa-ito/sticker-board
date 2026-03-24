import SwiftUI
import SwiftData

struct BoardEditorView: View {
    @Bindable var board: Board
    @Query(sort: \Sticker.createdAt, order: .reverse) private var allStickers: [Sticker]

    @State private var placements: [StickerPlacement] = []
    @State private var showingStickerPicker = false

    var body: some View {
        ZStack {
            // クラフト紙風のキャンバス背景
            canvasBackground

            // 空の場合のヒント
            if placements.isEmpty {
                emptyCanvasHint
            }

            // 配置されたシール
            ForEach(sortedPlacements) { placement in
                StickerItemView(
                    placement: binding(for: placement),
                    image: loadImage(for: placement)
                )
                .zIndex(Double(placement.zIndex))
                .contextMenu {
                    Button {
                        bringToFront(placement)
                    } label: {
                        Label("最前面に移動", systemImage: "square.3.layers.3d.top.filled")
                    }

                    Button {
                        bringForward(placement)
                    } label: {
                        Label("前面に移動", systemImage: "square.2.layers.3d.top.filled")
                    }

                    Button {
                        sendBackward(placement)
                    } label: {
                        Label("背面に移動", systemImage: "square.2.layers.3d.bottom.filled")
                    }

                    Button {
                        sendToBack(placement)
                    } label: {
                        Label("最背面に移動", systemImage: "square.3.layers.3d.bottom.filled")
                    }

                    Divider()

                    Button(role: .destructive) {
                        removeFromBoard(placement)
                    } label: {
                        Label("ボードから削除", systemImage: "trash")
                    }
                } preview: {
                    if let image = loadImage(for: placement) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 160, height: 160)
                            .padding(12)
                    }
                }
            }
        }
        .navigationTitle(board.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingStickerPicker = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(AppTheme.headerGradient)
                            .frame(width: 32, height: 32)

                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
        }
        .sheet(isPresented: $showingStickerPicker) {
            StickerPickerSheet(stickers: allStickers) { sticker in
                addStickerToBoard(sticker)
            }
        }
        .onAppear {
            placements = board.placements
        }
        .onDisappear {
            saveBoard()
        }
    }

    // MARK: - キャンバス背景

    private var canvasBackground: some View {
        ZStack {
            AppTheme.backgroundCanvas
                .ignoresSafeArea()

            // ドットグリッドパターン（シール手帳風）
            Canvas { context, size in
                let spacing: CGFloat = 24
                let dotSize: CGFloat = 2
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
                            with: .color(Color(hex: 0xDDD5C8).opacity(0.5))
                        )
                    }
                }
            }
            .ignoresSafeArea()
        }
    }

    // MARK: - 空のヒント

    private var emptyCanvasHint: some View {
        VStack(spacing: 12) {
            Image(systemName: "hand.tap")
                .font(.system(size: 36))
                .foregroundStyle(AppTheme.textTertiary)

            Text("右上の＋からシールを追加")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textTertiary)
        }
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

    /// imageFileName を直接使って画像を読み込む（IDマッチング不要）
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
        saveBoard()
    }

    // MARK: - Z軸操作

    private func bringToFront(_ placement: StickerPlacement) {
        guard let index = placements.firstIndex(where: { $0.id == placement.id }) else { return }
        let maxZ = placements.map(\.zIndex).max() ?? 0
        guard placements[index].zIndex < maxZ else { return }
        placements[index].zIndex = maxZ + 1
        saveBoard()
    }

    private func bringForward(_ placement: StickerPlacement) {
        let sorted = placements.sorted { $0.zIndex < $1.zIndex }
        guard let sortedIndex = sorted.firstIndex(where: { $0.id == placement.id }),
              sortedIndex < sorted.count - 1 else { return }
        let nextId = sorted[sortedIndex + 1].id
        guard let idx1 = placements.firstIndex(where: { $0.id == placement.id }),
              let idx2 = placements.firstIndex(where: { $0.id == nextId }) else { return }
        let tempZ = placements[idx1].zIndex
        placements[idx1].zIndex = placements[idx2].zIndex
        placements[idx2].zIndex = tempZ
        saveBoard()
    }

    private func sendBackward(_ placement: StickerPlacement) {
        let sorted = placements.sorted { $0.zIndex < $1.zIndex }
        guard let sortedIndex = sorted.firstIndex(where: { $0.id == placement.id }),
              sortedIndex > 0 else { return }
        let prevId = sorted[sortedIndex - 1].id
        guard let idx1 = placements.firstIndex(where: { $0.id == placement.id }),
              let idx2 = placements.firstIndex(where: { $0.id == prevId }) else { return }
        let tempZ = placements[idx1].zIndex
        placements[idx1].zIndex = placements[idx2].zIndex
        placements[idx2].zIndex = tempZ
        saveBoard()
    }

    private func removeFromBoard(_ placement: StickerPlacement) {
        placements.removeAll { $0.id == placement.id }
        saveBoard()
    }

    private func sendToBack(_ placement: StickerPlacement) {
        guard let index = placements.firstIndex(where: { $0.id == placement.id }) else { return }
        let minZ = placements.map(\.zIndex).min() ?? 0
        guard placements[index].zIndex > minZ else { return }
        placements[index].zIndex = minZ - 1
        saveBoard()
    }

    private func saveBoard() {
        board.placements = placements
        board.updatedAt = Date()
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
