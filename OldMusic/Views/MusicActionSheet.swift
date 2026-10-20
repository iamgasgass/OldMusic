import SwiftUI
import UIKit

// The iOS 6 action sheet and the share-sheet bridge, ported verbatim from
// OldSafari (`ShareSheet.swift`) so both apps share the same chrome.

// MARK: - iOS 6 action sheet

/// A single row of an OldOS/iOS 6 action sheet.
struct OldOSSheetButton: Identifiable {
    let id = UUID()
    let title: String
    var destructive: Bool = false
    let action: () -> Void
}

/// OldOS `share_view`: a 30pt brushed strip, a translucent charcoal body and
/// double-bevelled 50pt buttons.  Reused for every action sheet in the app so
/// Clear History and Share look like they came from the same 2012 binary.
struct OldOSActionSheet: View {
    let theme: OldMusicTheme
    let buttons: [OldOSSheetButton]
    var cancelTitle: String = "Cancel"
    /// Optional minimum height, kept for the sheets that were tuned by hand.
    var heightFraction: CGFloat = 0
    var bottomInset: CGFloat = 0
    let onCancel: () -> Void

    /// 30pt strip + 28pt top padding + 50pt rows + cancel button + insets.
    private func sheetHeight(for available: CGFloat) -> CGFloat {
        let rows = CGFloat(buttons.count)
        let content = 30 + 18 + rows * 55 + 50 + 25 + bottomInset
        let minimum = available * heightFraction
        return min(max(content, minimum), available * 0.94)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                theme.scrim.opacity(0.45)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture { onCancel() }

                ZStack {
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(LinearGradient(oldOS: theme.shareStrip))
                            .oldOSInnerShadowBottom(color: Color.white.opacity(0.98), radius: 0.1)
                            .oldOSBorder(width: 1, edges: [.top], color: .black)
                            .frame(height: 30)

                        Rectangle().fill(LinearGradient(oldOS: theme.shareBody))
                    }

                    // Buttons scroll when there are too many for the sheet
                    // height, so extending the action list never clips rows
                    // off the top of the sheet.
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            ForEach(Array(buttons.enumerated()), id: \.element.id) { index, button in
                                sheetButton(
                                    title: button.title,
                                    destructive: button.destructive,
                                    action: button.action
                                )
                                .padding(.top, index == 0 ? 18 : 2.5)
                                .padding(.bottom, 2.5)
                            }
                        }
                    }
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        cancelButton
                            .padding(.bottom, 25 + bottomInset)
                            .background(LinearGradient(oldOS: theme.shareBody))
                    }
                }
                .frame(height: sheetHeight(for: geometry.size.height))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ignoresSafeArea()
    }

    private func sheetButton(title: String, destructive: Bool, action: @escaping () -> Void) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(LinearGradient(oldOS: theme.shareButtonOuterStroke), lineWidth: 0.5)
                    )
                    .oldOSInnerShadowBackground(
                        RoundedRectangle(cornerRadius: 12),
                        LinearGradient(oldOS: [theme.shareButtonBase, theme.shareButtonBase]),
                        radius: 5.0 / 3.0,
                        offset: CGPoint(x: 0, y: 1.0 / 3.0),
                        intensity: 1
                    )

                RoundedRectangle(cornerRadius: 9)
                    .fill(LinearGradient(oldOS: theme.shareButtonInner))
                    .oldOSAddBorder(LinearGradient(oldOS: theme.shareButtonBorder), width: 0.4, cornerRadius: 9)
                    .padding(3)

                Text(title)
                    .font(OldOSFont.bold(18))
                    .foregroundColor(destructive ? .oldOS(189, 20, 33) : theme.shareButtonText)
                    .shadow(color: theme.shareButtonTextShadow, radius: 0, x: 0, y: theme.shareButtonTextShadowY)
                    .lineLimit(1)
            }
            .padding([.leading, .trailing], 25)
            .frame(minHeight: 50, maxHeight: 50)
        }
        .buttonStyle(.plain)
    }

    private var cancelButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onCancel()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(LinearGradient(oldOS: theme.shareButtonOuterStroke), lineWidth: 0.5)
                    )
                    .oldOSInnerShadowBackground(
                        RoundedRectangle(cornerRadius: 12),
                        LinearGradient(oldOS: [theme.shareButtonBase, theme.shareButtonBase]),
                        radius: 5.0 / 3.0,
                        offset: CGPoint(x: 0, y: 1.0 / 3.0),
                        intensity: 1
                    )

                RoundedRectangle(cornerRadius: 9)
                    .fill(LinearGradient(oldOS: theme.shareCancelInner))
                    .oldOSAddBorder(LinearGradient(oldOS: theme.shareCancelBorder), width: 0.4, cornerRadius: 9)
                    .padding(3)

                Text(cancelTitle)
                    .font(OldOSFont.bold(18))
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.9), radius: 0, x: 0, y: -0.9)
            }
            .padding([.leading, .trailing], 25)
            .frame(minHeight: 50, maxHeight: 50)
        }
        .buttonStyle(.plain)
    }
}


// MARK: - System share sheet bridge

struct MusicShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        // The share sheet follows the app appearance (Aspect UI) through the window.
        controller.overrideUserInterfaceStyle = .unspecified
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
