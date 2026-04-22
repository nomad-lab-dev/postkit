# PostKit — Build Guide
### Follow alongside Xcode + Claude Code · One slice per session

---

## How to use this guide

1. Open this file on one screen. Xcode + Claude Code on the other.
2. Work one slice at a time. Don't start the next slice until the current one passes its ✅ checklist.
3. Each slice has a **Claude Code prompt** — paste it at the very start of a new `claude` session in the project folder.
4. Architecture rules never change — they're in `CLAUDE.md` at the repo root. Claude reads it automatically.
5. When stuck: read the architecture reference in `docs/briefs/16-dev-programme.md`.

**Session startup** (every time you open Claude Code):
```bash
cd ~/Desktop/GithubRepos/PillarBox
claude
```

---

## Prerequisites — Before Slice 0

- [ ] Xcode 16+ installed
- [ ] iOS 18 simulator available
- [ ] Google Generative AI SDK URL ready: `https://github.com/google/generative-ai-swift`
- [ ] Gemini API key ready (get one free at aistudio.google.com)

---

---

# SLICE 0 · Project Foundation
**Delivers:** Runnable Xcode project · DI container · SwiftData stack · Empty screens · Tab navigation

---

### Step 1 · Create the Xcode project

- [ ] Xcode → File → New → Project → App
- [ ] Product Name: `PostKit`
- [ ] Bundle Identifier: `com.yourname.postkit`
- [ ] Interface: **SwiftUI**
- [ ] Language: **Swift**
- [ ] Storage: **SwiftData** ← important, check this
- [ ] Minimum Deployments: **iOS 18.0**
- [ ] Save to: `~/Desktop/GithubRepos/PillarBox/`
- [ ] Create Git repository: **yes**

---

### Step 2 · Add Google Generative AI Swift Package

- [ ] File → Add Package Dependencies…
- [ ] Paste URL: `https://github.com/google/generative-ai-swift`
- [ ] Version rule: Up to Next Major
- [ ] Add to target: **PostKit**

---

### Step 3 · Create the folder structure

In Xcode, create these groups (right-click → New Group):

```
PostKit/
├── App/
│   ├── PostKitApp.swift        ← already created by Xcode
│   └── AppContainer.swift      ← new
├── Models/
│   ├── Pillar.swift
│   ├── ClassifiedPhoto.swift
│   └── GeneratedPost.swift
├── Services/
│   ├── Protocols/
│   │   ├── PhotoLibraryService.swift
│   │   ├── ImageClassifierService.swift
│   │   ├── PersistenceService.swift
│   │   └── PostGeneratorService.swift
│   └── Live/
│       ├── LivePhotoLibraryService.swift
│       ├── HybridClassifierService.swift
│       ├── LivePersistenceService.swift
│       └── GeminiPostGeneratorService.swift
├── ViewModels/
├── Views/
│   ├── Onboarding/
│   ├── Dashboard/
│   ├── Classification/
│   ├── Explore/
│   ├── PostAssembly/
│   └── Shared/
├── Navigation/
│   ├── AppRouter.swift
│   └── Routes.swift
└── Utilities/
    └── AppStrings.swift
```

---

### Step 4 · Add Secrets.xcconfig (never commit this)

- [ ] File → New → File → Configuration Settings File → `Secrets.xcconfig`
- [ ] Add to project root (not a target)
- [ ] Add content:

```
GEMINI_API_KEY = paste_your_key_here
```

- [ ] In Info.plist, add key `GEMINI_API_KEY` → value `$(GEMINI_API_KEY)`
- [ ] Add `Secrets.xcconfig` to `.gitignore`

---

### Step 5 · Claude Code prompt for this slice

Open Claude Code in the project folder and paste:

```
I'm building PostKit — an iOS 18+ SwiftUI app that uses AI to classify 
camera roll photos into content pillars and auto-generate social media posts.

Read CLAUDE.md first — it defines the full stack, architecture rules, and naming.

For this session, build Slice 0: Project Foundation.

Deliver:
1. All SwiftData @Model classes: Pillar, ClassifiedPhoto, GeneratedPost 
   (with all fields from the dev programme in docs/briefs/16-dev-programme.md)
2. All 4 service protocols (PhotoLibraryService, ImageClassifierService, 
   PersistenceService, PostGeneratorService) — protocol only, no implementation yet
3. EnvironmentValues extensions using @Entry macro for all 4 services
4. AppRouter (@Observable @MainActor) with HomeRoute, ClassifyRoute, CreateRoute enums
5. RootView with TabView (4 tabs: Home, Classify, Create, Settings) 
   using NavigationStack per tab
6. Empty placeholder Views for: DashboardView, ClassificationQueueView, 
   ExploreView, PostAssemblyView — each just shows a Text with screen name
7. PostKitApp.swift wired up with ModelContainer and AppRouter in environment

Architecture rules (from CLAUDE.md):
- @Observable, never ObservableObject
- @Entry for DI, never EnvironmentObject  
- @MainActor on all ViewModels
- Zero logic in Views
- Swift 6 Sendable on all service protocols

The app should compile and launch to an empty Dashboard tab with a tab bar.
```

