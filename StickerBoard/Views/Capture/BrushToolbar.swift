import SwiftUI

struct BrushToolbar: View {
    @Binding var brushMode: BrushMode
    @Binding var brushSize: CGFloat
    var canUndo: Bool
    var onUndo: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // モード切替
            HStack(spacing: 4) {
                modeButton(mode: .eraser, icon: "eraser.fill", label: "消す")
                modeButton(mode: .restore, icon: "paintbrush.fill", label: "戻す")
            }
            .padding(4)
            .background(AppTheme.backgroundCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // ブラシサイズ
            HStack(spacing: 8) {
                Circle()
                    .fill(brushMode == .eraser ? Color.red.opacity(0.6) : AppTheme.mint)
                    .frame(width: max(brushSize * 0.4, 6), height: max(brushSize * 0.4, 6))

                Slider(value: $brushSize, in: 5...80)
                    .tint(AppTheme.accent)
                    .frame(maxWidth: 120)
            }

            // Undo
            Button(action: onUndo) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(canUndo ? AppTheme.accent : AppTheme.textTertiary)
            }
            .disabled(!canUndo)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }

    private func modeButton(mode: BrushMode, icon: String, label: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                brushMode = mode
            }
        } label: {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                Text(label)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
            }
            .foregroundStyle(brushMode == mode ? .white : AppTheme.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background {
                if brushMode == mode {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(mode == .eraser
                              ? Color.red.opacity(0.7)
                              : AppTheme.mint)
                }
            }
        }
    }
}
