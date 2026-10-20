import SwiftUI
import UIKit

// OldOS drawing helpers needed by the iPod screens that OldSafari never used.
// `OldOSKit.swift` is shared verbatim with OldSafari; additions live here.

// MARK: - Borders and glows

extension View {
    func oldOSBorder(width: CGFloat = 1, edges: [Edge], gradient: LinearGradient) -> some View {
        overlay(OldOSEdgeBorder(width: width, edges: edges).fill(gradient))
    }

    /// OldOS `innerShadowBottomView`: the glow rising from the bottom edge.
    func oldOSInnerShadowBottomView(color: Color, radius: CGFloat = 0.1) -> some View {
        modifier(OldMusicEdgeGlow(color: color, radius: min(max(0, radius), 1), fromTop: false, offset: 0))
    }

    /// OldOS `innerShadowBottomWithOffset`: the top glow pushed down by `offset`
    /// (used under artwork so the reflection starts with a soft shadow).
    func oldOSInnerShadowBottomWithOffset(color: Color, radius: CGFloat = 0.1, offset: CGFloat) -> some View {
        modifier(OldMusicEdgeGlow(color: color, radius: min(max(0, radius), 1), fromTop: true, offset: offset))
    }
}

private struct OldMusicEdgeGlow: ViewModifier {
    var color: Color
    var radius: CGFloat
    var fromTop: Bool
    var offset: CGFloat

    private var colors: [Color] {
        [color.opacity(0.75), color.opacity(0.0), .clear]
    }

    func body(content: Content) -> some View {
        GeometryReader { geo in
            content.overlay(
                LinearGradient(
                    gradient: Gradient(colors: colors),
                    startPoint: fromTop ? .top : .bottom,
                    endPoint: fromTop ? .bottom : .top
                )
                .frame(height: radius * min(geo.size.width, geo.size.height) * 1.5)
                .offset(y: offset)
                .allowsHitTesting(false),
                alignment: fromTop ? .top : .bottom
            )
        }
    }
}

// MARK: - iOS 6 switch (OldOS `toggle`)

/// The blue ON / grey OFF iOS 6 switch, dragged or tapped, with the exact
/// OldOS gradients and 104×30 geometry.
struct OldOSToggle: View {
    @Binding var isOn: Bool
    @State private var offset: CGFloat = -53.6666666667
    @State private var pressed = false

    private let travel: CGFloat = 53.6666666667

    var body: some View {
        ZStack {
            Rectangle()
                .fill(LinearGradient(oldOS: [
                    OldOSStop(.oldOS(52, 123, 245), 0.0),
                    OldOSStop(.oldOS(53, 126, 247), 0.47),
                    OldOSStop(.oldOS(91, 154, 247), 0.50),
                    OldOSStop(.oldOS(101, 161, 249), 1.0)
                ]))
                .modifier(OldMusicToggleShadow(color: Color.oldOS(1, 19, 50).opacity(0.32), side: .leading))
                .overlay(
                    Rectangle()
                        .fill(LinearGradient(oldOS: [
                            OldOSStop(.oldOS(232, 232, 232), 0.0),
                            OldOSStop(.oldOS(235, 235, 235), 0.50),
                            OldOSStop(.oldOS(247, 247, 247), 0.50),
                            OldOSStop(.oldOS(251, 251, 251), 1.0)
                        ]))
                        .modifier(OldMusicToggleShadow(color: Color.black.opacity(0.43), side: .trailing))
                        .offset(x: 100 + offset)
                )
                .cornerRadius(4)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.gray, lineWidth: 0.25))

            HStack {
                Spacer()
                Text("OFF")
                    .font(OldOSFont.bold(18))
                    .foregroundColor(.oldOS(125, 125, 125))
                    .padding(.trailing, 12)
                    .shadow(color: Color.white.opacity(0.84), radius: 2, x: 0, y: 2)
                    .offset(x: travel + offset)
            }
            .clipped()

            HStack(spacing: 0) {
                Text("ON")
                    .font(OldOSFont.bold(18))
                    .foregroundColor(.white)
                    .padding(.leading, 14)
                    .shadow(color: Color.black.opacity(0.45), radius: 0.34, x: 0, y: -1.25)
                    .frame(width: 50, alignment: .leading)
                ZStack {
                    Rectangle()
                        .fill(LinearGradient(oldOS: [.oldOS(208, 208, 208), .oldOS(254, 254, 254)]))
                        .cornerRadius(4)
                        .overlay(Color.gray.opacity(pressed ? 0.3 : 0).cornerRadius(4))
                        .oldOSAddBorder(
                            LinearGradient(oldOS: [.oldOS(136, 135, 135), .oldOS(183, 182, 182)]),
                            width: 0.5,
                            cornerRadius: 4
                        )
                        .padding(.leading, 4)
                }
                .frame(width: 54)
            }
            .offset(x: offset)
            .frame(width: 104, alignment: .leading)
        }
        .frame(width: 104, height: 30)
        .clipped()
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    pressed = true
                    let base: CGFloat = isOn ? 0 : -travel
                    offset = min(max(base + value.translation.width, -travel), 0)
                }
                .onEnded { value in
                    pressed = false
                    let newValue: Bool
                    if abs(value.translation.width) < 4 {
                        newValue = !isOn
                    } else {
                        newValue = offset > -travel / 2
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.linear(duration: 0.1)) {
                        offset = newValue ? 0 : -travel
                    }
                    isOn = newValue
                }
        )
        .onAppear { offset = isOn ? 0 : -travel }
        .onChange(of: isOn) { newValue in
            withAnimation(.linear(duration: 0.1)) { offset = newValue ? 0 : -travel }
        }
    }
}

/// OldOS `innerShadowToggle` / `innerShadowToggleSecondary`.
private struct OldMusicToggleShadow: ViewModifier {
    var color: Color
    var side: HorizontalEdge
    var radius: CGFloat = 0.3

    private var colors: [Color] {
        [color.opacity(0.75), color.opacity(0.0), .clear]
    }

    func body(content: Content) -> some View {
        GeometryReader { geo in
            let side3 = CGFloat(3) * min(geo.size.width, geo.size.height) / 2
            content
                .overlay(
                    LinearGradient(gradient: Gradient(colors: colors), startPoint: .top, endPoint: .bottom)
                        .frame(height: radius * side3),
                    alignment: .top
                )
                .overlay(
                    LinearGradient(
                        gradient: Gradient(colors: colors),
                        startPoint: side == .leading ? .leading : .trailing,
                        endPoint: side == .leading ? .trailing : .leading
                    )
                    .frame(width: 20 * radius, height: side3)
                    .opacity(0.3),
                    alignment: side == .leading ? .leading : .trailing
                )
                .overlay(
                    LinearGradient(gradient: Gradient(colors: colors), startPoint: .bottom, endPoint: .top)
                        .frame(height: radius * side3 * 0.3)
                        .opacity(0.25),
                    alignment: .bottom
                )
        }
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
}

extension Color {
    /// PureSwiftUI `cgLightGray` (white 0.667), used for iPod row subtitles.
    static let oldOSLightGray = Color(white: 0.667)
}

extension Collection {
    subscript(optional index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Haptics (same feedback as the OldSafari toolbar)

enum OldMusicHaptics {
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func press() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
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

// MARK: - Key window

extension OldOSScreen {
    static var keyWindow: UIWindow? {
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
        return windows.first(where: { $0.isKeyWindow }) ?? windows.first
    }
}