---

### ✅ Slice 0 is done when:
- [ ] Project compiles with zero errors
- [ ] App launches in simulator to Dashboard tab
- [ ] Tab bar shows 4 tabs: Home / Classify / Create / Settings
- [ ] All 4 service protocols exist with correct method signatures
- [ ] All 3 SwiftData models exist with all fields
- [ ] No hardcoded data anywhere

---
---

# SLICE 1 · Onboarding
**Delivers:** Welcome screen → Photo permission → Quick Scan (20 photos) → Pillar suggestions → Save → dismiss to Dashboard

```
┌──────────────────────────────┐
│         PostKit              │   Screen 1: Welcome
│                              │
│   Turn your camera roll      │
│   into daily content.        │
│                              │
│  📸  Camera Roll             │
│  🧠  AI Classification       │
│  🎯  Content Pillars         │
│  ✦   Ready to Post           │
│                              │
│  [ Get Started → ]           │
└──────────────────────────────┘
         ↓ tap
┌──────────────────────────────┐
│   Scanning your photos…      │   Screen 2: Quick Scan
│                              │
│      [Progress ring]         │
│         14 / 20              │
│                              │
│  [Live 3-col thumbnail grid] │
│   photos appear as scanned   │
└──────────────────────────────┘
         ↓ done
┌──────────────────────────────┐
│   We found your pillars      │   Screen 3: Suggestions
│                              │
│  🚗 Automotive  [✓]  [−]    │
│     47 photos                │
│  🌍 Travel      [✓]  [−]    │
│     32 photos                │
│  ☕ Food        [✓]  [−]    │
│     18 photos                │
│  + Add a pillar              │
│                              │
│  [ Start PostKit → ]         │
└──────────────────────────────┘
```

---

### Key behaviours

- **Permission flow**: request `.readWrite` authorization before scanning. If denied → show settings deeplink, don't crash.
- **Quick Scan**: fetch last 20 `PHAsset` from PhotoKit → resize to 299×299 → run `HybridClassifierService` → group results by predicted pillar name.
- **Suggestions**: deduplicate pillar names, show top 5 by photo count. User can remove any.
- **Confirm**: `PersistenceService.save(pillars)` → dismiss sheet → Dashboard loads with real data.
- **Onboarding only shows once**: check `UserDefaults.standard.bool(forKey: "onboardingComplete")` in `RootView`.

---

### Step 1 · Implement LivePhotoLibraryService

Before writing the View, the service must exist. This is what Claude Code builds first.

Needed methods for this slice:
```swift
func requestAuthorization() async -> PHAuthorizationStatus
func fetchRecentPhotos(limit: Int) async throws -> [PHAsset]
func image(for asset: PHAsset, targetSize: CGSize) async throws -> UIImage
```

---

### Step 2 · Implement HybridClassifierService (stub for now)

For Slice 1, Gemini isn't needed yet. Build a stub that returns a random pillar from a fixed list — real Core ML comes in Slice 2.

```swift
// Stub for onboarding — replace with real Core ML in Slice 2
actor HybridClassifierService: ImageClassifierService {
    private let knownPillars = ["Automotive", "Travel", "Food", "Business", "Fitness", "Behind the Scenes"]
    
    func classify(_ image: UIImage) async throws -> ClassificationResult {
        let pillar = knownPillars.randomElement()!
        return ClassificationResult(
            pillarName: pillar,
            confidence: Float.random(in: 0.65...0.95),
            suggestedTags: [],
            source: .coreML
        )
    }
}
```

---

### Step 3 · Claude Code prompt for this slice

