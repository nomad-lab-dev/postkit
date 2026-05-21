// MARK: - PostKit
// DashboardFeature.swift — Dashboard reducer: scan orchestration, pillar loading, scheduled templates

import ComposableArchitecture
import os
import UIKit

private let log = Logger(subsystem: "PostKit", category: "Dashboard")

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
        @Presents var topicEditor: TopicEditorFeature.State?

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

        var pillarsByActivity: IdentifiedArrayOf<PillarSnapshot> {
            IdentifiedArrayOf(uniqueElements: pillars.sorted { $0.photoCount > $1.photoCount })
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
        case scanPhotoProcessed
        case batchProcessed(perPillar: [String: Int], pendingCount: Int)
        case scanFinished
        case scanCompleteToastDismissed
        case pillarsLoaded([PillarSnapshot])
        case scheduledTemplatesLoaded([TemplateSnapshot])
        case scheduledTemplateTapped(TemplateSnapshot)
        case scheduledSlotsFilled(template: TemplateSnapshot, slots: [FilledSlot])
        case detail(PresentationAction<PillarDetailFeature.Action>)
        case classificationQueue(PresentationAction<ClassificationQueueFeature.Action>)
        case scheduledEditor(PresentationAction<PostEditorFeature.Action>)
        case topicEditor(PresentationAction<TopicEditorFeature.Action>)
    }

    @Dependency(\.photoLibrary) var photoLibrary
    @Dependency(\.imageClassifier) var imageClassifier
    @Dependency(\.persistence) var persistence
    @Dependency(\.gallery) var gallery
    @Dependency(\.geocoder) var geocoder
    @Dependency(\.userDefaults) var userDefaults
    @Dependency(\.date.now) var now

    private enum CancelID: Int, Sendable { case fullScan }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                let pillarCount = state.pillars.count
                let isFirstLoad = state.pillars.isEmpty && state.isInitialLoading
                if isFirstLoad {
                    state.isInitialLoading = true
                }
                log.info("⏳ onAppear — firstLoad=\(isFirstLoad), pillars=\(pillarCount)")
                return .run { [userDefaults, gallery, photoLibrary, now] send in
                    log.info("⏳ gallery.pillars start")
                    async let pillarsTask = gallery.pillars()
                    log.info("⏳ gallery.photos(nil) start")
                    async let allPhotosTask = gallery.photos(nil)
                    log.info("⏳ countAllPhotos start")
                    async let libraryCountTask = photoLibrary.countAllPhotos()

                    let pillars = try await pillarsTask
                    log.info("✅ gallery.pillars done — \(pillars.count) pillars")
                    let allPhotos = (try? await allPhotosTask) ?? []
                    log.info("✅ gallery.photos done — \(allPhotos.count) photos")
                    let libraryCount = await libraryCountTask
                    log.info("✅ countAllPhotos done — \(libraryCount) in library")

                    let classifiedPhotos = allPhotos.filter { $0.status == .classified }
                    let pendingCount = allPhotos.filter { $0.status == .pending }.count
                    let classifiedCount = allPhotos.count

                    var counts: [UUID: Int] = [:]
                    for photo in classifiedPhotos {
                        for pid in photo.pillarIDs {
                            counts[pid, default: 0] += 1
                        }
                    }

                    var enriched = pillars
                    for i in enriched.indices {
                        let pid = enriched[i].id
                        enriched[i].photoCount = counts[pid] ?? 0
                        let matching = classifiedPhotos
                            .filter { $0.pillarID == pid || $0.pillarIDs.contains(pid) }
                        enriched[i].topPhotoAssetIDs = Array(matching.prefix(4).map(\.assetLocalIdentifier))
                    }

                    let totalSorted = counts.values.reduce(0, +)
                    let scanDone = userDefaults.boolForKey("fullScanComplete")
                    log.info("📤 sending dashboardLoaded — sorted=\(totalSorted), scanDone=\(scanDone)")
                    await send(.dashboardLoaded(pillars: enriched, totalSorted: totalSorted, scanDone: scanDone, pendingCount: pendingCount, libraryCount: libraryCount, classifiedCount: classifiedCount))

                    let today = Weekday.current(from: now)
                    let templates = (try? await gallery.templates()) ?? []
                    let scheduled = templates.filter { !$0.schedule.isEmpty && $0.schedule.weekdays.contains(today) }
                    log.info("📤 sending scheduledTemplatesLoaded — \(scheduled.count) templates")
                    await send(.scheduledTemplatesLoaded(scheduled))
                } catch: { error, send in
                    log.error("❌ Dashboard load FAILED: \(error)")
                    await send(.dashboardLoaded(
                        pillars: [], totalSorted: 0, scanDone: false,
                        pendingCount: 0, libraryCount: 0, classifiedCount: 0
                    ))
                }

            case let .dashboardLoaded(pillars, totalSorted, scanDone, pendingCount, libraryCount, classifiedCount):
                log.info("✅ dashboardLoaded received — pillars=\(pillars.count), sorted=\(totalSorted), pending=\(pendingCount)")
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
                    return .run { send in
                        try await Task.sleep(for: .seconds(5))
                        await send(.startFullScanRequested)
                    }
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
                return .run { [gallery] send in
                    await gallery.invalidateAll()
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
                let pillarDefs = state.pillars.map {
                    PillarDefinition(name: $0.name, about: $0.about, referenceTags: $0.referenceTags)
                }
                let fetchAllPhotos = photoLibrary.fetchAllPhotos
                let fetchImage = photoLibrary.image
                let classify = imageClassifier.classify
                let detectCadrage = imageClassifier.detectCadrage
                let batchSave = persistence.batchSavePhotos
                let fetchClassifiedIDs = persistence.fetchClassifiedAssetIDs
                let reverseGeocode = geocoder.reverseGeocode
                let invalidatePhotos = gallery.invalidatePhotos
                return .run(priority: .utility) { [userDefaults] send in
                    userDefaults.setBool(false, "fullScanCancelled")
                    let alreadyClassified = (try? await fetchClassifiedIDs()) ?? []

                    for await batch in fetchAllPhotos(30) {
                        try Task.checkCancellation()
                        var perPillar: [String: Int] = [:]
                        var pendingInBatch = 0
                        var photosToSave: [ClassifiedPhotoSnapshot] = []
                        var batchProcessedCount = 0

                        let maxConcurrent = 2
                        try await withThrowingTaskGroup(
                            of: (snapshot: ClassifiedPhotoSnapshot, results: [ClassificationResult])?.self
                        ) { group in
                            var inFlight = 0

                            for asset in batch {
                                try Task.checkCancellation()

                                if alreadyClassified.contains(asset.localIdentifier) {
                                    batchProcessedCount += 1
                                    continue
                                }

                                if inFlight >= maxConcurrent {
                                    if let result = try await group.next() {
                                        batchProcessedCount += 1
                                        if let (snapshot, results) = result {
                                            photosToSave.append(snapshot)
                                            Self.accumulateCounts(
                                                snapshot: snapshot, results: results,
                                                into: &perPillar, pending: &pendingInBatch
                                            )
                                        }
                                    }
                                    inFlight -= 1
                                }

                                group.addTask {
                                    let img: UIImage
                                    do {
                                        img = try await fetchImage(
                                            asset.localIdentifier,
                                            Layout.ImageSize.classification
                                        )
                                    } catch is CancellationError {
                                        throw CancellationError()
                                    } catch {
                                        return nil
                                    }

                                    async let classifyTask = classify(img, pillarDefs)
                                    async let cadrageTask: Cadrage = (try? await detectCadrage(img)) ?? .wide

                                    let results: [ClassificationResult]
                                    let cadrage: Cadrage
                                    do {
                                        results = try await classifyTask
                                        cadrage = await cadrageTask
                                    } catch is CancellationError {
                                        throw CancellationError()
                                    } catch {
                                        return nil
                                    }

                                    let matchedIDs = results.compactMap { pillarNameToID[$0.pillarName] }
                                    let bestConfidence = results.max(by: { $0.confidence < $1.confidence })?.confidence ?? 0
                                    let allTags = results.flatMap(\.suggestedTags)
                                    let hasMatch = !matchedIDs.isEmpty && bestConfidence >= 0.55

                                    let locationString: String?
                                    if let loc = asset.location {
                                        locationString = await reverseGeocode(loc)
                                    } else {
                                        locationString = nil
                                    }

                                    return (
                                        snapshot: ClassifiedPhotoSnapshot(
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
                                        ),
                                        results: results
                                    )
                                }
                                inFlight += 1
                            }

                            for try await result in group {
                                batchProcessedCount += 1
                                if let (snapshot, results) = result {
                                    photosToSave.append(snapshot)
                                    Self.accumulateCounts(
                                        snapshot: snapshot, results: results,
                                        into: &perPillar, pending: &pendingInBatch
                                    )
                                }
                            }
                        }

                        for _ in 0..<batchProcessedCount {
                            await send(.scanPhotoProcessed)
                        }

                        do {
                            try await batchSave(photosToSave)
                            await invalidatePhotos()
                        } catch {
                            Logger(subsystem: "PostKit", category: "Dashboard")
                                .error("Batch save failed (\(photosToSave.count) photos): \(error)")
                        }
                        await send(.batchProcessed(perPillar: perPillar, pendingCount: pendingInBatch))
                        await Task.yield()
                    }
                    await send(.scanFinished)
                } catch: { error, send in
                    if !(error is CancellationError) {
                        Logger(subsystem: "PostKit", category: "Dashboard")
                            .error("Full scan failed: \(error)")
                        await send(.scanFinished)
                    }
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

            case .scanPhotoProcessed:
                state.totalPhotosSorted += 1
                state.classifiedAssetCount += 1
                if state.totalPhotosToScan > 0 {
                    let scannedSoFar = state.totalPhotosToScan - state.remainingToScan
                    state.scanProgress = min(Double(scannedSoFar) / Double(state.totalPhotosToScan), 1.0)
                }
                return .none

            case let .batchProcessed(perPillar, pendingCount):
                state.pendingReviewCount += pendingCount
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
                return .run { [userDefaults, gallery] send in
                    userDefaults.setBool(true, "fullScanComplete")
                    await gallery.invalidateAll()
                    try? await Task.sleep(for: .seconds(2.5))
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

            case .addPillarTapped:
                state.topicEditor = TopicEditorFeature.State()
                return .none

            case .browsePhotosTapped:
                return .none

            case .topicEditor(.presented(.delegate(.didSave))):
                return .run { [gallery] send in
                    await gallery.invalidatePillars()
                    await gallery.invalidatePhotos()
                    await send(.onAppear)
                }

            case let .topicEditor(.presented(.delegate(.didDelete(id)))):
                state.pillars.remove(id: id)
                return .run { [gallery] send in
                    await gallery.invalidatePillars()
                    await gallery.invalidatePhotos()
                    await send(.onAppear)
                }

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

            case .detail(.presented(.delegate(.pillarUpdated))):
                return .run { [gallery] send in
                    await gallery.invalidatePillars()
                    await gallery.invalidatePhotos()
                    await send(.onAppear)
                }

            case let .detail(.presented(.delegate(.pillarDeleted(id)))):
                state.pillars.remove(id: id)
                return .run { [gallery] send in
                    await gallery.invalidatePillars()
                    await gallery.invalidatePhotos()
                    await send(.onAppear)
                }

            case .detail, .classificationQueue, .scheduledEditor, .topicEditor:
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
        .ifLet(\.$topicEditor, action: \.topicEditor) {
            TopicEditorFeature()
        }
    }

    private static func accumulateCounts(
        snapshot: ClassifiedPhotoSnapshot,
        results: [ClassificationResult],
        into perPillar: inout [String: Int],
        pending: inout Int
    ) {
        if snapshot.status == .classified {
            for result in results where result.confidence >= 0.55 {
                perPillar[result.pillarName, default: 0] += 1
            }
        } else {
            pending += 1
        }
    }
}
