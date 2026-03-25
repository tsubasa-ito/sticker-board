import SwiftUI

/// 背景パターン選択シート
struct BackgroundPatternPickerView: View {
    @Binding var config: BackgroundPatternConfig
    let onChanged: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // プレビュー
                        previewSection

                        // パターン選択
                        patternTypeSection

                        // カラー設定
                        colorSection
                    }
                    .padding(20)
                }
            }
            .navigationTitle("背景パターン")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.backgroundPrimary, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") { dismiss() }
                        .foregroundStyle(AppTheme.accent)
                        .fontWeight(.bold)
                }
            }
        }
    }

    // MARK: - プレビュー

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("プレビュー")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
                .textCase(.uppercase)
                .tracking(1)

            BoardBackgroundView(config: config)
                .frame(height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.black.opacity(0.06), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
        }
    }

    // MARK: - パターン選択

    private var patternTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("パターン")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
                .textCase(.uppercase)
                .tracking(1)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 12)], spacing: 12) {
                ForEach(BackgroundPatternType.allCases) { type in
                    patternTypeButton(type)
                }
            }
        }
    }

    private func patternTypeButton(_ type: BackgroundPatternType) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                // プリセットから同じタイプのものを適用
                if let preset = BackgroundPatternConfig.presets.first(where: { $0.patternType == type }) {
                    config = preset
                } else {
                    config.patternType = type
                }
                onChanged()
            }
        } label: {
            VStack(spacing: 8) {
                // ミニプレビュー
                let previewConfig = BackgroundPatternConfig.presets.first(where: { $0.patternType == type }) ?? config
                BoardBackgroundView(config: previewConfig)
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                config.patternType == type ? AppTheme.accent : Color.clear,
                                lineWidth: 2.5
                            )
                    )

                Text(type.displayName)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(
                        config.patternType == type ? AppTheme.accent : AppTheme.textSecondary
                    )
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - カラー設定

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("カラー")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
                .textCase(.uppercase)
                .tracking(1)

            VStack(spacing: 16) {
                colorRow(
                    label: config.patternType == .gradient ? "開始色" : "背景色",
                    colorHex: $config.primaryColorHex
                )

                if config.patternType != .solid {
                    colorRow(
                        label: config.patternType == .gradient ? "終了色" : "パターン色",
                        colorHex: $config.secondaryColorHex
                    )
                }
            }
            .padding(16)
            .background(AppTheme.backgroundCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private func colorRow(label: String, colorHex: Binding<String>) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            Spacer()

            ColorPicker(
                "",
                selection: colorBinding(hex: colorHex),
                supportsOpacity: false
            )
            .labelsHidden()
        }
    }

    /// hex文字列とColorのバインディング変換
    private func colorBinding(hex: Binding<String>) -> Binding<Color> {
        Binding<Color>(
            get: { Color(hexString: hex.wrappedValue) },
            set: { newColor in
                hex.wrappedValue = newColor.toHexString()
                onChanged()
            }
        )
    }
}

// MARK: - Color → Hex変換

extension Color {
    func toHexString() -> String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: nil)
        return String(
            format: "%02X%02X%02X",
            Int(round(r * 255)),
            Int(round(g * 255)),
            Int(round(b * 255))
        )
    }
}
