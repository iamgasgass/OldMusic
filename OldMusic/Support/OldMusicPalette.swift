import SwiftUI

// MARK: - Button families

/// OldOS `tool_bar_button_type`.
enum OldOSButtonType {
    case gray
    case blueGray
    case blue
    case black
    case red
}

/// OldOS `returnLinearGradient(_:)`, values copied 1:1.
func oldOSButtonGradient(_ type: OldOSButtonType) -> LinearGradient {
    switch type {
    case .gray:
        return LinearGradient(oldOS: [
            OldOSStop(.oldOS(164, 175, 191), 0),
            OldOSStop(.oldOS(124, 141, 164), 0.51),
            OldOSStop(.oldOS(113, 131, 156), 0.51),
            OldOSStop(.oldOS(112, 130, 155), 1)
        ])
    case .blueGray:
        return LinearGradient(oldOS: [
            OldOSStop(.oldOS(142, 166, 196), 0),
            OldOSStop(.oldOS(88, 119, 166), 0.50),
            OldOSStop(.oldOS(71, 105, 153), 0.533),
            OldOSStop(.oldOS(74, 108, 155), 1)
        ])
    case .blue:
        return LinearGradient(oldOS: [
            OldOSStop(.oldOS(137, 173, 238), 0),
            OldOSStop(.oldOS(80, 140, 231), 0.51),
            OldOSStop(.oldOS(43, 120, 228), 0.52),
            OldOSStop(.oldOS(46, 123, 229), 1)
        ])
    case .black:
        return LinearGradient(oldOS: [
            OldOSStop(.oldOS(95, 95, 95), 0),
            OldOSStop(.oldOS(32, 32, 32), 0.51),
            OldOSStop(.oldOS(7.5, 7.5, 7.5), 0.51),
            OldOSStop(.oldOS(7.5, 7.5, 7.5), 1)
        ])
    case .red:
        return LinearGradient(oldOS: [
            OldOSStop(.oldOS(239, 135, 142), 0),
            OldOSStop(.oldOS(199, 52, 63), 0.48),
            OldOSStop(.oldOS(189, 20, 33), 0.49),
            OldOSStop(.oldOS(189, 20, 33), 1)
        ])
    }
}

// MARK: - Theme

/// Every colour value of the OldMusic chrome, in the two skins the app
/// supports: the stock OldOS blue-grey aluminium (Light), and the iOS 6
/// graphite treatment (Dark). The shared block below is OldSafari's
/// `OldOSSafariTheme`, value for value: OldMusic Dark == OldSafari Private.
struct OldMusicTheme {

    // Bars
    let barGradient: [OldOSStop]
    let barHairline: Color
    let barHighlight: Color
    let pageTitle: Color
    let pageTitleShadow: Color
    let pageTitleShadowY: CGFloat
    let toolbarGradient: [OldOSStop]
    let titleBarTitle: Color
    let titleBarTitleEmboss: Color
    let titleBarTitleShadow: Color

    // Address / search fields
    let fieldStroke: Color
    let fieldFill: LinearGradient
    let fieldPlain: Color
    let fieldTextIdle: Color
    let fieldTextActive: Color
    let fieldPlaceholder: Color
    let progressGradient: [OldOSStop]
    let scrim: Color

    // Buttons
    let neutralButton: OldOSButtonType
    let secondaryButton: OldOSButtonType
    let primaryButton: OldOSButtonType

    // Tables
    let listBackground: Color
    let listRowText: Color
    let listRowDetail: Color
    let listSeparator: Color
    let groupedBackground: Color
    let groupedPinstripe: Color
    let cardFill: Color
    let cardStroke: Color
    let cardFieldText: Color
    let cardDetailText: Color
    let sectionHeader: Color