```
Working on PostKit — iOS 18+ SwiftUI. Read CLAUDE.md.

Slice 1: Onboarding flow (full vertical slice).

Deliver:
1. OnboardingViewModel (@Observable @MainActor):
   - step: OnboardingStep enum (.welcome | .scanning(Double) | .suggestions([PillarSuggestion]))
   - func startQuickScan() async — fetches 20 recent PHAssets, classifies each, 
     groups into PillarSuggestion array (name, emoji, photoCount)
   - func confirmPillars(_ selected: [PillarSuggestion]) async — saves to PersistenceService
   - injected: PhotoLibraryService, ImageClassifierService, PersistenceService via init

2. OnboardingView — full sheet with 3 steps driven by viewModel.step:
   - .welcome: app logo, 4 feature bullets with entrance animation, "Get Started" button
   - .scanning(progress): circular progress ring, live 3-col photo grid (thumbnails 
     appear as they're classified), pillar emoji overlaid on each thumb
   - .suggestions: list of PillarSuggestion rows with confirm/remove toggles, 
     "Start PostKit" CTA button
   
3. LivePhotoLibraryService implementing PhotoLibraryService:
   - requestAuthorization() — PHPhotoLibrary.requestAuthorization(.readWrite)
   - fetchRecentPhotos(limit:) — PHAsset.fetchAssets sorted by creationDate desc
   - image(for:targetSize:) — PHImageManager.default().requestImage async

4. HybridClassifierService stub (random pillar, real Core ML in Slice 2)

5. In RootView: show OnboardingView as .sheet if UserDefaults "onboardingComplete" == false
   After confirmPillars succeeds → set UserDefaults flag → dismiss sheet

Architecture:
- @Observable on ViewModel, @MainActor
- Services injected via @Environment
- No logic in Views, no hardcoded data
- Handle PHAuthorizationStatus.denied gracefully (show alert with Settings deeplink)
- The scanning loop must use Swift concurrency (Task + withThrowingTaskGroup)
```

---

### ✅ Slice 1 is done when:
- [ ] Fresh install shows Onboarding sheet on launch
- [ ] "Get Started" requests photo permission
- [ ] If denied: alert with link to Settings, not a crash
- [ ] Quick Scan visibly processes 20 photos with live progress
- [ ] Suggestions screen shows ≥ 1 pillar with photo count
- [ ] Tapping "Start PostKit" dismisses the sheet
- [ ] Dashboard is now visible (empty state OK)
- [ ] Second launch does NOT show onboarding again

---
---

# SLICE 2 · Dashboard + Full Scan
**Delivers:** Pillar cards with metrics · Live scan progress · Full library scan in background

```
┌──────────────────────────────┐
│  Dashboard              [+]  │
├──────────────────────────────┤
│  ┌───────────┬─────────────┐ │
│  │ 155       │ 6           │ │
│  │ Photos    │ Active      │ │
│  │ sorted    │ Pillars     │ │
│  └───────────┴─────────────┘ │
│                              │
│  YOUR PILLARS                │
│  ┌────────────────────────┐  │
│  │ 🚗 Automotive    47 ↗  │  │  ← tap → PillarDetailView (Slice 6)
│  │ ████████░░ 84%  3/wk   │  │
│  ├────────────────────────┤  │
│  │ 🌍 Travel        32 ↗  │  │
│  │ ██████░░░░ 64%  2/wk   │  │
│  └────────────────────────┘  │
│                              │
│  [Scanning library… 42%  ✕]  │  ← live progress bar, tap ✕ to cancel
└──────────────────────────────┘
```

---

### Key behaviours

- **Full Scan** starts automatically when Dashboard appears for the first time after onboarding.
- Processes the entire library in batches of 30 photos (older → newer), background `Task`.
- Dashboard pillar cards update in real time as photos are classified.
- Scan persists across app backgrounding (use `BackgroundTasks` framework).
- Real Core ML classifier goes here — replace the stub from Slice 1.

---

### Core ML setup

- [ ] Download `MobileNetV2.mlmodel` from Apple's Core ML Model Gallery
- [ ] Drag into Xcode project → check "Add to target: PostKit"
- [ ] The Vision request maps MobileNet labels to your pillar names via a mapping dict

```swift
// Pillar name mapping — MobileNet label → PostKit pillar
let labelToPillar: [String: String] = [
    "sports car": "Automotive",
    "racing car": "Automotive",
    "convertible": "Automotive",
    "airliner": "Travel",
    "lakeside": "Travel",
    "seashore": "Travel",
    "espresso": "Food",
    "pizza": "Food",
    "cheeseburger": "Food",
    // expand as needed
]
```

---

### Step 1 · Claude Code prompt for this slice

