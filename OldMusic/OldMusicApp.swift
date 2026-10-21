import SwiftUI
import UIKit
import Combine

@main
final class OldMusicAppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        // Shake is used by "Shake to Shuffle", not by the system undo alert.
        application.applicationSupportsShakeToEdit = false
        _ = MusicPlayer.shared
        return true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        configuration.delegateClass = OldMusicSceneDelegate.self
        return configuration
    }

    /// The interface stays portrait (Cover Flow rotates itself when the device turns).
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        .portrait
    }
}

final class OldMusicSceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = OldMusicHostingController(root: OldMusicRootView())
        window.backgroundColor = .black
        self.window = window
        window.makeKeyAndVisible()
        MusicSettings.shared.apply()
        MusicVolume.shared.install(in: window)
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        MusicPlayer.shared.refresh()
        MusicSettings.shared.apply()
        window?.rootViewController?.becomeFirstResponder()
        MusicVolume.shared.install(in: window)
        MusicVolume.shared.reactivate()
        // AirPlay devices are already known when Now Playing slides up.
        MusicAirPlay.shared.startWatching()
    }

    func sceneWillResignActive(_ scene: UIScene) {
        MusicAirPlay.shared.stopWatching()
        MusicVolume.shared.suspend()
    }
}

/// Hosts the SwiftUI app and applies the status bar style requested by the
/// visible screen (dark text on the light bar, light text on black / graphite).
final class OldMusicHostingController: UIHostingController<OldMusicRootView> {
    private var cancellables = Set<AnyCancellable>()

    init(root: OldMusicRootView) {
        super.init(rootView: root)
        let statusBar = MusicStatusBar.shared
        statusBar.$style
            .combineLatest(statusBar.$hidden)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                UIView.animate(withDuration: 0.2) {
                    self?.setNeedsStatusBarAppearanceUpdate()
                }
            }
            .store(in: &cancellables)

        // Become first responder again whenever the keyboard goes away, so
        // shake gestures keep reaching `motionEnded`.
        NotificationCenter.default.publisher(for: UIResponder.keyboardDidHideNotification)
            .sink { [weak self] _ in
                self?.becomeFirstResponder()
            }
            .store(in: &cancellables)
    }

    override var canBecomeFirstResponder: Bool {
        true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
    }

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: .oldMusicDeviceShaken, object: nil)
        } else {
            super.motionEnded(motion, with: event)
        }
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        MusicStatusBar.shared.style
    }

    override var prefersStatusBarHidden: Bool {
        MusicStatusBar.shared.hidden
    }

    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        .fade
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }
}
