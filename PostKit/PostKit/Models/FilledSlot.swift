// MARK: - PostKit
// FilledSlot.swift — FilledSlot model and PostEditorFeature reducer

import ComposableArchitecture
import Foundation
import UIKit

struct FilledSlot: Equatable, Identifiable, Sendable {
    let slotData: TemplateSlotData
    var photoIDs: Set<String>
    var activePillarID: UUID?
    var locationLabel: String?

    var id: UUID { slotData.id }
    var isEmpty: Bool { photoIDs.isEmpty }
}

// MARK: - Shared Slot Filling

/// Auto-fills template slots by picking one random photo per slot that matches its constraints.
/// Each slot's pillar, location, and date filters are applied as soft constraints — if no
/// photo matches all filters, the broader pool is used. Photos are not reused across slots.
enum SlotFiller {
    static func fill(
        slots: [TemplateSlotData],
        using persistence: PersistenceClient
    ) async throws -> [FilledSlot] {
        var filledSlots: [FilledSlot] = []
        var usedIDs: Set<String> = []

        for slot in slots {
            let allPhotos: [ClassifiedPhotoSnapshot]
            if slot.pillarIDs.isEmpty {
                allPhotos = try await persistence.fetchPhotos(.classified)
            } else {
                var photos: [ClassifiedPhotoSnapshot] = []
                for pillarID in slot.pillarIDs {
                    photos.append(contentsOf: try await persistence.fetchPhotosForPillar(pillarID))
                }
                allPhotos = photos
            }

            var available = allPhotos.filter { !usedIDs.contains($0.assetLocalIdentifier) }

            // Soft constraint: prefer photos matching slot locations
            if !slot.locations.isEmpty {
                let filtered = available.filter { photo in
                    guard let loc = photo.location else { return false }
                    return slot.locations.contains(loc)
                }
                if !filtered.isEmpty { available = filtered }
            }

            // Soft constraint: prefer photos within the slot's date range
            if slot.startDate != nil || slot.endDate != nil {
                let filtered = available.filter { photo in
                    guard let captured = photo.capturedAt else { return false }
                    if let s = slot.startDate, captured < s { return false }
                    if let e = slot.endDate, captured > e { return false }
                    return true
                }
                if !filtered.isEmpty { available = filtered }
            }

            var filled = FilledSlot(slotData: slot, photoIDs: [])
            if let picked = available.randomElement() {
                filled.photoIDs = [picked.assetLocalIdentifier]
                filled.activePillarID = picked.pillarID
                filled.locationLabel = picked.location
                usedIDs.insert(picked.assetLocalIdentifier)
            }
            filledSlots.append(filled)
        }
        return filledSlots
    }
}

@Reducer
struct PostEditorFeature {
    @ObservableState
    struct State: Equatable {
        let template: TemplateSnapshot
        var filledSlots: [FilledSlot] = []
        var availablePillars: [PillarSnapshot] = []
        var caption: String = ""
        var hashtags: [String] = []
        var isGenerating: Bool = false
        var isLoadingShare: Bool = false
        var shareImages: [UIImage]? = nil
        var filterStartDate: Date? = nil
        var filterEndDate: Date? = nil
        @Presents var slotFiller: SlotFillerFeature.State?

        var allSlotsFilled: Bool {
            filledSlots.allSatisfy { !$0.isEmpty }
        }

        var totalPhotoCount: Int {
            filledSlots.reduce(0) { $0 + $1.photoIDs.count }
        }

        var allPhotoIDs: [String] {
            filledSlots.flatMap { Array($0.photoIDs) }
        }

        init(template: TemplateSnapshot) {
            self.template = template
            self.filledSlots = template.slots.map { FilledSlot(slotData: $0, photoIDs: []) }
        }

