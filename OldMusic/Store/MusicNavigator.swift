import SwiftUI
import MediaPlayer

/// Owns every piece of navigation state of the iPod app: the current screen
/// (library, Now Playing, Cover Flow), the selected tab and one push stack
/// per tab. Views send actions here instead of juggling string flags.
final class MusicNavigator: ObservableObject {
    enum Screen: Equatable {
        case library
        case nowPlaying
        case coverFlow
    }

    @Published private(set) var screen: Screen = .library
    @Published private(set) var tab: MusicTab = .playlists
    @Published private(set) var stacks: [MusicTab: [MusicRoute]] = [:]
    /// Direction of the current slide transition (iOS 6 push / pop).
    @Published private(set) var movingForward = true
    @Published private(set) var coverFlowOrientation: UIDeviceOrientation = .landscapeLeft

    private var screenBeforeCoverFlow: Screen = .library
    private var orientationObserver: NSObjectProtocol?

    static let pushAnimation = Animation.linear(duration: 0.28)

    init() {
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        orientationObserver = NotificationCenter.default.addObserver(
            forName: UIDevice.orientationDidChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            self?.deviceOrientationChanged()
        }
    }

    deinit {
        if let orientationObserver {
            NotificationCenter.default.removeObserver(orientationObserver)
        }
    }

    // MARK: Stack

    var stack: [MusicRoute] { stacks[tab] ?? [] }
    var depth: Int { stack.count }
    var currentRoute: MusicRoute? { stack.last }

    var title: String {
        currentRoute?.title ?? tab.title
    }

    var backTitle: String? {
        guard depth > 0 else { return nil }
        return depth >= 2 ? stack[depth - 2].title : tab.title
    }

    /// Pushes a screen. `delayed` reproduces OldOS' short pause that lets the
    /// tapped row highlight before the slide.
    func push(_ route: MusicRoute, delayed: Bool = true) {
        // The direction is published first and the stack changes on the next
        // run loop, so the outgoing screen already knows which way to slide.
        movingForward = true
        let tab = self.tab
        DispatchQueue.main.asyncAfter(deadline: .now() + (delayed ? 0.2 : 0.01)) { [weak self] in
            guard let self, self.tab == tab else { return }
            withAnimation(Self.pushAnimation) {
                self.stacks[tab, default: []].append(route)
            }
        }
    }

    func pop() {
        guard depth > 0 else { return }
        oldMusicResignKeyboard()
        movingForward = false
        let tab = self.tab
        DispatchQueue.main.async { [weak self] in
            guard let self, self.stacks[tab]?.isEmpty == false else { return }
            withAnimation(Self.pushAnimation) {
                _ = self.stacks[tab]?.removeLast()
            }
        }
    }

    /// Tapping a tab always shows its root list (also when it is already selected).
    func select(_ newTab: MusicTab) {
        oldMusicResignKeyboard()
        stacks = [:]
        tab = newTab
    }

    /// Jumps to another tab with a prepared stack (search results → artist / album).
    func open(tab newTab: MusicTab, stack newStack: [MusicRoute]) {
        oldMusicResignKeyboard()
        movingForward = true
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            withAnimation(Self.pushAnimation) {
                self.stacks = [newTab: newStack]
                self.tab = newTab
            }
        }
    }

    // MARK: Screens

    func showNowPlaying() {
        oldMusicResignKeyboard()
        guard screen != .nowPlaying else { return }
        movingForward = true
        DispatchQueue.main.async { [weak self] in
            withAnimation(Self.pushAnimation) {
                self?.screen = .nowPlaying
            }
        }
    }

    func showLibrary() {
        guard screen != .library else { return }
        movingForward = false
        DispatchQueue.main.async { [weak self] in
            withAnimation(Self.pushAnimation) {
                self?.screen = .library
            }
        }
    }

    /// iOS 6: turning the device sideways shows Cover Flow, turning it back
    /// returns to the screen that was visible before.
    private func deviceOrientationChanged() {
        let orientation = UIDevice.current.orientation
        if orientation.isLandscape {
            coverFlowOrientation = orientation
            guard screen != .coverFlow else { return }
            oldMusicResignKeyboard()
            screenBeforeCoverFlow = screen
            withAnimation(.easeInOut(duration: 0.35)) {
                screen = .coverFlow
            }
        } else if orientation.isPortrait, screen == .coverFlow {
            withAnimation(.easeInOut(duration: 0.35)) {
                screen = screenBeforeCoverFlow
            }
        }
    }
}
