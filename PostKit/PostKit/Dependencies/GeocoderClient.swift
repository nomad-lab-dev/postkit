// MARK: - PostKit
// GeocoderClient.swift — Reverse geocoding dependency

import ComposableArchitecture
import CoreLocation

@DependencyClient
struct GeocoderClient: Sendable {
    var reverseGeocode: @Sendable (_ location: CLLocation) async -> String?
}

private actor GeocoderCache {
    private var cache: [String: String] = [:]
    private let geocoder = CLGeocoder()

    func resolve(_ location: CLLocation) async -> String? {
        let key = String(format: "%.2f,%.2f", location.coordinate.latitude, location.coordinate.longitude)
        if let cached = cache[key] { return cached }

        try? await Task.sleep(for: .milliseconds(20))

        let placemarks = try? await geocoder.reverseGeocodeLocation(location)
        guard let placemark = placemarks?.first else { return nil }

        let parts = [placemark.locality, placemark.country].compactMap { $0 }
        guard !parts.isEmpty else { return nil }
        let result = parts.joined(separator: ", ")
        cache[key] = result
        return result
    }
}

extension GeocoderClient: DependencyKey {
    static let liveValue: GeocoderClient = {
        let cache = GeocoderCache()
        return GeocoderClient(
            reverseGeocode: { location in
                await cache.resolve(location)
            }
        )
    }()

    static let previewValue = GeocoderClient(
        reverseGeocode: { _ in "Paris, France" }
    )
}

extension DependencyValues {
    var geocoder: GeocoderClient {
        get { self[GeocoderClient.self] }
        set { self[GeocoderClient.self] = newValue }
    }
}
