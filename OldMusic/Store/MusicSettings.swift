import SwiftUI
import UIKit

/// "Aspect UI" choice offered in More.
enum MusicAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "Sistema"
        case .light: return "Chiaro"
        case .dark: return "Scuro"
        }
    }

    var interfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .system: return .unspecified
        case .light: return .light
        case .dark: return .dark
        }
    }
}

/// Persistent app preferences.
final class MusicSettings: ObservableObject {
    static let shared = MusicSettings()

    private enum Key {
        static let appearance = "OldMusic.Appearance"
        static let shakeToShuffle = "OldMusic.ShakeToShuffle"
    }

    @Published var appearance: MusicAppearance {
        didSet {
            UserDefaults.standard.set(appearance.rawValue, forKey: Key.appearance)
            apply()
        }
    }

    /// iOS 6 Settings › Music › Shake to Shuffle (on by default, like iOS 6).
    @Published var shakeToShuffle: Bool {
        didSet { UserDefaults.standard.set(shakeToShuffle, forKey: Key.shakeToShuffle) }
    }

    private init() {
        let defaults = UserDefaults.standard
        appearance = MusicAppearance(rawValue: defaults.string(forKey: Key.appearance) ?? "") ?? .system
        if defaults.object(forKey: Key.shakeToShuffle) == nil {
            shakeToShuffle = true
        } else {
            shakeToShuffle = defaults.bool(forKey: Key.shakeToShuffle)
        }
    }

    /// Forces the chosen appearance on every window, so the SwiftUI colour
    /// scheme *and* the system chrome (keyboard, alerts, share sheet, status
    /// bar) switch together. "Sistema" hands control back to iOS.
    func apply() {
        let style = appearance.interfaceStyle
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
        for window in windows where window.overrideUserInterfaceStyle != style {
            window.overrideUserInterfaceStyle = style
        }
    }
}

extension Notification.Name {
    /// Posted by the hosting controller when the device is shaken.
    static let oldMusicDeviceShaken = Notification.Name("com.iamgasgass.oldmusic.DeviceShaken")
}
