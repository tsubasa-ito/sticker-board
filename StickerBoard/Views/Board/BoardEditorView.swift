import SwiftUI
import SwiftData
import Photos

struct BoardEditorView: View {
    @Bindable var board: Board
    @Query(sort: \Sticker.createdAt, order: .reverse) private var allStickers: [Sticker]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.displayScale) private var displayScale
    @Environment(\.dismiss) private var dismiss

    @State private var placements: [StickerPlacement] = []
    @State private var selectedPlacementId: UUID?
    @State private var showingStickerPicker = false
    @State private var showingSaveConfirmation = false
    @State private var showingSaveResult = false
    @State private var saveResultSuccess = false
    @State private var canvasSize: CGSize = .zero
    @State private var showHint = true
    @State private var bottomBarExpanded = true
    @State private var showQuickPicks = false
    @State private var showingBackgroundPicker = false
    @State private var backgroundConfig: BackgroundPatternConfig = .default
    @State private var customBackgroundImage: UIImage?
    @State private var showingFilterPicker = false
    @State private var showingBorderPicker = false
    @State private var loadedImages: [UUID: UIImage] = [:]
    @State private var rebuildTask: Task<Void, Never>?
    @State private var updateTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            // 背景（グレー + 微細ドットグリッド）
            editorBackground

            // メインコンテンツ
            VStack(spacing: 0) {
                canvasArea
            }

            // フローティングUI（折りたたみ可能）
            VStack(spacing: 0) {
                Spacer()

                if bottomBarExpanded {
                    // 折りたたみハンドル
                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            bottomBarExpanded = false
                            showQuickPicks = false
                        }
                    } label: {
                        VStack(spacing: 2) {
                            Capsule()
                                .fill(AppTheme.textTertiary.opacity(0.4))
                                .frame(width: 36, height: 4)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(AppTheme.textTertiary)
                        }
                        .frame(height: 24)
                        .frame(maxWidth: .infinity)
                    }

                    if showQuickPicks && !allStickers.isEmpty {
                        stickerQuickPicks
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    floatingToolbar
                        .padding(.horizontal, 16)
                        .padding(.bottom, 10)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    // 折りたたみ時: 小さな展開ボタン
                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            bottomBarExpanded = true
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.up")
                                .font(.system(size: 12, weight: .bold))
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 14))
                        }
                        .foregroundStyle(AppTheme.textSecondary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
                    }
                    .padding(.bottom, 16)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(duration: 0.3), value: bottomBarExpanded)
            .animation(.spring(duration: 0.3), value: showQuickPicks)

            // ヒントトースト
            if showHint && !placements.isEmpty {
                VStack {
                    hintToast
                        .padding(.top, 16)
                    Spacer()
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .navigationTitle(board.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppTheme.editorBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AppTheme.textPrimary)
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingSaveConfirmation = true
                } label: {
                    Image(systemName: "arrow.down.to.line")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .disabled(placements.isEmpty)
                .opacity(placements.isEmpty ? 0.4 : 1)
            }
        }
        .sheet(isPresented: $showingStickerPicker) {
            StickerPickerSheet(stickers: allStickers) { sticker in
                addStickerToBoard(sticker)
            }
        }
        .sheet(isPresented: $showingBackgroundPicker, onDismiss: {
            board.backgroundPattern = backgroundConfig
            loadCustomBackgroundImage()
            saveBoard()
        }) {
            BackgroundPatternPickerView(config: $backgroundConfig)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showingFilterPicker) {
            if let id = selectedPlacementId,
               let index = placements.firstIndex(where: { $0.id == id }) {
                PlacementFilterPickerSheet(placement: $placements[index]) {
                    if let placement = placements.first(where: { $0.id == id }) {
                        updateProcessedCache(for: placement)
                    }
                    saveBoard()
                }
                .presentationDetents([.medium])
            }
        }
        .sheet(isPresented: $showingBorderPicker) {
            if let id = selectedPlacementId,
               let index = placements.firstIndex(where: { $0.id == id }) {
                PlacementBorderPickerSheet(placement: $placements[index]) {
                    if let placement = placements.first(where: { $0.id == id }) {
                        updateProcessedCache(for: placement)
                    }
                    saveBoard()
                }
                .presentationDetents([.medium, .large])
            }
        }
        .alert("写真を保存", isPresented: $showingSaveConfirmation) {
            Button("保存") {
                saveBoardAsImage()
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("ボードを写真に保存しますか？")
        }
        .alert(
            saveResultSuccess ? "保存完了" : "エラー",
            isPresented: $showingSaveResult
        ) {
            Button("OK") {}
        } message: {
            Text(saveResultSuccess
                 ? "ボードを写真に保存しました"
                 : "写真の保存に失敗しました。設定から写真へのアクセスを許可してください。")
        }
        .onAppear {
            placements = board.placements
            backgroundConfig = board.backgroundPattern
            loadCustomBackgroundImage()
            rebuildFilterCache()
        }
        .onDisappear {
            rebuildTask?.cancel()
            updateTask?.cancel()
            saveBoard()
            loadedImages = [:]
        }
        .task {
            try? await Task.sleep(for: .seconds(3))
            withAnimation(.easeOut(duration: 0.5)) { showHint = false }
        }
    }

    // MARK: - 背景

    private var editorBackground: some View {
        ZStack {
            AppTheme.editorBackground
                .ignoresSafeArea()

            Canvas { context, size in
                let spacing: CGFloat = 40
                let dotSize: CGFloat = 1.5
                let rows = Int(size.height / spacing) + 1
                let cols = Int(size.width / spacing) + 1

                for row in 0..<rows {
                    for col in 0..<cols {
                        let point = CGPoint(
                            x: CGFloat(col) * spacing + spacing / 2,
                            y: CGFloat(row) * spacing + spacing / 2
                        )
                        context.fill(
                            Path(ellipseIn: CGRect(
                                x: point.x - dotSize / 2,
                                y: point.y - dotSize / 2,
                                width: dotSize,
                                height: dotSize
                            )),
                            with: .color(AppTheme.editorDark.opacity(0.03))
                        )
                    }
                }
            }
            .ignoresSafeArea()
        }
    }

    // MARK: - キャンバスエリア

    private var canvasArea: some View {
        ZStack {
            // ボードカード（背景パターン付き）
            BoardBackgroundView(config: backgroundConfig, customImage: customBackgroundImage)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.08), radius: 20, y: 4)
                .padding(24)

            // タップで選択解除
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedPlacementId = nil
                    }
                }

            // 空の場合のヒント
            if placements.isEmpty {
                emptyCanvasHint
            }

            // 配置されたシール
            ForEach(sortedPlacements) { placement in
                StickerItemView(
                    placement: binding(for: placement),
                    image: loadedImages[placement.id],
                    isSelected: selectedPlacementId == placement.id,
                    onTap: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedPlacementId = placement.id
                        }
                    },
                    onGestureEnded: {
                        saveBoard()
                    }
                )
                .zIndex(Double(placement.zIndex))
            }
        }
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        } action: { newSize in
            canvasSize = newSize
        }
    }

    // MARK: - 空のヒント

    private var emptyCanvasHint: some View {
        VStack(spacing: 12) {
            Image(systemName: "hand.tap")
                .font(.system(size: 36))
                .foregroundStyle(AppTheme.textTertiary)

            Text("下の＋からシールを追加")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textTertiary)
        }
    }

    // MARK: - ヒントトースト

    private var hintToast: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 12))
            Text("ドラッグで移動。ピンチでサイズ変更")
                .font(.system(size: 12, weight: .medium, design: .rounded))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(AppTheme.editorDark.opacity(0.9))
        )
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
    }

    // MARK: - シールクイックピック

    private var stickerQuickPicks: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(allStickers) { sticker in
                    Button {
                        addStickerToBoard(sticker)
                    } label: {
                        QuickPickThumbnail(fileName: sticker.imageFileName)
                    }
                }

                // 全て見るボタン
                Button {
                    showQuickPicks = false
                    showingStickerPicker = true
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "square.grid.2x2")
                            .font(.system(size: 18))
                        Text("全て")
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                    }
                    .foregroundStyle(AppTheme.textSecondary)
                    .frame(width: 64, height: 64)
                    .background(AppTheme.editorBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
        }
        .frame(height: 80)
    }

    // MARK: - フローティングツールバー

    private var floatingToolbar: some View {
        HStack(spacing: 10) {
            // 追加
            toolbarButton(icon: "plus.circle.fill", label: "追加", color: AppTheme.accent) {
                withAnimation(.spring(duration: 0.3)) {
                    showQuickPicks.toggle()
                }
            }

            // 背景
            toolbarButton(icon: "paintpalette.fill", label: "背景", color: AppTheme.secondary) {
                showingBackgroundPicker = true
            }

            // 効果・枠線グループ
            toolbarGroup {
                toolbarButton(icon: "wand.and.stars", label: "効果",
                              color: selectedPlacementId != nil ? AppTheme.accent : AppTheme.textTertiary) {
                    showingFilterPicker = true
                }
                .disabled(selectedPlacementId == nil)

                toolbarButton(icon: "square.dashed", label: "枠線",
                              color: selectedPlacementId != nil ? AppTheme.accent : AppTheme.textTertiary) {
                    showingBorderPicker = true
                }
                .disabled(selectedPlacementId == nil)
            }

            // レイヤー操作グループ
            toolbarGroup {
                toolbarButton(icon: "square.2.layers.3d.top.filled", label: "前面",
                              color: selectedPlacementId != nil ? AppTheme.textPrimary : AppTheme.textTertiary) {
                    applyToSelected { bringToFront($0) }
                }
                .disabled(selectedPlacementId == nil)

                toolbarButton(icon: "square.2.layers.3d.bottom.filled", label: "背面",
                              color: selectedPlacementId != nil ? AppTheme.textPrimary : AppTheme.textTertiary) {
                    applyToSelected { sendToBack($0) }
                }
                .disabled(selectedPlacementId == nil)
            }

            // 削除
            toolbarButton(icon: "trash", label: "削除",
                          color: selectedPlacementId != nil ? .red : AppTheme.textTertiary) {
                if let id = selectedPlacementId,
                   let placement = placements.first(where: { $0.id == id }) {
                    withAnimation {
                        removeFromBoard(placement)
                        selectedPlacementId = nil
                    }
                }
            }
            .disabled(selectedPlacementId == nil)
        }
        .padding(.horizontal, 12)
        .frame(height: 64)
        .frame(maxWidth: .infinity)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.12), radius: 16, y: 4)
                .overlay(
                    Capsule()
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private func toolbarButton(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(color)
                    .frame(height: 24)
                Text(label)
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func toolbarGroup<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 4) {
            content()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.editorBackground.opacity(0.5))
        )
    }

    // MARK: - ロジック

    private var sortedPlacements: [StickerPlacement] {
        placements.sorted { $0.zIndex < $1.zIndex }
    }

    private func binding(for placement: StickerPlacement) -> Binding<StickerPlacement> {
        guard let index = placements.firstIndex(where: { $0.id == placement.id }) else {
            fatalError("Placement not found")
        }
        return $placements[index]
    }

    private func rebuildFilterCache() {
        rebuildTask?.cancel()
        let cache = ImageCacheManager.shared
        let currentPlacements = placements
        rebuildTask = Task.detached {
            var result: [UUID: UIImage] = [:]
            for placement in currentPlacements {
                guard !Task.isCancelled else { return }
                if let image = cache.processed(
                    for: placement.imageFileName,
                    filter: placement.filter,
                    borderWidth: placement.borderWidth,
                    borderColorHex: placement.borderColorHex
                ) {
                    result[placement.id] = image
                }
            }
            guard !Task.isCancelled else { return }
            await MainActor.run {
                result.merge(loadedImages) { _, existing in existing }
                let currentIds = Set(placements.map(\.id))
                loadedImages = result.filter { currentIds.contains($0.key) }
            }
        }
    }

    private func updateProcessedCache(for placement: StickerPlacement) {
        updateTask?.cancel()
        let cache = ImageCacheManager.shared
        let fileName = placement.imageFileName
        let filter = placement.filter
        let borderWidth = placement.borderWidth
        let borderColorHex = placement.borderColorHex
        let placementId = placement.id
        updateTask = Task.detached {
            if let processed = cache.processed(
                for: fileName,
                filter: filter,
                borderWidth: borderWidth,
                borderColorHex: borderColorHex
            ) {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    loadedImages[placementId] = processed
                }
            }
        }
    }

    private func addStickerToBoard(_ sticker: Sticker) {
        let maxZ = placements.map(\.zIndex).max() ?? -1
        let placement = StickerPlacement(
            stickerId: sticker.id,
            imageFileName: sticker.imageFileName,
            positionX: 0,
            positionY: 0,
            scale: 1.0,
            rotation: 0,
            zIndex: maxZ + 1
        )
        placements.append(placement)
        selectedPlacementId = placement.id
        if let image = ImageCacheManager.shared.fullResolution(for: sticker.imageFileName) {
            loadedImages[placement.id] = image
        }
        saveBoard()
    }

    private func applyToSelected(_ action: (StickerPlacement) -> Void) {
        guard let id = selectedPlacementId,
              let placement = placements.first(where: { $0.id == id }) else { return }
        action(placement)
    }

    // MARK: - Z軸操作

    private func reorderAndNormalizeZIndex(for placement: StickerPlacement, moveToFront: Bool) {
        guard let targetIndex = placements.firstIndex(where: { $0.id == placement.id }) else { return }

        var sortedIndices = placements.indices.sorted { placements[$0].zIndex < placements[$1].zIndex }

        if let position = sortedIndices.firstIndex(of: targetIndex) {
            let index = sortedIndices.remove(at: position)
            if moveToFront {
                sortedIndices.append(index)
            } else {
                sortedIndices.insert(index, at: 0)
            }
        }

        for (newZ, originalIndex) in sortedIndices.enumerated() {
            placements[originalIndex].zIndex = newZ
        }
        saveBoard()
    }

    private func bringToFront(_ placement: StickerPlacement) {
        reorderAndNormalizeZIndex(for: placement, moveToFront: true)
    }

    private func sendToBack(_ placement: StickerPlacement) {
        reorderAndNormalizeZIndex(for: placement, moveToFront: false)
    }

    private func removeFromBoard(_ placement: StickerPlacement) {
        loadedImages.removeValue(forKey: placement.id)
        placements.removeAll { $0.id == placement.id }
        saveBoard()
    }

    private func saveBoard() {
        board.placements = placements
        board.updatedAt = Date()
        try? modelContext.save()
    }

    private func loadCustomBackgroundImage() {
        if backgroundConfig.patternType == .custom,
           let fileName = backgroundConfig.customImageFileName {
            customBackgroundImage = BackgroundImageStorage.load(fileName: fileName)
        } else {
            customBackgroundImage = nil
        }
    }

    // MARK: - 画像として保存

    private func saveBoardAsImage() {
        let content = BoardSnapshotView(placements: sortedPlacements, size: canvasSize, backgroundConfig: backgroundConfig, customBackgroundImage: customBackgroundImage, showWatermark: !SubscriptionManager.shared.isProUser)

        let renderer = ImageRenderer(content: content)
        renderer.scale = displayScale

        guard let image = renderer.uiImage else {
            saveResultSuccess = false
            showingSaveResult = true
            return
        }

        Task {
            let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            guard status == .authorized else {
                saveResultSuccess = false
                showingSaveResult = true
                return
            }
            do {
                try await PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                }
                saveResultSuccess = true
            } catch {
                saveResultSuccess = false
            }
            showingSaveResult = true
        }
    }
}

