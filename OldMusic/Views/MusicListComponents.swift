import SwiftUI
import MediaPlayer

// The table building blocks of the iOS 6 iPod lists (rows, separators,
// lettered headers, index bar, footers), themed for Light and Dark Mode.

// MARK: - Artwork

extension MPMediaItem {
    func oldMusicArtwork(_ side: CGFloat = 400) -> UIImage {
        artwork?.image(at: CGSize(width: side, height: side))
            ?? UIImage(named: "noartplaceholder")
            ?? UIImage()
    }
}

extension MPMediaItemCollection {
    func oldMusicArtwork(_ side: CGFloat = 400) -> UIImage {
        representativeItem?.oldMusicArtwork(side)
            ?? UIImage(named: "noartplaceholder")
            ?? UIImage()
    }
}

// MARK: - List style

struct MusicListStyle: ViewModifier {
    @Environment(\.oldMusicTheme) private var theme

    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(theme.listBackground)
                .listSectionSpacing(0)
                .environment(\.defaultMinListRowHeight, 44)
                .environment(\.defaultMinListHeaderHeight, 23)
                .scrollIndicators(.hidden)
        } else {
            content
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(theme.listBackground)
                .environment(\.defaultMinListRowHeight, 44)
                .environment(\.defaultMinListHeaderHeight, 23)
                .scrollIndicators(.hidden)
        }
    }
}

/// OldOS `hideRowSeparator` / `hideRowSeparator_larger`.
struct MusicRowStyle: ViewModifier {
    @Environment(\.oldMusicTheme) private var theme
    var minHeight: CGFloat

    func body(content: Content) -> some View {
        content
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: minHeight, alignment: .leading)
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .listRowBackground(theme.listBackground)
            .background(theme.listBackground)
    }
}

extension View {
    func musicListStyle() -> some View {
        modifier(MusicListStyle())
    }

    func musicRow(minHeight: CGFloat = 44) -> some View {
        modifier(MusicRowStyle(minHeight: minHeight))
    }
}

// MARK: - Separator

struct MusicSeparator: View {
    @Environment(\.oldMusicTheme) private var theme

    var body: some View {
        Rectangle()
            .fill(theme.listSeparator)
            .frame(height: 0.95)
    }
}

// MARK: - Section headers

/// OldOS `alpha_list_header` / `generic_text_list_header`.
struct MusicSectionHeader: View {
    @Environment(\.oldMusicTheme) private var theme
    let text: String

    var body: some View {
        if theme.isDark {
            // OldSafari Private section header (SafariLibraryView), 1:1.
            ZStack {
                LinearGradient(oldOS: theme.barGradient)
                    .oldOSBorder(width: 0.95, edges: [.bottom], color: theme.barHairline)
                HStack {
                    Text(text)
                        .font(OldOSFont.bold(18))
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.45), radius: 0, x: 0, y: -1)
                        .textCase(.none)
                        .lineLimit(1)
                        .padding(.leading, 12)
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, minHeight: 23, maxHeight: .infinity)
            .clipped()
            .listRowInsets(EdgeInsets())
        } else {
            standardHeader
        }
    }

    private var standardHeader: some View {
        ZStack {
            Rectangle()
                .fill(LinearGradient(oldOS: theme.headerGradient))
                .oldOSBorder(width: 2.4, edges: [.top], gradient: LinearGradient(oldOS: theme.headerOuterBorder))
                .oldOSBorder(width: 1.2, edges: [.top], gradient: LinearGradient(oldOS: theme.headerInnerBorder))
            HStack {
                Text(text)
                    .font(OldOSFont.bold(18))
                    .foregroundColor(theme.headerText)
                    .shadow(color: theme.headerTextShadow, radius: 0, x: 0, y: 1.2)
                    .textCase(.none)
                    .lineLimit(1)
                    .padding(.leading, 12)
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, minHeight: 23, maxHeight: .infinity)
        .clipped()
        .listRowInsets(EdgeInsets())
    }
}

// MARK: - Rows

