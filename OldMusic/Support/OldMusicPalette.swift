import SwiftUI

/// Every colour of the iPod chrome, in the two skins OldMusic supports:
/// the stock iOS 6 blue-grey aluminium (Light Mode) and an iOS 6 graphite
/// treatment (Dark Mode), chosen automatically from the device appearance.
/// The Now Playing screen, the tab bar and Cover Flow were already black on
/// iOS 6, so they are identical in both skins.
struct OldMusicTheme {
    let isDark: Bool

    // Navigation bar
    let barGradient: [OldOSStop]
    let barHairline: Color
    let barHighlight: Color
    let barTitle: Color
    let barTitleShadow: Color
    /// The original back / Now Playing button artwork is blue; in Dark Mode it
    /// is desaturated so it sits on the graphite bar like iOS 6 black bars did.
    let barButtonSaturation: Double
    let barButtonBrightness: Double

    // Search bar
    let searchGradient: [OldOSStop]
    let searchHairline: Color
    let searchFieldFill: Color
    let searchFieldStroke: Color
    let searchFieldText: Color
    let searchCancelGradient: [OldOSStop]
    let searchScrim: Color

    // Lists
    let listBackground: Color
    let listTopBounce: Color
    let rowText: Color
    let rowDetail: Color
    let rowSeparator: Color
    let listFooterText: Color
    let indexText: Color
    let indexPressed: Color

    // Section headers ("A", "B", "Artists (3 Results)" ...)
    let headerGradient: [OldOSStop]
    let headerOuterBorder: [OldOSStop]
    let headerInnerBorder: [OldOSStop]
    let headerText: Color
    let headerTextShadow: Color

    // Album track list
    let albumHeaderGradient: [Color]
    let albumHeaderTitle: Color
    let albumHeaderDetail: Color
    let albumRowEven: Color
    let albumRowOdd: Color
    let albumRowLine: Color
    let albumTrackText: Color
    let albumTrackDuration: Color

    // Playlist Edit / Clear / Delete buttons
    let editButtonGradient: [Color]
    let editButtonStroke: Color
    let editButtonText: Color
    let editButtonTextShadow: Color
    let editButtonTextShadowY: CGFloat

    // Empty states
    let emptyText: Color
    let emptyArrowCircle: Color

    static func theme(for scheme: ColorScheme) -> OldMusicTheme {
        scheme == .dark ? .graphite : .standard
    }

    // MARK: Standard (OldOS / iOS 6 blue-grey) — values copied 1:1 from OldOS

    static let standard = OldMusicTheme(
        isDark: false,
        barGradient: [
            OldOSStop(.oldOS(180, 191, 205), 0.0),
            OldOSStop(.oldOS(136, 155, 179), 0.49),
            OldOSStop(.oldOS(128, 149, 175), 0.49),
            OldOSStop(.oldOS(110, 133, 162), 1.0)
        ],
        barHairline: .oldOS(45, 48, 51),
        barHighlight: .oldOS(230, 230, 230),
        barTitle: .white,
        barTitleShadow: Color.black.opacity(0.21),
        barButtonSaturation: 1,
        barButtonBrightness: 0,

        searchGradient: [
            OldOSStop(.oldOS(252, 250, 250), 0),
            OldOSStop(.oldOS(224, 228, 231), 0.04),
            OldOSStop(.oldOS(180, 190, 198), 1)
        ],
        searchHairline: .oldOS(163, 173, 182),
        searchFieldFill: .white,
        searchFieldStroke: .oldOS(166, 166, 166),
        searchFieldText: .black,
        searchCancelGradient: [
            OldOSStop(.oldOS(164, 175, 191), 0),
            OldOSStop(.oldOS(124, 141, 164), 0.51),
            OldOSStop(.oldOS(113, 131, 156), 0.51),
            OldOSStop(.oldOS(112, 130, 155), 1)
        ],
        searchScrim: Color.black.opacity(0.9),

        listBackground: .white,
        listTopBounce: .oldOS(227, 231, 236),
        rowText: .black,
        rowDetail: .oldOSLightGray,
        rowSeparator: .oldOS(224, 224, 224),
        listFooterText: .oldOSLightGray,
        indexText: .oldOS(106, 115, 125),
        indexPressed: Color.oldOS(106, 115, 125).opacity(0.5),

        headerGradient: [
            OldOSStop(.oldOS(148, 162, 173), 0),
            OldOSStop(.oldOS(177, 186, 195), 0.52),
            OldOSStop(.oldOS(183, 192, 199), 0.93),
            OldOSStop(.oldOS(148, 158, 166), 0.97),
            OldOSStop(.oldOS(152, 163, 170), 1)
        ],
        headerOuterBorder: [
            OldOSStop(.oldOS(176, 186, 194), 0),
            OldOSStop(.oldOS(176, 186, 194), 0.45),
            OldOSStop(.oldOS(165, 177, 186), 0.5),
            OldOSStop(.oldOS(165, 177, 186), 1)
        ],
        headerInnerBorder: [
            OldOSStop(.oldOS(122, 134, 142), 0),
            OldOSStop(.oldOS(122, 134, 143), 0.45),
            OldOSStop(.oldOS(140, 152, 160), 0.5),
            OldOSStop(.oldOS(140, 152, 160), 1)
        ],
        headerText: .white,
        headerTextShadow: Color.oldOS(94, 90, 90).opacity(0.75),

        albumHeaderGradient: [.oldOS(248, 248, 248), .oldOS(236, 236, 236)],
        albumHeaderTitle: .black,
        albumHeaderDetail: .oldOS(128, 128, 128),
        albumRowEven: .white,
        albumRowOdd: .oldOS(243, 243, 243),
        albumRowLine: .oldOS(228, 228, 228),
        albumTrackText: .black,
        albumTrackDuration: .oldOS(128, 128, 128),

        editButtonGradient: [.oldOS(229, 230, 231), .oldOS(210, 210, 213)],
        editButtonStroke: .oldOS(154, 154, 154),
        editButtonText: .oldOS(51, 51, 51),
        editButtonTextShadow: Color.white.opacity(0.9),
        editButtonTextShadowY: 0.9,

        emptyText: .oldOS(98, 106, 121),
        emptyArrowCircle: .oldOS(125, 127, 133)
    )

