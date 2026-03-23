import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            List {
                // シール追加セクション
                Section {
                    NavigationLink {
                        StickerCaptureView()
                    } label: {
                        Label("シールを追加する", systemImage: "plus.circle.fill")
                    }

                    NavigationLink {
                        StickerLibraryView()
                    } label: {
                        Label("シールライブラリ", systemImage: "square.grid.2x2.fill")
                    }
                } header: {
                    Text("シール")
                }

                // ボードセクション
                Section {
                    NavigationLink {
                        BoardListView()
                    } label: {
                        Label("ボード一覧", systemImage: "rectangle.on.rectangle.angled")
                    }
                } header: {
                    Text("ボード")
                }
            }
            .navigationTitle("シールボード")
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Sticker.self, Board.self], inMemory: true)
}
