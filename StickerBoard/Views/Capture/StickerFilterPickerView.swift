import SwiftUI

struct StickerFilterPickerView: View {
    let originalImage: UIImage
    @Binding var selectedFilter: StickerFilter
    @State private var previewImages: [StickerFilter: UIImage] = [:]
    @State private var isGenerating = true

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "wand.and.stars")
                    .foregroundStyle(AppTheme.secondary)
                Text("フィルターを選択")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(StickerFilter.allCases) { filter in
                        filterThumbnail(filter)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
            }
        }
        .task {
            await generatePreviews()
        }
    }

    private func filterThumbnail(_ filter: StickerFilter) -> some View {
        let isSelected = selectedFilter == filter

        return Button {
            withAnimation(.spring(duration: 0.25)) {
                selectedFilter = filter
            }
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    CheckerboardBackground()
                        .frame(width: 72, height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    if let preview = previewImages[filter] {
                        Image(uiImage: preview)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                    } else {
                        ProgressView()
                            .frame(width: 60, height: 60)
                    }
                }
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(
                            isSelected ? AppTheme.accent : AppTheme.accent.opacity(0.15),
                            lineWidth: isSelected ? 2.5 : 1
                        )
                }
                .shadow(
                    color: isSelected ? AppTheme.accent.opacity(0.3) : .clear,
                    radius: 4, y: 2
                )

                Text(filter.displayName)
                    .font(.system(size: 11, weight: isSelected ? .bold : .medium, design: .rounded))
                    .foregroundStyle(isSelected ? AppTheme.accent : AppTheme.textSecondary)
            }
        }
        .buttonStyle(.plain)
    }

    private func generatePreviews() async {
        // サムネイル用にリサイズしてからフィルター適用（パフォーマンス最適化）
        let thumbnailSize: CGFloat = 150
        let scale = thumbnailSize / max(originalImage.size.width, originalImage.size.height)
        let thumbSize = CGSize(
            width: originalImage.size.width * scale,
            height: originalImage.size.height * scale
        )
        let renderer = UIGraphicsImageRenderer(size: thumbSize)
        let thumbnail = renderer.image { _ in
            originalImage.draw(in: CGRect(origin: .zero, size: thumbSize))
        }

        // オリジナルはそのまま
        previewImages[.original] = thumbnail

        // 各フィルターを非同期で生成
        for filter in StickerFilter.allCases where filter != .original {
            let result = await Task.detached {
                StickerFilterService.apply(filter, to: thumbnail)
            }.value
            previewImages[filter] = result
        }
        isGenerating = false
    }
}
