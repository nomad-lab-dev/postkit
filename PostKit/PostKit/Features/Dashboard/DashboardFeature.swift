// MARK: - PostKit
// DashboardFeature.swift — Dashboard reducer: scan orchestration, pillar loading, scheduled templates

import ComposableArchitecture
import UIKit

enum DashboardStatus: Equatable, Sendable {
    case scanning(progress: Double, processed: Int, total: Int)
    case reviewNeeded(count: Int)
    case newItems(count: Int)
    case idle(lastScanAt: Date?)
}

@Reducer
struct DashboardFeature {
    @ObservableState
    struct State: Equatable {
        var pillars: IdentifiedArrayOf<PillarSnapshot> = []
        var totalPhotosSorted: Int = 0
        var isInitialLoading: Bool = true
        var isScanning: Bool = false
        var scanProgress: Double = 0
        var showScanCompleteToast: Bool = false
        var hasCompletedInitialScan: Bool = false
        var pendingReviewCount: Int = 0
        var newPhotoCount: Int = 0
        var totalPhotosToScan: Int = 0
        var lastScanCompletedAt: Date? = nil
        var totalLibraryCount: Int = 0
        var classifiedAssetCount: Int = 0
        var scheduledTemplates: [TemplateSnapshot] = []
        var isFillingScheduledSlots: Bool = false
        @Presents var detail: PillarDetailFeature.State?
        @Presents var classificationQueue: ClassificationQueueFeature.State?
        @Presents var scheduledEditor: PostEditorFeature.State?

        var remainingToScan: Int {
            max(totalLibraryCount - classifiedAssetCount, 0)
        }

        var derivedStatus: DashboardStatus {
            if isScanning {
                return .scanning(
                    progress: scanProgress,
                    processed: Int(scanProgress * Double(max(totalPhotosToScan, 1))),
                    total: totalPhotosToScan
                )
            }
            if pendingReviewCount > 0 { return .reviewNeeded(count: pendingReviewCount) }
            if newPhotoCount > 0 { return .newItems(count: newPhotoCount) }
            return .idle(lastScanAt: lastScanCompletedAt)
        }
    }

    enum Action {
        case onAppear
        case dashboardLoaded(pillars: [PillarSnapshot], totalSorted: Int, scanDone: Bool, pendingCount: Int, libraryCount: Int, classifiedCount: Int)
        case startFullScanRequested
        case cancelScanTapped
        case pillarTapped(PillarSnapshot)
        case addPillarTapped
        case reviewPendingTapped
        case browsePhotosTapped
        case statusPrimaryTapped
        case composePostTapped
        case newTemplateTapped
        case pullToRefresh
        case batchProcessed(count: Int, perPillar: [String: Int], pendingCount: Int)
        case scanFinished
        case scanCompleteToastDismissed
        case pillarsLoaded([PillarSnapshot])
        case scheduledTemplatesLoaded([TemplateSnapshot])
        case scheduledTemplateTapped(TemplateSnapshot)
        case scheduledSlotsFilled(template: TemplateSnapshot, slots: [FilledSlot])
        case detail(PresentationAction<PillarDetailFeature.Action>)
        case classificationQueue(PresentationAction<ClassificationQueueFeature.Action>)
        case scheduledEditor(PresentationAction<PostEditorFeature.Action>)
    }

    @Dependency(\.photoLibrary) var photoLibrary
    @Dependency(\.imageClassifier) var imageClassifier
    @Dependency(\.persistence) var persistence
    @Dependency(\.geocoder) var geocoder
    @Dependency(\.userDefaults) var userDefaults
    @Dependency(\.date.now) var now

