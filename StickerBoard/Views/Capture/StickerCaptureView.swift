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
    @State private var animateIn = false

    var body: some View {
        ZStack {
            AppTheme.backgroundPrimary
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    if let processedImage {
                        // 切り抜き結果
                        resultSection(processedImage)
                    } else if isProcessing {
                        processingSection
                    } else {
                        pickerSection
                    }

                    if let errorMessage {
                        errorBanner(errorMessage)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
        }
        .navigationTitle("シール追加")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppTheme.backgroundPrimary, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") { dismiss() }
                    .foregroundStyle(AppTheme.accent)
            }
        }
        .onChange(of: selectedItem) { _, newItem in
            loadImage(from: newItem)
        }
        .alert("保存完了!", isPresented: $showingSaveSuccess) {
            Button("続けて追加") { resetState() }
            Button("閉じる") { dismiss() }
        } message: {
            Text("シールをコレクションに追加しました")
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                animateIn = true
            }
        }
    }

    // MARK: - 写真選択セクション

    private var pickerSection: some View {
        VStack(spacing: 20) {
            // シミュレータ注意書き
            if BackgroundRemover.isSimulator {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(AppTheme.cream)
                    Text("シミュレータでは背景除去がスキップされます")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(AppTheme.cream.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // 写真選択ボタン
            PhotosPicker(selection: $selectedItem, matching: .images) {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.headerGradient)
                            .frame(width: 80, height: 80)

                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 32))
                            .foregroundStyle(.white)
                    }
                    .scaleEffect(animateIn ? 1 : 0.6)

                    VStack(spacing: 4) {
                        Text("写真を選んでシールを作ろう")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)

                        Text("カメラロールからシールにしたい写真を選択")
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 48)
                .background {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(AppTheme.cardGradient)
                        .overlay {
                            RoundedRectangle(cornerRadius: 20)
                                .strokeBorder(
                                    AppTheme.accent.opacity(0.3),
                                    style: StrokeStyle(lineWidth: 2, dash: [8, 6])
                                )
                        }
                }
            }

            // 選択された写真のプレビュー
            if let originalImage {
                VStack(spacing: 16) {
                    Image(uiImage: originalImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)

                    Button {
                        processImage()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "scissors")
                            Text("背景を除去する")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.headerGradient)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    // MARK: - 処理中

    private var processingSection: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 80)

            ZStack {
                Circle()
                    .fill(AppTheme.secondary.opacity(0.15))
                    .frame(width: 100, height: 100)

                ProgressView()
                    .controlSize(.large)
                    .tint(AppTheme.secondary)
            }

            VStack(spacing: 4) {
                Text("背景を除去しています...")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

                Text("AIが被写体を認識しています")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()
        }
    }

    // MARK: - 結果表示

    private func resultSection(_ image: UIImage) -> some View {
        VStack(spacing: 20) {
            StickerPreviewView(image: image)

            // 保存ボタン
            Button {
                saveSticker(image)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("コレクションに追加")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppTheme.mintGradient)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            Button {
                resetState()
            } label: {
                Text("別の写真を選ぶ")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
    }

    // MARK: - エラー

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(message)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - ロジック

    private func loadImage(from item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                withAnimation(.spring(duration: 0.4)) {
                    originalImage = image
                    errorMessage = nil
                }
            }
        }
    }

    private func processImage() {
        guard let originalImage else { return }
        withAnimation { isProcessing = true }
        errorMessage = nil

        Task {
            do {
                let result = try await BackgroundRemover.removeBackground(from: originalImage)
                withAnimation(.spring(duration: 0.5)) {
                    processedImage = result
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            withAnimation { isProcessing = false }
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
