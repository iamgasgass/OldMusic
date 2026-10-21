import SwiftUI
import AVKit
import AVFoundation

/// Watches for AirPlay devices and the current output route. Like iOS 6,
/// the AirPlay button only appears when there is somewhere to send audio,
/// and turns blue while an AirPlay device is playing.
final class MusicAirPlay: ObservableObject {
    static let shared = MusicAirPlay()

    @Published private(set) var routesAvailable = false
    @Published private(set) var isActive = false

    private let detector = AVRouteDetector()
    private var observers: [NSObjectProtocol] = []
    private var watchers = 0

    private init() {
        let center = NotificationCenter.default
        observers.append(center.addObserver(
            forName: .AVRouteDetectorMultipleRoutesDetectedDidChange, object: detector, queue: .main
        ) { [weak self] _ in self?.refresh() })
        observers.append(center.addObserver(
            forName: AVAudioSession.routeChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in self?.refresh() })
        refresh()
    }

    /// Route detection costs power: only on while the Now Playing footer is visible.
    func startWatching() {
        watchers += 1
        detector.isRouteDetectionEnabled = true
        refresh()
    }

    func stopWatching() {
        watchers = max(watchers - 1, 0)
        if watchers == 0 { detector.isRouteDetectionEnabled = false }
    }

    private func refresh() {
        let outputs = AVAudioSession.sharedInstance().currentRoute.outputs
        let active = outputs.contains { $0.portType == .airPlay }
        let available = detector.multipleRoutesDetected || active
        DispatchQueue.main.async {
            if self.isActive != active { self.isActive = active }
            if self.routesAvailable != available { self.routesAvailable = available }
        }
    }
}

/// iOS 6 AirPlay glyph next to the volume slider. The system route picker sits
/// underneath (invisible) and handles the tap, opening the AirPlay device list.
struct MusicAirPlayButton: View {
    @ObservedObject private var airPlay = MusicAirPlay.shared
    @State private var pressed = false

    var body: some View {
        ZStack {
            MusicRoutePicker(pressed: $pressed)
            Image(systemName: "airplayaudio")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(airPlay.isActive ? .oldOS(90, 160, 245) : .white)
                .shadow(color: Color.black.opacity(0.8), radius: 0, x: 0, y: -1)
                // iOS 6 white glow while touched.
                .shadow(color: Color.white.opacity(pressed ? 0.9 : 0), radius: 6)
                .scaleEffect(pressed ? 0.92 : 1)
                .animation(.easeOut(duration: 0.15), value: pressed)
                .animation(.easeInOut(duration: 0.25), value: airPlay.isActive)
                .allowsHitTesting(false)
        }
        .frame(width: 30, height: 25)
    }
}

private struct MusicRoutePicker: UIViewRepresentable {
    @Binding var pressed: Bool

    func makeCoordinator() -> Coordinator { Coordinator(pressed: $pressed) }

    func makeUIView(context: Context) -> AVRoutePickerView {
        let picker = AVRoutePickerView()
        picker.prioritizesVideoDevices = false
        picker.tintColor = .clear
        picker.activeTintColor = .clear
        picker.backgroundColor = .clear
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}

    final class Coordinator: NSObject, AVRoutePickerViewDelegate {
        @Binding var pressed: Bool

        init(pressed: Binding<Bool>) { _pressed = pressed }

        func routePickerViewWillBeginPresentingRoutes(_ routePickerView: AVRoutePickerView) {
            pressed = true
            OldMusicHaptics.press()
        }

        func routePickerViewDidEndPresentingRoutes(_ routePickerView: AVRoutePickerView) {
            pressed = false
        }
    }
}
