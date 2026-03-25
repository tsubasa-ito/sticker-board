import SwiftUI

struct StickerFilterPickerView: View {
    let originalImage: UIImage
    @Binding var selectedFilter: StickerFilter
    @State private var previewImages: [StickerFilter: UIImage] = [:]
    @State private var isGenerating = true

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(StickerFilter.allCases) { filter in
                filterThumbnail(filter)
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
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    if let preview = previewImages[filter] {
                        Image(uiImage: preview)
                            .resizable()
                            .scaledToFit()
                            .padding(10)
                    } else {
                        ProgressView()
                    }
                }
                .aspectRatio(1, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
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
                    .font(.system(size: 12, weight: isSelected ? .bold : .medium, design: .rounded))
                    .foregroundStyle(isSelected ? AppTheme.accent : AppTheme.textSecondary)
            }
        }
        .buttonStyle(.plain)
    }

    private func generatePreviews() async {
        let thumbnailSize: CGFloat = 200
        let thumbnail = originalImage.resized(maxDimension: thumbnailSize)

        previewImages[.original] = thumbnail

        await withTaskGroup(of: (StickerFilter, UIImage).self) { group in
            for filter in StickerFilter.allCases where filter != .original {
                group.addTask {
                    let result = StickerFilterService.apply(filter, to: thumbnail)
                    return (filter, result)
                }
            }
            for await (filter, result) in group {
                previewImages[filter] = result
            }
        }
        isGenerating = false
    }
}
