import SwiftUI
import SwiftData

struct MainTabView: View {
    enum Tab {
        case home, library

        var icon: String {
            switch self {
            case .home: "square.grid.2x2"
            case .library: "star.square.on.square"
            }
        }

        var filledIcon: String {
            switch self {
            case .home: "square.grid.2x2.fill"
            case .library: "star.square.on.square.fill"
            }
        }
    }

    @State private var selectedTab: Tab = .home
    @State private var showCapture = false
    @State private var hideTabBar = false
    @State private var libraryRefreshID = UUID()

    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack {
                NavigationStack {
                    HomeView(hideTabBar: $hideTabBar)
                }
                .opacity(selectedTab == .home ? 1 : 0)
                .allowsHitTesting(selectedTab == .home)

                NavigationStack {
                    StickerLibraryView(
                        refreshTrigger: libraryRefreshID,
                        onAddSticker: { showCapture = true }
                    )
                }
                .opacity(selectedTab == .library ? 1 : 0)
                .allowsHitTesting(selectedTab == .library)
            }

            if !hideTabBar {
                floatingTabBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: hideTabBar)
        .sheet(isPresented: $showCapture) {
            NavigationStack {
                StickerCaptureView(onStickerSaved: {
                    libraryRefreshID = UUID()
                })
            }
        }
    }

    // MARK: - フローティングタブバー

    private var floatingTabBar: some View {
        HStack(spacing: 0) {
            // ホームタブ
            Button {
                withAnimation(.spring(duration: 0.3)) {
                    selectedTab = .home
                }
            } label: {
                tabItem(
                    tab: .home,
                    isSelected: selectedTab == .home
                )
                .frame(maxWidth: .infinity)
            }
            .accessibilityLabel("ホーム")
            .accessibilityHint("ボード一覧を表示します")
            .accessibilityAddTraits(selectedTab == .home ? .isSelected : [])

            // 撮影ボタン（中央・浮き上がり）
            Button {
                showCapture = true
            } label: {
                ZStack {
                    Circle()
                        .fill(AppTheme.accent)
                        .frame(width: 56, height: 56)
                        .shadow(color: AppTheme.accent.opacity(0.4), radius: 10, x: 0, y: 4)

                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                }
                .offset(y: -20)
                .overlay(alignment: .bottom) {
                    Circle()
                        .fill(.white)
                        .frame(width: 64, height: 64)
                        .offset(y: -18)
                        .blendMode(.destinationOver)
                }
                .frame(maxWidth: .infinity)
            }
            .accessibilityLabel("シールを追加")
            .accessibilityHint("カメラを開いてシールを撮影します")

            // ライブラリタブ
            Button {
                withAnimation(.spring(duration: 0.3)) {
                    selectedTab = .library
                }
            } label: {
                tabItem(
                    tab: .library,
                    isSelected: selectedTab == .library
                )
                .frame(maxWidth: .infinity)
            }
            .accessibilityLabel("ライブラリ")
            .accessibilityHint("シール一覧を表示します")
            .accessibilityAddTraits(selectedTab == .library ? .isSelected : [])
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .background {
            Capsule()
                .fill(.white.opacity(0.92))
                .shadow(color: .black.opacity(0.08), radius: 24, x: 0, y: -4)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
    }

    private func tabItem(tab: Tab, isSelected: Bool) -> some View {
        ZStack {
            if isSelected {
                Circle()
                    .fill(AppTheme.accent)
                    .frame(width: 46, height: 46)
                    .transition(.scale.combined(with: .opacity))
            }

            Image(systemName: isSelected ? tab.filledIcon : tab.icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(isSelected ? .white : AppTheme.textSecondary)
        }
        .animation(.spring(duration: 0.3), value: isSelected)
    }
}
