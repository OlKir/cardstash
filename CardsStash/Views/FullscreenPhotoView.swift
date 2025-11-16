import SwiftUI
import UIKit
import Photos

struct FullscreenPhotoView: View {
    @EnvironmentObject private var photoLibrary: PhotoLibraryViewModel
    @Environment(\.dismiss) private var dismiss

    let asset: PHAsset
    @State private var image: UIImage?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if let image {
                    GeometryReader { geometry in
                        let size = geometry.size
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: size.width, height: size.height)
                            .background(Color.black)
                    }
                    .ignoresSafeArea()
                } else {
                    ProgressView()
                        .tint(.white)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
        }
        .onAppear(perform: requestFullImage)
    }

    private func requestFullImage() {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .none
        options.isSynchronous = false

        let targetSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)

        photoLibrary.imageManager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFit,
            options: options
        ) { image, _ in
            if let image {
                self.image = image
            }
        }
    }
}
