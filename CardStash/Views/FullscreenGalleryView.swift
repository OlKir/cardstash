import SwiftUI
import Photos
import UIKit

struct FullscreenGalleryView: View {
    @Environment(\.dismiss) private var dismiss

    let entries: [ImageEntry]
    let startIndex: Int

    @State private var currentIndex: Int

    init(entries: [ImageEntry], startIndex: Int) {
        self.entries = entries
        self.startIndex = startIndex
        _currentIndex = State(initialValue: startIndex)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if entries.isEmpty {
                Text("No images")
                    .foregroundStyle(.white)
            } else {
                TabView(selection: $currentIndex) {
                    ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                        ZoomableAssetView(entry: entry)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }

            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }
                .padding()
                Spacer()
                if !entries.isEmpty {
                    Text("\(currentIndex + 1)/\(entries.count)")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.bottom, 20)
                }
            }
            .padding(.horizontal)
        }
    }
}

private struct ZoomableAssetView: View {
    @EnvironmentObject private var photoLibrary: PhotoLibraryViewModel
    @EnvironmentObject private var store: GalleryDataStore

    let entry: ImageEntry
    @State private var image: UIImage?
    @State private var hasError = false

    var body: some View {
        Group {
            if let image {
                ZoomableImageContainer(image: image)
                    .ignoresSafeArea()
            } else if hasError {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title)
                        .foregroundStyle(.white.opacity(0.8))
                    Text("Unable to load image")
                        .foregroundStyle(.white)
                        .font(.footnote)
                }
            } else {
                ProgressView()
                    .tint(.white)
            }
        }
        .onAppear(perform: loadImage)
        .onChange(of: entry) { _, _ in
            image = nil
            hasError = false
            loadImage()
        }
    }

    private func loadImage() {
        hasError = false
        if let identifier = entry.assetIdentifier {
            loadAssetImage(identifier: identifier)
        } else if let fileName = entry.storedFileName {
            loadStoredImage(fileName: fileName)
        } else {
            hasError = true
        }
    }

    private func loadAssetImage(identifier: String) {
        guard let asset = photoLibrary.asset(for: identifier) else {
            hasError = true
            return
        }

        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isSynchronous = false
        options.resizeMode = .none

        let targetSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)

        photoLibrary.imageManager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFit,
            options: options
        ) { image, _ in
            if let image {
                DispatchQueue.main.async {
                    self.image = image
                    hasError = false
                }
            } else {
                DispatchQueue.main.async {
                    hasError = true
                }
            }
        }
    }

    private func loadStoredImage(fileName: String) {
        let url = store.storedImageURL(for: fileName)
        guard let data = try? Data(contentsOf: url), let image = UIImage(data: data) else {
            hasError = true
            return
        }
        self.image = image
    }
}

private struct ZoomableImageContainer: UIViewRepresentable {
    let image: UIImage

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 5
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.backgroundColor = .black
        scrollView.delegate = context.coordinator

        context.coordinator.imageView.contentMode = .scaleAspectFit
        context.coordinator.imageView.frame = scrollView.bounds
        context.coordinator.imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        context.coordinator.imageView.image = image
        scrollView.addSubview(context.coordinator.imageView)

        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        context.coordinator.imageView.image = image
        context.coordinator.imageView.frame = scrollView.bounds
        scrollView.setZoomScale(1, animated: false)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        let imageView = UIImageView()

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            imageView
        }
    }
}
