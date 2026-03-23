import SwiftUI
import SwiftData

struct BoardListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Board.updatedAt, order: .reverse) private var boards: [Board]

    @State private var showingNewBoard = false
    @State private var newBoardTitle = ""

    var body: some View {
        Group {
            if boards.isEmpty {
                ContentUnavailableView(
                    "ボードがありません",
                    systemImage: "rectangle.on.rectangle",
                    description: Text("＋ボタンから新しいボードを作りましょう")
                )
            } else {
                List {
                    ForEach(boards) { board in
                        NavigationLink {
                            BoardEditorView(board: board)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(board.title)
                                    .font(.headline)
                                Text("シール \(board.placements.count)枚")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete(perform: deleteBoards)
                }
            }
        }
        .navigationTitle("ボード一覧")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingNewBoard = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .alert("新しいボード", isPresented: $showingNewBoard) {
            TextField("ボード名", text: $newBoardTitle)
            Button("作成") { createBoard() }
            Button("キャンセル", role: .cancel) { newBoardTitle = "" }
        } message: {
            Text("ボードの名前を入力してください")
        }
    }

    private func createBoard() {
        let title = newBoardTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        let board = Board(title: title)
        modelContext.insert(board)
        newBoardTitle = ""
    }

    private func deleteBoards(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(boards[index])
        }
    }
}