/// 44pt single-line row with optional disclosure arrow (playlists, genres, composers).
struct MusicTextRow: View {
    @Environment(\.oldMusicTheme) private var theme
    let title: String
    var disclosure: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: 0)
            HStack {
                Text(title)
                    .font(OldOSFont.bold(18))
                    .foregroundColor(theme.listRowText)
                    .lineLimit(1)
                    .padding(.leading, 11)
                    .padding(.trailing, 40)
                Spacer()
                if disclosure {
                    Image("UITableNext").padding(.trailing, 12)
                }
            }
            Spacer(minLength: 0)
            MusicSeparator()
        }
        .frame(height: 44)
        .contentShape(Rectangle())
    }
}

/// 60pt row with artwork (albums, search results, podcasts, videos).
struct MusicArtworkRow: View {
    @Environment(\.oldMusicTheme) private var theme
    let image: UIImage
    let title: String
    var subtitle: String? = nil
    var disclosure: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60 - 0.95, height: 60 - 0.95)
                    .clipped()
                VStack(alignment: .leading, spacing: 0) {
                    Text(title)
                        .font(OldOSFont.bold(18))
                        .foregroundColor(theme.listRowText)
                        .lineLimit(1)
                    if let subtitle, !subtitle.isEmpty {
                        Spacer().frame(height: 1)
                        Text(subtitle)
                            .font(OldOSFont.regular(14))
                            .foregroundColor(theme.listRowDetail)
                            .lineLimit(1)
                    }
                }
                .padding(.leading, 6)
                .padding(.trailing, 40)
                Spacer()
                if disclosure {
                    Image("UITableNext").padding(.trailing, 12)
                }
            }
            MusicSeparator()
        }
        .frame(height: 60)
        .contentShape(Rectangle())
    }
}

/// Two-line song row ("Title" / "Album - Artist") with the blue Now Playing speaker.
struct MusicSongRow: View {
    @Environment(\.oldMusicTheme) private var theme
    let song: MPMediaItem
    let isPlaying: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 4.5)
            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    Text(song.title ?? "---")
                        .font(OldOSFont.bold(18))
                        .foregroundColor(theme.listRowText)
                        .lineLimit(1)
                    Spacer().frame(height: 1)
                    Text("\(song.albumTitle ?? "---") - \(song.artist ?? "---")")
                        .font(OldOSFont.regular(14))
                        .foregroundColor(theme.listRowDetail)
                        .lineLimit(1)
                }
                .padding(.leading, 11)
                Spacer()
                if isPlaying {
                    Image("NowPlayingListItemIcon")
                }
            }
            .padding(.trailing, 40)
            Spacer().frame(height: 4.5)
            MusicSeparator()
        }
        .contentShape(Rectangle())
    }
}

/// The "Shuffle ⤮" row at the top of song lists.
struct MusicShuffleRow: View {
    @Environment(\.oldMusicTheme) private var theme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                Spacer(minLength: 0)
                HStack {
                    Text("Shuffle")
                        .font(OldOSFont.bold(18))
                        .foregroundColor(theme.listRowText)
                        .lineLimit(1)
                    Image("shuffle_icon")
                    Spacer()
                }
                .padding(.leading, 11)
                Spacer(minLength: 0)
                MusicSeparator()
            }
            .frame(height: 44)
            .contentShape(Rectangle())
        }
    }
}

/// "123 Songs" centred footer.
struct MusicListFooter: View {
    @Environment(\.oldMusicTheme) private var theme
    let text: String

    var body: some View {
        HStack {
            Spacer()
            Text(text)
                .font(OldOSFont.regular(20))
                .foregroundColor(theme.listFooterText)
                .lineLimit(1)
            Spacer()
        }
        .frame(height: 44)
    }
}

/// iOS 6 empty list placeholder ("No Podcasts").
struct MusicEmptyView: View {
    @Environment(\.oldMusicTheme) private var theme
    let title: String
    var message: String? = nil

    var body: some View {
        ZStack {
            theme.listBackground
            VStack(spacing: 12) {
                Spacer()
                Text(title)
                    .font(OldOSFont.bold(20))
                    .foregroundColor(theme.emptyText)
                if let message {
                    Text(message)
                        .font(OldOSFont.bold(14))
                        .foregroundColor(theme.emptyText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }
                Spacer()
            }
        }
    }
}

// MARK: - Index bar

/// OldOS `VerticalIndex`: the magnifying glass + A…Z + # strip on the right.
/// A letter without entries scrolls to the closest following section.
struct MusicIndexBar: ViewModifier {
    @Environment(\.oldMusicTheme) private var theme
    let available: [String]
    let hidden: Bool

