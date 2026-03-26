import SwiftUI
import PhotosUI
import SwiftData

struct StickerCaptureView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedItem: PhotosPickerItem?
    @State private var originalImage: UIImage?
    @State private var processedImage: UIImage?
    @State private var extractedStickers: [UIImage]?
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showingSaveSuccess = false
    @State private var savedStickerCount = 0
    @State private var animateIn = false
    @State private var showingCamera = false
    @State private var cameraImage: UIImage?
    @State private var backgroundRemovalResult: BackgroundRemovalResult?
    @State private var showingMaskEditor = false
    @State private var maskEditorId = UUID()

    var body: some View {
        ZStack {
            AppTheme.backgroundPrimary
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    if let extractedStickers, extractedStickers.count > 1 {
                        // 複数シール選択
                        MultiStickerSelectionView(images: extractedStickers) { count in
                            savedStickerCount = count
                            resetState()
                            showingSaveSuccess = true
                        }
                    } else if let processedImage {
                        // 切り抜き結果（単一）
                        resultSection(processedImage)
                    } else if isProcessing {
                        processingSection
                    } else {
                        pickerSection
                    }

                    if let errorMessage {
                        errorBanner(errorMessage)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
        }
        .navigationTitle("シール追加")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppTheme.backgroundPrimary, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") { dismiss() }
                    .foregroundStyle(AppTheme.accent)
            }
        }
        .onChange(of: selectedItem) { _, newItem in
            loadImage(from: newItem)
        }
        .onChange(of: cameraImage) { _, newImage in
            guard let newImage else { return }
            withAnimation(.spring(duration: 0.4)) {
                originalImage = newImage
                errorMessage = nil
            }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraView(image: $cameraImage)
                .ignoresSafeArea()
        }
        .fullScreenCover(isPresented: $showingMaskEditor) {
            if let result = backgroundRemovalResult {
                MaskEditorView(
                    originalImage: result.originalImage,
                    maskImage: result.maskImage
                ) { composited, _ in
                    withAnimation(.spring(duration: 0.4)) {
                        processedImage = composited
                    }
                }
                .id(maskEditorId)
            }
        }
        .alert("保存完了!", isPresented: $showingSaveSuccess) {
            Button("続けて追加") { resetState() }
            Button("閉じる") { dismiss() }
        } message: {
            if savedStickerCount > 1 {
                Text("\(savedStickerCount)枚のシールをコレクションに追加しました")
            } else {
                Text("シールをコレクションに追加しました")
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                animateIn = true
            }
        }
    }

    // MARK: - 写真選択セクション

    private var pickerSection: some View {
        VStack(spacing: 20) {
            // シミュレータ注意書き
            if BackgroundRemover.isSimulator {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(AppTheme.cream)
                    Text("シミュレータでは背景除去がスキップされます")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(AppTheme.cream.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            if originalImage == nil {
                // 取得方法の選択
                VStack(spacing: 8) {
                    Text("シールにしたい写真を選ぼう")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                        .scaleEffect(animateIn ? 1 : 0.8)

                    Text("カメラで撮影するか、ライブラリから選択できます")
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(.top, 8)

                // 撮影ガイド
                CaptureGuideTipsView()

                HStack(spacing: 16) {
                    // カメラボタン（カメラ搭載デバイスのみ表示）
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        Button {
                            showingCamera = true
                        } label: {
                            sourceButton(
                                icon: "camera.fill",
                                title: "カメラで撮る",
                                gradient: AppTheme.headerGradient
                            )
                        }
                    }

                    // フォトライブラリボタン
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        sourceButton(
                            icon: "photo.on.rectangle",
                            title: "写真から選ぶ",
                            gradient: AppTheme.mintGradient
                        )
                    }
                }
            }

            // 選択された写真のプレビュー
            if let originalImage {
                VStack(spacing: 16) {
                    Image(uiImage: originalImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)

                    Button {
                        processImage()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "scissors")
                            Text("背景を除去する")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.headerGradient)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private func sourceButton(icon: String, title: String, gradient: LinearGradient) -> some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(gradient)
                    .frame(width: 64, height: 64)

                Image(systemName: icon)
                    .font(.system(size: 26))
                    .foregroundStyle(.white)
            }
            .scaleEffect(animateIn ? 1 : 0.6)

            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.cardGradient)
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            AppTheme.accent.opacity(0.3),
                            style: StrokeStyle(lineWidth: 2, dash: [8, 6])
                        )
                }
        }
    }

    // MARK: - 処理中

    private var processingSection: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 80)

            ZStack {
                Circle()
                    .fill(AppTheme.secondary.opacity(0.15))
                    .frame(width: 100, height: 100)

                ProgressView()
                    .controlSize(.large)
                    .tint(AppTheme.secondary)
            }

            VStack(spacing: 4) {
                Text("背景を除去しています...")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

                Text("AIが被写体を検出しています")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()
        }
    }

    // MARK: - 結果表示

    private func resultSection(_ image: UIImage) -> some View {
        VStack(spacing: 20) {
            StickerPreviewView(image: image)

            // マスク手動調整ボタン
            if backgroundRemovalResult != nil {
                Button {
                    maskEditorId = UUID()
                    showingMaskEditor = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "paintbrush.pointed.fill")
                        Text("手動で調整する")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .foregroundStyle(AppTheme.secondary)
                    .background {
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(AppTheme.secondary, lineWidth: 2)
                    }
                }
            }

            // 保存ボタン
            Button {
                saveSticker(image)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("コレクションに追加")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppTheme.mintGradient)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            Button {
                resetState()
            } label: {
                Text("別の写真を選ぶ")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
    }

    // MARK: - エラー

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(message)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - ロジック

    private func loadImage(from item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                withAnimation(.spring(duration: 0.4)) {
                    originalImage = image
                    errorMessage = nil
                }
            }
        }
    }

    private func processImage() {
        guard let originalImage else { return }
        withAnimation { isProcessing = true }
        errorMessage = nil

        Task {
            do {
                // まず複数オブジェクト検出を試みる
                let results = try await BackgroundRemover.extractIndividualStickers(from: originalImage)
                if results.count > 1 {
                    withAnimation(.spring(duration: 0.5)) {
                        extractedStickers = results
                    }
                } else {
                    // 単一シール: マスク付きで処理（手動調整を可能にする）
                    let result = try await BackgroundRemover.removeBackgroundWithMask(from: originalImage)
                    withAnimation(.spring(duration: 0.5)) {
                        backgroundRemovalResult = result
                        processedImage = result.processedImage
                    }
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            withAnimation { isProcessing = false }
        }
    }

    private func saveSticker(_ image: UIImage) {
        do {
            let fileName = try ImageStorage.save(image)
            let sticker = Sticker(imageFileName: fileName)
            modelContext.insert(sticker)
            savedStickerCount = 1
            showingSaveSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func resetState() {
        selectedItem = nil
        originalImage = nil
        processedImage = nil
        extractedStickers = nil
        cameraImage = nil
        errorMessage = nil
        backgroundRemovalResult = nil
    }
}
