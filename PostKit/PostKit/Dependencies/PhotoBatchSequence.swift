// MARK: - PostKit
// PhotoBatchSequence.swift — Pull-based photo batch AsyncSequence

@preconcurrency import Photos

/// Pull-based `AsyncSequence` that yields `[PhotoAsset]` batches on demand.
///
/// Replaces `AsyncStream<[PhotoAsset]>` with `.unbounded` buffering in `fetchAllPhotos`.
/// By fetching each batch only when the consumer calls `next()`, we get natural
/// backpressure — the PHFetchResult enumeration stalls while ML inference is running
/// instead of filling unbounded memory with pre-queued batches.
struct PhotoBatchSequence: AsyncSequence, @unchecked Sendable {
    typealias Element = [PhotoAsset]

    private enum Storage {
        case live(batchSize: Int)
        case `static`(batches: [[PhotoAsset]])
        case pending
    }

    private let storage: Storage

    /// Live mode: lazily reads from PHFetchResult one batch per iteration.
    init(batchSize: Int) { storage = .live(batchSize: batchSize) }

    /// Static mode: yields provided batches in order — use in tests and previews.
    init(batches: [[PhotoAsset]]) { storage = .static(batches: batches) }

    private init(storage: Storage) { self.storage = storage }

    /// Finishes immediately — replaces `AsyncStream { $0.finish() }`.
    static let empty = PhotoBatchSequence(batches: [])

    /// Never yields, only completes on cancellation — replaces `AsyncStream { _ in }`.
    static let pending = PhotoBatchSequence(storage: .pending)

    func makeAsyncIterator() -> Iterator {
        switch storage {
        case .live(let batchSize):
            let options = PHFetchOptions()
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            let result = PHAsset.fetchAssets(with: .image, options: options)
            return Iterator(result: result, batchSize: batchSize)
        case .static(let batches):
            return Iterator(batches: batches)
        case .pending:
            return Iterator()
        }
    }

    struct Iterator: AsyncIteratorProtocol, @unchecked Sendable {
        private enum Mode {
            case live(result: PHFetchResult<PHAsset>, batchSize: Int, cursor: Int)
            case `static`(batches: [[PhotoAsset]], cursor: Int)
            case pending
        }

        private var mode: Mode

        fileprivate init(result: PHFetchResult<PHAsset>, batchSize: Int) {
            mode = .live(result: result, batchSize: batchSize, cursor: 0)
        }
        fileprivate init(batches: [[PhotoAsset]]) {
            mode = .static(batches: batches, cursor: 0)
        }
        fileprivate init() {
            mode = .pending
        }

        mutating func next() async throws -> [PhotoAsset]? {
            try Task.checkCancellation()

            switch mode {
            case .live(let result, let batchSize, let cursor):
                guard cursor < result.count else { return nil }
                // Yield between batches so concurrent ML tasks get CPU time
                await Task.yield()
                try Task.checkCancellation()

                let end = Swift.min(cursor + batchSize, result.count)
                var batch: [PhotoAsset] = []
                batch.reserveCapacity(end - cursor)
                for i in cursor..<end {
                    let asset = result.object(at: i)
                    batch.append(PhotoAsset(
                        localIdentifier: asset.localIdentifier,
                        creationDate: asset.creationDate,
                        location: asset.location
                    ))
                }
                mode = .live(result: result, batchSize: batchSize, cursor: end)
                return batch

            case .static(let batches, let cursor):
                guard cursor < batches.count else { return nil }
                mode = .static(batches: batches, cursor: cursor + 1)
                return batches[cursor]

            case .pending:
                // Suspends until the enclosing Task is cancelled
                try await Task.sleep(nanoseconds: .max)
                return nil
            }
        }
    }
}