```
Working on PostKit — iOS 18+ SwiftUI. Read CLAUDE.md.

Slice 2: Dashboard + Full Library Scan.

Deliver:
1. DashboardViewModel (@Observable @MainActor):
   - pillars: [Pillar] — loaded from PersistenceService on appear
   - totalPhotosSorted: Int
   - isScanning: Bool
   - scanProgress: Double (0.0–1.0)
   - scanTask: Task? (for cancellation)
   - func startFullScan() — launches background Task consuming AsyncStream<[PHAsset]>
     from photoLibraryService.fetchAllPhotos(batchSize: 30), classifies each batch
     with withThrowingTaskGroup, saves ClassifiedPhoto via persistenceService
   - func cancelScan()
   - Pillars update live as scan progresses (don't wait for full completion)

2. DashboardView:
   - 2-column metric header (total photos sorted, active pillar count)
   - Scrollable list of PillarRowView (emoji, name, progress bar, photo count, freq)
   - Tapping a pillar row navigates to HomeRoute.pillarDetail(pillar) — 
     placeholder PillarDetailView is fine, built in Slice 6
   - Live scan progress bar at bottom (dismiss button cancels Task)
   - [+] nav button → HomeRoute.pillarEditor(nil)
   - Empty state when no pillars: "Add your first pillar" button

3. LivePhotoLibraryService.fetchAllPhotos(batchSize:) → AsyncStream<[PHAsset]>
   Full library sorted by creationDate desc, chunked into batches

4. Real HybridClassifierService (replace stub from Slice 1):
   - VNCoreMLModel from MobileNetV2.mlmodel
   - VNCoreMLRequest in async continuation
   - Map top label to pillar name via labelToPillar dict
   - If confidence < 0.70 OR label not in dict → Gemini Flash fallback
   - Gemini call: send base64 image with prompt asking for pillar classification
     from the user's pillar list

5. LivePersistenceService implementing PersistenceService:
   - All CRUD operations using @ModelContext from ModelContainer
   - fetchPillars(), save(photo:), fetchPhotos(status:) etc.

Architecture:
- Full Scan MUST use AsyncStream + withThrowingTaskGroup (showcase concurrency)
- Actor isolation on HybridClassifierService
- @MainActor updates on DashboardViewModel
- Task cancellation via scanTask?.cancel() on view disappear
```

---

### ✅ Slice 2 is done when:
- [ ] Dashboard shows pillar cards with real data from SwiftData
- [ ] Photo count and progress bar update live during scan
- [ ] Scan can be cancelled cleanly (no crash, task properly cancelled)
- [ ] Core ML classifies a photo successfully (check with a print)
- [ ] Gemini fallback is called when Core ML confidence < 70%
- [ ] Pillar photo counts persist across app restart

---
---

# SLICE 3 · Classification (Queue + Swipe Card)
**Delivers:** Photo queue grid → Swipe card with AI suggestion → Confirm/Reject → Updates pillar count

```
┌──────────────────────────────┐
│  ← Back    Classify  Filter  │  Queue View (tab 📸)
├──────────────────────────────┤
│  38 photos to review         │
│  ┌─────┬─────┬─────┐         │
│  │[img]│[img]│[img]│         │  ? = pending
│  │ 🚗? │ 🌍? │  ?  │         │  emoji = AI suggestion
│  ├─────┼─────┼─────┤         │
│  │[img]│[img]│[img]│         │
│  └─────┴─────┴─────┘         │
│  [Classify All — Accept AI]  │
└──────────────────────────────┘
         ↓ tap photo
┌──────────────────────────────┐
│  ← Library  Classify  Filter │  Classification Card
│  🚗 Automotive  ████░░  7/38 │
│                              │
│  ┌──────────────────────┐    │
│  │                      │    │
│  │    [Full photo]      │    │  ← swipe right = confirm
│  │                      │    │    swipe left = reject
│  │    AI 87% ✓          │    │
│  │                      │    │
│  │  track day  porsche  │    │
│  │  📍 Barcelona        │    │
│  └──────────────────────┘    │
│                              │
│    [✕ Reject] [↩] [✓ Keep]   │
└──────────────────────────────┘
```

---

### Key behaviours

- Queue shows only `ClassifiedPhoto` with `.pending` status.
- Tapping a photo in the queue opens the swipe card at that index.
- **Swipe right** = confirm AI suggestion → `photo.status = .classified`.
- **Swipe left** = reject → `photo.status = .rejected`.
- **Undo** = restore previous photo's status.
- **Classify All** = accept AI suggestion on all pending photos in one batch.
- After confirming, pillar's photo count updates immediately on Dashboard.
- Tags are editable inline (tap chip to remove, tap + to add).

