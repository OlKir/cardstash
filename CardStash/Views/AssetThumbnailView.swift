import SwiftUI
import Photos
import UIKit

struct AssetThumbnailView: View {
    @EnvironmentObject private var photoLibrary: PhotoLibraryViewModel
    @EnvironmentObject private var store: GalleryDataStore

    let entry: ImageEntry
    var thumbnailLength: CGFloat = 140
    var cornerRadius: CGFloat = 12

    @State private var thumbnail: UIImage?
    @State private var isMissingAsset = false

    var body: some View {
        ZStack {
            if let thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            } else {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.secondary.opacity(0.2))
                    .overlay(placeholderContent)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .onAppear(perform: loadThumbnail)
        .onChange(of: entry) { _, _ in
            thumbnail = nil
            isMissingAsset = false
            loadThumbnail()
        }
    }

    @ViewBuilder
    private var placeholderContent: some View {
        if isMissingAsset {
            Image(systemName: "exclamationmark.triangle")
                .font(.title3)
                .foregroundStyle(.secondary)
        } else {
            ProgressView()
        }
    }

    private func loadThumbnail() {
        if let assetIdentifier = entry.assetIdentifier {
            loadAssetThumbnail(identifier: assetIdentifier)
        } else if let fileName = entry.storedFileName {
            loadStoredThumbnail(fileName: fileName)
        } else {
            isMissingAsset = true
        }
    }

    private func loadAssetThumbnail(identifier: String) {
        let scale = UIScreen.main.scale
        let targetSize = CGSize(width: thumbnailLength * scale, height: thumbnailLength * scale)
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        options.isSynchronous = false

        photoLibrary.requestImage(
            for: identifier,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: options
        ) { image in
            DispatchQueue.main.async {
                if let image {
                    thumbnail = image
                } else {
                    isMissingAsset = true
                }
            }
        }
    }

    private func loadStoredThumbnail(fileName: String) {
        let url = store.storedImageURL(for: fileName)
        guard let data = try? Data(contentsOf: url), let image = UIImage(data: data) else {
            isMissingAsset = true
            return
        }
        thumbnail = image
    }
}
