import GoogleMobileAds
import SwiftUI

// MARK: - NativeAdCard

/// グリッドに挿入するネイティブ広告カード。
/// nativeAd は呼び出し元（StickerLibraryView）から渡す。
/// @Observable singleton を直接参照すると SwiftUI の再レンダリングが発火しないため、
/// 呼び出し元で @State として保持した adManager.nativeAd を引数経由で受け取る設計。
struct NativeAdCard: View {
    let nativeAd: GADNativeAd

    var body: some View {
        NativeAdViewRepresentable(nativeAd: nativeAd)
            .frame(maxWidth: .infinity)
            .frame(height: 76)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
            .accessibilityLabel("広告")
            .accessibilityAddTraits(.isStaticText)
    }
}

// MARK: - UIViewRepresentable

private struct NativeAdViewRepresentable: UIViewRepresentable {
    let nativeAd: GADNativeAd

    func makeUIView(context: Context) -> NativeAdDisplayView {
        NativeAdDisplayView()
    }

    func updateUIView(_ uiView: NativeAdDisplayView, context: Context) {
        uiView.populate(with: nativeAd)
    }
}

// MARK: - NativeAdDisplayView

private final class NativeAdDisplayView: GADNativeAdView {
    // MARK: Ad asset subviews

    private let adBadgeLabel: UILabel = {
        let label = UILabel()
        label.text = "広告"
        label.font = .systemFont(ofSize: 10)
        label.textColor = UIColor(red: 160/255, green: 162/255, blue: 184/255, alpha: 1) // textTertiary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.layer.cornerRadius = 8
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let headlineLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = UIColor(red: 42/255, green: 45/255, blue: 91/255, alpha: 1) // textPrimary
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let bodyLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11)
        label.textColor = UIColor(red: 107/255, green: 109/255, blue: 142/255, alpha: 1) // textSecondary
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let ctaLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .bold)
        label.textColor = UIColor(red: 232/255, green: 122/255, blue: 46/255, alpha: 1) // accent
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: Init

    init() {
        super.init(frame: .zero)
        backgroundColor = UIColor(red: 1, green: 254/255, blue: 248/255, alpha: 1) // backgroundCard
        setupLayout()
        // GADNativeAdView の登録済みビューとして設定
        headlineView = headlineLabel
        bodyView = bodyLabel
        iconView = iconImageView
        callToActionView = ctaLabel
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: Layout

    private func setupLayout() {
        let textStack = UIStackView(arrangedSubviews: [headlineLabel, bodyLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.alignment = .leading
        textStack.translatesAutoresizingMaskIntoConstraints = false

        [adBadgeLabel, iconImageView, textStack, ctaLabel].forEach { addSubview($0) }

        NSLayoutConstraint.activate([
            adBadgeLabel.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            adBadgeLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),

            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            iconImageView.topAnchor.constraint(equalTo: adBadgeLabel.bottomAnchor, constant: 4),
            iconImageView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -8),
            iconImageView.widthAnchor.constraint(equalToConstant: 36),
            iconImageView.heightAnchor.constraint(equalToConstant: 36),

            textStack.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 10),
            textStack.centerYAnchor.constraint(equalTo: iconImageView.centerYAnchor),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: ctaLabel.leadingAnchor, constant: -8),

            ctaLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            ctaLabel.centerYAnchor.constraint(equalTo: iconImageView.centerYAnchor),
        ])
    }

    // MARK: Populate

    func populate(with ad: GADNativeAd) {
        headlineLabel.text = ad.headline
        bodyLabel.text = ad.body
        ctaLabel.text = ad.callToAction
        iconImageView.image = ad.icon?.image
        nativeAd = ad
    }
}
