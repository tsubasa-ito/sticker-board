import SwiftUI
import SwiftData

struct MultiStickerSelectionView: View {
    @Environment(\.modelContext) private var modelContext
    let images: [UIImage]
    let onComplete: (Int) -> Void

    @State private var selectedIndices: Set<Int>
    @State private var errorMessage: String?
    @State private var appeared = false
    @State private var showingPaywall = false
    @Query private var existingStickers: [Sticker]

    init(images: [UIImage], onComplete: @escaping (Int) -> Void) {
        self.images = images
        self.onComplete = onComplete
        self._selectedIndices = State(initialValue: Set(images.indices))
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(spacing: 20) {
                    stickerGrid
                    actionButtons
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .background(AppTheme.backgroundPrimary)
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
        .onAppear {
            withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
                appeared = true
            }
        }
    }

    // MARK: - ヘッダー

    private var header: some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .foregroundStyle(AppTheme.cream)
                    .accessibilityHidden(true)
                Text("\(images.count)個のシールを検出しました")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
            }

            Text("追加したいシールを選択してください")
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(.vertical, 12)
    }

    // MARK: - シールグリッド

    private var stickerGrid: some View {
        let columns = [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
        ]

        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(images.indices, id: \.self) { index in
                stickerCell(index: index)
            }
        }
    }

    private func stickerCell(index: Int) -> some View {
        let isSelected = selectedIndices.contains(index)

        return Button {
            withAnimation(.spring(duration: 0.3)) {
                if isSelected {
                    selectedIndices.remove(index)
                } else {
                    selectedIndices.insert(index)
                }
            }
        } label: {
            ZStack(alignment: .topTrailing) {
                VStack {
                    ZStack {
                        CheckerboardBackground()
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .accessibilityHidden(true)

                        Image(uiImage: images[index])
                            .resizable()
                            .scaledToFit()
                            .padding(12)
                    }
                    .frame(height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                isSelected ? AppTheme.softOrange : AppTheme.accent.opacity(0.2),
                                lineWidth: isSelected ? 3 : 1
                            )
                    }
                }

                // 選択チェックマーク
                ZStack {
                    Circle()
                        .fill(isSelected ? AppTheme.softOrange : Color.white.opacity(0.8))
                        .frame(width: 28, height: 28)
                        .shadow(color: .black.opacity(0.1), radius: 2, y: 1)

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22))
                        .foregroundStyle(isSelected ? .white : AppTheme.textTertiary)
                }
                .offset(x: -6, y: 6)
            }
            .scaleEffect(appeared ? 1 : 0.7)
            .opacity(appeared ? 1 : 0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("シール \(index + 1)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - アクションボタン

    private var actionButtons: some View {
        VStack(spacing: 12) {
            if let errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .accessibilityHidden(true)
                    Text(errorMessage)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // 全選択/全解除トグル
            Button {
                withAnimation(.spring(duration: 0.3)) {
                    if selectedIndices.count == images.count {
                        selectedIndices.removeAll()
                    } else {
                        selectedIndices = Set(images.indices)
                    }
                }
            } label: {
                Text(selectedIndices.count == images.count ? "すべて解除" : "すべて選択")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.accent)
            }
            .accessibilityValue("\(selectedIndices.count)/\(images.count)枚選択中")

            // 保存ボタン
            Button {
                saveSelectedStickers()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("\(selectedIndices.count)枚をコレクションに追加")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(selectedIndices.isEmpty ? AnyShapeStyle(Color.gray.opacity(0.3)) : AnyShapeStyle(AppTheme.accent))
                .foregroundStyle(selectedIndices.isEmpty ? AppTheme.textTertiary : .white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(selectedIndices.isEmpty)
            .accessibilityLabel("\(selectedIndices.count)枚をコレクションに追加")
            .accessibilityHint(selectedIndices.isEmpty ? "シールを選択してください" : "選択したシールをコレクションに保存します")
        }
    }

    // MARK: - 保存

    private func saveSelectedStickers() {
        let currentCount = existingStickers.count
        let selectedCount = selectedIndices.count
        if !SubscriptionManager.shared.isProUser && currentCount + selectedCount > 30 {
            showingPaywall = true
            return
        }

        var savedCount = 0
        var firstError: Error?

        for index in selectedIndices.sorted() {
            do {
                let fileName = try ImageStorage.save(images[index])
                let sticker = Sticker(imageFileName: fileName)
                modelContext.insert(sticker)
                savedCount += 1
            } catch {
                if firstError == nil {
                    firstError = error
                }
            }
        }

        if let error = firstError {
            errorMessage = "\(selectedIndices.count - savedCount)枚のシールの保存に失敗しました: \(error.localizedDescription)"
        }

        if savedCount > 0 {
            onComplete(savedCount)
        }
    }
}
