import SwiftUI
import UIKit

// Native replacements for the helpers the OldOS iPod app took from
// PureSwiftUI and from the shared OldOS "Common" file, so OldMusic has no
// third-party Swift dependency.

// MARK: - Colors

extension Color {
    /// 8-bit sRGB convenience initialiser, matching the `Color(red: n/255, ...)`
    /// style used throughout the original OldOS sources.
    static func oldOS(_ r: Double, _ g: Double, _ b: Double, _ opacity: Double = 1) -> Color {
        Color(.sRGB, red: r / 255, green: g / 255, blue: b / 255, opacity: opacity)
    }

    /// PureSwiftUI `cgLightGray` (white 0.667), used for row subtitles.
    static let oldOSLightGray = Color(white: 0.667)
}

// MARK: - Gradients

/// A single gradient stop expressed the same way OldOS expresses it.
struct OldOSStop {
    let color: Color
    let location: Double

    init(_ color: Color, _ location: Double) {
        self.color = color
        self.location = location
    }
}

extension LinearGradient {
    init(oldOS stops: [OldOSStop], from: UnitPoint = .top, to: UnitPoint = .bottom) {
        self.init(
            gradient: Gradient(stops: stops.map {
                Gradient.Stop(color: $0.color, location: CGFloat($0.location))
            }),
            startPoint: from,
            endPoint: to
        )
    }

    init(oldOS colors: [Color], from: UnitPoint = .top, to: UnitPoint = .bottom) {
        self.init(gradient: Gradient(colors: colors), startPoint: from, endPoint: to)
    }
}

// MARK: - Fonts

/// OldOS renders every label with Helvetica Neue at a fixed size. The font is
/// resolved through UIFont first so the app falls back to the system face
/// instead of a wrong metric when a PostScript name is unavailable.
enum OldMusicFont {
    static func bold(_ size: CGFloat) -> Font {
        resolve(["HelveticaNeue-Bold", "Helvetica Neue Bold"], size: size, weight: .bold)
    }

    static func regular(_ size: CGFloat) -> Font {
        resolve(["HelveticaNeue", "Helvetica Neue"], size: size, weight: .regular)
    }

    static func medium(_ size: CGFloat) -> Font {
        resolve(["HelveticaNeue-Medium", "Helvetica Neue Medium"], size: size, weight: .medium)
    }

    private static var cache: [String: Font] = [:]

    private static func resolve(_ names: [String], size: CGFloat, weight: Font.Weight) -> Font {
        let key = "\(names.first ?? "system")-\(size)"
        if let cached = cache[key] { return cached }

        var resolved = Font.system(size: size, weight: weight)
        for name in names where UIFont(name: name, size: size) != nil {
            resolved = Font.custom(name, fixedSize: size)
            break
        }
        cache[key] = resolved
        return resolved
    }
}

// MARK: - Edge borders

/// OldOS `EdgeBorder`, used to draw the 1pt hairlines of bars and headers.
struct OldMusicEdgeBorder: Shape {
    var width: CGFloat
    var edges: [Edge]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        for edge in edges {
            let frame: CGRect
            switch edge {
            case .top:
                frame = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: width)
            case .bottom:
                frame = CGRect(x: rect.minX, y: rect.maxY - width, width: rect.width, height: width)
            case .leading:
                frame = CGRect(x: rect.minX, y: rect.minY, width: width, height: rect.height)
            case .trailing:
                frame = CGRect(x: rect.maxX - width, y: rect.minY, width: width, height: rect.height)
            }
            path.addRect(frame)
        }
        return path
    }
}

extension View {
    func oldOSBorder(width: CGFloat = 1, edges: [Edge], color: Color) -> some View {
        overlay(OldMusicEdgeBorder(width: width, edges: edges).fill(color))
    }

    func oldOSBorder(width: CGFloat = 1, edges: [Edge], gradient: LinearGradient) -> some View {
        overlay(OldMusicEdgeBorder(width: width, edges: edges).fill(gradient))
    }

    /// OldOS `innerShadowBottom`: a soft highlight bleeding down from the top edge.
    func oldOSInnerShadowTop(color: Color, radius: CGFloat = 0.1) -> some View {
        modifier(OldMusicEdgeGlow(color: color, radius: min(max(0, radius), 1), alignment: .top, offset: 0))
    }

    /// OldOS `innerShadowBottomView`: the same glow, rising from the bottom edge.
    func oldOSInnerShadowBottom(color: Color, radius: CGFloat = 0.1) -> some View {
        modifier(OldMusicEdgeGlow(color: color, radius: min(max(0, radius), 1), alignment: .bottom, offset: 0))
    }

    /// OldOS `innerShadowBottomWithOffset`: the top glow, pushed down by `offset`.
    func oldOSInnerShadowTop(color: Color, radius: CGFloat = 0.1, offset: CGFloat) -> some View {
        modifier(OldMusicEdgeGlow(color: color, radius: min(max(0, radius), 1), alignment: .top, offset: offset))
    }

    func oldOSStrokeCapsule(_ color: Color, lineWidth: CGFloat) -> some View {
        overlay(Capsule().stroke(color, lineWidth: lineWidth))
    }