    // Share sheet
    let shareStrip: [OldOSStop]
    let shareBody: [OldOSStop]
    let shareButtonBase: Color
    let shareButtonOuterStroke: [Color]
    let shareButtonInner: [OldOSStop]
    let shareButtonBorder: [Color]
    let shareButtonText: Color
    let shareButtonTextShadow: Color
    let shareButtonTextShadowY: CGFloat
    let shareCancelInner: [OldOSStop]
    let shareCancelBorder: [Color]

    // Back/Forward history preview panel. This strip is always the dark
    // "iOS 6 sheet metal" treatment regardless of Normal/Private mode, so the
    // title needs its own colours instead of reusing `shareButtonText`
    // (which flips to black for the light Normal-mode action-sheet buttons
    // and would be unreadable on this dark strip).
    let panelTitleText: Color
    let panelTitleShadow: Color
    let panelTitleShadowY: CGFloat

    // Tab switcher / app
    let tabsBackground: [Color]
    let tabTitle: Color
    let tabTitleShadow: Color
    let tabURL: Color
    let appBackground: Color
    let pageBackground: Color

    // iPod-only surfaces (search bar, lettered headers, album page, index…)
    let isDark: Bool
    let searchGradient: [OldOSStop]
    let searchHairline: Color
    let searchFieldStroke: Color
    let listTopBounce: Color
    let listFooterText: Color
    let indexText: Color
    let indexPressed: Color
    let headerGradient: [OldOSStop]
    let headerOuterBorder: [OldOSStop]
    let headerInnerBorder: [OldOSStop]
    let headerText: Color
    let headerTextShadow: Color
    let albumHeaderGradient: [Color]
    let albumHeaderTitle: Color
    let albumHeaderDetail: Color
    let albumRowEven: Color
    let albumRowOdd: Color
    let albumRowLine: Color
    let albumTrackDuration: Color
    let editButtonGradient: [Color]
    let editButtonStroke: Color
    let editButtonText: Color
    let editButtonTextShadow: Color
    let editButtonTextShadowY: CGFloat
    let emptyText: Color
    let emptyArrowCircle: Color
    let checkmark: Color
    /// The OldOS back / Now Playing artwork is blue; in Dark it is desaturated
    /// to sit on the graphite bar.
    let barButtonSaturation: Double
    let barButtonBrightness: Double

    static func theme(isDark: Bool) -> OldMusicTheme {
        isDark ? .dark : .standard
    }

    // MARK: Standard (OldOS / iOS 6 blue-grey)

