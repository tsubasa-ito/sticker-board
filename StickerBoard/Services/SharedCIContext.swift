import CoreImage

/// アプリ全体で共有する CIContext シングルトン。
/// CIContext は内部に GPU/Metal リソースとレンダリングキャッシュを保持する重量オブジェクトのため、
/// 複数インスタンスの生成を避け、1つを再利用する。
enum SharedCIContext {
    static let shared = CIContext()
}
