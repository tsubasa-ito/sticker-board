import SwiftUI
import SwiftData
import Photos
import os

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
    @State private var widgetSyncTask: Task<Void, Never>?
    @State private var widgetSyncDebounceTask: Task<Void, Never>?
    @State private var hasPerformedInitialSync = false
    @State private var undoStack: [(placements: [StickerPlacement], backgroundConfig: BackgroundPatternConfig)] = []

    private let undoStackLimit = 20

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
                    .accessibilityLabel("ツールバーを折りたたむ")
                    .accessibilityHint("ツールバーを非表示にします")

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
                    .accessibilityLabel("ツールバーを展開")
                    .accessibilityHint("ツールバーを表示します")
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
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    undoLastAction()
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(undoStack.isEmpty ? AppTheme.textTertiary : AppTheme.accent)
                }
                .accessibilityLabel(String(localized: "元に戻す"))
                .disabled(undoStack.isEmpty)

                Button {
                    shareBoardAsImage()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(placements.isEmpty ? AppTheme.textTertiary : AppTheme.accent)
                }
                .accessibilityLabel(String(localized: "共有"))
                .disabled(placements.isEmpty)

                Button {
                    showingSaveConfirmation = true
                } label: {
                    Image(systemName: "arrow.down.to.line")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(placements.isEmpty ? AppTheme.textTertiary : AppTheme.accent)
                }
                .accessibilityLabel(String(localized: "写真に保存"))
                .disabled(placements.isEmpty)
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
                .presentationDetents([.large])
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
                Task { await saveBoardAsImage() }
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
            widgetSyncTask?.cancel()
            widgetSyncDebounceTask?.cancel()
            board.placements = placements
            board.updatedAt = Date()
            try? modelContext.save()
            syncBoardToWidget()
            loadedImages = [:]
        }
        .onChange(of: canvasSize) { oldSize, newSize in
            // キャンバスの初回レンダリング時（.zero → 実サイズ）にウィジェット同期を実行。
            // アルゴリズム変更後の旧スナップショットが残らないようにする。
            guard oldSize == .zero, newSize != .zero, !hasPerformedInitialSync else { return }
            hasPerformedInitialSync = true
            syncBoardToWidget()
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

    @ViewBuilder
    private var canvasArea: some View {
        switch board.boardType {
        case .widgetLarge:
            boardCanvasZStack
                .aspectRatio(BoardType.widgetLargeAspectRatio, contentMode: .fit)
        case .widgetMedium:
            boardCanvasZStack
                .aspectRatio(BoardType.widgetMediumAspectRatio, contentMode: .fit)
        case .widgetSmall:
            // aspectRatio(1.0, .fit) が ZStack 内で意図通りに機能しないケースを防ぐため
            // screenBounds から明示的に正方形の frame を算出して適用する
            boardCanvasZStack
                .frame(width: widgetSmallCanvasSide, height: widgetSmallCanvasSide)
        case .standard:
            boardCanvasZStack
        }
    }

    /// widgetSmall キャンバスの一辺（正方形）。親 VStack が縦方向サイズを確定できないため
    /// aspectRatio(1.0, .fit) が機能しないケースがあり、screenBounds.width で明示指定する
    private var widgetSmallCanvasSide: CGFloat {
        let w = AppTheme.screenBounds.width
        // screenBounds が未確定（シーン起動直後など）の場合は iPhone 15 Pro 幅をフォールバックに使用
        return w > 0 ? w : 393
    }

    private var boardCanvasZStack: some View {
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
                    onGestureStarted: {
                        saveUndoSnapshot()
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
        .overlay(alignment: .topTrailing) {
            if board.boardType != .standard {
                widgetBadge
            }
        }
    }

    private var widgetBadge: some View {
        let label: LocalizedStringKey = {
            switch board.boardType {
            case .widgetLarge: return "ウィジェット大"
            case .widgetMedium: return "ウィジェット中"
            case .widgetSmall: return "ウィジェット小"
            default: return "ウィジェット"
            }
        }()
        return Label(label, systemImage: "apps.iphone")
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(AppTheme.accent.opacity(0.85), in: Capsule())
            .padding(.top, 32)
            .padding(.trailing, 32)
            .accessibilityHidden(true)
    }

    // MARK: - 空のヒント

    private var emptyCanvasHint: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppTheme.accent.opacity(0.1))
                    .frame(width: 72, height: 72)
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 38))
                    .foregroundStyle(AppTheme.accent.opacity(0.5))
            }

            VStack(spacing: 4) {
                Text("シールを追加しよう")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                Text("下の ＋ ボタンからシールを選択")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(AppTheme.textTertiary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("キャンバスが空です。下の追加ボタンからシールを追加してください")
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("ヒント: ドラッグで移動、ピンチでサイズ変更")
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
                            .font(.system(size: 16))
                        Text("全て")
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                    }
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 56, height: 56)
                    .padding(4)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(AppTheme.accent.opacity(0.3), lineWidth: 1.5)
                    )
                    .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
                }
                .accessibilityLabel("すべてのシールを表示")
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
        }
        .frame(height: 80)
    }

    // MARK: - フローティングツールバー

    private var floatingToolbar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                // --- 高頻度（左側） ---

                // 追加
                toolbarButton(icon: "plus.circle.fill", label: "追加", color: AppTheme.accent) {
                    withAnimation(.spring(duration: 0.3)) {
                        showQuickPicks.toggle()
                    }
                }

                // 効果
                toolbarButton(icon: "wand.and.stars", label: "効果",
                              color: selectedPlacementId != nil && !isSelectedPlacementLocked ? AppTheme.accent : AppTheme.textTertiary) {
                    saveUndoSnapshot()
                    showingFilterPicker = true
                }
                .disabled(selectedPlacementId == nil || isSelectedPlacementLocked)

                // 枠線
                toolbarButton(icon: "square.dashed", label: "枠線",
                              color: selectedPlacementId != nil && !isSelectedPlacementLocked ? AppTheme.accent : AppTheme.textTertiary) {
                    saveUndoSnapshot()
                    showingBorderPicker = true
                }
                .disabled(selectedPlacementId == nil || isSelectedPlacementLocked)

                // 前面
                toolbarButton(icon: "square.2.layers.3d.top.filled", label: "前面",
                              color: selectedPlacementId != nil && !isSelectedPlacementLocked ? AppTheme.textPrimary : AppTheme.textTertiary) {
                    applyToSelected { bringToFront($0) }
                }
                .disabled(selectedPlacementId == nil || isSelectedPlacementLocked)

                // 背面
                toolbarButton(icon: "square.2.layers.3d.bottom.filled", label: "背面",
                              color: selectedPlacementId != nil && !isSelectedPlacementLocked ? AppTheme.textPrimary : AppTheme.textTertiary) {
                    applyToSelected { sendToBack($0) }
                }
                .disabled(selectedPlacementId == nil || isSelectedPlacementLocked)

                // ロック / アンロック
                toolbarButton(
                    icon: isSelectedPlacementLocked ? "lock.fill" : "lock.open",
                    label: isSelectedPlacementLocked ? "解除" : "ロック",
                    color: selectedPlacementId != nil ? AppTheme.accent : AppTheme.textTertiary
                ) {
                    toggleLockForSelected()
                }
                .disabled(selectedPlacementId == nil)

                // --- 低頻度（右側） ---

                // 背景
                toolbarButton(icon: "paintpalette.fill", label: "背景", color: AppTheme.secondary) {
                    saveUndoSnapshot()
                    showingBackgroundPicker = true
                }

                // 削除
                toolbarButton(icon: "trash", label: "削除",
                              color: selectedPlacementId != nil && !isSelectedPlacementLocked ? .red : AppTheme.textTertiary) {
                    if let id = selectedPlacementId,
                       let placement = placements.first(where: { $0.id == id }) {
                        withAnimation {
                            removeFromBoard(placement)
                            selectedPlacementId = nil
                        }
                    }
                }
                .disabled(selectedPlacementId == nil || isSelectedPlacementLocked)
            }
            .padding(.horizontal, 28)
        }
        .frame(height: 64)
        .frame(maxWidth: .infinity)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.12), radius: 16, y: 4)
        .overlay(
            HStack {
                Image(systemName: "chevron.compact.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppTheme.textTertiary.opacity(0.5))
                    .padding(.leading, 8)
                Spacer()
                Image(systemName: "chevron.compact.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppTheme.textTertiary.opacity(0.5))
                    .padding(.trailing, 8)
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        )
    }

    private func toolbarButton(icon: String, label: LocalizedStringKey, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(color)
                    .frame(height: 28)
                Text(label)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)
            }
            .frame(minWidth: 44, minHeight: 44)
        }
        .accessibilityLabel(label)
    }

    // MARK: - ロジック

    private var sortedPlacements: [StickerPlacement] {
        placements.sorted { $0.zIndex < $1.zIndex }
    }

    private var isSelectedPlacementLocked: Bool {
        guard let id = selectedPlacementId else { return false }
        return placements.first(where: { $0.id == id })?.isLocked ?? false
    }

    private func toggleLockForSelected() {
        guard let id = selectedPlacementId,
              let index = placements.firstIndex(where: { $0.id == id }) else { return }
        saveUndoSnapshot()
        placements[index].isLocked.toggle()
        saveBoard()
    }

    private func binding(for placement: StickerPlacement) -> Binding<StickerPlacement> {
        guard let index = placements.firstIndex(where: { $0.id == placement.id }) else {
            return .constant(placement)
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

    // MARK: - Undo

    private func saveUndoSnapshot() {
        if let last = undoStack.last,
           last.placements == placements,
           last.backgroundConfig == backgroundConfig {
            return
        }
        undoStack.append((placements: placements, backgroundConfig: backgroundConfig))
        if undoStack.count > undoStackLimit {
            undoStack.removeFirst()
        }
    }

    private func undoLastAction() {
        guard let snapshot = undoStack.popLast() else { return }
        placements = snapshot.placements
        backgroundConfig = snapshot.backgroundConfig
        loadCustomBackgroundImage()
        rebuildFilterCache()
        saveBoard()
    }

    private func addStickerToBoard(_ sticker: Sticker) {
        saveUndoSnapshot()
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
        let placementId = placement.id
        let fileName = sticker.imageFileName
        Task {
            if let image = await ImageCacheManager.shared.fullResolutionAsync(for: fileName) {
                if placements.contains(where: { $0.id == placementId }) {
                    loadedImages[placementId] = image
                }
            }
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
        saveUndoSnapshot()

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
        saveUndoSnapshot()
        loadedImages.removeValue(forKey: placement.id)
        placements.removeAll { $0.id == placement.id }
        saveBoard()
    }

    private func saveBoard() {
        board.placements = placements
        board.updatedAt = Date()
        try? modelContext.save()
        debouncedSyncBoardToWidget()
    }

    /// ウィジェット同期をデバウンスして実行する。
    /// 高頻度なジェスチャー操作（ピンチ拡大縮小の連続操作など）で saveBoard() が連続発火した場合に、
    /// 重たい ImageRenderer 処理（3種類のウィジェットスナップショット生成）が並列で積み重なり、
    /// メモリ圧迫→クラッシュを引き起こす問題を防ぐ。
    /// 最後の呼び出しから 500ms 後に1回だけ syncBoardToWidget() を実行する。
    private func debouncedSyncBoardToWidget() {
        widgetSyncDebounceTask?.cancel()
        widgetSyncDebounceTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            syncBoardToWidget()
        }
    }

    private func syncBoardToWidget() {
        // 前回の同期タスクをキャンセル（レースコンディション防止）
        widgetSyncTask?.cancel()

        // @Model の値を値型にコピー（Task.detached 内で @Model を参照しない）
        let boardId = board.id
        let boardTitle = board.title
        let boardUpdatedAt = board.updatedAt
        let boardType = board.boardType
        let currentPlacements = sortedPlacements
        let currentCanvasSize = canvasSize
        let currentBgConfig = backgroundConfig
        let currentCustomBgImage = customBackgroundImage
        let stickerCount = currentPlacements.count

        // 全ボードのメタデータを生成
        let descriptor = FetchDescriptor<Board>(sortBy: [SortDescriptor(\Board.createdAt, order: .forward)])
        let allBoards: [Board]
        do {
            allBoards = try modelContext.fetch(descriptor)
        } catch {
            Logger(subsystem: "com.tebasaki.StickerBoard", category: "WidgetSync")
                .error("Failed to fetch boards for widget sync: \(error.localizedDescription)")
            return
        }
        let allMetadata = allBoards.map { b in
            WidgetDataSyncService.generateMetadata(
                boardId: b.id,
                title: b.title,
                stickerCount: b.placements.count,
                updatedAt: b.updatedAt
            )
        }

        // スナップショット生成は非同期で実行（前回タスクはキャンセル済み）
        widgetSyncTask = Task.detached {
            // キャンセル確認
            guard !Task.isCancelled else { return }

            // 通常スナップショット（medium ウィジェット・フォールバック用）
            let snapshotView = BoardSnapshotView(
                placements: currentPlacements,
                size: currentCanvasSize,
                backgroundConfig: currentBgConfig,
                customBackgroundImage: currentCustomBgImage,
                showWatermark: false
            )
            let renderer = await ImageRenderer(content: snapshotView)
            await MainActor.run { renderer.scale = 2.0 }

            guard !Task.isCancelled else { return }
            guard let image = await renderer.uiImage else {
                Logger(subsystem: "com.tebasaki.StickerBoard", category: "WidgetSync")
                    .error("Failed to render board snapshot for board \(boardId.uuidString)")
                return
            }

            // large ウィジェット専用スナップショット（364×382 pt）
            let largeWidgetSize = CGSize(width: 364, height: 382)
            // widgetSmall と同様に、boardCanvasZStack の背景は .padding(24) で縮小されている。
            // widgetLarge ではキャンバスと背景のアスペクト比がほぼ一致するため補正が有効に機能する。
            let largeSnapshotRefSize: CGSize
            if boardType == .widgetLarge {
                let pad: CGFloat = 24
                largeSnapshotRefSize = CGSize(
                    width: max(currentCanvasSize.width - pad * 2, 1),
                    height: max(currentCanvasSize.height - pad * 2, 1)
                )
            } else {
                largeSnapshotRefSize = currentCanvasSize
            }
            let largeSnapshotView = BoardSnapshotView(
                placements: currentPlacements,
                size: largeSnapshotRefSize,
                renderSize: largeWidgetSize,
                backgroundConfig: currentBgConfig,
                customBackgroundImage: currentCustomBgImage,
                showWatermark: false
            )
            let largeRenderer = await ImageRenderer(content: largeSnapshotView)
            await MainActor.run { largeRenderer.scale = 2.0 }
            let largeImage = await largeRenderer.uiImage

            guard !Task.isCancelled else { return }

            // small ウィジェット専用スナップショット（154×154 pt）
            let smallWidgetSize = BoardType.widgetSmallSize
            // widgetSmall ボードでは、boardCanvasZStack 内の BoardBackgroundView に .padding(24) が
            // 四方に適用されている。canvasSize は ZStack 全体（パディング込み）のサイズだが、
            // BoardSnapshotView では背景がフルサイズで描画されるため、座標系が異なる。
            // (canvas - padding×2) を positionScale の基準サイズとして渡すことで
            // 「背景端がエディタ上の背景端と一致する」よう補正する。
            let boardBackgroundPadding: CGFloat = 24
            let smallSnapshotRefSize: CGSize
            if boardType == .widgetSmall {
                smallSnapshotRefSize = CGSize(
                    width: max(currentCanvasSize.width - boardBackgroundPadding * 2, 1),
                    height: max(currentCanvasSize.height - boardBackgroundPadding * 2, 1)
                )
            } else {
                smallSnapshotRefSize = currentCanvasSize
            }
            let smallSnapshotView = BoardSnapshotView(
                placements: currentPlacements,
                size: smallSnapshotRefSize,
                renderSize: smallWidgetSize,
                backgroundConfig: currentBgConfig,
                customBackgroundImage: currentCustomBgImage,
                showWatermark: false
            )
            let smallImage = await MainActor.run {
                let renderer = ImageRenderer(content: smallSnapshotView)
                renderer.scale = 2.0
                return renderer.uiImage
            }
            if smallImage == nil {
                Logger(subsystem: "com.tebasaki.StickerBoard", category: "WidgetSync")
                    .error("Small widget snapshot render failed for board \(boardId.uuidString) — widget will fall back to standard snapshot")
            }

            guard !Task.isCancelled else { return }

            WidgetDataSyncService.syncBoard(
                boardId: boardId,
                title: boardTitle,
                stickerCount: stickerCount,
                updatedAt: boardUpdatedAt,
                snapshotImage: image,
                largeSnapshotImage: largeImage,
                smallSnapshotImage: smallImage,
                allBoardsMetadata: allMetadata
            )
        }
    }

    private func loadCustomBackgroundImage() {
        if backgroundConfig.patternType == .custom,
           let fileName = backgroundConfig.customImageFileName {
            customBackgroundImage = BackgroundImageStorage.load(fileName: fileName)
        } else {
            customBackgroundImage = nil
        }
    }

    // MARK: - SNSシェア

    private func shareBoardAsImage() {
        BoardShareService.share(
            placements: sortedPlacements,
            canvasSize: canvasSize,
            backgroundConfig: backgroundConfig,
            customBackgroundImage: customBackgroundImage,
            displayScale: displayScale
        )
    }

    // MARK: - 画像として保存

    private func saveBoardAsImage() async {
        let isProUser = SubscriptionManager.shared.isProUser
        let scale = displayScale
        let placements = sortedPlacements
        let size = canvasSize
        let bgConfig = backgroundConfig
        let bgImage = customBackgroundImage

        let image = await Task.detached { @Sendable in
            let content = BoardSnapshotView(
                placements: placements,
                size: size,
                backgroundConfig: bgConfig,
                customBackgroundImage: bgImage,
                showWatermark: !isProUser
            )
            return await MainActor.run {
                let renderer = ImageRenderer(content: content)
                renderer.scale = scale
                return renderer.uiImage
            }
        }.value

        guard let image else {
            saveResultSuccess = false
            showingSaveResult = true
            return
        }

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

// MARK: - ボードスナップショット（画像書き出し・ウィジェット共有用）

struct BoardSnapshotView: View {
    let placements: [StickerPlacement]
    /// エディタのキャンバスサイズ（シール位置の基準）
    let size: CGSize
    /// ウィジェット用の出力サイズ（nil = size をそのまま使用）
    var renderSize: CGSize?
    var backgroundConfig: BackgroundPatternConfig = .default
    var customBackgroundImage: UIImage?
    var showWatermark: Bool = false

    /// 実際の描画サイズ
    private var effectiveSize: CGSize { renderSize ?? size }

    /// シール位置・サイズのスケール係数（renderSize に合わせて内容を拡大縮小する）
    private var positionScale: CGFloat {
        guard let rs = renderSize, size.width > 0, size.height > 0 else { return 1.0 }
        // max() を採用してウィジェット領域を横幅いっぱいに埋める（scaledToFill）。
        // キャンバスが縦長の場合、縦方向の中央部分だけがウィジェットに収まる（center-crop）。
        return max(rs.width / size.width, rs.height / size.height)
    }

    var body: some View {
        ZStack {
            BoardBackgroundView(config: backgroundConfig, customImage: customBackgroundImage)

            ForEach(placements) { placement in
                if let displayImage = ImageCacheManager.shared.processed(for: placement.imageFileName, filter: placement.filter, borderWidth: placement.borderWidth, borderColorHex: placement.borderColorHex) {
                    Image(uiImage: displayImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120 * positionScale, height: 120 * positionScale)
                        .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
                        .scaleEffect(placement.scale)
                        .rotationEffect(.radians(placement.rotation))
                        .offset(x: placement.positionX * positionScale, y: placement.positionY * positionScale)
                }
            }

            if showWatermark {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        HStack(spacing: 5) {
                            Image("AppIconSmall")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18, height: 18)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                            Text("シールボード")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(.black.opacity(0.3)))
                        .padding(10)
                    }
                }
            }
        }
        .frame(width: effectiveSize.width, height: effectiveSize.height)
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
