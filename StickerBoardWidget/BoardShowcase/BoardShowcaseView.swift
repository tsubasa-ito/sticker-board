import SwiftUI
import WidgetKit

// MARK: - Medium サイズ

struct BoardShowcaseMediumView: View {
    let entry: BoardShowcaseEntry

    var body: some View {
        if let image = entry.snapshotImage {
            GeometryReader { geo in
                ZStack {
                    // ボードの背景色でウィジェット全体を塗りつぶし
                    Color(hex: 0xFAF0DE)

                    // scaledToFill でウィジェット枠を埋める（ウィジェット中用ボードは比率一致でクロップなし）
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                }
                .overlay(alignment: .bottomLeading) {
                    Text(entry.boardTitle)
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .shadow(color: .black.opacity(0.5), radius: 3, y: 1)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 10)
                }
            }
        } else {
            placeholderView
        }
    }

    private var placeholderView: some View {
        VStack(spacing: 8) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 28))
                .foregroundStyle(Color(hex: 0xE87A2E))
            Text("ボードを選択")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(hex: 0x2A2D5B))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: 0xFAF0DE))
    }
}

// MARK: - Large サイズ

struct BoardShowcaseLargeView: View {
    let entry: BoardShowcaseEntry

    var body: some View {
        if let image = entry.snapshotImage {
            GeometryReader { geo in
                ZStack {
                    // ボードの背景色でウィジェット全体を塗りつぶし
                    Color(hex: 0xFAF0DE)

                    // scaledToFit で全体を表示（ウィジェット大用ボードは比率一致でレターボックスなし）
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geo.size.width, height: geo.size.height)
                }
                .overlay(alignment: .bottomLeading) {
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.boardTitle)
                                .font(.system(size: 16, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .shadow(color: .black.opacity(0.5), radius: 3, y: 1)

                            Text("\(entry.stickerCount)枚のシール")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.85))
                                .shadow(color: .black.opacity(0.4), radius: 2, y: 1)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 12)
                    .background(
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.4)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 60)
                        .offset(y: 12)
                    )
                }
            }
        } else {
            placeholderView
        }
    }

    private var placeholderView: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 40))
                .foregroundStyle(Color(hex: 0xE87A2E))
            VStack(spacing: 4) {
                Text("シールボード")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(hex: 0x2A2D5B))
                Text("ボードを長押しして選択")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(Color(hex: 0x6B6D8E))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: 0xFAF0DE))
    }
}

// MARK: - Hex Color Extension (ウィジェット用)

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }
}