// MARK: - クイックピックサムネイル（非同期画像読み込み）

private struct QuickPickThumbnail: View {
    let fileName: String
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppTheme.editorBackground)
                    .frame(width: 56, height: 56)
            }
        }
        .padding(4)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        .task {
            image = await Task.detached {
                ImageStorage.loadThumbnail(fileName: fileName, size: 112)
            }.value
        }
    }
}

// MARK: - ボードスナップショット（画像書き出し用）

private struct BoardSnapshotView: View {
    let placements: [StickerPlacement]
    let size: CGSize
    var backgroundConfig: BackgroundPatternConfig = .default
    var customBackgroundImage: UIImage?
    var showWatermark: Bool = false

    var body: some View {
        ZStack {
            BoardBackgroundView(config: backgroundConfig, customImage: customBackgroundImage)

            ForEach(placements) { placement in
                if let displayImage = ImageCacheManager.shared.processed(for: placement.imageFileName, filter: placement.filter, borderWidth: placement.borderWidth, borderColorHex: placement.borderColorHex) {
                    Image(uiImage: displayImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
                        .scaleEffect(placement.scale)
                        .rotationEffect(.radians(placement.rotation))
                        .offset(x: placement.positionX, y: placement.positionY)
                }
            }

            if showWatermark {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("シールボード")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(.black.opacity(0.3)))
                            .padding(10)
                    }
                }
            }
        }
        .frame(width: size.width, height: size.height)
        .clipped()
    }
}