---

### Step 1 · Claude Code prompt for this slice

```
Working on PostKit — iOS 18+ SwiftUI. Read CLAUDE.md.

Slice 3: Classification — Queue view + Swipe card.

Deliver:
1. ClassificationViewModel (@Observable @MainActor):
   - pendingPhotos: [ClassifiedPhoto] from PersistenceService
   - currentIndex: Int
   - currentAsset: PHAsset? (loaded from assetLocalIdentifier)
   - currentImage: UIImage?
   - isLoading: Bool
   - undoStack: [(ClassifiedPhoto, ClassifiedPhoto.PhotoStatus)] for undo
   - func loadQueue() async
   - func confirm(pillar: Pillar) async — sets status .classified, pillarID
   - func reject() async — sets status .rejected
   - func undo() async
   - func acceptAll() async — batch update all pending to .classified with AI suggestion
   - func advance() — move to next index

2. ClassificationQueueView (tab 📸):
   - 3-column LazyVGrid of pending photos
   - Each cell shows thumbnail + pillar emoji overlay if AI suggestion exists
   - "38 photos to review" header
   - "Classify All" button
   - Tap → navigate to ClassifyRoute.classify(asset) at that index

3. ClassificationView (the swipe card):
   - Full-screen photo display
   - Pillar name + progress bar header (current index / total)
   - AI confidence badge (green if ≥ 70%, yellow if < 70%)
   - Editable tag chips at bottom
   - Swipe gesture: DragGesture, threshold 80pt left/right
   - Card rotates slightly during drag (visual feedback)
   - ✕ / ↩ / ✓ buttons at bottom (same actions as swipe)
   - After confirm/reject: advance to next photo with card-flip transition

Architecture:
- DragGesture offset tracked in @State, NOT in ViewModel
- ViewModel never imports SwiftUI (pure logic)
- Photos fetched lazily — don't load all UIImages at once, load current + prefetch next 2
- Task cancellation when view disappears
```

---

### ✅ Slice 3 is done when:
- [ ] Queue tab shows correct count of pending photos
- [ ] Tapping a photo opens the swipe card
- [ ] Swipe right confirms, swipe left rejects
- [ ] Undo restores the last photo's state
- [ ] "Classify All" batch-updates all pending
- [ ] Dashboard pillar count updates after classification
- [ ] Swiping through all photos returns to the queue (empty state)

---
---

# SLICE 4 · Explore Grid
**Delivers:** Full classified photo grid · Filter by pillar, status, date, location

```
┌──────────────────────────────┐
│  Explore              Filter │
├──────────────────────────────┤
│  [All] [🚗] [🌍] [☕] [💼]   │  ← horizontal scroll pill filter
├──────────────────────────────┤
│  ┌─────┬─────┬─────┐         │
│  │[img]│[img]│[img]│         │
│  │ 🚗  │ 🌍  │ 🚗  │         │
│  ├─────┼─────┼─────┤         │
│  │[img]│[img]│[img]│         │
│  │ ☕  │ 💼  │ 🌍  │         │
│  └─────┴─────┴─────┘         │
│                              │
│  [Cadrage] [Lieu] [Moment]   │  ← secondary filter chips
└──────────────────────────────┘
```

---

### Step 1 · Claude Code prompt for this slice

```
Working on PostKit — iOS 18+ SwiftUI. Read CLAUDE.md.

Slice 4: Explore Grid.

Deliver:
1. ExploreViewModel (@Observable @MainActor):
   - allPhotos: [ClassifiedPhoto]
   - filteredPhotos: [ClassifiedPhoto] (computed from filters)
   - selectedPillar: Pillar? 
   - statusFilter: ClassifiedPhoto.PhotoStatus?
   - locationFilter: String?
   - func applyFilters() — queries SwiftData with NSPredicate based on active filters
   - func loadPhotos() async

2. ExploreView:
   - Horizontal pill scroll for pillar filter (All + one per pillar)
   - Active pill highlighted in pillar color
   - 3-column LazyVGrid, each cell:
     - Thumbnail image (loaded lazily via PhotoLibraryService)
     - Pillar emoji badge (bottom-left overlay)
     - Status indicator: classified (✓), pending (?), rejected (✗)
   - Secondary filter row: Framing | Location | Moment | Status chips
   - Tapping a photo opens full-screen view (modal sheet, no navigation)
   - Tapping a pending photo navigates to ClassifyRoute.classify(asset)
   - Empty state: "No photos yet — start classifying" with button

Architecture:
- LazyVGrid with on-demand image loading only (no full UIImage array in memory)
- Filters applied via SwiftData @Query with dynamic predicates
- Smooth pillar filter animation (matched geometry effect on pill indicator)
```

