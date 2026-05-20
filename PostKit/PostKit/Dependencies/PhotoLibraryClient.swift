// MARK: - PostKit
// PhotoLibraryClient.swift — PhotoKit library access dependency

import ComposableArchitecture
import CoreLocation
@preconcurrency import Photos
import UIKit

struct PhotoAsset: Equatable, Identifiable, Sendable {
    let localIdentifier: String
    var creationDate: Date?
    var location: CLLocation?
    var id: String { localIdentifier }

    static func == (lhs: PhotoAsset, rhs: PhotoAsset) -> Bool {
        lhs.localIdentifier == rhs.localIdentifier
    }
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
    var countAllPhotos: @Sendable () async -> Int = { 0 }
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
                assets.append(PhotoAsset(
                    localIdentifier: asset.localIdentifier,
                    creationDate: asset.creationDate,
                    location: asset.location
                ))
            }
            return assets
        },
        fetchAllPhotos: { batchSize in
            AsyncStream { continuation in
                let options = PHFetchOptions()
                options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                let result = PHAsset.fetchAssets(with: .image, options: options)
                var batch: [PhotoAsset] = []
                result.enumerateObjects { asset, _, _ in
                    batch.append(PhotoAsset(
                        localIdentifier: asset.localIdentifier,
                        creationDate: asset.creationDate,
                        location: asset.location
                    ))
                    if batch.count == batchSize {
                        continuation.yield(batch)
                        batch = []
                    }
                }
                if !batch.isEmpty {
                    continuation.yield(batch)
                }
                continuation.finish()
            }
        },
        countAllPhotos: {
            PHAsset.fetchAssets(with: .image, options: nil).count
        },
        image: { identifier, size in
            let asset: PHAsset? = autoreleasepool {
                PHAsset.fetchAssets(
                    withLocalIdentifiers: [identifier],
                    options: nil
                ).firstObject
            }
            guard let asset else {
                throw PhotoLibraryError.assetNotFound
            }
            return try await withCheckedThrowingContinuation { continuation in
                let isThumb = max(size.width, size.height) <= 300
                let options = PHImageRequestOptions()
                options.deliveryMode = isThumb ? .fastFormat : .highQualityFormat
                options.resizeMode = isThumb ? .fast : .exact
                options.isNetworkAccessAllowed = !isThumb
                options.isSynchronous = false
                var hasResumed = false
                PHImageManager.default().requestImage(
                    for: asset,
                    targetSize: size,
                    contentMode: .aspectFill,
                    options: options
                ) { image, info in
                    let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                    guard !hasResumed, !isDegraded else { return }
                    hasResumed = true
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
        countAllPhotos: { 0 },
        image: { _, _ in UIImage(systemName: "photo")! }
    )
}

extension DependencyValues {
    var photoLibrary: PhotoLibraryClient {
        get { self[PhotoLibraryClient.self] }
        set { self[PhotoLibraryClient.self] = newValue }
    }
}
