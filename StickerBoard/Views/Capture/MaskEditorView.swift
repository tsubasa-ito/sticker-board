import SwiftUI

struct MaskEditorView: View {
    let originalImage: UIImage
    let initialMask: UIImage
    /// (合成画像, 編集後マスク) を返す
    var onComplete: (UIImage, UIImage) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var brushMode: BrushMode = .eraser
    @State private var brushSize: CGFloat = 30
    @State private var currentMask: UIImage
    @State private var undoStack: [CGImage] = []
    @State private var isProcessing = false

    private let maxUndoCount = 5

    init(originalImage: UIImage, maskImage: UIImage, onComplete: @escaping (UIImage, UIImage) -> Void) {
        self.originalImage = originalImage
        self.initialMask = maskImage
        self.onComplete = onComplete
        self._currentMask = State(initialValue: maskImage)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    canvas
                        .padding(.vertical, 8)
                    bottomToolbar
                        .padding(.bottom, 8)
                }

                if isProcessing {
                    processingOverlay
                }
            }
            .navigationTitle("マスク調整")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") { applyAndDismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.softOrange)
                }
            }
        }
        .onAppear {
            // fullScreenCover で @State がキャッシュされる問題の対策
            // 毎回 Vision のオリジナルマスクにリセット
            currentMask = initialMask
            undoStack = []
        }
    }

    // MARK: - キャンバス

    private var canvas: some View {
        GeometryReader { geo in
            MaskDrawingCanvas(
                originalImage: originalImage,
                currentMask: $currentMask,
                brushMode: $brushMode,
                brushSize: $brushSize,
                onStrokeStarted: {
                    // ストローク開始前に現在のマスクをスナップショット
                    pushUndo()
                },
                onStrokeCompleted: { updatedMask in
                    currentMask = updatedMask
                }
            )
            .frame(width: geo.size.width, height: geo.size.height)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal, 12)
    }

    // MARK: - ボトムツールバー

    private var bottomToolbar: some View {
        VStack(spacing: 8) {
            // ヒントテキスト
            Text(brushMode == .eraser
                 ? "指でなぞって不要な部分を消します"
                 : "指でなぞって消しすぎた部分を復元します")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))

            BrushToolbar(
                brushMode: $brushMode,
                brushSize: $brushSize,
                canUndo: !undoStack.isEmpty,
                onUndo: performUndo
            )
        }
        .padding(.horizontal, 16)
    }

    // MARK: - 処理中オーバーレイ

    private var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            VStack(spacing: 12) {
                ProgressView()
                    .controlSize(.large)
                    .tint(.white)
                Text("合成しています...")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
    }

    // MARK: - ロジック

    private func pushUndo() {
        guard let cgImage = currentMask.cgImage else { return }
        undoStack.append(cgImage)
        if undoStack.count > maxUndoCount {
            undoStack.removeFirst()
        }
    }

    private func performUndo() {
        guard let previousCG = undoStack.popLast() else { return }
        currentMask = UIImage(cgImage: previousCG)
    }

    private func applyAndDismiss() {
        isProcessing = true
        let original = originalImage
        let mask = currentMask
        Task.detached(priority: .userInitiated) {
            if let result = MaskCompositor.compositeWithMask(original: original, mask: mask) {
                await MainActor.run {
                    onComplete(result, mask)
                    dismiss()
                }
            } else {
                await MainActor.run {
                    isProcessing = false
                }
            }
        }
    }
}
