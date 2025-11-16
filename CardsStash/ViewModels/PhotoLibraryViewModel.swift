import Foundation
import Photos
import UIKit

@MainActor
final class PhotoLibraryViewModel: ObservableObject {
    @Published var authorizationStatus: PHAuthorizationStatus
    @Published var photos: [PHAsset]

    let imageManager: PHCachingImageManager

    init() {
        self.authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        self.photos = []
        self.imageManager = PHCachingImageManager()
        handleAuthorization(status: authorizationStatus)
    }

    func asset(for identifier: String) -> PHAsset? {
        let result = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
        return result.firstObject
    }

    func requestImage(
        for identifier: String,
        targetSize: CGSize,
        contentMode: PHImageContentMode,
        options: PHImageRequestOptions? = nil,
        completion: @escaping (UIImage?) -> Void
    ) {
        guard let asset = asset(for: identifier) else {
            completion(nil)
            return
        }

        imageManager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: contentMode,
            options: options
        ) { image, _ in
            completion(image)
        }
    }

    func requestAuthorizationIfNeeded() {
        let currentStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch currentStatus {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
                DispatchQueue.main.async {
                    self?.handleAuthorization(status: status)
                }
            }
        default:
            handleAuthorization(status: currentStatus)
        }
    }

    private func handleAuthorization(status: PHAuthorizationStatus) {
        authorizationStatus = status

        switch status {
        case .authorized, .limited:
            loadPhotos()
        default:
            photos = []
            imageManager.stopCachingImagesForAllAssets()
        }
    }

    private func loadPhotos() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)

        let result = PHAsset.fetchAssets(with: fetchOptions)
        var fetchedAssets: [PHAsset] = []
        fetchedAssets.reserveCapacity(result.count)
        result.enumerateObjects { asset, _, _ in
            fetchedAssets.append(asset)
        }
        photos = fetchedAssets

        let thumbnailTargetSize = CGSize(width: 200, height: 200)
        imageManager.startCachingImages(
            for: fetchedAssets,
            targetSize: thumbnailTargetSize,
            contentMode: .aspectFill,
            options: nil
        )
    }

    deinit {
        imageManager.stopCachingImagesForAllAssets()
    }

}