    private enum CancelID: Int, Sendable { case fullScan }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isInitialLoading = true
                return .run { [userDefaults, persistence, photoLibrary, now] send in
                    let pillars = try await persistence.fetchPillars()
                    let counts = try await persistence.countPhotosPerPillar()
                    var enriched = pillars
                    for i in enriched.indices {
                        enriched[i].photoCount = counts[enriched[i].id] ?? 0
                        let photos = (try? await persistence.fetchPhotosForPillar(enriched[i].id)) ?? []
                        enriched[i].topPhotoAssetIDs = Array(photos.prefix(4).map(\.assetLocalIdentifier))
                    }
                    let totalSorted = counts.values.reduce(0, +)
                    let scanDone = userDefaults.boolForKey("fullScanComplete")
                    let pendingCount = (try? await persistence.fetchPhotos(.pending).count) ?? 0
                    let libraryCount = await photoLibrary.countAllPhotos()
                    let classifiedCount = (try? await persistence.fetchClassifiedAssetIDs().count) ?? 0
                    await send(.dashboardLoaded(pillars: enriched, totalSorted: totalSorted, scanDone: scanDone, pendingCount: pendingCount, libraryCount: libraryCount, classifiedCount: classifiedCount))

                    let today = Weekday.current(from: now)
                    let templates = (try? await persistence.fetchTemplates()) ?? []
                    let scheduled = templates.filter { !$0.schedule.isEmpty && $0.schedule.weekdays.contains(today) }
                    await send(.scheduledTemplatesLoaded(scheduled))
                } catch: { _, _ in }

            case let .dashboardLoaded(pillars, totalSorted, scanDone, pendingCount, libraryCount, classifiedCount):
                state.isInitialLoading = false
                state.pillars = IdentifiedArrayOf(uniqueElements: pillars)
                state.totalPhotosSorted = totalSorted
                state.hasCompletedInitialScan = scanDone
                state.pendingReviewCount = pendingCount
                state.totalLibraryCount = libraryCount
                state.classifiedAssetCount = classifiedCount
                if scanDone {
                    state.lastScanCompletedAt = now
                }
                let userCancelled = userDefaults.boolForKey("fullScanCancelled")
                if !pillars.isEmpty && !state.isScanning && !scanDone && !userCancelled {
                    return .send(.startFullScanRequested)
                }
                return .none

            case let .pillarsLoaded(pillars):
                state.pillars = IdentifiedArrayOf(uniqueElements: pillars)
                return .none

            case .statusPrimaryTapped:
                switch state.derivedStatus {
                case .idle, .newItems:
                    return .send(.startFullScanRequested)
                case .scanning:
                    return .send(.cancelScanTapped)
                case .reviewNeeded:
                    return .send(.reviewPendingTapped)
                }

            case .pullToRefresh:
                return .run { send in
                    await send(.onAppear)
                }

            case .composePostTapped, .newTemplateTapped:
                return .none

            case .startFullScanRequested:
                guard !state.pillars.isEmpty else { return .none }
                state.isScanning = true
                state.scanProgress = 0
                state.totalPhotosToScan = state.remainingToScan
                let pillarNameToID: [String: UUID] = Dictionary(
                    uniqueKeysWithValues: state.pillars.map { ($0.name, $0.id) }
                )
                let pillarNames = state.pillars.map(\.name)
                let fetchAllPhotos = photoLibrary.fetchAllPhotos
                let fetchImage = photoLibrary.image
                let classify = imageClassifier.classify
                let detectCadrage = imageClassifier.detectCadrage
                let batchSave = persistence.batchSavePhotos
                let fetchClassifiedIDs = persistence.fetchClassifiedAssetIDs
                let reverseGeocode = geocoder.reverseGeocode
                return .run { [userDefaults] send in
                    userDefaults.setBool(false, "fullScanCancelled")
                    let alreadyClassified = (try? await fetchClassifiedIDs()) ?? []

                    for await batch in fetchAllPhotos(30) {
                        try Task.checkCancellation()
                        var batchCount = 0
                        var perPillar: [String: Int] = [:]
                        var pendingInBatch = 0
                        var photosToSave: [ClassifiedPhotoSnapshot] = []

                        for asset in batch {
                            try Task.checkCancellation()

                            if alreadyClassified.contains(asset.localIdentifier) {
                                batchCount += 1
                                continue
                            }

                            do {
                                let img = try await fetchImage(
                                    asset.localIdentifier,
                                    CGSize(width: 224, height: 224)
                                )
                                let results = try await classify(img, pillarNames)
                                let cadrage = (try? await detectCadrage(img)) ?? .wide
                                let matchedIDs = results.compactMap { pillarNameToID[$0.pillarName] }
                                let bestResult = results.max(by: { $0.confidence < $1.confidence })
                                let bestConfidence = bestResult?.confidence ?? 0
                                let allTags = results.flatMap(\.suggestedTags)
                                let hasMatch = !matchedIDs.isEmpty && bestConfidence >= 0.55

                                let locationString: String?
                                if let loc = asset.location {
                                    locationString = await reverseGeocode(loc)
                                } else {
                                    locationString = nil
                                }

                                photosToSave.append(ClassifiedPhotoSnapshot(
                                    assetLocalIdentifier: asset.localIdentifier,
                                    pillarID: matchedIDs.first,
                                    pillarIDs: matchedIDs,
                                    confidence: bestConfidence,
                                    classifiedByAI: true,
                                    tags: Array(Set(allTags).prefix(5)),
                                    location: locationString,
                                    capturedAt: asset.creationDate,
                                    status: hasMatch ? .classified : .pending,
                                    cadrage: cadrage
                                ))

                                if hasMatch {
                                    for result in results where result.confidence >= 0.55 {
                                        perPillar[result.pillarName, default: 0] += 1
                                    }
                                } else {
                                    pendingInBatch += 1
                                }
                                batchCount += 1
                            } catch is CancellationError {
                                throw CancellationError()
                            } catch {
                                batchCount += 1
                            }

                            await Task.yield()
                        }

                        try? await batchSave(photosToSave)
                        await send(.batchProcessed(count: batchCount, perPillar: perPillar, pendingCount: pendingInBatch))
                    }
                    await send(.scanFinished)
                }
                .cancellable(id: CancelID.fullScan)