    static let standard = OldMusicTheme(
        barGradient: [
            OldOSStop(.oldOS(180, 191, 205), 0.0),
            OldOSStop(.oldOS(136, 155, 179), 0.49),
            OldOSStop(.oldOS(128, 149, 175), 0.49),
            OldOSStop(.oldOS(110, 133, 162), 1.0)
        ],
        barHairline: .oldOS(45, 48, 51),
        barHighlight: .oldOS(230, 230, 230),
        pageTitle: .oldOS(62, 69, 79),
        pageTitleShadow: Color.white.opacity(0.51),
        pageTitleShadowY: 2.0 / 3.0,
        toolbarGradient: [
            OldOSStop(.oldOS(230, 230, 230), 0),
            OldOSStop(.oldOS(180, 191, 206), 0.04),
            OldOSStop(.oldOS(136, 155, 179), 0.51),
            OldOSStop(.oldOS(126, 148, 176), 0.51),
            OldOSStop(.oldOS(110, 132, 162), 1)
        ],
        titleBarTitle: .white,
        titleBarTitleEmboss: Color.white.opacity(0.07),
        titleBarTitleShadow: Color.black.opacity(0.21),

        fieldStroke: .oldOS(84, 108, 138),
        fieldFill: LinearGradient(oldOS: [Color.white, Color.white]),
        fieldPlain: .white,
        fieldTextIdle: .oldOS(102, 102, 102),
        fieldTextActive: .black,
        fieldPlaceholder: .oldOS(142, 142, 147),
        progressGradient: [
            OldOSStop(.oldOS(129, 184, 237), 0),
            OldOSStop(.oldOS(96, 168, 236), 0.50),
            OldOSStop(.oldOS(71, 148, 233), 0.50),
            OldOSStop(.oldOS(104, 194, 233), 1)
        ],
        scrim: Color.black.opacity(0.75),

        neutralButton: .gray,
        secondaryButton: .blueGray,
        primaryButton: .blue,

        listBackground: .white,
        listRowText: .black,
        listRowDetail: .oldOS(143, 143, 143),
        listSeparator: .oldOS(224, 224, 224),
        groupedBackground: .oldOS(197, 204, 212),
        groupedPinstripe: .oldOS(203, 210, 216),
        cardFill: .white,
        cardStroke: .oldOS(171, 171, 171),
        cardFieldText: .oldOS(62, 83, 131),
        cardDetailText: .oldOS(143, 143, 143),
        sectionHeader: .oldOS(76, 86, 108),

        shareStrip: [
            OldOSStop(.oldOS(74, 76, 80, 0.92), 0),
            OldOSStop(.oldOS(46, 48, 52, 0.92), 1)
        ],
        shareBody: [
            OldOSStop(.oldOS(28, 29, 32, 0.93), 0),
            OldOSStop(.oldOS(28, 29, 32, 0.95), 1)
        ],
        shareButtonBase: .oldOS(24, 25, 28),
        shareButtonOuterStroke: [.oldOS(70, 70, 70), .oldOS(120, 120, 120)],
        shareButtonInner: [
            OldOSStop(.oldOS(235, 235, 236), 0),
            OldOSStop(.oldOS(208, 209, 211), 0.52),
            OldOSStop(.oldOS(192, 193, 196), 0.52),
            OldOSStop(.oldOS(192, 193, 196), 1)
        ],
        shareButtonBorder: [Color.white.opacity(0.9), Color.white.opacity(0.25)],
        shareButtonText: .black,
        shareButtonTextShadow: Color.white.opacity(0.9),
        shareButtonTextShadowY: 0.9,
        shareCancelInner: [
            OldOSStop(.oldOS(239, 135, 142), 0),
            OldOSStop(.oldOS(199, 52, 63), 0.48),
            OldOSStop(.oldOS(189, 20, 33), 0.49),
            OldOSStop(.oldOS(189, 20, 33), 1)
        ],
        shareCancelBorder: [Color.white.opacity(0.55), Color.black.opacity(0.35)],

        panelTitleText: .white,
        panelTitleShadow: Color.black.opacity(0.9),
        panelTitleShadowY: -0.9,

        tabsBackground: [.oldOS(149, 161, 172), .oldOS(85, 105, 121)],
        tabTitle: .white,
        tabTitleShadow: Color.black.opacity(0.51),
        tabURL: .oldOS(182, 188, 192),
        appBackground: .oldOS(93, 99, 103),
        pageBackground: .white,

        // iPod (OldOS iPod.swift values)
        isDark: false,
        searchGradient: [
            OldOSStop(.oldOS(252, 250, 250), 0),
            OldOSStop(.oldOS(224, 228, 231), 0.04),
            OldOSStop(.oldOS(180, 190, 198), 1)
        ],
        searchHairline: .oldOS(163, 173, 182),
        searchFieldStroke: .oldOS(166, 166, 166),
        listTopBounce: .oldOS(227, 231, 236),
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
        albumTrackDuration: .oldOS(128, 128, 128),
        editButtonGradient: [.oldOS(229, 230, 231), .oldOS(210, 210, 213)],
        editButtonStroke: .oldOS(154, 154, 154),
        editButtonText: .oldOS(51, 51, 51),
        editButtonTextShadow: Color.white.opacity(0.9),
        editButtonTextShadowY: 0.9,
        emptyText: .oldOS(98, 106, 121),
        emptyArrowCircle: .oldOS(125, 127, 133),
        checkmark: .oldOS(50, 79, 133),
        barButtonSaturation: 1,
        barButtonBrightness: 0
    )

    // MARK: Dark (OldSafari Private Browsing — iOS 6 graphite)