        init(template: TemplateSnapshot, filledSlots: [FilledSlot]) {
            self.template = template
            self.filledSlots = filledSlots
        }
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case slotTapped(UUID)
        case clearSlotTapped(UUID)
        case filterStartDateChanged(Date?)
        case filterEndDateChanged(Date?)
        case autoFillTapped
        case autoFillCompleted([UUID: (photos: Set<String>, pillarID: UUID?, locationLabel: String?)])
        case reshuffleSlotTapped(UUID)
        case reshuffleSlotCompleted(slotID: UUID, photos: Set<String>, pillarID: UUID?, locationLabel: String?)
        case generateCaptionTapped
        case captionGenerated(caption: String, hashtags: [String])
        case captionGenerationFailed
        case closeTapped
        case saveDraftTapped
        case saved
        case copyTapped
        case shareTapped
        case shareImagesLoaded([UIImage])
        case shareDismissed
        case slotFiller(PresentationAction<SlotFillerFeature.Action>)
        case delegate(Delegate)

        enum Delegate: Equatable {
            case didSave
        }
    }

    @Dependency(\.persistence) var persistence
    @Dependency(\.postGenerator) var postGenerator
    @Dependency(\.photoLibrary) var photoLibrary
    @Dependency(\.dismiss) var dismiss

    private enum CancelID: Hashable { case generation }

    var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case let .slotTapped(slotID):
                guard let slot = state.filledSlots.first(where: { $0.id == slotID }) else {
                    return .none
                }
                state.slotFiller = SlotFillerFeature.State(
                    slotID: slotID,
                    slotName: slot.slotData.name,
                    constrainedPillarIDs: slot.slotData.pillarIDs,
                    constrainedCadrages: slot.slotData.cadrages,
                    constrainedLocations: state.template.locations,
                    preselectedPhotoIDs: slot.photoIDs
                )
                return .none

            case let .clearSlotTapped(slotID):
                if let index = state.filledSlots.firstIndex(where: { $0.id == slotID }) {
                    state.filledSlots[index].photoIDs = []
                }
                return .none

            case let .filterStartDateChanged(date):
                state.filterStartDate = date
                return .none

            case let .filterEndDateChanged(date):
                state.filterEndDate = date
                return .none

