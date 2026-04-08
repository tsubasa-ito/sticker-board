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
    @State private var rotationAngle: Double = 0
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
                            GeometryReader { geometry in
                                Color.clear
                                    .contentShape(Rectangle())
                                    .gesture(
                                        LongPressGesture(minimumDuration: 0.5)
                                            .sequenced(before: DragGesture(minimumDistance: 0))
                                            .onChanged { value in
                                                switch value {
                                                case .second(true, let drag):
                                                    if let drag, !isProcessing {
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
                        .foregroundStyle(AppTheme.secondary)
                        .background {
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(AppTheme.secondary, lineWidth: 2)
                        }
                    }
                    .accessibilityLabel("すべて自動で切り抜く")
                    .accessibilityHint("写真内のすべての被写体を自動的に検出して切り抜きます")
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private func sourceButton(icon: String, title: String, color: Color) -> some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color)
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
                .fill(AppTheme.backgroundCard)
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
                    .accessibilityHidden(true)

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
        .onAppear {
            AccessibilityNotification.Announcement("背景を除去しています").post()
        }
    }

    // MARK: - 結果表示

    private func resultSection(_ image: UIImage) -> some View {
        VStack(spacing: 20) {
            StickerPreviewView(image: image)
                .rotationEffect(.degrees(rotationAngle))
                .animation(.spring(duration: 0.3), value: rotationAngle)

            // 回転ボタン
            HStack(spacing: 12) {
                Button {
                    processedImage = image.rotatedBy90Degrees(clockwise: false)
                    rotationAngle = 0
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
                    rotationAngle = 0
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
                .padding(.vertical, 16)
                .background(AppTheme.accent)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
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
                // まず複数オブジェクト検出を試みる
                let results = try await BackgroundRemover.extractIndividualStickers(from: originalImage)

                guard !Task.isCancelled else { return }

                if results.count > 1 {
                    withAnimation(.spring(duration: 0.5)) {
                        extractedStickers = results
                        self.originalImage = nil
                    }
                } else {
                    // 単一シール: マスク付きで処理（手動調整を可能にする）
                    let result = try await BackgroundRemover.removeBackgroundWithMask(from: originalImage)

                    guard !Task.isCancelled else { return }

                    withAnimation(.spring(duration: 0.5)) {
                        backgroundRemovalResult = result
                        processedImage = result.processedImage
                        self.originalImage = nil
                    }
                }
            } catch {
                if !Task.isCancelled {
                    errorMessage = error.localizedDescription
                }
            }
            if !Task.isCancelled {
                withAnimation { isProcessing = false }
            }
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
        rotationAngle = 0
    }
}
