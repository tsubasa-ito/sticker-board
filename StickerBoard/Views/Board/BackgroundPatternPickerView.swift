import SwiftUI
import PhotosUI

/// 背景パターン選択シート
struct BackgroundPatternPickerView: View {
    @Binding var config: BackgroundPatternConfig
    @Environment(\.dismiss) private var dismiss
    @State private var showingPaywall = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isLoadingPhoto = false
    @State private var customImage: UIImage?

    private static let premiumPatterns: Set<BackgroundPatternType> = [.stripe, .gradient]

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
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") {
                        let needsPro = Self.premiumPatterns.contains(config.patternType) || config.patternType == .custom
                        if !SubscriptionManager.shared.isProUser && needsPro {
                            showingPaywall = true
                        } else {
                            dismiss()
                        }
                    }
                    .fontWeight(.bold)
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                guard let newItem else { return }
                isLoadingPhoto = true
                Task.detached(priority: .userInitiated) {
                    let data = try? await newItem.loadTransferable(type: Data.self)
                    guard let data, let image = UIImage(data: data) else {
                        await MainActor.run { isLoadingPhoto = false }
                        return
                    }
                    // 以前のカスタム背景画像を削除
                    let oldFileName = await MainActor.run { config.customImageFileName }
                    if let oldFileName {
                        BackgroundImageStorage.delete(fileName: oldFileName)
                    }
                    guard let fileName = try? BackgroundImageStorage.save(image) else {
                        await MainActor.run { isLoadingPhoto = false }
                        return
                    }
                    let loaded = BackgroundImageStorage.load(fileName: fileName)
                    await MainActor.run {
                        config.patternType = .custom
                        config.customImageFileName = fileName
                        customImage = loaded
                        isLoadingPhoto = false
                    }
                }
            }
            .onAppear {
                if config.patternType == .custom, let fileName = config.customImageFileName {
                    customImage = BackgroundImageStorage.load(fileName: fileName)
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

            BoardBackgroundView(config: config, customImage: customImage)
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
                ForEach(BackgroundPatternType.pickerCases) { type in
                    patternTypeButton(type)
                }

                // 写真を選択ボタン（Pro限定）
                customPhotoButton
            }
        }
    }

    private var customPhotoButton: some View {
        Group {
            if SubscriptionManager.shared.isProUser {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    customPhotoButtonLabel
                }
            } else {
                Button {
                    showingPaywall = true
                } label: {
                    customPhotoButtonLabel
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var customPhotoButtonLabel: some View {
        VStack(spacing: 8) {
            ZStack {
                if let customImage, config.patternType == .custom {
                    Image(uiImage: customImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 56, height: 56)
                        .clipped()
                } else {
                    AppTheme.editorBackground
                }

                if isLoadingPhoto {
                    ProgressView()
                } else if !(config.patternType == .custom && customImage != nil) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 18))
                        .foregroundStyle(AppTheme.textTertiary)
                }
            }
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        config.patternType == .custom ? AppTheme.accent : Color.clear,
                        lineWidth: 2.5
                    )
            )
            .overlay(alignment: .topTrailing) {
                if !SubscriptionManager.shared.isProUser {
                    ProBadge()
                        .offset(x: 6, y: -6)
                }
            }

            Text("写真")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(
                    config.patternType == .custom ? AppTheme.accent : AppTheme.textSecondary
                )
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }

    private func patternTypeButton(_ type: BackgroundPatternType) -> some View {
        let isPremium = Self.premiumPatterns.contains(type)
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                if let preset = BackgroundPatternConfig.presets.first(where: { $0.patternType == type }) {
                    config = preset
                } else {
                    config.patternType = type
                }
            }
        } label: {
            VStack(spacing: 8) {
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
                    .overlay(alignment: .topTrailing) {
                        if isPremium && !SubscriptionManager.shared.isProUser {
                            ProBadge()
                                .offset(x: 6, y: -6)
                        }
                    }

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

    @ViewBuilder
    private var colorSection: some View {
        if config.patternType != .custom {
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
            }
        )
    }
}
