// MARK: - PostKit
// MarketingPhotoLibraryClient.swift — DEBUG-only PhotoLibraryClient override.
// When asset IDs start with "marketing:", serves images from the bundle's
// MarketingPhotos folder instead of hitting PhotoKit (which would require
// authorization + actual photos on the device).

#if DEBUG

import ComposableArchitecture
import Photos
import UIKit

extension PhotoLibraryClient {

    /// Returns a client that serves bundled marketing assets for IDs prefixed
    /// with `DemoDataSeeder.assetPrefix`, and falls back to a placeholder for
    /// anything else (real PhotoKit not used during capture).
    static func marketingCapture() -> PhotoLibraryClient {
        PhotoLibraryClient(
            requestAuthorization: { .authorized },
            fetchRecentPhotos: { _ in [] },
            fetchAllPhotos: { _ in .empty },
            countAllPhotos: { 191 }, // matches seeded total (47 + 32 + 89 + 23)
            fetchAllAssetIDs: { [] },
            image: { identifier, _ in
                guard identifier.hasPrefix(DemoDataSeeder.assetPrefix) else {
                    throw PhotoLibraryError.assetNotFound
                }

                // Strip "marketing:" prefix and any "-N" suffix → reduce to base slug.
                // e.g. "marketing:auto-1-12" → "gallery-auto-1.webp"
                let raw = String(identifier.dropFirst(DemoDataSeeder.assetPrefix.count))
                let slug = baseSlug(from: raw)
                let fileName = "gallery-\(slug)"

                guard
                    let url = Bundle.main.url(forResource: fileName, withExtension: "webp"),
                    let data = try? Data(contentsOf: url),
                    let image = UIImage(data: data)
                else {
                    // Fallback: neutral grey placeholder so the UI doesn't crash.
                    return placeholderImage()
                }
                return image
            }
        )
    }

    /// Reduces e.g. "auto-1-12" → "auto-1" (the bundled filename slug).
    private static func baseSlug(from raw: String) -> String {
        // We seeded with "{group}-{n}-{i}" where {group}-{n} is the file slug.
        let parts = raw.split(separator: "-")
        guard parts.count >= 2 else { return raw }
        return "\(parts[0])-\(parts[1])"
    }

    private static func placeholderImage() -> UIImage {
        let size = CGSize(width: 400, height: 400)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            UIColor(white: 0.85, alpha: 1).setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }
}

#endif
