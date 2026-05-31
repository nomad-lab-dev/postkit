import ComposableArchitecture
import SwiftUI
import UIKit

// MARK: - Onboarding fonts (Space Grotesk + Instrument Serif + Geist Mono)
// Font files must be in Resources/Fonts/ and registered in Info.plist UIAppFonts.

extension Font {
    static func obHeadline(_ size: CGFloat = 20) -> Font {
        .custom("SpaceGrotesk-Bold", size: size)
    }
    static func obEmphasis(_ size: CGFloat = 22) -> Font {
        .custom("InstrumentSerif-Italic", size: size)
    }
    static func obMono(_ size: CGFloat = 9) -> Font {
        .custom("GeistMono-SemiBold", size: size)
    }
    static func obBody(_ size: CGFloat = 14) -> Font {
        .custom("SpaceGrotesk-Medium", size: size)
    }
}

// MARK: - Pillar accent colors

private let pillarAccents: [Color] = [
    Color(red: 0/255,   green: 122/255, blue: 255/255),
    Color(red: 255/255, green: 149/255, blue: 0/255),
    Color(red: 175/255, green: 82/255,  blue: 222/255),
    Color(red: 52/255,  green: 199/255, blue: 89/255),
    Color(red: 255/255, green: 159/255, blue: 10/255),
    Color(red: 255/255, green: 45/255,  blue: 85/255),
    Color(red: 90/255,  green: 200/255, blue: 250/255),
]

private let pillarGradientPairs: [(Color, Color)] = [
    (Color(red: 0/255,   green: 122/255, blue: 255/255), Color(red: 88/255,  green: 86/255,  blue: 214/255)),
    (Color(red: 255/255, green: 149/255, blue: 0/255),   Color(red: 255/255, green: 59/255,  blue: 48/255)),
    (Color(red: 52/255,  green: 199/255, blue: 89/255),  Color(red: 50/255,  green: 173/255, blue: 230/255)),
    (Color(red: 175/255, green: 82/255,  blue: 222/255), Color(red: 255/255, green: 45/255,  blue: 85/255)),
    (Color(red: 255/255, green: 159/255, blue: 10/255),  Color(red: 255/255, green: 109/255, blue: 0/255)),
]

func pillarAccent(at index: Int) -> Color {
    pillarAccents[index % pillarAccents.count]
}

func pillarGradient(at index: Int) -> LinearGradient {
    let (s, e) = pillarGradientPairs[index % pillarGradientPairs.count]
    return LinearGradient(colors: [s, e], startPoint: .leading, endPoint: .trailing)
}

// MARK: - Bundle image cache + preloader

let _onboardingImageCache = NSCache<NSString, UIImage>()

func preloadOnboardingImages() {
    let names = [
        "gallery-auto-1", "gallery-auto-2", "gallery-auto-3", "gallery-auto-4",
        "gallery-food-1", "gallery-food-2", "gallery-food-3",
        "gallery-life-1", "gallery-life-2", "gallery-life-3",
        "gallery-nomad-1", "gallery-nomad-2", "gallery-nomad-3", "gallery-nomad-4",
        "gallery-dev-1", "gallery-dev-2", "gallery-dev-3",
    ]
    Task.detached(priority: .userInitiated) {
        await withTaskGroup(of: Void.self) { group in
            for name in names {
                group.addTask {
                    guard _onboardingImageCache.object(forKey: name as NSString) == nil,
                          let url = Bundle.main.url(forResource: name, withExtension: "webp"),
                          let data = try? Data(contentsOf: url),
                          let image = UIImage(data: data)
                    else { return }
                    _onboardingImageCache.setObject(image, forKey: name as NSString)
                }
            }
        }
    }
}

// MARK: - Bundle image view

struct BundleImage: View {
    let name: String
    @State private var uiImage: UIImage?

    var body: some View {
        Group {
            if let uiImage {
                Image(uiImage: uiImage).resizable().scaledToFill()
            } else {
                Palette.surface
            }
        }
        .task(id: name) {
            if let cached = _onboardingImageCache.object(forKey: name as NSString) {
                uiImage = cached
                return
            }
            guard let url = Bundle.main.url(forResource: name, withExtension: "webp"),
                  let data = try? Data(contentsOf: url),
                  let image = UIImage(data: data)
            else { return }
            _onboardingImageCache.setObject(image, forKey: name as NSString)
            uiImage = image
        }
    }
}

// MARK: - Demo data for Step 02

struct DemoData: Equatable, Identifiable {
    let id: UUID
    let prompt: String
    let photoNames: [String]
    let caption: String

    static func make(_ chip: OnboardingFeature.DemoChip) -> DemoData {
        switch chip {
        case .italy:
            return DemoData(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                prompt: "My weekend in Italy",
                photoNames: ["gallery-nomad-1", "gallery-nomad-2", "gallery-nomad-3", "gallery-nomad-4"],
                caption: "Three days, two cities, one road. Naples → Capri."
            )
        case .coffee:
            return DemoData(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
                prompt: "Coffee shops I keep coming back to",
                photoNames: ["gallery-food-1", "gallery-food-2", "gallery-food-3", "gallery-life-1"],
                caption: "Three rooms, one ritual. The flat white that started the day."
            )
        case .build:
            return DemoData(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
                prompt: "Build log · what shipped this week",
                photoNames: ["gallery-dev-1", "gallery-dev-2", "gallery-dev-3", "gallery-dev-1"],
                caption: "Three PRs, one feature, zero regressions. Subscription tier is live."
            )
        }
    }
}

// MARK: - Shared CTA bar layout

func ctaBar<Content: View>(dark: Bool = false, @ViewBuilder content: () -> Content) -> some View {
    VStack(spacing: 0) {
        content()
            .padding(.horizontal, Layout.Padding.screen.leading)
            .padding(.bottom, Spacing.xxl)
            .padding(.top, Spacing.md)
            .background(dark ? Color.black.opacity(0.25) : Palette.bg)
    }
}

// MARK: - Eyebrow label

func obEyebrow(_ text: LocalizedStringKey, color: Color) -> some View {
    Text(text)
        .font(.obMono(9))
        .foregroundStyle(color)
        .tracking(0.54)
        .textCase(.uppercase)
}
