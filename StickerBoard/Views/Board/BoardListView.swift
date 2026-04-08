import SwiftUI
import SwiftData

struct BoardListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Board.createdAt, order: .forward) private var boards: [Board]

    @State private var showingNewBoard = false
    @State private var newBoardTitle = ""
    @State private var showingPaywall = false
    @State private var boardToDelete: Board?
    @State private var showingDeleteConfirmation = false

    var body: some View {
        ZStack {
            AppTheme.backgroundPrimary
                .ignoresSafeArea()

            Group {
                if boards.isEmpty {
                    emptyState
                } else {
                    boardList
                }
            }
        }
        .navigationTitle("ボード")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    if !SubscriptionManager.shared.isProUser && boards.count >= 1 {
                        showingPaywall = true
                    } else {
                        showingNewBoard = true
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(AppTheme.accent)
                            .frame(width: 32, height: 32)

                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .accessibilityLabel("新しいボードを作成")
                .accessibilityHint("ボード名を入力して新しいボードを追加します")
            }
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
        .alert("新しいボード", isPresented: $showingNewBoard) {
            TextField("ボード名", text: $newBoardTitle)
            Button("作成") { createBoard() }
            Button("キャンセル", role: .cancel) { newBoardTitle = "" }
        } message: {
            Text("ボードの名前を入力してください")
        }
        .alert("削除の確認", isPresented: $showingDeleteConfirmation, presenting: boardToDelete) { board in
            Button("削除", role: .destructive) { deleteBoard(board) }
            Button("キャンセル", role: .cancel) { boardToDelete = nil }
        } message: { board in
            Text("「\(board.title)」を削除しますか？\nこの操作は取り消せません。")
        }
    }

    // MARK: - 空の状態

    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppTheme.secondary.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "rectangle.on.rectangle.angled")
                    .font(.system(size: 40))
                    .foregroundStyle(AppTheme.secondary.opacity(0.5))
            }
            .accessibilityHidden(true)

            VStack(spacing: 6) {
                Text("ボードがありません")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

                Text("右上の＋ボタンから\n新しいボードを作りましょう")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .accessibilityElement(children: .combine)
            .accessibilityHint("右上のプラスボタンをタップしてボードを作成できます")
        }
    }

    // MARK: - ボードリスト

    private var boardList: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(boards) { board in
                    NavigationLink {
                        BoardEditorView(board: board)
                    } label: {
                        BoardCard(board: board)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            boardToDelete = board
                            showingDeleteConfirmation = true
                        } label: {
                            Label("削除", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(20)
        }
    }

    private func createBoard() {
        let title = newBoardTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        let board = Board(title: title)
        modelContext.insert(board)
        newBoardTitle = ""
    }

    private func deleteBoard(_ board: Board) {
        let deletedId = board.id
        // delete 前にメタデータを生成（@Query が stale になる前に）
        let remaining = boards.filter { $0.id != deletedId }.map { b in
            WidgetDataSyncService.generateMetadata(
                boardId: b.id, title: b.title,
                stickerCount: b.placements.count, updatedAt: b.updatedAt
            )
        }
        modelContext.delete(board)
        WidgetDataSyncService.removeBoard(boardId: deletedId, remainingMetadata: remaining)
        boardToDelete = nil
    }
}

// MARK: - ボードカード

struct BoardCard: View {
    let board: Board

    var body: some View {
        HStack(spacing: 14) {
            // ボードアイコン
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.backgroundCanvas)
                    .frame(width: 56, height: 56)
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(AppTheme.borderSubtle, lineWidth: 1)
                    }

                Image(systemName: "rectangle.on.rectangle.angled")
                    .font(.system(size: 22))
                    .foregroundStyle(AppTheme.secondary)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(board.title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

                HStack(spacing: 12) {
                    Label("\(board.placements.count)枚", systemImage: "star.fill")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.accent)

                    Text(board.updatedAt.formatted(.relative(presentation: .named)))
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(AppTheme.textTertiary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.textTertiary)
                .accessibilityHidden(true)
        }
        .padding(14)
        .stickerCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(board.title)、シール\(board.placements.count)枚、\(board.updatedAt.formatted(.relative(presentation: .named)))")
    }
}