    /// Applies a recessed iOS 6 bevel *behind* the receiver (PureSwiftUI `ps_innerShadow`).
    func oldOSInnerShadowBackground<S: Shape, F: ShapeStyle>(
        _ shape: S,
        _ fill: F,
        radius: CGFloat = 1.8,
        offset: CGPoint = CGPoint(x: 0, y: 1),
        intensity: Double = 0.5
    ) -> some View {
        background(
            OldMusicInnerShadow(shape: shape, fill: fill, radius: radius, offset: offset, intensity: intensity)
        )
    }
}

private struct OldMusicEdgeGlow: ViewModifier {
    var color: Color
    var radius: CGFloat
    var alignment: Alignment
    var offset: CGFloat

    private var colors: [Color] {
        [color.opacity(0.75), color.opacity(0.0), .clear]
    }

    func body(content: Content) -> some View {
        GeometryReader { geo in
            content.overlay(
                LinearGradient(
                    gradient: Gradient(colors: colors),
                    startPoint: alignment == .top ? .top : .bottom,
                    endPoint: alignment == .top ? .bottom : .top
                )
                .frame(height: radius * min(geo.size.width, geo.size.height) * 1.5)
                .offset(y: offset)
                .allowsHitTesting(false),
                alignment: alignment
            )
        }
    }
}

/// The shape is filled, then stroked with a blurred dark stroke clipped back
/// into itself, producing the recessed bevel used by iOS 6 fields and buttons.
struct OldMusicInnerShadow<S: Shape, F: ShapeStyle>: View {
    var shape: S
    var fill: F
    var radius: CGFloat = 1.8
    var offset: CGPoint = CGPoint(x: 0, y: 1)
    var intensity: Double = 0.5
    var shadowColor: Color = .black

    var body: some View {
        shape
            .fill(fill)
            .overlay(
                shape
                    .stroke(shadowColor.opacity(intensity), lineWidth: max(radius, 0.4) * 2)
                    .blur(radius: radius)
                    .offset(x: offset.x, y: offset.y)
                    .clipShape(shape)
            )
    }
}

// MARK: - View helpers

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, content: (Self) -> Content) -> some View {
        if condition {
            content(self)
        } else {
            self
        }
    }

    @ViewBuilder
    func isHidden(_ hidden: Bool, remove: Bool = false) -> some View {
        if hidden {
            if !remove {
                self.hidden()
            }
        } else {
            self
        }
    }

    func oldMusicHideKeyboard() {
        oldMusicResignKeyboard()
    }
}

func oldMusicResignKeyboard() {
    UIApplication.shared.sendAction(
        #selector(UIResponder.resignFirstResponder),
        to: nil, from: nil, for: nil
    )
}

extension Collection {
    subscript(optional index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Safe area

/// Reading the safe area from a `GeometryReader` that ignores it returns zero,
/// so the window is queried directly (same approach as OldSafari).
enum OldMusicScreen {
    static var keyWindow: UIWindow? {
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
        return windows.first(where: { $0.isKeyWindow }) ?? windows.first
    }

    static var safeArea: EdgeInsets {
        guard let window = keyWindow else {
            return EdgeInsets(top: 20, leading: 0, bottom: 0, trailing: 0)
        }
        let insets = window.safeAreaInsets
        return EdgeInsets(top: insets.top, leading: insets.left, bottom: insets.bottom, trailing: insets.right)
    }
}

/// Keeps a live copy of the window safe area for views that draw edge to edge.
final class OldMusicSafeArea: ObservableObject {
    @Published private(set) var insets: EdgeInsets = OldMusicScreen.safeArea

    private var observers: [NSObjectProtocol] = []

    init() {
        let center = NotificationCenter.default
        let names: [Notification.Name] = [
            UIDevice.orientationDidChangeNotification,
            UIApplication.didBecomeActiveNotification
        ]
        observers = names.map { name in
            center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                self?.refresh()
            }
        }
    }

    deinit {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    func refresh() {
        let latest = OldMusicScreen.safeArea
        if latest != insets { insets = latest }
    }
}

// MARK: - Time formatting (OldOS)

func oldMusicTimeComponents(_ raw: Double) -> (hours: Int, minutes: Int, seconds: Int) {
    let value = (raw.isFinite && raw >= 0) ? raw : 0
    let total = Int(min(value, Double(Int.max)).rounded(.down))
    return (total / 3600, (total % 3600) / 60, total % 60)
}

/// "m:ss" or "h:mm:ss".
func oldMusicFormatTime(_ seconds: Double) -> String {
    let t = oldMusicTimeComponents(seconds)
    if t.hours > 0 {
        return "\(t.hours):\(String(format: "%02d", t.minutes)):\(String(format: "%02d", t.seconds))"
    }
    return "\(t.minutes):\(String(format: "%02d", t.seconds))"
}

/// Rounded minutes ("42") or "h:mm" — used by the album header.
func oldMusicFormatMinutes(_ seconds: Double) -> String {
    let t = oldMusicTimeComponents(seconds)
    if t.hours > 0 {
        return "\(t.hours):\(String(format: "%02d", t.minutes))"
    }
    return "\(t.minutes + (t.seconds >= 30 ? 1 : 0))"
}
