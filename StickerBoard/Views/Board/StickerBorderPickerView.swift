import SwiftUI

struct StickerBorderPickerView: View {
    @Binding var selectedWidth: StickerBorderWidth
    @Binding var selectedColorHex: String
    let originalImage: UIImage?
    @State private var previewImage: UIImage?
    @State private var isGenerating = false

    var body: some View {
        VStack(spacing: 20) {
            // プレビュー
            previewSection

            // 太さ選択
            widthSection

            // カラー選択
            if selectedWidth != .none {
                colorSection
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.spring(duration: 0.3), value: selectedWidth)
        .onChange(of: selectedWidth) { generatePreview() }
        .onChange(of: selectedColorHex) { generatePreview() }
        .task { generatePreview() }
    }

    // MARK: - プレビュー

    private var previewSection: some View {
        ZStack {
            CheckerboardBackground()
                .clipShape(RoundedRectangle(cornerRadius: 16))

            if let previewImage {
                Image(uiImage: previewImage)
                    .resizable()
                    .scaledToFit()
                    .padding(16)
            } else if isGenerating {
                ProgressView()
            }
        }
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AppTheme.accent.opacity(0.15), lineWidth: 1)
        }
    }

    // MARK: - 太さ選択

    private var widthSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("太さ")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)

            HStack(spacing: 8) {
                ForEach(StickerBorderWidth.allCases) { width in
                    let isSelected = selectedWidth == width
                    let isPremium = [StickerBorderWidth.medium, .thick].contains(width)
                    Button {
                        selectedWidth = width
                    } label: {
                        VStack(spacing: 6) {
                            borderWidthIcon(width)
                                .frame(width: 36, height: 36)
                            Text(width.displayName)
                                .font(.system(size: 11, weight: isSelected ? .bold : .medium, design: .rounded))
                                .foregroundStyle(isSelected ? AppTheme.accent : AppTheme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isSelected ? AppTheme.accent.opacity(0.12) : AppTheme.editorBackground)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(isSelected ? AppTheme.accent : .clear, lineWidth: 1.5)
                        }
                        .overlay(alignment: .topTrailing) {
                            if isPremium && !SubscriptionManager.shared.isProUser {
                                ProBadge()
                                    .offset(x: 4, y: -4)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private func borderWidthIcon(_ width: StickerBorderWidth) -> some View {
        let lineWidth: CGFloat = switch width {
        case .none: 0
        case .thin: 1.5
        case .medium: 3
        case .thick: 5
        }

        if width == .none {
            Image(systemName: "circle.dashed")
                .font(.system(size: 22))
                .foregroundStyle(AppTheme.textTertiary)
        } else {
            Circle()
                .stroke(AppTheme.accent, lineWidth: lineWidth)
                .frame(width: 24, height: 24)
        }
    }

    // MARK: - カラー選択

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("カラー")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 44), spacing: 10)], spacing: 10) {
                ForEach(StickerBorderColor.presets) { preset in
                    let isSelected = selectedColorHex == preset.hex
                    Button {
                        selectedColorHex = preset.hex
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color(preset.color))
                                .frame(width: 36, height: 36)
                                .overlay {
                                    Circle()
                                        .stroke(.gray.opacity(0.2), lineWidth: 0.5)
                                }

                            if isSelected {
                                Circle()
                                    .stroke(AppTheme.accent, lineWidth: 2.5)
                                    .frame(width: 42, height: 42)
                            }
                        }
                        .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - プレビュー生成

    private func generatePreview() {
        guard let originalImage else { return }
        isGenerating = true
        let width = selectedWidth
        let colorHex = selectedColorHex
        let thumbnail = originalImage.resized(maxDimension: 300)

        Task.detached {
            let result: UIImage?
            if width == .none {
                result = thumbnail
            } else {
                result = StickerBorderService.applyBorder(to: thumbnail, width: width, colorHex: colorHex)
            }
            await MainActor.run {
                previewImage = result ?? thumbnail
                isGenerating = false
            }
        }
    }
}
