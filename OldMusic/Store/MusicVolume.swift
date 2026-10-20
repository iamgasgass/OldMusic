import SwiftUI
import MediaPlayer
import AVFoundation

/// Observes the system output volume and changes it through a hidden
/// MPVolumeView that lives in the window. Keeping that view in the hierarchy
/// also hides the modern volume HUD, so the iOS 6 slider is the only feedback.
final class MusicVolume: ObservableObject {
    static let shared = MusicVolume()

    /// 0...100, like the OldOS slider.
    @Published var level: Double = Double(AVAudioSession.sharedInstance().outputVolume) * 100

    private let session = AVAudioSession.sharedInstance()
    private var observation: NSKeyValueObservation?

    let volumeView: MPVolumeView = {
        let view = MPVolumeView(frame: CGRect(x: -1000, y: -1000, width: 120, height: 40))
        view.alpha = 0.0001
        view.isUserInteractionEnabled = false
        view.clipsToBounds = true
        return view
    }()

    private init() {
        do {
            try session.setCategory(.ambient, options: [.mixWithOthers])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("OldMusic: cannot activate the audio session (\(error.localizedDescription))")
        }
        observation = session.observe(\.outputVolume, options: [.new]) { [weak self] session, _ in
            DispatchQueue.main.async {
                self?.level = Double(session.outputVolume) * 100
            }
        }
    }

    deinit {
        observation?.invalidate()
    }

    func install(in window: UIWindow?) {
        guard let window else { return }
        if volumeView.superview !== window {
            volumeView.removeFromSuperview()
            window.addSubview(volumeView)
        }
    }

    func set(_ newLevel: Double) {
        if volumeView.superview == nil {
            install(in: OldMusicScreen.keyWindow)
        }
        let value = Float(min(max(newLevel / 100, 0), 1))
        let slider = volumeView.subviews.compactMap { $0 as? UISlider }.first
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            slider?.value = value
        }
    }
}

/// Status bar appearance requested by the visible screen; the hosting
/// controller follows it (dark text on the light blue bar, light text on
/// black / graphite bars, hidden in Cover Flow).
final class MusicStatusBar: ObservableObject {
    static let shared = MusicStatusBar()

    @Published var style: UIStatusBarStyle = .darkContent
    @Published var hidden: Bool = false

    private init() {}

    func update(screen: MusicNavigator.Screen, isDark: Bool) {
        let newHidden = screen == .coverFlow
        let newStyle: UIStatusBarStyle = (screen == .library && !isDark) ? .darkContent : .lightContent
        if newHidden != hidden { hidden = newHidden }
        if newStyle != style { style = newStyle }
    }
}
