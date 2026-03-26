import SwiftUI
import SwiftData

struct BoardListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Board.updatedAt, order: .reverse) private var boards: [Board]

    @State private var showingNewBoard = false
    @State private var newBoardTitle = ""
    @State private var showingPaywall = false

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

            VStack(spacing: 6) {
                Text("ボードがありません")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

                Text("右上の＋ボタンから\n新しいボードを作りましょう")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
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
                            modelContext.delete(board)
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
        }
        .padding(14)
        .stickerCard()
    }
}
