import SwiftUI
import WidgetKit

// MARK: - Medium サイズ

struct BoardShowcaseMediumView: View {
    let entry: BoardShowcaseEntry

    var body: some View {
        if let image = entry.snapshotImage {
            ZStack(alignment: .bottomLeading) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()

                // ボトムグラデーション + タイトル
                VStack {
                    Spacer()
                    HStack {
                        Text(entry.boardTitle)
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .shadow(color: .black.opacity(0.4), radius: 3, y: 1)
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 12)
                    .background(
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.5)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 60)
                        .offset(y: 10)
                    )
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
            ZStack(alignment: .bottom) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()

                // ボトムオーバーレイ
                VStack {
                    Spacer()
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.boardTitle)
                                .font(.system(size: 18, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .shadow(color: .black.opacity(0.4), radius: 3, y: 1)

                            Text("\(entry.stickerCount)枚のシール")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)
                    .background(
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.5)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 80)
                        .offset(y: 14)
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
