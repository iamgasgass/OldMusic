//
//  AppDelegate.swift
//  OldMusic
//
//  Based on OldOS by Zane Kleinberg (AppDelegate.swift / SceneDelegate.swift).
//  OldMusic boots straight into the iPod app, full screen.
//

import UIKit
import SwiftUI
import MediaPlayer

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UIDevice.current.isBatteryMonitoringEnabled = true
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        // Start observing the system music player right away (playback notifications).
        _ = iPodPlayer.shared
        return true
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        // The interface stays portrait (like OldOS); landscape is handled by Cover Flow,
        // which rotates itself when the *device* is turned.
        return .portrait
    }
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    let music_observer = MusicObserver()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        let contentView = OldMusicRoot().environmentObject(music_observer)
        window.rootViewController = OldMusicHostingController(rootView: contentView)
        window.backgroundColor = .black
        self.window = window
        window.makeKeyAndVisible()
        MPVolumeView.oldmusic_install(in: window)
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        iPodPlayer.shared.refresh()
        if let window = window {
            MPVolumeView.oldmusic_install(in: window)
        }
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        music_observer.reload()
    }
}

/// Hosting controller: system status bar hidden (OldMusic draws the iOS 6 one), home indicator auto-hidden, portrait.
final class OldMusicHostingController<Content>: UIHostingController<Content> where Content: View {
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    override var prefersStatusBarHidden: Bool {
        return true
    }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        return [.bottom]
    }
}

/// Root of the app: the iPod, full screen, with the OldOS iOS 6 keyboard host.
struct OldMusicRoot: View {
    @StateObject var oldOSKeyboard = OldOSKeyboardController()
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            iPod()
        }
        .oldOSKeyboardHost(oldOSKeyboard, horizontalInset: 0, bottomInset: 0)
        .ignoresSafeArea(.keyboard)
        .preferredColorScheme(.light)
        .ifButtonShapesEnabledLive { view in
            view.buttonStyle(buttonShapesOverride())
        }
    }
}

//From OldOS HomeScreen.swift: keeps iOS 6 buttons looking like iOS 6 even with "Button Shapes" enabled.
private struct IfButtonShapesEnabledModifier<S: View>: ViewModifier {
    let style: (AnyView) -> S
    @State private var enabled: Bool = UIAccessibility.buttonShapesEnabled

    func body(content: Content) -> some View {
        let base = AnyView(content)
        Group {
            if enabled {
                style(base)
            } else {
                base
            }
        }
        .onReceive(NotificationCenter.default.publisher(
            for: UIAccessibility.buttonShapesEnabledStatusDidChangeNotification
        )) { _ in
            enabled = UIAccessibility.buttonShapesEnabled
        }
    }
}

public extension View {
    /// Apply a style only when the user has "Button Shapes" enabled (updates live).
    func ifButtonShapesEnabledLive<S: View>(
        _ style: @escaping (AnyView) -> S
    ) -> some View {
        modifier(IfButtonShapesEnabledModifier(style: style))
    }
}

struct buttonShapesOverride: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}