    static let dark = OldMusicTheme(
        barGradient: [
            OldOSStop(.oldOS(96, 96, 98), 0.0),
            OldOSStop(.oldOS(58, 58, 60), 0.49),
            OldOSStop(.oldOS(50, 50, 52), 0.49),
            OldOSStop(.oldOS(28, 28, 30), 1.0)
        ],
        barHairline: .oldOS(10, 10, 11),
        barHighlight: .oldOS(150, 150, 152),
        pageTitle: .oldOS(228, 230, 234),
        pageTitleShadow: Color.black.opacity(0.65),
        pageTitleShadowY: -2.0 / 3.0,
        toolbarGradient: [
            OldOSStop(.oldOS(122, 122, 124), 0),
            OldOSStop(.oldOS(96, 96, 98), 0.04),
            OldOSStop(.oldOS(58, 58, 60), 0.51),
            OldOSStop(.oldOS(50, 50, 52), 0.51),
            OldOSStop(.oldOS(28, 28, 30), 1)
        ],
        titleBarTitle: .white,
        titleBarTitleEmboss: Color.white.opacity(0.05),
        titleBarTitleShadow: Color.black.opacity(0.75),

        fieldStroke: .oldOS(16, 16, 18),
        fieldFill: LinearGradient(oldOS: [
            OldOSStop(.oldOS(80, 80, 82), 0),
            OldOSStop(.oldOS(54, 54, 56), 0.50),
            OldOSStop(.oldOS(48, 48, 50), 0.50),
            OldOSStop(.oldOS(62, 62, 64), 1)
        ]),
        fieldPlain: .oldOS(56, 56, 58),
        fieldTextIdle: .oldOS(186, 186, 190),
        fieldTextActive: .white,
        fieldPlaceholder: Color.white.opacity(0.42),
        progressGradient: [
            OldOSStop(.oldOS(129, 184, 237), 0),
            OldOSStop(.oldOS(96, 168, 236), 0.50),
            OldOSStop(.oldOS(71, 148, 233), 0.50),
            OldOSStop(.oldOS(104, 194, 233), 1)
        ],
        scrim: Color.black.opacity(0.82),

        neutralButton: .black,
        secondaryButton: .black,
        primaryButton: .blue,

        listBackground: .oldOS(30, 30, 32),
        listRowText: .white,
        listRowDetail: .oldOS(150, 150, 154),
        listSeparator: Color.white.opacity(0.09),
        groupedBackground: .oldOS(44, 46, 50),
        groupedPinstripe: .oldOS(50, 52, 56),
        cardFill: .oldOS(58, 58, 60),
        cardStroke: .oldOS(18, 18, 20),
        cardFieldText: .oldOS(152, 180, 238),
        cardDetailText: .oldOS(150, 150, 154),
        sectionHeader: .oldOS(198, 202, 210),

        shareStrip: [
            OldOSStop(.oldOS(74, 76, 80, 0.90), 0),
            OldOSStop(.oldOS(46, 48, 52, 0.90), 1)
        ],
        shareBody: [
            OldOSStop(.oldOS(28, 29, 32, 0.92), 0),
            OldOSStop(.oldOS(28, 29, 32, 0.94), 1)
        ],
        shareButtonBase: .oldOS(24, 25, 28),
        shareButtonOuterStroke: [.oldOS(70, 70, 70), .oldOS(120, 120, 120)],
        shareButtonInner: [
            OldOSStop(.oldOS(98, 100, 104), 0),
            OldOSStop(.oldOS(62, 64, 68), 0.52),
            OldOSStop(.oldOS(52, 54, 58), 0.52),
            OldOSStop(.oldOS(52, 54, 58), 1)
        ],
        shareButtonBorder: [Color.white.opacity(0.35), Color.white.opacity(0.10)],
        shareButtonText: .white,
        shareButtonTextShadow: Color.black.opacity(0.9),
        shareButtonTextShadowY: -0.9,
        shareCancelInner: [
            OldOSStop(.oldOS(239, 135, 142), 0),
            OldOSStop(.oldOS(199, 52, 63), 0.48),
            OldOSStop(.oldOS(189, 20, 33), 0.49),
            OldOSStop(.oldOS(189, 20, 33), 1)
        ],
        shareCancelBorder: [Color.white.opacity(0.55), Color.black.opacity(0.35)],

        panelTitleText: .white,
        panelTitleShadow: Color.black.opacity(0.9),
        panelTitleShadowY: -0.9,

        tabsBackground: [.oldOS(74, 76, 80), .oldOS(20, 21, 24)],
        tabTitle: .white,
        tabTitleShadow: Color.black.opacity(0.7),
        tabURL: .oldOS(158, 162, 168),
        appBackground: .oldOS(24, 25, 28),
        pageBackground: .oldOS(20, 20, 22),

        // iPod surfaces, built from the same graphite values
        isDark: true,
        // OldSafari Private toolbar, value for value.
        searchGradient: [
            OldOSStop(.oldOS(122, 122, 124), 0),
            OldOSStop(.oldOS(96, 96, 98), 0.04),
            OldOSStop(.oldOS(58, 58, 60), 0.51),
            OldOSStop(.oldOS(50, 50, 52), 0.51),
            OldOSStop(.oldOS(28, 28, 30), 1)
        ],
        searchHairline: .oldOS(10, 10, 11),
        searchFieldStroke: .oldOS(16, 16, 18),
        listTopBounce: .oldOS(44, 46, 50),
        listFooterText: .oldOS(150, 150, 154),
        indexText: .oldOS(198, 202, 210),
        indexPressed: Color.oldOS(198, 202, 210).opacity(0.3),
        headerGradient: [
            OldOSStop(.oldOS(96, 96, 98), 0),
            OldOSStop(.oldOS(74, 76, 80), 0.52),
            OldOSStop(.oldOS(58, 58, 60), 0.93),
            OldOSStop(.oldOS(46, 48, 52), 0.97),
            OldOSStop(.oldOS(50, 50, 52), 1)
        ],
        headerOuterBorder: [
            OldOSStop(.oldOS(122, 122, 124), 0),
            OldOSStop(.oldOS(122, 122, 124), 0.45),
            OldOSStop(.oldOS(96, 96, 98), 0.5),
            OldOSStop(.oldOS(96, 96, 98), 1)
        ],
        headerInnerBorder: [
            OldOSStop(.oldOS(10, 10, 11), 0),
            OldOSStop(.oldOS(10, 10, 11), 0.45),
            OldOSStop(.oldOS(28, 28, 30), 0.5),
            OldOSStop(.oldOS(28, 28, 30), 1)
        ],
        headerText: .oldOS(228, 230, 234),
        headerTextShadow: Color.black.opacity(0.65),
        albumHeaderGradient: [.oldOS(58, 58, 60), .oldOS(44, 46, 50)],
        albumHeaderTitle: .white,
        albumHeaderDetail: .oldOS(150, 150, 154),
        albumRowEven: .oldOS(30, 30, 32),
        albumRowOdd: .oldOS(36, 36, 38),
        albumRowLine: Color.white.opacity(0.09),
        albumTrackDuration: .oldOS(150, 150, 154),
        editButtonGradient: [.oldOS(98, 100, 104), .oldOS(52, 54, 58)],
        editButtonStroke: .oldOS(18, 18, 20),
        editButtonText: .white,
        editButtonTextShadow: Color.black.opacity(0.9),
        editButtonTextShadowY: -0.9,
        emptyText: .oldOS(198, 202, 210),
        emptyArrowCircle: .oldOS(96, 96, 98),
        checkmark: .oldOS(152, 180, 238),
        barButtonSaturation: 0,
        barButtonBrightness: -0.28
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

/// The iOS 6 black chrome shared by the tab bar, Now Playing and Cover Flow
/// (identical in Light and Dark, as on iOS 6).
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
