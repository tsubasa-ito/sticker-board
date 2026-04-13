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
        // largeSnapshotImage が存在する場合はそちらを優先（364×382 で生成済み）
        if let image = entry.largeSnapshotImage ?? entry.snapshotImage {
            GeometryReader { geo in
                ZStack {
                    // ボードの背景色でウィジェット全体を塗りつぶし
                    Color(hex: 0xFAF0DE)

                    // largeSnapshotImage は 364×382 でプリレンダリング済み。scaledToFill でウィジェット全体を埋める
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
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

// MARK: - Small サイズ

struct BoardShowcaseSmallView: View {
    let entry: BoardShowcaseEntry

    var body: some View {
        // smallSnapshotImage が存在する場合はそちらを優先（154×154 で生成済み）
        if let image = entry.smallSnapshotImage ?? entry.snapshotImage {
            GeometryReader { geo in
                ZStack {
                    // ボードの背景色でウィジェット全体を塗りつぶし
                    Color(hex: 0xFAF0DE)

                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                }
            }
        } else {
            placeholderView
        }
    }

    private var placeholderView: some View {
        VStack(spacing: 6) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 22))
                .foregroundStyle(Color(hex: 0xE87A2E))
            Text("ボードを選択")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(hex: 0x2A2D5B))
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
