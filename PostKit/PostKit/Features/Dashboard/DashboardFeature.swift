import ComposableArchitecture
import UIKit

@Reducer
struct DashboardFeature {
    @ObservableState
    struct State: Equatable {
        var pillars: IdentifiedArrayOf<PillarSnapshot> = []
        var totalPhotosSorted: Int = 0
        var isScanning: Bool = false
        var scanProgress: Double = 0
        var showScanCompleteToast: Bool = false
    }

    enum Action {
        case onAppear
        case startFullScanRequested
        case cancelScanTapped
        case pillarTapped(PillarSnapshot)
        case addPillarTapped
        case batchProcessed(count: Int, perPillar: [String: Int])
        case scanFinished
        case scanCompleteToastDismissed
        case pillarsLoaded([PillarSnapshot])
    }

    @Dependency(\.photoLibrary) var photoLibrary
    @Dependency(\.imageClassifier) var imageClassifier
    @Dependency(\.persistence) var persistence

    private enum CancelID { case fullScan }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    let pillars = try await persistence.fetchPillars()
                    await send(.pillarsLoaded(pillars))
                }

            case let .pillarsLoaded(pillars):
                state.pillars = IdentifiedArrayOf(uniqueElements: pillars)
                return .none

            case .startFullScanRequested:
                state.isScanning = true
                state.scanProgress = 0
                return .run { send in
                    let pillars = try await persistence.fetchPillars()
                    await send(.pillarsLoaded(pillars))

                    for await batch in photoLibrary.fetchAllPhotos(30) {
                        try Task.checkCancellation()
                        let perPillar = try await withThrowingTaskGroup(
                            of: ClassificationResult.self
                        ) { group in
                            for asset in batch {
                                group.addTask {
                                    let img = try await photoLibrary.image(
                                        asset.localIdentifier,
                                        CGSize(width: 224, height: 224)
                                    )
                                    return try await imageClassifier.classify(img)
                                }
                            }
                            var counts: [String: Int] = [:]
                            for try await result in group {
                                counts[result.pillarName, default: 0] += 1
                            }
                            return counts
                        }
                        await send(.batchProcessed(count: batch.count, perPillar: perPillar))
                    }
                    await send(.scanFinished)
                }
                .cancellable(id: CancelID.fullScan)

            case .cancelScanTapped:
                state.isScanning = false
                return .cancel(id: CancelID.fullScan)

            case let .batchProcessed(count, perPillar):
                state.totalPhotosSorted += count
                for (pillarName, photoCount) in perPillar {
                    if let index = state.pillars.firstIndex(where: { $0.name == pillarName }) {
                        state.pillars[index].photoCount += photoCount
                    }
                }
                return .none

            case .scanFinished:
                state.isScanning = false
                state.scanProgress = 1
                state.showScanCompleteToast = true
                return .run { send in
                    try await Task.sleep(for: .seconds(2.5))
                    await send(.scanCompleteToastDismissed)
                }

            case .scanCompleteToastDismissed:
                state.showScanCompleteToast = false
                return .none

            case .pillarTapped, .addPillarTapped:
                return .none
            }
        }
    }
}
