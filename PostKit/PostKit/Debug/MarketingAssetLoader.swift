// MARK: - PostKit
// MarketingAssetLoader.swift — Bundle image loader for marketing capture mode.
// Views that load images directly via PHAsset (e.g. BentoThumbnail) call into
// this helper first; on a "marketing:" prefix, the image comes from the bundle
// instead of PhotoKit. NO-OP for production identifiers.

import UIKit

enum MarketingAssetLoader {
    /// Returns true when the identifier is a marketing seed asset
    /// (e.g. "marketing:auto-1-12").
    static func isMarketingID(_ identifier: String) -> Bool {
        identifier.hasPrefix("marketing:")
    }

    /// Resolves a marketing seed identifier to a bundled UIImage.
    /// Returns nil if the identifier doesn't match or the file isn't found.
    static func loadImage(for identifier: String) -> UIImage? {
        guard isMarketingID(identifier) else { return nil }

        // Strip "marketing:" and any "-N" iteration suffix → base slug
        // "marketing:auto-1-12" → "auto-1" → "gallery-auto-1.webp"
        let raw = String(identifier.dropFirst("marketing:".count))
        let parts = raw.split(separator: "-")
        guard parts.count >= 2 else { return nil }
        let slug = "\(parts[0])-\(parts[1])"
        let fileName = "gallery-\(slug)"

        guard
            let url = Bundle.main.url(forResource: fileName, withExtension: "webp"),
            let data = try? Data(contentsOf: url),
            let image = UIImage(data: data)
        else { return nil }
        return image
    }
}
