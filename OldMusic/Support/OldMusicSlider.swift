import SwiftUI

/// OldOS `CustomSlider`: the caller draws the left bar, right bar and knob,
/// the slider only positions them. Used for the volume slider and the
/// Now Playing scrubber.
struct OldMusicSliderParts {
    let barLeft: OldMusicSliderPart
    let barRight: OldMusicSliderPart
    let knob: OldMusicSliderPart
}

struct OldMusicSliderPart: ViewModifier {
    let size: CGSize
    let offset: CGFloat

    func body(content: Content) -> some View {
        content
            .frame(width: size.width)
            .position(x: size.width * 0.5, y: size.height * 0.5)
            .offset(x: offset)
    }
}

struct OldMusicSlider<Component: View>: View {
    @Binding var value: Double
    var range: (Double, Double) = (0, 100)
    var knobWidth: CGFloat? = nil
    /// Called continuously while dragging.
    var onChanged: (Double) -> Void = { _ in }
    /// Called once when the finger is lifted.
    var onEnded: (Double) -> Void = { _ in }
    let content: (OldMusicSliderParts) -> Component

    var body: some View {
        GeometryReader { geometry in
            let frame = geometry.frame(in: .local)
            let knob = CGSize(width: knobWidth ?? frame.height, height: frame.height)
            let offsetX = knobOffset(width: frame.width, knob: knob.width)
            let leftSize = CGSize(width: offsetX + knob.width * 0.5, height: frame.height)
            let rightSize = CGSize(width: max(0, frame.width - leftSize.width), height: frame.height)
            let parts = OldMusicSliderParts(
                barLeft: OldMusicSliderPart(size: leftSize, offset: 0),
                barRight: OldMusicSliderPart(size: rightSize, offset: leftSize.width),
                knob: OldMusicSliderPart(size: knob, offset: offsetX)
            )

            ZStack {
                content(parts)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        let newValue = valueFor(location: drag.location.x, width: frame.width, knob: knob.width)
                        value = newValue
                        onChanged(newValue)
                    }
                    .onEnded { drag in
                        let newValue = valueFor(location: drag.location.x, width: frame.width, knob: knob.width)
                        value = newValue
                        onEnded(newValue)
                    }
            )
        }
    }

    private func valueFor(location: CGFloat, width: CGFloat, knob: CGFloat) -> Double {
        let track = Double(max(width - knob, 1))
        var position = Double(location) - Double(knob) * 0.5
        position = min(max(position, 0), track)
        return range.0 + (position / track) * (range.1 - range.0)
    }

    private func knobOffset(width: CGFloat, knob: CGFloat) -> CGFloat {
        let track = max(width - knob, 0)
        let span = range.1 - range.0
        guard span > 0 else { return 0 }
        let clamped = min(max(value.isFinite ? value : range.0, range.0), range.1)
        return CGFloat((clamped - range.0) / span) * track
    }
}

/// The glossy blue / white bars and fat knob shared by both sliders (OldOS values).
struct OldMusicSliderSkin: View {
    let parts: OldMusicSliderParts
    var barHeight: CGFloat = 8.5

    var body: some View {
        ZStack {
            LinearGradient(oldOS: [
                OldOSStop(.oldOS(205, 220, 241), 0),
                OldOSStop(.oldOS(125, 174, 245), 0.5),
                OldOSStop(.oldOS(45, 111, 198), 0.5),
                OldOSStop(.oldOS(50, 151, 236), 1)
            ])
            .frame(height: barHeight)
            .cornerRadius(4.25)
            .padding(.leading, 4)
            .modifier(parts.barLeft)

            LinearGradient(oldOS: [
                OldOSStop(.oldOS(218, 218, 218), 0),
                OldOSStop(.oldOS(166, 166, 166), 0.19),
                OldOSStop(.oldOS(204, 204, 204), 0.5),
                OldOSStop(.oldOS(255, 255, 255), 0.5),
                OldOSStop(.oldOS(255, 255, 255), 1)
            ])
            .frame(height: barHeight)
            .cornerRadius(4.25)
            .padding(.trailing, 4)
            .modifier(parts.barRight)

            ZStack {
                Image("volume-slider-fat-knob").resizable().scaledToFill()
            }
            .modifier(parts.knob)
        }
    }
}
