import SwiftUI

struct StickerFilterEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var sticker: Sticker
    @State private var selectedFilter: StickerFilter = .original
    @State private var filteredPreviewImage: UIImage?
    @State private var originalImage: UIImage?
    @State private var isSaving = false

    var body: some View {
        ZStack {
            AppTheme.backgroundPrimary
                .ignoresSafeArea()

            if let originalImage {
                ScrollView {
                    VStack(spacing: 20) {
                        // プレビュー
                        StickerPreviewView(image: filteredPreviewImage ?? originalImage)

                        // フィルター選択
                        StickerFilterPickerView(
                            originalImage: originalImage,
                            selectedFilter: $selectedFilter
                        )

                        // 保存ボタン
                        Button {
                            saveFilter()
                        } label: {
                            HStack(spacing: 8) {
                                if isSaving {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                }
                                Text("フィルターを適用")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                selectedFilter == sticker.filter
                                    ? AnyShapeStyle(Color.gray.opacity(0.3))
                                    : AnyShapeStyle(AppTheme.mintGradient)
                            )
                            .foregroundStyle(selectedFilter == sticker.filter ? AppTheme.textTertiary : .white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(selectedFilter == sticker.filter || isSaving)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            } else {
                ProgressView()
            }
        }
        .navigationTitle("フィルター変更")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppTheme.backgroundPrimary, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("キャンセル") { dismiss() }
                    .foregroundStyle(AppTheme.accent)
            }
        }
        .onAppear {
            selectedFilter = sticker.filter
            originalImage = ImageStorage.load(fileName: sticker.imageFileName)
        }
        .onChange(of: selectedFilter) { _, newFilter in
            applyFilterPreview(newFilter)
        }
    }

    private func applyFilterPreview(_ filter: StickerFilter) {
        guard let originalImage else { return }
        guard filter != .original else {
            filteredPreviewImage = nil
            return
        }
        Task.detached {
            let result = StickerFilterService.apply(filter, to: originalImage)
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.2)) {
                    filteredPreviewImage = result
                }
            }
        }
    }

    private func saveFilter() {
        guard let originalImage else { return }
        isSaving = true

        Task.detached {
            do {
                // 古いフィルター画像を削除
                if let oldFilteredFileName = sticker.filteredImageFileName {
                    ImageStorage.delete(fileName: oldFilteredFileName)
                }

                // 新しいフィルター画像を保存（オリジナル以外）
                var newFilteredFileName: String?
                if selectedFilter != .original {
                    let filteredImage = StickerFilterService.apply(selectedFilter, to: originalImage)
                    newFilteredFileName = try ImageStorage.save(filteredImage)
                }

                await MainActor.run {
                    sticker.filter = selectedFilter
                    sticker.filteredImageFileName = newFilteredFileName
                    isSaving = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                }
            }
        }
    }
}