---

### ✅ Slice 4 is done when:
- [ ] All classified photos appear in the grid
- [ ] Tapping a pillar pill filters correctly
- [ ] Secondary filters work independently (and compose with pillar filter)
- [ ] Scrolling through 100+ photos is smooth (no janking)
- [ ] Tapping a pending photo goes to classification
- [ ] Empty state shows when no photos match filter

---
---

# SLICE 5 · Post Assembly
**Delivers:** Photo selection → AI caption generation → Platform tabs → Export sheet

```
┌──────────────────────────────┐
│  ← Automotive  Post Builder  │  Step 1: Photo + Caption
│                        Save  │
├──────────────────────────────┤
│  [img✓][img ][img ][img ][+] │  ← horizontal photo strip
├──────────────────────────────┤
│  Instagram  LinkedIn  Twitter│
├──────────────────────────────┤
│  ┌────────────────────────┐  │
│  │ [selected photo]       │  │
│  │ 🚗 Automotive          │  │
│  │ ✦ AI Generated         │  │
│  │ Track day at Circuit…  │  │  ← editable
│  │ #automotive #trackday  │  │
│  │              218/2200  │  │
│  └────────────────────────┘  │
│  ┌──┐ ┌────────────────────┐ │
│  │🔄│ │ Post to Instagram  │ │
│  └──┘ └────────────────────┘ │
└──────────────────────────────┘
         ↓ "Post to Instagram"
┌──────────────────────────────┐
│  Share                  Done │  Step 2: Platform Export
├──────────────────────────────┤
│  [Post mini preview]         │
│                              │
│  SHARE TO                    │
│  📸 Instagram    [ON  ●]    │
│  💼 LinkedIn     [ON  ●]    │
│  𝕏  Twitter      [off ○]   │
│                              │
│  [ Share Now  [2] ]          │  ← triggers iOS Share Sheet
└──────────────────────────────┘
```

---

### Key behaviours

- Post Assembly is reached by tapping a pillar card on Dashboard.
- Photo selection: shows all classified photos for that pillar, multi-select up to 10.
- AI caption is generated by `PostGeneratorService` (Gemini Flash) for the selected platform.
- Caption is editable inline — user can tweak before posting.
- Switching platform tabs regenerates the caption (adapted tone/length).
- "Share Now" opens the native iOS `ShareLink` / `UIActivityViewController`.
- Save button saves a `GeneratedPost` to SwiftData (status: `.ready`).

---

### Step 1 · Claude Code prompt for this slice

```
Working on PostKit — iOS 18+ SwiftUI. Read CLAUDE.md.

Slice 5: Post Assembly — full vertical slice.

Deliver:
1. PostAssemblyViewModel (@Observable @MainActor):
   - pillar: Pillar (injected)
   - eligiblePhotos: [ClassifiedPhoto] (all .classified for this pillar)
   - selectedAssets: [String] (assetLocalIdentifiers, max 10)
   - currentPlatform: SocialPlatform = .instagram
   - caption: String (editable)
   - hashtags: [String]
   - isGenerating: Bool
   - generationTask: Task? (for cancellation on platform switch)
   - func loadPhotos() async
   - func togglePhoto(_ id: String) — add/remove from selectedAssets
   - func generateCaption() async throws — calls PostGeneratorService
   - func regenerate() async throws — cancels in-flight, generates new
   - func switchPlatform(_ platform: SocialPlatform) — regenerates caption
   - func savePost() async throws -> GeneratedPost

2. PostAssemblyView (reached from Dashboard pillar tap → CreateRoute):
   - Horizontal photo strip (thumbnails, selected = purple border + checkmark)
   - Platform tab bar (Instagram / LinkedIn / Twitter)
   - Post preview card: photo, pillar tag, "✦ AI Generated" chip, caption TextEditor,
     hashtag pills, character count
   - 🔄 regenerate button + primary "Post to [Platform]" CTA button
   - Generating state: skeleton/shimmer over caption area

3. PlatformExportView (sheet pushed from CTA):
   - Post mini-preview card
   - Toggle rows for each platform (iOS-style UISwitch)
   - "Share Now [N]" button → UIActivityViewController via ShareLink
   - Each platform generates adapted copy before sharing

4. GeminiPostGeneratorService implementing PostGeneratorService:
   - generateCaption(for:pillar:platform:) — sends image(s) + pillar context to Gemini Flash
   - Prompt includes: pillar name, tone, topics, platform character limit
   - generateHashtags(caption:pillar:platform:) — separate Gemini call for hashtags
   - Use structured output (JSON mode) for reliable parsing

Architecture:
- Caption generation MUST be cancellable (generationTask?.cancel())
- TextEditor for caption (not Text) — user should be able to edit
- Character counter turns red when approaching platform limit
- No hardcoded captions
```

