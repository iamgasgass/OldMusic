import SwiftUI

/// More › Aspect UI: chooses between following iOS (Sistema), the classic
/// blue-grey skin (Chiaro) and the OldSafari graphite skin (Scuro).
/// Drawn as an iOS 6 grouped table on the pinstriped background.
struct MusicAspectView: View {
    @Environment(\.oldMusicTheme) private var theme
    @ObservedObject private var settings = MusicSettings.shared

    private let rowHeight: CGFloat = 50

    var body: some View {
        ZStack {
            theme.groupedBackground
            OldOSPinstripeBackground(line: theme.groupedPinstripe)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    groupHeader("Aspetto")

                    card

                    groupFooter(footerText)
                }
                .padding(.bottom, 30)
            }
        }
    }

    private var footerText: String {
        switch settings.appearance {
        case .system:
            return "OldMusic segue l'aspetto Chiaro o Scuro scelto in Impostazioni › Schermo e luminosità."
        case .light:
            return "OldMusic usa sempre la finitura blu-grigio di iOS 6."
        case .dark:
            return "OldMusic usa sempre la finitura grafite di iOS 6, la stessa di OldSafari."
        }
    }

    private var card: some View {
        let options = MusicAppearance.allCases
        return VStack(spacing: 0) {
            ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                Button {
                    OldMusicHaptics.tap()
                    settings.appearance = option
                } label: {
                    VStack(spacing: 0) {
                        HStack {
                            Text(option.title)
                                .font(OldOSFont.bold(17))
                                .foregroundColor(settings.appearance == option ? theme.checkmark : theme.listRowText)
                                .lineLimit(1)
                            Spacer()
                            if settings.appearance == option {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(theme.checkmark)
                            }
                        }
                        .padding(.horizontal, 12)
                        .frame(height: rowHeight - 1)

                        Rectangle()
                            .fill(theme.cardStroke.opacity(index == options.count - 1 ? 0 : 0.6))
                            .frame(height: 1)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .background(theme.cardFill)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(theme.cardStroke, lineWidth: 1.25)
        )
        .shadow(color: Color.white.opacity(theme.isDark ? 0.06 : 0.6), radius: 0, x: 0, y: 1)
        .padding(.horizontal, 12)
    }

    private func groupHeader(_ text: String) -> some View {
        Text(text)
            .font(OldOSFont.bold(17))
            .foregroundColor(theme.sectionHeader)
            .shadow(color: theme.isDark ? Color.black.opacity(0.65) : Color.white.opacity(0.9), radius: 0, x: 0, y: theme.isDark ? -1 : 1)
            .padding(.leading, 22)
            .padding(.top, 20)
            .padding(.bottom, 8)
    }

    private func groupFooter(_ text: String) -> some View {
        Text(text)
            .font(OldOSFont.regular(15))
            .foregroundColor(theme.sectionHeader)
            .shadow(color: theme.isDark ? Color.black.opacity(0.65) : Color.white.opacity(0.9), radius: 0, x: 0, y: theme.isDark ? -1 : 1)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.top, 10)
    }
}
