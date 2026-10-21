import SwiftUI
import MediaPlayer
import AVFoundation

/// Observes the system output volume and changes it through a hidden
/// MPVolumeView that lives in the window. Keeping that view in the hierarchy
/// also hides the modern volume HUD, so the iOS 6 slider is the only feedback.
///
/// The hardware buttons are followed through three independent sources, so
/// the slider always moves: the system "volume did change" notification,
/// KVO on `outputVolume`, and a light poll of the system volume (the hidden
/// MPVolumeView slider, which iOS keeps up to date, and `outputVolume`)
/// while the app is in the foreground.
final class MusicVolume: ObservableObject {
    static let shared = MusicVolume()

    /// 0...100, like the OldOS slider.
    @Published var level: Double = Double(AVAudioSession.sharedInstance().outputVolume) * 100

    private let session = AVAudioSession.sharedInstance()
    private var observation: NSKeyValueObservation?
    private var observers: [NSObjectProtocol] = []
    private var pollTimer: Timer?
    /// Last system value seen from each source (0...100).
    private var lastSessionLevel: Double = -1
    private var lastViewLevel: Double = -1
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

    private var systemSlider: UISlider? {
        volumeView.subviews.compactMap { $0 as? UISlider }.first
    }

    private init() {
        activate()
        observeVolume()
        level = Double(session.outputVolume) * 100
        lastSessionLevel = level

        let center = NotificationCenter.default
        // Posted by iOS on every hardware button press (iOS 15+ name and the
        // older one); delivered once remote-control events are on.
        for name in ["SystemVolumeDidChange", "AVSystemController_SystemVolumeDidChangeNotification"] {
            observers.append(center.addObserver(forName: Notification.Name(name), object: nil, queue: .main) { [weak self] note in
                let info = note.userInfo
                let raw = (info?["Volume"] ?? info?["AVSystemController_AudioVolumeNotificationParameter"]) as? NSNumber
                if let raw {
                    self?.apply(Double(raw.floatValue) * 100)
                } else {
                    self?.poll()
                }
            })
        }
        // `outputVolume` only stays live while the session is active:
        // re-activate it whenever iOS takes it away.
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
            self?.poll()
        })

        DispatchQueue.main.async {
            UIApplication.shared.beginReceivingRemoteControlEvents()
        }
        startPolling()
    }

    deinit {
        observation?.invalidate()
        pollTimer?.invalidate()
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    /// Called when the app comes back to the foreground.
    func reactivate() {
        activate()
        observeVolume()
        lastSessionLevel = -1
        lastViewLevel = -1
        if Date() >= userChangeUntil {
            level = Double(session.outputVolume) * 100
        }
        startPolling()
    }

    /// Called when the app leaves the foreground.
    func suspend() {
        pollTimer?.invalidate()
        pollTimer = nil
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
        observation = session.observe(\.outputVolume, options: [.new]) { [weak self] _, change in
            let value = change.newValue.map { Double($0) * 100 }
            DispatchQueue.main.async {
                if let value { self?.apply(value) } else { self?.poll() }
            }
        }
    }

    private func startPolling() {
        guard pollTimer == nil else { return }
        let timer = Timer(timeInterval: 0.15, repeats: true) { [weak self] _ in
            self?.poll()
        }
        RunLoop.main.add(timer, forMode: .common)
        pollTimer = timer
    }

    /// Reads both system sources and follows whichever one changed.
    private func poll() {
        let sessionLevel = Double(session.outputVolume) * 100
        if abs(sessionLevel - lastSessionLevel) > 0.01 {
            lastSessionLevel = sessionLevel
            apply(sessionLevel)
        }
        if let slider = systemSlider {
            let viewLevel = Double(slider.value) * 100
            if abs(viewLevel - lastViewLevel) > 0.01 {
                lastViewLevel = viewLevel
                apply(viewLevel)
            }
        }
    }

    /// Moves the iOS 6 slider to a system volume (hardware buttons, Control Center…).
    private func apply(_ newLevel: Double) {
        guard Date() >= userChangeUntil, newLevel.isFinite else { return }
        let clamped = min(max(newLevel, 0), 100)
        guard abs(clamped - level) > 0.01 else { return }
        withAnimation(.easeOut(duration: 0.15)) { level = clamped }
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
        let slider = systemSlider
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { [weak self] in
            slider?.value = value
            // Our own change is not a "new" system value for the poll.
            self?.lastViewLevel = Double(value) * 100
            self?.lastSessionLevel = Double(value) * 100
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