---

### ✅ Slice 5 is done when:
- [ ] Tapping a pillar on Dashboard opens Post Assembly for that pillar
- [ ] Photo strip shows all classified photos for the pillar
- [ ] Selecting photos and switching platforms regenerates the caption
- [ ] Caption is editable (user can type freely)
- [ ] Character count is accurate and warns near platform limit
- [ ] 🔄 button generates a different caption
- [ ] "Share Now" opens iOS share sheet with correct text
- [ ] Post is saved to SwiftData after sharing

---
---

# SLICE 6 · Pillar Editor
**Delivers:** Create new pillar · Edit existing pillar · Emoji picker · Tone selector · Topics chips · Frequency control

```
┌──────────────────────────────┐
│  ← Dashboard  Edit Pillar    │
│                        Save  │
├──────────────────────────────┤
│        [🚗]                  │  ← tap to open emoji picker
│      Automotive              │
│   47 photos · 84% coverage   │
├──────────────────────────────┤
│  PILLAR NAME                 │
│  [Automotive          ]      │
│  ABOUT THIS PILLAR           │
│  [Cars, track days…   ]      │
│  BRAND TONE                  │
│  [Casual][Technical✓][Inspi] │
│  TOPICS                      │
│  [#automotive][#trackday][+] │
│  POSTING FREQUENCY           │
│  Posts per week  [−] 3 [+]   │
├──────────────────────────────┤
│  [ 🚗 Save Pillar ]          │
└──────────────────────────────┘
```

---

### Step 1 · Claude Code prompt for this slice

```
Working on PostKit — iOS 18+ SwiftUI. Read CLAUDE.md.

Slice 6: Pillar Editor (create + edit).

Deliver:
1. PillarEditorViewModel (@Observable @MainActor):
   - mode: EditorMode (.create | .edit(Pillar))
   - name: String, emoji: String, about: String
   - tone: PillarTone, topics: [String], postsPerWeek: Int, colorHex: String
   - isValid: Bool (name not empty, emoji not empty)
   - func save() async throws — create or update via PersistenceService
   - func deletePillar() async throws (edit mode only)
   - Populated from existing Pillar in .edit mode

2. PillarEditorView:
   - Large emoji display at top (tap → sheet with EmojiPickerView)
   - Name TextField (focused on appear in .create mode)
   - About TextEditor (multiline, max 200 chars with counter)
   - Tone: 3-segment segmented-style button row (Casual / Technical / Inspirational)
   - Topics: flow layout chip input (tag appears after typing + return, 
     tap chip to delete it)
   - Frequency: stepper-style control (− / value / +), range 1–7
   - "Save Pillar" button (disabled if !isValid)
   - In edit mode: destructive "Delete Pillar" button at bottom (confirmation alert)
   - Navigation title: "New Pillar" or "Edit Pillar"

3. EmojiPickerView (simple grid, no external dependency):
   - 6 categories, ~60 curated emojis relevant to content pillars
   - Presented as a .sheet
   - Tapping emoji dismisses sheet + updates PillarEditorViewModel.emoji

Architecture:
- Topics chip input: @State localTopic string, .onSubmit appends to viewModel.topics
- Flow layout for chips: use Layout protocol (iOS 16+) for custom FlowLayout
- No emoji picker library — build a simple curated grid
```

---

### ✅ Slice 6 is done when:
- [ ] [+] on Dashboard opens editor in create mode
- [ ] Tapping a pillar row offers an "Edit" path
- [ ] All fields save correctly and persist across restart
- [ ] Emoji picker opens and selection is reflected immediately
- [ ] Topics can be added (type + return) and removed (tap ✕)
- [ ] Delete pillar shows confirmation alert before deleting
- [ ] Validation prevents saving an empty name

---
---

# SLICE 7 · Settings + Pro Paywall
**Delivers:** Settings screen · StoreKit 2 paywall · Photo access deeplink · Re-scan