            case .autoFillTapped:
                let emptySlots = state.filledSlots.filter(\.isEmpty)
                guard !emptySlots.isEmpty else { return .none }
                let templateLocations = state.template.locations
                let startDate = state.filterStartDate.flatMap {
                    Calendar.current.startOfDay(for: $0)
                }
                let endDate = state.filterEndDate.flatMap {
                    Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: $0))
                }
                return .run { send in
                    var result: [UUID: (photos: Set<String>, pillarID: UUID?, locationLabel: String?)] = [:]
                    var usedIDs: Set<String> = []
                    for slot in emptySlots {
                        let pillarIDs = slot.slotData.pillarIDs
                        let allPhotos: [ClassifiedPhotoSnapshot]
                        if pillarIDs.isEmpty {
                            allPhotos = try await persistence.fetchPhotos(.classified)
                        } else {
                            var photos: [ClassifiedPhotoSnapshot] = []
                            for pillarID in pillarIDs {
                                let pillarPhotos = try await persistence.fetchPhotosForPillar(pillarID)
                                photos.append(contentsOf: pillarPhotos)
                            }
                            allPhotos = photos
                        }
                        var available = allPhotos.filter { !usedIDs.contains($0.assetLocalIdentifier) }
                        if !templateLocations.isEmpty {
                            let locationFiltered = available.filter { photo in
                                guard let loc = photo.location else { return false }
                                return templateLocations.contains(loc)
                            }
                            if !locationFiltered.isEmpty { available = locationFiltered }
                        }
                        if startDate != nil || endDate != nil {
                            let dateFiltered = available.filter { photo in
                                guard let captured = photo.capturedAt else { return false }
                                if let s = startDate, captured < s { return false }
                                if let e = endDate, captured > e { return false }
                                return true
                            }
                            if !dateFiltered.isEmpty { available = dateFiltered }
                        }
                        if let picked = available.randomElement() {
                            result[slot.id] = (photos: [picked.assetLocalIdentifier], pillarID: picked.pillarID, locationLabel: picked.location)
                            usedIDs.insert(picked.assetLocalIdentifier)
                        }
                    }
                    await send(.autoFillCompleted(result))
                }

            case let .autoFillCompleted(fills):
                for (slotID, fill) in fills {
                    if let index = state.filledSlots.firstIndex(where: { $0.id == slotID }) {
                        state.filledSlots[index].photoIDs = fill.photos
                        state.filledSlots[index].activePillarID = fill.pillarID
                        state.filledSlots[index].locationLabel = fill.locationLabel
                    }
                }
                return .none

            case let .reshuffleSlotTapped(slotID):
                guard let slot = state.filledSlots.first(where: { $0.id == slotID }) else {
                    return .none
                }
                let currentIDs = slot.photoIDs
                let otherUsedIDs = Set(state.filledSlots.filter { $0.id != slotID }.flatMap { Array($0.photoIDs) })
                let pillarIDs = slot.slotData.pillarIDs
                let slotLocations = slot.slotData.locations
                let templateLocations = state.template.locations
                let slotStartDate = slot.slotData.startDate
                let slotEndDate = slot.slotData.endDate
                let filterStartDate = state.filterStartDate.flatMap {
                    Calendar.current.startOfDay(for: $0)
                }
                let filterEndDate = state.filterEndDate.flatMap {
                    Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: $0))
                }
                return .run { send in
                    let allPhotos: [ClassifiedPhotoSnapshot]
                    if pillarIDs.isEmpty {
                        allPhotos = try await persistence.fetchPhotos(.classified)
                    } else {
                        var photos: [ClassifiedPhotoSnapshot] = []
                        for pillarID in pillarIDs {
                            photos.append(contentsOf: try await persistence.fetchPhotosForPillar(pillarID))
                        }
                        allPhotos = photos
                    }
                    var available = allPhotos.filter {
                        !otherUsedIDs.contains($0.assetLocalIdentifier) &&
                        !currentIDs.contains($0.assetLocalIdentifier)
                    }
                    let locationsToMatch = !slotLocations.isEmpty ? slotLocations : templateLocations
                    if !locationsToMatch.isEmpty {
                        let locationFiltered = available.filter { photo in
                            guard let loc = photo.location else { return false }
                            return locationsToMatch.contains(loc)
                        }
                        if !locationFiltered.isEmpty { available = locationFiltered }
                    }
                    let startDate = slotStartDate ?? filterStartDate
                    let endDate = slotEndDate ?? filterEndDate
                    if startDate != nil || endDate != nil {
                        let dateFiltered = available.filter { photo in
                            guard let captured = photo.capturedAt else { return false }
                            if let s = startDate, captured < s { return false }
                            if let e = endDate, captured > e { return false }
                            return true
                        }
                        if !dateFiltered.isEmpty { available = dateFiltered }
                    }
                    if let picked = available.randomElement() {
                        await send(.reshuffleSlotCompleted(slotID: slotID, photos: [picked.assetLocalIdentifier], pillarID: picked.pillarID, locationLabel: picked.location))
                    } else if let fallback = allPhotos.filter({ !otherUsedIDs.contains($0.assetLocalIdentifier) }).randomElement() {
                        await send(.reshuffleSlotCompleted(slotID: slotID, photos: [fallback.assetLocalIdentifier], pillarID: fallback.pillarID, locationLabel: fallback.location))
                    }
                }

            case let .reshuffleSlotCompleted(slotID, photos, pillarID, locationLabel):
                if let index = state.filledSlots.firstIndex(where: { $0.id == slotID }) {
                    state.filledSlots[index].photoIDs = photos
                    state.filledSlots[index].activePillarID = pillarID
                    state.filledSlots[index].locationLabel = locationLabel
                }
                return .none

            case .generateCaptionTapped:
                guard !state.allPhotoIDs.isEmpty else { return .none }
                state.isGenerating = true
                let photoIDs = state.allPhotoIDs
                let templateName = state.template.name
                let fetchImage = photoLibrary.image
                let generateCaption = postGenerator.generateCaption
                let generateHashtags = postGenerator.generateHashtags
                let pillar = PillarSnapshot(name: templateName, emoji: "📝")
                return .run { send in
                    var images: [UIImage] = []
                    for id in photoIDs.prefix(4) {
                        if let img = try? await fetchImage(id, CGSize(width: 512, height: 512)) {
                            images.append(img)
                        }
                    }
                    let caption = try await generateCaption(images, pillar, .instagram)
                    let hashtags = try await generateHashtags(caption, pillar, .instagram)
                    await send(.captionGenerated(caption: caption, hashtags: hashtags))
                } catch: { _, send in
                    await send(.captionGenerationFailed)
                }
                .cancellable(id: CancelID.generation)

            case let .captionGenerated(caption, hashtags):
                state.caption = caption
                state.hashtags = hashtags
                state.isGenerating = false
                return .none

            case .captionGenerationFailed:
                state.isGenerating = false
                return .none

            case .closeTapped:
                return .run { _ in await dismiss() }

            case .saveDraftTapped:
                let hasContent = !state.allPhotoIDs.isEmpty || !state.caption.isEmpty
                guard hasContent else {
                    return .run { _ in await dismiss() }
                }
                let snapshot = GeneratedPostSnapshot(
                    pillarID: UUID(),
                    templateID: state.template.id,
                    photoIDs: state.allPhotoIDs,
                    caption: state.caption,
                    hashtags: state.hashtags,
                    status: .draft
                )
                return .run { send in
                    try await persistence.savePost(snapshot)
                    await send(.saved)
                }

            case .saved:
                return .merge(
                    .send(.delegate(.didSave)),
                    .run { _ in await dismiss() }
                )

            case .copyTapped:
                var text = state.caption
                if !state.hashtags.isEmpty {
                    text += "\n\n" + state.hashtags.joined(separator: " ")
                }
                UIPasteboard.general.string = text
                return .none

            case .shareTapped:
                guard !state.allPhotoIDs.isEmpty else { return .none }
                state.isLoadingShare = true
                let photoIDs = state.allPhotoIDs
                let captionText = state.caption
                let hashtagText = state.hashtags.joined(separator: " ")
                let fetchImage = photoLibrary.image
                return .run { send in
                    var images: [UIImage] = []
                    for id in photoIDs {
                        if let img = try? await fetchImage(id, CGSize(width: 1080, height: 1080)) {
                            images.append(img)
                        }
                    }
                    if !captionText.isEmpty || !hashtagText.isEmpty {
                        var text = captionText
                        if !hashtagText.isEmpty {
                            text += text.isEmpty ? hashtagText : "\n\n" + hashtagText
                        }
                        UIPasteboard.general.string = text
                    }
                    await send(.shareImagesLoaded(images))
                }

            case let .shareImagesLoaded(images):
                state.isLoadingShare = false
                state.shareImages = images
                return .none

            case .shareDismissed:
                state.shareImages = nil
                return .none

            case let .slotFiller(.presented(.delegate(.didConfirm(slotID, photoIDs, locationLabel)))):
                if let index = state.filledSlots.firstIndex(where: { $0.id == slotID }) {
                    state.filledSlots[index].photoIDs = photoIDs
                    state.filledSlots[index].locationLabel = locationLabel
                }
                return .none

            case .slotFiller, .delegate, .binding:
                return .none
            }
        }
        .ifLet(\.$slotFiller, action: \.slotFiller) {
            SlotFillerFeature()
        }
    }
}
