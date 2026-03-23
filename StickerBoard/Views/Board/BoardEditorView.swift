import SwiftUI
import SwiftData

struct BoardEditorView: View {
    @Bindable var board: Board
    @Query(sort: \Sticker.createdAt, order: .reverse) private var allStickers: [Sticker]

    @State private var placements: [StickerPlacement] = []
    @State private var showingStickerPicker = false

    var body: some View {
        ZStack {
            // キャンバス背景
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            // 配置されたシール
            ForEach(sortedPlacements) { placement in
                StickerItemView(
                    placement: binding(for: placement),
                    image: imageForPlacement(placement)
                )
            }
        }
        .navigationTitle(board.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingStickerPicker = true
                } label: {
                    Image(systemName: "plus.circle")
                }
            }

            ToolbarItem(placement: .secondaryAction) {
                Button("保存") {
                    saveBoard()
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

    private var sortedPlacements: [StickerPlacement] {
        placements.sorted { $0.zIndex < $1.zIndex }
    }

    private func binding(for placement: StickerPlacement) -> Binding<StickerPlacement> {
        guard let index = placements.firstIndex(where: { $0.id == placement.id }) else {
            fatalError("Placement not found")
        }
        return $placements[index]
    }

    private func addStickerToBoard(_ sticker: Sticker) {
        let maxZ = placements.map(\.zIndex).max() ?? -1
        let placement = StickerPlacement(
            stickerId: sticker.id,
            positionX: 150,
            positionY: 300,
            scale: 1.0,
            rotation: 0,
            zIndex: maxZ + 1
        )
        placements.append(placement)
    }

    private func imageForPlacement(_ placement: StickerPlacement) -> UIImage? {
        guard let sticker = allStickers.first(where: { $0.id == placement.stickerId }) else {
            return nil
        }
        return ImageStorage.load(fileName: sticker.imageFileName)
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

    private let columns = [GridItem(.adaptive(minimum: 80), spacing: 12)]

    var body: some View {
        NavigationStack {
            Group {
                if stickers.isEmpty {
                    ContentUnavailableView(
                        "シールがありません",
                        systemImage: "star.slash",
                        description: Text("先にシールを追加してください")
                    )
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(stickers) { sticker in
                                Button {
                                    onSelect(sticker)
                                    dismiss()
                                } label: {
                                    StickerThumbnailView(sticker: sticker)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("シールを選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }
}
