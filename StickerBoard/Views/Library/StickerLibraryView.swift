import SwiftUI
import SwiftData

struct StickerLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Sticker.createdAt, order: .reverse) private var stickers: [Sticker]

    private let columns = [
        GridItem(.adaptive(minimum: 100), spacing: 12)
    ]

    var body: some View {
        Group {
            if stickers.isEmpty {
                ContentUnavailableView(
                    "シールがありません",
                    systemImage: "star.slash",
                    description: Text("「シールを追加する」から写真を切り抜いてみましょう")
                )
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(stickers) { sticker in
                            StickerThumbnailView(sticker: sticker)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        deleteSticker(sticker)
                                    } label: {
                                        Label("削除", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("ライブラリ")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func deleteSticker(_ sticker: Sticker) {
        ImageStorage.delete(fileName: sticker.imageFileName)
        modelContext.delete(sticker)
    }
}

struct StickerThumbnailView: View {
    let sticker: Sticker

    var body: some View {
        Group {
            if let image = ImageStorage.load(fileName: sticker.imageFileName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 100, height: 100)
        .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 8))
    }
}
