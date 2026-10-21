import SwiftUI
import UIKit

// The drop-down ("tendina") panel of OldSafari's Back / Forward history,
// ported 1:1 and generalised: it can hang above a bottom bar (pointer down)
// or under the navigation bar (pointer up), and rows can show a check.

struct OldOSPopoverPanel: View {
    let theme: OldMusicTheme
    let request: MusicPanelRequest
    let onDismiss: () -> Void

    private let rowHeight: CGFloat = 44
    private let headerHeight: CGFloat = 30

    var body: some View {
        GeometryReader { geometry in
            let width = min(geometry.size.width - 24, 420)
            let available = geometry.size.height - request.inset - 90
            let wanted = headerHeight + CGFloat(max(request.items.count, 1)) * rowHeight
            let height = max(min(wanted, available), headerHeight + rowHeight)
            let anchorX = min(
                max(request.anchor * geometry.size.width, 24),
                geometry.size.width - 24
            )
            let left = min(
                max(anchorX - width / 2, 12),
                max(geometry.size.width - width - 12, 12)
            )
            let top: CGFloat = request.edge == .bottom
                ? geometry.size.height - request.inset - height - 9 - 4
                : request.inset + 4

            ZStack(alignment: .topLeading) {
                theme.scrim.opacity(0.4)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture { onDismiss() }

                VStack(spacing: 0) {
                    if request.edge == .top {
                        OldOSPanelPointer()
                            .fill(LinearGradient(oldOS: theme.shareStrip))
                            .rotationEffect(.degrees(180))
                            .frame(width: 20, height: 9)
                            .offset(x: anchorX - left - 10)
                            .frame(width: width, alignment: .leading)
                    }

                    panelBody(height: height)

                    if request.edge == .bottom {
                        OldOSPanelPointer()
                            .fill(LinearGradient(oldOS: theme.shareBody))
                            .frame(width: 20, height: 9)
                            .offset(x: anchorX - left - 10)
                            .frame(width: width, alignment: .leading)
                    }
                }
                .frame(width: width)
                .offset(x: left, y: top)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .ignoresSafeArea()
    }

    private func panelBody(height: CGFloat) -> some View {
        VStack(spacing: 0) {
            ZStack {
                Rectangle()
                    .fill(LinearGradient(oldOS: theme.shareStrip))
                    .oldOSInnerShadowBottom(color: Color.white.opacity(0.98), radius: 0.1)

                Text(request.title)
                    .font(OldOSFont.bold(13.25))
                    .foregroundColor(theme.panelTitleText)
                    .shadow(
                        color: theme.panelTitleShadow,
                        radius: 0,
                        x: 0,
                        y: theme.panelTitleShadowY
                    )
                    .lineLimit(1)
                    .padding(.horizontal, 12)
            }
            .frame(height: headerHeight)

            if request.items.isEmpty {
                Text(request.emptyText)
                    .font(OldOSFont.bold(15))
                    .foregroundColor(Color.white.opacity(0.45))
                    .frame(maxWidth: .infinity)
                    .frame(height: rowHeight)
            } else {
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 0) {
                        ForEach(Array(request.items.enumerated()), id: \.element.id) { index, item in
                            row(item, isLast: index == request.items.count - 1)
                        }
                    }
                }
            }
        }
        .background(LinearGradient(oldOS: theme.shareBody))
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .oldOSAddBorder(
            LinearGradient(oldOS: theme.shareButtonOuterStroke),
            width: 0.5,
            cornerRadius: 12
        )
        .shadow(color: Color.black.opacity(0.5), radius: 14, x: 0, y: 5)
    }

    private func row(_ item: MusicPanelItem, isLast: Bool) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            item.action()
        } label: {
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Image(systemName: item.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.white.opacity(0.5))
                        .frame(width: 18)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(item.title)
                            .font(OldOSFont.bold(15))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        if !item.subtitle.isEmpty {
                            Text(item.subtitle)
                                .font(OldOSFont.regular(11))
                                .foregroundColor(Color.white.opacity(0.45))
                                .lineLimit(1)
                        }
                    }

                    Spacer(minLength: 0)

                    if item.checked {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.oldOS(152, 180, 238))
                    } else if item.showsChevron {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(theme.isDark ? .oldOS(126, 131, 140) : Color.white.opacity(0.35))
                    }
                }
                .padding([.leading, .trailing], 14)
                .frame(height: rowHeight - 1)

                Rectangle()
                    .fill(Color.white.opacity(isLast ? 0 : 0.09))
                    .frame(height: 1)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Little triangle under the panel, pointing at the control that opened it.
struct OldOSPanelPointer: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Rectangle pill button (OldSafari `OldOSRectangleButton`)

/// OldOS `tool_bar_rectangle_button`: 32pt tall, 5.5pt radius, recessed bevel,
/// Helvetica Neue Bold 13.25 with a hard dark shadow above the glyphs.
struct OldOSRectangleButton: View {
    let title: String
    var type: OldOSButtonType = .gray
    var heightModifier: CGFloat = 0
    var action: () -> Void

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            Text(title)
                .font(OldOSFont.bold(13.25))
                .foregroundColor(.white)
                .shadow(color: Color.black.opacity(0.75), radius: 1, x: 0, y: -0.25)
                .lineLimit(1)
                .fixedSize()
                .padding([.leading, .trailing], 11)
                .frame(height: 32 + heightModifier)
                .oldOSInnerShadowBackground(
                    RoundedRectangle(cornerRadius: 5.5),
                    oldOSButtonGradient(type),
                    radius: 0.8,
                    offset: CGPoint(x: 0, y: 0.6),
                    intensity: 0.7
                )
                .shadow(color: Color.white.opacity(0.28), radius: 0, x: 0, y: 0.8)
        }
        .buttonStyle(.plain)
        .frame(height: 32 + heightModifier)
    }
}
