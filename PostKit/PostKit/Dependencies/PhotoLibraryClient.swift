import ComposableArchitecture
@preconcurrency import Photos
import UIKit

struct PhotoAsset: Equatable, Identifiable, Sendable {
    let localIdentifier: String
    var id: String { localIdentifier }
}

enum PhotoLibraryError: Error, Sendable {
    case assetNotFound
    case imageRequestFailed
}

@DependencyClient
struct PhotoLibraryClient: Sendable {
    var requestAuthorization: @Sendable () async -> PHAuthorizationStatus = { .notDetermined }
    var fetchRecentPhotos: @Sendable (_ limit: Int) async throws -> [PhotoAsset]
    var fetchAllPhotos: @Sendable (_ batchSize: Int) -> AsyncStream<[PhotoAsset]> = { _ in .finished }
    var image: @Sendable (_ identifier: String, _ size: CGSize) async throws -> UIImage
}

extension PhotoLibraryClient: DependencyKey {
    static let liveValue = PhotoLibraryClient(
        requestAuthorization: {
            await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        },
        fetchRecentPhotos: { limit in
            let options = PHFetchOptions()
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            options.fetchLimit = limit
            let result = PHAsset.fetchAssets(with: .image, options: options)
            var assets: [PhotoAsset] = []
            result.enumerateObjects { asset, _, _ in
                assets.append(PhotoAsset(localIdentifier: asset.localIdentifier))
            }
            return assets
        },
        fetchAllPhotos: { _ in .finished },
        image: { identifier, size in
            let fetchResult = PHAsset.fetchAssets(
                withLocalIdentifiers: [identifier],
                options: nil
            )
            guard let asset = fetchResult.firstObject else {
                throw PhotoLibraryError.assetNotFound
            }
            return try await withCheckedThrowingContinuation { continuation in
                let options = PHImageRequestOptions()
                options.deliveryMode = .highQualityFormat
                options.isNetworkAccessAllowed = true
                PHImageManager.default().requestImage(
                    for: asset,
                    targetSize: size,
                    contentMode: .aspectFill,
                    options: options
                ) { image, _ in
                    if let image {
                        continuation.resume(returning: image)
                    } else {
                        continuation.resume(throwing: PhotoLibraryError.imageRequestFailed)
                    }
                }
            }
        }
    )

    static let previewValue = PhotoLibraryClient(
        requestAuthorization: { .authorized },
        fetchRecentPhotos: { limit in
            (0..<limit).map { PhotoAsset(localIdentifier: "preview-\($0)") }
        },
        fetchAllPhotos: { _ in .finished },
        image: { _, _ in UIImage(systemName: "photo")! }
    )
}

extension DependencyValues {
    var photoLibrary: PhotoLibraryClient {
        get { self[PhotoLibraryClient.self] }
        set { self[PhotoLibraryClient.self] = newValue }
    }
}