// MARK: - 配置フィルター選択シート

private struct PlacementFilterPickerSheet: View {
    @Binding var placement: StickerPlacement
    var onApply: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFilter: StickerFilter = .original
    @State private var originalImage: UIImage?

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundPrimary
                    .ignoresSafeArea()

                if let originalImage {
                    ScrollView {
                        StickerFilterPickerView(
                            originalImage: originalImage,
                            selectedFilter: $selectedFilter
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    }
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("フィルター変更")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("適用") {
                        placement.filter = selectedFilter
                        onApply()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                selectedFilter = placement.filter
                originalImage = ImageStorage.load(fileName: placement.imageFileName)
            }
        }
    }
}

// MARK: - 枠線設定シート

private struct PlacementBorderPickerSheet: View {
    @Binding var placement: StickerPlacement
    var onApply: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedWidth: StickerBorderWidth = .none
    @State private var selectedColorHex: String = "FFFFFF"
    @State private var originalImage: UIImage?
    @State private var showingPaywall = false

    private var isPremiumWidth: Bool {
        [StickerBorderWidth.medium, .thick].contains(selectedWidth)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundPrimary
                    .ignoresSafeArea()

                if originalImage != nil {
                    ScrollView {
                        StickerBorderPickerView(
                            selectedWidth: $selectedWidth,
                            selectedColorHex: $selectedColorHex,
                            originalImage: originalImage
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    }
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("枠線設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("適用") {
                        if !SubscriptionManager.shared.isProUser && isPremiumWidth {
                            showingPaywall = true
                        } else {
                            placement.borderWidth = selectedWidth
                            placement.borderColorHex = selectedColorHex
                            onApply()
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .onAppear {
                selectedWidth = placement.borderWidth
                selectedColorHex = placement.borderColorHex
                originalImage = ImageStorage.load(fileName: placement.imageFileName)
            }
        }
    }
}

// MARK: - シール選択シート

struct StickerPickerSheet: View {
    let stickers: [Sticker]
    let onSelect: (Sticker) -> Void
    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.adaptive(minimum: 80), spacing: 14)]

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundPrimary
                    .ignoresSafeArea()

                Group {
                    if stickers.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "star.slash")
                                .font(.system(size: 36))
                                .foregroundStyle(AppTheme.textTertiary)

                            Text("シールがありません")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)

                            Text("先にホームからシールを追加してください")
                                .font(.system(size: 13, design: .rounded))
                                .foregroundStyle(AppTheme.textTertiary)
                        }
                    } else {
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 14) {
                                ForEach(stickers) { sticker in
                                    Button {
                                        onSelect(sticker)
                                        dismiss()
                                    } label: {
                                        StickerThumbnailView(sticker: sticker)
                                    }
                                }
                            }
                            .padding(20)
                        }
                    }
                }
            }
            .navigationTitle("シールを選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }
}
