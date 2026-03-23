import SwiftUI
import PhotosUI
import SwiftData

struct StickerCaptureView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedItem: PhotosPickerItem?
    @State private var originalImage: UIImage?
    @State private var processedImage: UIImage?
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showingSaveSuccess = false

    var body: some View {
        VStack(spacing: 20) {
            if let processedImage {
                // 切り抜き結果プレビュー
                StickerPreviewView(image: processedImage)

                Button {
                    saveSticker(processedImage)
                } label: {
                    Label("ライブラリに保存", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)

                Button("別の写真を選ぶ") {
                    resetState()
                }
                .padding(.horizontal)
            } else if isProcessing {
                Spacer()
                ProgressView("背景を除去中...")
                    .controlSize(.large)
                Spacer()
            } else {
                Spacer()

                // シミュレータの場合は案内を表示
                if BackgroundRemover.isSimulator {
                    Text("シミュレータでは背景除去が使えないため、\n元画像がそのまま保存されます。\n実機では自動で背景が除去されます。")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // 写真選択
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        Text("写真を選択してシールを作る")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                    .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                }

                if let originalImage {
                    Image(uiImage: originalImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)

                    Button {
                        processImage()
                    } label: {
                        Label("背景を除去する", systemImage: "scissors")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal)
                }

                Spacer()
            }

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.caption)
                    .padding(.horizontal)
            }
        }
        .navigationTitle("シール追加")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedItem) { _, newItem in
            loadImage(from: newItem)
        }
        .alert("保存完了", isPresented: $showingSaveSuccess) {
            Button("続けて追加") { resetState() }
            Button("戻る") { dismiss() }
        } message: {
            Text("シールをライブラリに保存しました")
        }
    }

    private func loadImage(from item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                originalImage = image
                errorMessage = nil
            }
        }
    }

    private func processImage() {
        guard let originalImage else { return }
        isProcessing = true
        errorMessage = nil

        Task {
            do {
                let result = try await BackgroundRemover.removeBackground(from: originalImage)
                processedImage = result
            } catch {
                errorMessage = error.localizedDescription
            }
            isProcessing = false
        }
    }

    private func saveSticker(_ image: UIImage) {
        do {
            let fileName = try ImageStorage.save(image)
            let sticker = Sticker(imageFileName: fileName)
            modelContext.insert(sticker)
            showingSaveSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func resetState() {
        selectedItem = nil
        originalImage = nil
        processedImage = nil
        errorMessage = nil
    }
}
