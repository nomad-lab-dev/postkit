import ComposableArchitecture
import Foundation
@preconcurrency import Photos
import UIKit

struct PillarOption: Equatable, Identifiable, Sendable {
    let id: UUID
    var name: String
    var emoji: String
    var isSelected: Bool
    var matchedPhotos: Int = 0
}

@Reducer
struct OnboardingFeature {
    @ObservableState
    struct State: Equatable {
        var step: Step = .welcome
        var availablePillars: IdentifiedArrayOf<PillarOption> = []
        var scanProgress: Double = 0
        var scannedCount: Int = 0
        var totalToScan: Int = 20
        @Presents var alert: AlertState<Action.Alert>?

        var selectedPillarCount: Int {
            availablePillars.filter(\.isSelected).count
        }

        var totalMatchedPhotos: Int {
            availablePillars.filter(\.isSelected).reduce(0) { $0 + $1.matchedPhotos }
        }

        enum Step: Equatable {
            case welcome, pillarSetup, scanning, scanComplete
        }
    }

    enum Action {
        case getStartedTapped
        case authorizationResponse(PHAuthorizationStatus)
        case pillarToggled(PillarOption.ID)
        case startScanTapped
        case scanStarted(totalPhotos: Int)
        case scanProgressed(ClassificationResult, assetIdentifier: String)
        case scanFinished
        case startPostKitTapped
        case persistResponse(Result<Void, Error>)
        case alert(PresentationAction<Alert>)

        enum Alert: Equatable {
            case openSettingsTapped
        }
    }

    @Dependency(\.photoLibrary) var photoLibrary
    @Dependency(\.imageClassifier) var imageClassifier
    @Dependency(\.persistence) var persistence
    @Dependency(\.openURL) var openURL
    @Dependency(\.uuid) var uuid

    private enum CancelID { case quickScan }

    static let defaultPillars: [(name: String, emoji: String)] = [
        ("Automotive", "🚗"),
        ("Travel", "✈️"),
        ("Food", "🍽️"),
        ("Business", "💼"),
        ("Fitness", "💪"),
        ("Behind the Scenes", "🎬"),
    ]

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .getStartedTapped:
                return .run { send in
                    let status = await photoLibrary.requestAuthorization()
                    await send(.authorizationResponse(status))
                }

            case let .authorizationResponse(status):
                switch status {
                case .authorized, .limited:
                    state.step = .pillarSetup
                    state.availablePillars = IdentifiedArrayOf(
                        uniqueElements: Self.defaultPillars.map {
                            PillarOption(
                                id: uuid(),
                                name: $0.name,
                                emoji: $0.emoji,
                                isSelected: false
                            )
                        }
                    )
                    return .none

                case .denied, .restricted:
                    state.alert = .photoAccessDenied
                    return .none

                case .notDetermined:
                    return .none

                @unknown default:
                    return .none
                }

            case let .pillarToggled(id):
                state.availablePillars[id: id]?.isSelected.toggle()
                return .none

            case .startScanTapped:
                state.step = .scanning
                state.scannedCount = 0
                state.scanProgress = 0
                return .run { send in
                    let assets = try await photoLibrary.fetchRecentPhotos(20)
                    await send(.scanStarted(totalPhotos: assets.count))
                    await withTaskGroup(of: Void.self) { group in
                        for asset in assets {
                            group.addTask {
                                do {
                                    let image = try await photoLibrary.image(
                                        asset.localIdentifier,
                                        CGSize(width: 224, height: 224)
                                    )
                                    let result = try await imageClassifier.classify(image)
                                    await send(.scanProgressed(result, assetIdentifier: asset.localIdentifier))
                                } catch {
                                    await send(.scanProgressed(
                                        ClassificationResult(
                                            pillarName: "Uncategorized",
                                            confidence: 0,
                                            suggestedTags: [],
                                            source: .coreML
                                        ),
                                        assetIdentifier: asset.localIdentifier
                                    ))
                                }
                            }
                        }
                        await group.waitForAll()
                    }
                    await send(.scanFinished)
                }
                .cancellable(id: CancelID.quickScan)

            case let .scanStarted(totalPhotos):
                state.totalToScan = max(totalPhotos, 1)
                return .none

            case let .scanProgressed(result, _):
                state.scannedCount += 1
                state.scanProgress = Double(state.scannedCount) / Double(state.totalToScan)
                if let index = state.availablePillars.firstIndex(
                    where: { $0.name == result.pillarName && $0.isSelected }
                ) {
                    state.availablePillars[index].matchedPhotos += 1
                }
                return .none

            case .scanFinished:
                state.step = .scanComplete
                state.scanProgress = 1
                return .none

            case .startPostKitTapped:
                let selected = state.availablePillars.filter(\.isSelected)
                return .run { send in
                    for pillar in selected {
                        let snapshot = PillarSnapshot(
                            name: pillar.name,
                            emoji: pillar.emoji
                        )
                        try await persistence.savePillar(snapshot)
                    }
                    await send(.persistResponse(.success(())))
                } catch: { error, send in
                    await send(.persistResponse(.failure(error)))
                }

            case .persistResponse(.success):
                return .none

            case .persistResponse(.failure):
                state.alert = .saveFailed
                return .none

            case .alert(.presented(.openSettingsTapped)):
                return .run { _ in
                    await openURL(URL(string: UIApplication.openSettingsURLString)!)
                }

            case .alert:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}

extension AlertState where Action == OnboardingFeature.Action.Alert {
    static let photoAccessDenied = AlertState {
        TextState("Photo Access Required")
    } actions: {
        ButtonState(action: .openSettingsTapped) {
            TextState("Open Settings")
        }
        ButtonState(role: .cancel) {
            TextState("Cancel")
        }
    } message: {
        TextState("PostKit needs access to your photo library to classify your content.")
    }

    static let saveFailed = AlertState {
        TextState("Save Failed")
    } actions: {
        ButtonState(role: .cancel) {
            TextState("OK")
        }
    } message: {
        TextState("Could not save your pillars. Please try again.")
    }
}