```
┌──────────────────────────────┐
│  Settings                    │
├──────────────────────────────┤
│  ACCOUNT                     │
│  → PostKit Pro          Free │  ← tap → paywall sheet
│  → Restore Purchases         │
├──────────────────────────────┤
│  LIBRARY                     │
│  → Photo Access      Full ›  │  ← opens iOS Settings deeplink
│  → Re-scan Library       ›   │  ← resets scan state, restarts
│  → Clear All Data        ›   │  ← destructive, confirmation alert
├──────────────────────────────┤
│  ABOUT                       │
│  → Privacy Policy        ›   │
│  → Rate PostKit          ›   │  ← SKStoreReviewController
│  → Version            1.0.0  │
└──────────────────────────────┘
```

---

### Step 1 · Claude Code prompt for this slice

```
Working on PostKit — iOS 18+ SwiftUI. Read CLAUDE.md.

Slice 7: Settings + StoreKit 2 paywall.

Deliver:
1. SettingsViewModel (@Observable @MainActor):
   - isPro: Bool (from StoreKit subscription status)
   - photoAuthStatus: PHAuthorizationStatus
   - appVersion: String (from Bundle)
   - func openPhotoSettings() — UIApplication.shared.open Settings URL
   - func rescanLibrary() async — resets ClassifiedPhoto statuses, triggers new full scan
   - func clearAllData() async — deletes all SwiftData records
   - func requestReview() — SKStoreReviewController.requestReview()

2. SettingsView (List-based, iOS Settings style):
   - ACCOUNT section: Pro status row, Restore Purchases row
   - LIBRARY section: Photo Access row (shows current status), Re-scan, Clear All Data
   - ABOUT section: Privacy Policy (WKWebView or Safari), Rate PostKit, Version

3. PaywallView (sheet from Pro row):
   - Hero: "PostKit Pro"
   - Feature comparison: free vs pro limits
   - 2 purchase options: monthly ($4.99) + annual ($34.99, "Best Value" badge)
   - "Try Free for 7 Days" if trial available
   - StoreKit 2: Product.products(for:), product.purchase(), Transaction.updates listener
   - Restore button
   - Dismiss (X) button

4. StoreKit configuration file for local testing:
   - Monthly subscription: com.yourname.postkit.pro.monthly
   - Annual subscription: com.yourname.postkit.pro.annual
   - 3-day trial on both for testing

Architecture:
- StoreKit 2 (async/await), NOT SKPaymentQueue
- Transaction.updates AsyncSequence listened in AppContainer on init
- isPro stored in @AppStorage, updated on transaction verification
- Clear All Data: confirmation alert with destructive button, 
  then modelContext.delete on all models
```

---

### ✅ Slice 7 is done when:
- [ ] Settings screen navigates correctly from tab bar
- [ ] Photo Access row shows current permission status
- [ ] Opening Photo Settings deep-links to iOS Settings
- [ ] Re-scan resets and restarts full scan
- [ ] Clear All Data deletes everything after confirmation
- [ ] Paywall shows both subscription options
- [ ] Purchase flow completes without crash (sandbox)
- [ ] isPro persists across restart after purchase

---
---

## Global Rules — Always Active

These apply to every slice, every file, every session.

| Rule | What it means |
|------|---------------|
| `@Observable` only | Never use `ObservableObject` or `@Published` |
| `@Entry` DI | Services injected via `EnvironmentValues`, never as singletons |
| `@MainActor` on VMs | Every ViewModel is `@MainActor` — no manual `DispatchQueue.main` |
| Zero logic in Views | No `if` that isn't pure display logic, no calculations |
| Services behind protocols | Never call `SwiftData` from a ViewModel directly |
| Sendable everywhere | All service protocols conform to `Sendable` |
| Async/await | No callbacks, no Combine, no `DispatchQueue` except legacy bridging |
| Typed routes | Navigation via enum cases, never string-based |
| `AppStrings` enum | All user-facing strings in one place |
| No force unwrap | `guard let` or `if let`, never `!` except tests |

---

## Quick Reference — Claude Code Session Template

Paste this at the top of **every** new session:

```
Working on PostKit — iOS 18+ SwiftUI app.
CLAUDE.md is in the repo root — read it before anything else.
Architecture brief: docs/briefs/16-dev-programme.md
Build guide: docs/briefs/17-build-guide.md

Current slice: [NUMBER + NAME]
[paste the slice prompt from the guide]
```

---

*Phase 2 (after MVP ships): StoreKit 2 paywall · AI caption fine-tuning · CloudKit sync · LinkedIn direct publish via API*