            case .cancelScanTapped:
                state.isScanning = false
                return .merge(
                    .cancel(id: CancelID.fullScan),
                    .run { [userDefaults] _ in
                        userDefaults.setBool(true, "fullScanCancelled")
                    }
                )

            case let .batchProcessed(count, perPillar, pendingCount):
                state.totalPhotosSorted += count
                state.classifiedAssetCount += count
                state.pendingReviewCount += pendingCount
                if state.totalPhotosToScan > 0 {
                    let scannedSoFar = state.totalPhotosToScan - state.remainingToScan
                    state.scanProgress = min(Double(scannedSoFar) / Double(state.totalPhotosToScan), 1.0)
                }
                for (pillarName, photoCount) in perPillar {
                    if let index = state.pillars.firstIndex(where: { $0.name == pillarName }) {
                        state.pillars[index].photoCount += photoCount
                    }
                }
                return .none

            case .scanFinished:
                state.isScanning = false
                state.hasCompletedInitialScan = true
                state.scanProgress = 1
                state.showScanCompleteToast = true
                state.lastScanCompletedAt = now
                return .run { [userDefaults] send in
                    userDefaults.setBool(true, "fullScanComplete")
                    try await Task.sleep(for: .seconds(2.5))
                    await send(.scanCompleteToastDismissed)
                }

            case .scanCompleteToastDismissed:
                state.showScanCompleteToast = false
                return .none

            case let .pillarTapped(pillar):
                state.detail = PillarDetailFeature.State(pillar: pillar)
                return .none

            case .reviewPendingTapped:
                state.classificationQueue = ClassificationQueueFeature.State()
                return .none

            case .addPillarTapped, .browsePhotosTapped:
                return .none

            case let .scheduledTemplatesLoaded(templates):
                state.scheduledTemplates = templates
                return .none

            case let .scheduledTemplateTapped(template):
                state.isFillingScheduledSlots = true
                let slots = template.slots
                return .run { send in
                    let filledSlots = try await SlotFiller.fill(slots: slots, using: persistence)
                    await send(.scheduledSlotsFilled(template: template, slots: filledSlots))
                }

            case let .scheduledSlotsFilled(template, filledSlots):
                state.isFillingScheduledSlots = false
                var editorState = PostEditorFeature.State(template: template, filledSlots: filledSlots)
                editorState.availablePillars = Array(state.pillars)
                state.scheduledEditor = editorState
                return .none

            case .scheduledEditor(.presented(.delegate(.didSave))):
                let templateID = state.scheduledEditor?.template.id
                return .run { [now, persistence] send in
                    if let id = templateID {
                        try? await persistence.updateTemplateLastPostedAt(id, now)
                    }
                    await send(.onAppear)
                }

            case .detail, .classificationQueue, .scheduledEditor:
                return .none
            }
        }
        .ifLet(\.$detail, action: \.detail) {
            PillarDetailFeature()
        }
        .ifLet(\.$classificationQueue, action: \.classificationQueue) {
            ClassificationQueueFeature()
        }
        .ifLet(\.$scheduledEditor, action: \.scheduledEditor) {
            PostEditorFeature()
        }
    }
}
