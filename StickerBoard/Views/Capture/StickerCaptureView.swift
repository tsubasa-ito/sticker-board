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
    @State private var showingPaywall = false
    @State private var processingTask: Task<Void, Never>?
    @State private var pressLocation: CGPoint = .zero
    @State private var longPressImageViewSize: CGSize = .zero
    @Query private var allStickers: [Sticker]
    var onStickerSaved: () -> Void = {}

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
                            onStickerSaved()
                        }
                    } else if let processedImage {
                        // 切り抜き結果（単一）
                        resultSection(processedImage)
                    } else if originalImage != nil {
                        // 写真プレビュー（処理中はオーバーレイ表示）
                        pickerSection
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
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") { dismiss() }
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
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
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
        .onDisappear {
            processingTask?.cancel()
            processingTask = nil
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
                        .accessibilityHidden(true)
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
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.accent.opacity(0.06))
                            .frame(width: 96, height: 96)
                        Circle()
                            .fill(AppTheme.accent.opacity(0.12))
                            .frame(width: 72, height: 72)
                        Image(systemName: "scissors")
                            .font(.system(size: 32))
                            .foregroundStyle(AppTheme.accent.opacity(0.8))
                    }
                    .accessibilityHidden(true)
                    .scaleEffect(animateIn ? 1 : 0.6)
                    .opacity(animateIn ? 1 : 0)

                    VStack(spacing: 6) {
                        Text("シールにしたい写真を選ぼう")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                            .scaleEffect(animateIn ? 1 : 0.8)

                        Text("カメラで撮影するか、ライブラリから選択できます")
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
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
                                color: AppTheme.accent
                            )
                        }
                        .accessibilityLabel("カメラで撮る")
                        .accessibilityHint("カメラを起動してシールにする写真を撮影します")
                    }

                    // フォトライブラリボタン
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        sourceButton(
                            icon: "photo.on.rectangle",
                            title: "写真から選ぶ",
                            color: AppTheme.secondary
                        )
                    }
                    .accessibilityLabel("写真から選ぶ")
                    .accessibilityHint("フォトライブラリからシールにする写真を選択します")
                }
            }

            // 選択された写真のプレビュー
            if let originalImage {
                VStack(spacing: 16) {
                    // 長押し選択の案内
                    HStack(spacing: 8) {
                        Image(systemName: "hand.tap.fill")
                            .foregroundStyle(AppTheme.accent)
                            .accessibilityHidden(true)
                        Text("シールにしたい被写体を長押しで選択")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.accent.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    Image(uiImage: originalImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 280)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                        .overlay {
                            if isProcessing {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.black.opacity(0.5))
                                    VStack(spacing: 12) {
                                        ProgressView()
                                            .controlSize(.large)
                                            .tint(.white)
                                        Text("背景を除去しています...")
                                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                                            .foregroundStyle(.white)
                                        Text("AIが被写体を検出しています")
                                            .font(.system(size: 12, design: .rounded))
                                            .foregroundStyle(.white.opacity(0.7))
                                    }
                                }
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel("背景を除去しています。しばらくお待ちください")
                                .onAppear {
                                    AccessibilityNotification.Announcement("背景を除去しています").post()
                                }
                            }
                        }
                        .overlay {
                            if !isProcessing {
                                GeometryReader { geometry in
                                    Color.clear
                                        .contentShape(Rectangle())
                                        .gesture(
                                            LongPressGesture(minimumDuration: 0.5)
                                                .sequenced(before: DragGesture(minimumDistance: 0))
                                                .onChanged { value in
                                                    switch value {
                                                    case .second(true, let drag):
                                                        if let drag {
                                                            pressLocation = drag.startLocation
                                                            longPressImageViewSize = geometry.size
                                                            let generator = UIImpactFeedbackGenerator(style: .medium)
                                                            generator.impactOccurred()
                                                            processImageAtPoint()
                                                        }
                                                    default:
                                                        break
                                                    }
                                                }
                                        )
                                }
                            }
                        }
                        .accessibilityLabel("選択した写真のプレビュー")
                        .accessibilityHint("被写体を長押しして選択できます")
                        .accessibilityAction(named: "すべて自動で切り抜く") {
                            processImage()
                        }

                    Button {
                        processImage()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "scissors")
                                .accessibilityHidden(true)
                            Text("すべて自動で切り抜く")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .foregroundStyle(isProcessing ? AppTheme.secondary.opacity(0.4) : AppTheme.secondary)
                        .background {
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(isProcessing ? AppTheme.secondary.opacity(0.4) : AppTheme.secondary, lineWidth: 2)
                        }
                    }
                    .disabled(isProcessing)
                    .accessibilityLabel("すべて自動で切り抜く")
                    .accessibilityHint("写真内のすべての被写体を自動的に検出して切り抜きます")
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private func sourceButton(icon: String, title: LocalizedStringKey, color: Color) -> some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 78, height: 78)
                Circle()
                    .fill(color.opacity(0.18))
                    .frame(width: 60, height: 60)
                Image(systemName: icon)
                    .font(.system(size: 26))
                    .foregroundStyle(color)
            }
            .scaleEffect(animateIn ? 1 : 0.6)

            Text(title)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(color.opacity(0.05), in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: color.opacity(0.18), radius: 10, x: 0, y: 4)
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(color.opacity(0.2), lineWidth: 1.5)
        }
    }

    // MARK: - 処理中

    private var processingSection: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 80)

            ZStack {
                Circle()
                    .fill(AppTheme.secondary.opacity(0.08))
                    .frame(width: 116, height: 116)
                Circle()
                    .fill(AppTheme.secondary.opacity(0.15))
                    .frame(width: 88, height: 88)
                ProgressView()
                    .controlSize(.large)
                    .tint(AppTheme.secondary)
            }
            .accessibilityHidden(true)

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
        .onAppear {
            AccessibilityNotification.Announcement("背景を除去しています").post()
        }
    }

    // MARK: - 結果表示

    private func resultSection(_ image: UIImage) -> some View {
        VStack(spacing: 20) {
            StickerPreviewView(image: image)

            // 回転ボタン
            HStack(spacing: 12) {
                Button {
                    processedImage = image.rotatedBy90Degrees(clockwise: false)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "rotate.left")
                            .accessibilityHidden(true)
                        Text("左に回転")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundStyle(AppTheme.secondary)
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(AppTheme.secondary.opacity(0.6), lineWidth: 1.5)
                    }
                }
                .accessibilityLabel("左に90度回転")
                .accessibilityHint("シールを反時計回りに90度回転します")

                Button {
                    processedImage = image.rotatedBy90Degrees(clockwise: true)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "rotate.right")
                            .accessibilityHidden(true)
                        Text("右に回転")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundStyle(AppTheme.secondary)
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(AppTheme.secondary.opacity(0.6), lineWidth: 1.5)
                    }
                }
                .accessibilityLabel("右に90度回転")
                .accessibilityHint("シールを時計回りに90度回転します")
            }

            // マスク手動調整ボタン
            if backgroundRemovalResult != nil {
                Button {
                    maskEditorId = UUID()
                    showingMaskEditor = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "paintbrush.pointed.fill")
                            .accessibilityHidden(true)
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
                .accessibilityLabel("手動で調整する")
                .accessibilityHint("マスクエディタを開いて切り抜き範囲を手動で調整します")
            }

            // 保存ボタン
            Button {
                saveSticker(image)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .accessibilityHidden(true)
                    Text("コレクションに追加")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(AppTheme.accent)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: AppTheme.accent.opacity(0.4), radius: 12, x: 0, y: 6)
            }
            .accessibilityLabel("コレクションに追加")
            .accessibilityHint("切り抜いたシールをコレクションに保存します")

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
                .accessibilityHidden(true)
            Text(message)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear {
            AccessibilityNotification.Announcement("エラー: \(message)").post()
        }
    }

    // MARK: - ロジック

    private func loadImage(from item: PhotosPickerItem?) {
        guard let item else { return }
        processingTask?.cancel()
        processingTask = Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                guard !Task.isCancelled else { return }
                withAnimation(.spring(duration: 0.4)) {
                    originalImage = image
                    errorMessage = nil
                }
            }
        }
    }

    private func processImageAtPoint() {
        guard let originalImage else { return }
        guard longPressImageViewSize != .zero else { return }
        let normalizedPoint = convertToNormalizedImagePoint(
            pressLocation,
            imageSize: originalImage.size,
            viewSize: longPressImageViewSize
        )
        withAnimation { isProcessing = true }
        errorMessage = nil

        processingTask?.cancel()
        processingTask = Task {
            do {
                let result = try await BackgroundRemover.removeBackgroundAtPoint(
                    from: originalImage,
                    normalizedPoint: normalizedPoint
                )

                guard !Task.isCancelled else { return }

                withAnimation(.spring(duration: 0.5)) {
                    backgroundRemovalResult = result
                    processedImage = result.processedImage
                    self.originalImage = nil
                }
            } catch {
                if !Task.isCancelled {
                    if (error as? BackgroundRemoverError) == .noSubjectAtPoint {
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.warning)
                    }
                    errorMessage = error.localizedDescription
                }
            }
            if !Task.isCancelled {
                withAnimation { isProcessing = false }
            }
        }
    }

    /// ビュー座標を画像の正規化座標（0-1）に変換する
    private func convertToNormalizedImagePoint(_ viewPoint: CGPoint, imageSize: CGSize, viewSize: CGSize) -> CGPoint {
        let imageAspect = imageSize.width / imageSize.height
        let viewAspect = viewSize.width / viewSize.height

        let displayRect: CGRect
        if imageAspect > viewAspect {
            // 画像の方が横長 → 幅にフィット、上下中央
            let displayWidth = viewSize.width
            let displayHeight = displayWidth / imageAspect
            let yOffset = (viewSize.height - displayHeight) / 2
            displayRect = CGRect(x: 0, y: yOffset, width: displayWidth, height: displayHeight)
        } else {
            // 画像の方が縦長 → 高さにフィット、左右中央
            let displayHeight = viewSize.height
            let displayWidth = displayHeight * imageAspect
            let xOffset = (viewSize.width - displayWidth) / 2
            displayRect = CGRect(x: xOffset, y: 0, width: displayWidth, height: displayHeight)
        }

        let normalizedX = (viewPoint.x - displayRect.minX) / displayRect.width
        let normalizedY = (viewPoint.y - displayRect.minY) / displayRect.height

        return CGPoint(
            x: max(0, min(1, normalizedX)),
            y: max(0, min(1, normalizedY))
        )
    }

    private func processImage() {
        guard let originalImage else { return }
        withAnimation { isProcessing = true }
        errorMessage = nil

        processingTask?.cancel()
        processingTask = Task {
            do {
                let result = try await BackgroundRemover.processForCapture(from: originalImage)

                guard !Task.isCancelled else { return }

                switch result {
                case .singleSticker(let bgResult):
                    withAnimation(.spring(duration: 0.5)) {
                        backgroundRemovalResult = bgResult
                        processedImage = bgResult.processedImage
                        self.originalImage = nil
                    }
                case .multipleStickers(let stickers):
                    withAnimation(.spring(duration: 0.5)) {
                        extractedStickers = stickers
                        self.originalImage = nil
                    }
                }
            } catch {
                if !Task.isCancelled {
                    errorMessage = error.localizedDescription
                }
            }
            withAnimation { isProcessing = false }
        }
    }

    private func saveSticker(_ image: UIImage) {
        if !SubscriptionManager.shared.isProUser && allStickers.count >= 30 {
            showingPaywall = true
            return
        }
        do {
            let fileName = try ImageStorage.save(image)
            let sticker = Sticker(imageFileName: fileName)
            modelContext.insert(sticker)
            savedStickerCount = 1
            showingSaveSuccess = true
            onStickerSaved()
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
