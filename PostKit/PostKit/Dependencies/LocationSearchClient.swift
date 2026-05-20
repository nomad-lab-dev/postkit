import ComposableArchitecture
import MapKit

@DependencyClient
struct LocationSearchClient: Sendable {
    var search: @Sendable (_ query: String) async -> [String] = { _ in [] }
}

extension LocationSearchClient: DependencyKey {
    static let liveValue: LocationSearchClient = {
        let actor = LocationSearchActor()
        return LocationSearchClient(
            search: { query in
                await actor.search(query: query)
            }
        )
    }()

    static let previewValue = LocationSearchClient(
        search: { query in
            let all = ["Paris, France", "Bangkok, Thailand", "Bang Na, Thailand", "Barcelona, Spain", "Berlin, Germany", "Bali, Indonesia"]
            return all.filter { $0.lowercased().contains(query.lowercased()) }
        }
    )

    static let testValue = LocationSearchClient()
}

extension DependencyValues {
    var locationSearch: LocationSearchClient {
        get { self[LocationSearchClient.self] }
        set { self[LocationSearchClient.self] = newValue }
    }
}

private actor LocationSearchActor {
    private var completer: Completer?

    func search(query: String) async -> [String] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 2 else { return [] }

        let completer = Completer()
        self.completer = completer
        return await completer.complete(query: trimmed)
    }
}

private final class Completer: NSObject, MKLocalSearchCompleterDelegate, @unchecked Sendable {
    private let completer = MKLocalSearchCompleter()
    private var continuation: CheckedContinuation<[String], Never>?

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = .address
    }

    func complete(query: String) async -> [String] {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
            completer.queryFragment = query

            Task {
                try? await Task.sleep(for: .milliseconds(800))
                if let pending = self.continuation {
                    self.continuation = nil
                    pending.resume(returning: [])
                }
            }
        }
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let results = completer.results
            .prefix(8)
            .map { result in
                if result.subtitle.isEmpty {
                    return result.title
                }
                return "\(result.title), \(result.subtitle)"
            }

        if let continuation {
            self.continuation = nil
            continuation.resume(returning: results)
        }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        if let continuation {
            self.continuation = nil
            continuation.resume(returning: [])
        }
    }
}