    @State private var pressed = false
    @State private var lastTarget = ""

    func body(content: Content) -> some View {
        ScrollViewReader { proxy in
            ZStack(alignment: .topTrailing) {
                content

                if !hidden {
                    GeometryReader { geometry in
                        let entries = MusicIndex.bar
                        let rowHeight = max(min(geometry.size.height / CGFloat(entries.count), 18.5), 1)

                        HStack {
                            Spacer()
                            ZStack {
                                if pressed {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(theme.indexPressed)
                                        .frame(width: 24)
                                        .padding(.vertical, 2)
                                }
                                VStack(spacing: 0) {
                                    ForEach(entries, id: \.self) { entry in
                                        Group {
                                            if entry == MusicIndex.search {
                                                Image(systemName: "magnifyingglass")
                                                    .font(.system(size: 11, weight: .bold))
                                            } else {
                                                Text(entry)
                                                    .font(OldOSFont.bold(13.25))
                                            }
                                        }
                                        .foregroundColor(theme.indexText)
                                        .frame(width: 24, height: rowHeight)
                                    }
                                }
                                .frame(maxHeight: .infinity)
                            }
                            .frame(width: 30)
                            .padding(.trailing, 5)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { drag in
                                        pressed = true
                                        let top = (geometry.size.height - rowHeight * CGFloat(entries.count)) / 2
                                        let index = Int((drag.location.y - top) / rowHeight)
                                        let clamped = min(max(index, 0), entries.count - 1)
                                        if let target = target(for: entries[clamped]), target != lastTarget {
                                            lastTarget = target
                                            proxy.scrollTo(target, anchor: .top)
                                        }
                                    }
                                    .onEnded { _ in
                                        pressed = false
                                        lastTarget = ""
                                    }
                            )
                        }
                    }
                }
            }
        }
    }

    private func target(for entry: String) -> String? {
        if entry == MusicIndex.search { return MusicIndex.search }
        if available.contains(entry) { return entry }
        guard let start = MusicIndex.letters.firstIndex(of: entry) else { return nil }
        if let next = MusicIndex.letters[start...].first(where: { available.contains($0) }) {
            return next
        }
        return MusicIndex.letters[..<start].last(where: { available.contains($0) })
    }
}

extension View {
    func musicIndexBar(available: [String], hidden: Bool) -> some View {
        modifier(MusicIndexBar(available: available, hidden: hidden))
    }
}

// MARK: - Long press → iOS 6 action sheet

/// Long-pressing a song opens the action sheet (Play Next, Add to Up Next,
/// Go to Album, Go to Artist, Share Song). The row's own tap must be wrapped
/// in `navigator.tap { }` so the release of the long press does not play it.
struct MusicSongActions: ViewModifier {
    @EnvironmentObject private var navigator: MusicNavigator
    let song: MPMediaItem
    let list: [MPMediaItem]

    func body(content: Content) -> some View {
        content.simultaneousGesture(
            LongPressGesture(minimumDuration: 0.45).onEnded { _ in
                OldMusicHaptics.press()
                navigator.presentActions(for: song, in: list)
            }
        )
    }
}

extension View {
    func musicSongActions(_ song: MPMediaItem, in list: [MPMediaItem]) -> some View {
        modifier(MusicSongActions(song: song, list: list))
    }
}

/// Long press on an album row: Play, Shuffle, Play Next, Add to Up Next, Go to Artist.
struct MusicAlbumActions: ViewModifier {
    @EnvironmentObject private var navigator: MusicNavigator
    let album: MPMediaItemCollection

    func body(content: Content) -> some View {
        content.simultaneousGesture(
            LongPressGesture(minimumDuration: 0.45).onEnded { _ in
                OldMusicHaptics.press()
                navigator.presentActions(forAlbum: album)
            }
        )
    }
}

extension View {
    func musicAlbumActions(_ album: MPMediaItemCollection) -> some View {
        modifier(MusicAlbumActions(album: album))
    }
}