    // MARK: Graphite (Dark Mode)

    static let graphite = OldMusicTheme(
        isDark: true,
        barGradient: [
            OldOSStop(.oldOS(96, 96, 98), 0.0),
            OldOSStop(.oldOS(58, 58, 60), 0.49),
            OldOSStop(.oldOS(50, 50, 52), 0.49),
            OldOSStop(.oldOS(28, 28, 30), 1.0)
        ],
        barHairline: .oldOS(10, 10, 11),
        barHighlight: .oldOS(150, 150, 152),
        barTitle: .white,
        barTitleShadow: Color.black.opacity(0.75),
        barButtonSaturation: 0,
        barButtonBrightness: -0.28,

        searchGradient: [
            OldOSStop(.oldOS(88, 88, 90), 0),
            OldOSStop(.oldOS(64, 64, 66), 0.04),
            OldOSStop(.oldOS(38, 38, 40), 1)
        ],
        searchHairline: .oldOS(14, 14, 16),
        searchFieldFill: .oldOS(58, 58, 60),
        searchFieldStroke: .oldOS(16, 16, 18),
        searchFieldText: .white,
        searchCancelGradient: [
            OldOSStop(.oldOS(110, 110, 112), 0),
            OldOSStop(.oldOS(66, 66, 68), 0.51),
            OldOSStop(.oldOS(52, 52, 54), 0.51),
            OldOSStop(.oldOS(50, 50, 52), 1)
        ],
        searchScrim: Color.black.opacity(0.9),

        listBackground: .oldOS(30, 30, 32),
        listTopBounce: .oldOS(44, 46, 50),
        rowText: .white,
        rowDetail: .oldOS(150, 150, 154),
        rowSeparator: Color.white.opacity(0.09),
        listFooterText: .oldOS(130, 130, 134),
        indexText: .oldOS(150, 156, 164),
        indexPressed: Color.oldOS(150, 156, 164).opacity(0.35),

        headerGradient: [
            OldOSStop(.oldOS(70, 72, 76), 0),
            OldOSStop(.oldOS(84, 86, 90), 0.52),
            OldOSStop(.oldOS(88, 90, 94), 0.93),
            OldOSStop(.oldOS(62, 64, 68), 0.97),
            OldOSStop(.oldOS(66, 68, 72), 1)
        ],
        headerOuterBorder: [
            OldOSStop(.oldOS(92, 94, 98), 0),
            OldOSStop(.oldOS(92, 94, 98), 0.45),
            OldOSStop(.oldOS(80, 82, 86), 0.5),
            OldOSStop(.oldOS(80, 82, 86), 1)
        ],
        headerInnerBorder: [
            OldOSStop(.oldOS(40, 42, 46), 0),
            OldOSStop(.oldOS(40, 42, 46), 0.45),
            OldOSStop(.oldOS(58, 60, 64), 0.5),
            OldOSStop(.oldOS(58, 60, 64), 1)
        ],
        headerText: .white,
        headerTextShadow: Color.black.opacity(0.75),

        albumHeaderGradient: [.oldOS(48, 48, 50), .oldOS(36, 36, 38)],
        albumHeaderTitle: .white,
        albumHeaderDetail: .oldOS(150, 150, 154),
        albumRowEven: .oldOS(30, 30, 32),
        albumRowOdd: .oldOS(37, 37, 39),
        albumRowLine: .oldOS(55, 55, 58),
        albumTrackText: .white,
        albumTrackDuration: .oldOS(150, 150, 154),

        editButtonGradient: [.oldOS(92, 92, 94), .oldOS(60, 60, 62)],
        editButtonStroke: .oldOS(20, 20, 22),
        editButtonText: .white,
        editButtonTextShadow: Color.black.opacity(0.9),
        editButtonTextShadowY: -0.9,

        emptyText: .oldOS(150, 156, 168),
        emptyArrowCircle: .oldOS(110, 112, 118)
    )
}

private struct OldMusicThemeKey: EnvironmentKey {
    static let defaultValue: OldMusicTheme = .standard
}

extension EnvironmentValues {
    var oldMusicTheme: OldMusicTheme {
        get { self[OldMusicThemeKey.self] }
        set { self[OldMusicThemeKey.self] = newValue }
    }
}

/// The iOS 6 black chrome shared by the tab bar, Now Playing and Cover Flow.
enum OldMusicBlackChrome {
    static let barGradient: [OldOSStop] = [
        OldOSStop(.oldOS(0, 0, 0), 0),
        OldOSStop(.oldOS(84, 84, 84), 0.02),
        OldOSStop(.oldOS(59, 59, 59), 0.04),
        OldOSStop(.oldOS(29, 29, 29), 0.5),
        OldOSStop(.oldOS(7.5, 7.5, 7.5), 0.51),
        OldOSStop(.oldOS(7.5, 7.5, 7.5), 1)
    ]
    static let bottomFill = Color.oldOS(7.5, 7.5, 7.5)
    static let hairline = Color.oldOS(45, 48, 51)
}
