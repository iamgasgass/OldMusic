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
    private var observers: [NSObjectProtocol] = []
    /// While the finger is on the slider, the system echo of our own change
    /// must not move the knob back.
    private var userChangeUntil = Date.distantPast

    let volumeView: MPVolumeView = {
        let view = MPVolumeView(frame: CGRect(x: -1000, y: -1000, width: 120, height: 40))
        view.alpha = 0.0001
        view.isUserInteractionEnabled = false
        view.clipsToBounds = true
        return view
    }()

    private init() {
        activate()
        observeVolume()
        sync(animated: false)

        let center = NotificationCenter.default
        // The hardware buttons only reach `outputVolume` while the session is
        // active: re-activate it whenever iOS takes it away.
        observers.append(center.addObserver(forName: AVAudioSession.interruptionNotification, object: session, queue: .main) { [weak self] note in
            guard let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  AVAudioSession.InterruptionType(rawValue: raw) == .ended else { return }
            self?.reactivate()
        })
        observers.append(center.addObserver(forName: AVAudioSession.mediaServicesWereResetNotification, object: session, queue: .main) { [weak self] _ in
            self?.activate()
            self?.observeVolume()
        })
        // Each output (speaker, headphones, AirPlay) has its own volume.
        observers.append(center.addObserver(forName: AVAudioSession.routeChangeNotification, object: session, queue: .main) { [weak self] _ in
            self?.sync(animated: true)
        })
    }

    deinit {
        observation?.invalidate()
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    /// Called when the app comes back to the foreground.
    func reactivate() {
        activate()
        sync(animated: false)
    }

    /// Ambient (mixable) unless OldMusic is playing, so coming back to the
    /// app never stops another app's audio.
    private func activate() {
        do {
            if session.category != .playback || !MusicPlayer.shared.isPlaying {
                try session.setCategory(.ambient, options: [.mixWithOthers])
            }
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("OldMusic: cannot activate the audio session (\(error.localizedDescription))")
        }
    }

    private func observeVolume() {
        observation?.invalidate()
        observation = session.observe(\.outputVolume, options: [.new]) { [weak self] _, _ in
            DispatchQueue.main.async {
                self?.sync(animated: true)
            }
        }
    }

    /// Moves the slider to the system volume (hardware buttons, Control Center…).
    private func sync(animated: Bool) {
        guard Date() >= userChangeUntil else { return }
        let newLevel = Double(session.outputVolume) * 100
        guard abs(newLevel - level) > 0.01 else { return }
        if animated {
            withAnimation(.easeOut(duration: 0.15)) { level = newLevel }
        } else {
            level = newLevel
        }
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
            install(in: OldOSScreen.keyWindow)
        }
        userChangeUntil = Date().addingTimeInterval(0.4)
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
