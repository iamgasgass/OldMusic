import SwiftUI
import MediaPlayer

/// Artists tab root (OldOS `SkeuomorphicList_Artists`), lettered and indexed.
struct MusicArtistsView: View {
    @EnvironmentObject private var library: MusicLibrary
    @EnvironmentObject private var navigator: MusicNavigator

    var body: some View {
        MusicSearchableList(indexLetters: library.artistSections.map(\.letter)) {
            ForEach(library.artistSections, id: \.letter) { section in
                Section {
                    ForEach(section.items, id: \.persistentID) { artist in
                        Button {
                            open(artist)
                        } label: {
                            MusicTextRow(title: artist.representativeItem?.artist ?? "", disclosure: false)
                        }
                        .musicRow()
                    }
                } header: {
                    MusicSectionHeader(text: section.letter)
                        .id(section.letter)
                }
            }

            MusicListFooter(text: "\(library.artists.count) Artists")
                .musicRow()
        }
    }

    private func open(_ artist: MPMediaItemCollection) {
        let albums = library.albums(of: artist)
        guard !albums.isEmpty else { return }
        navigator.push(.artist(name: artist.representativeItem?.artist ?? "", albums: albums))
    }
}

/// An artist's albums (OldOS `SkeuomorphicList_Artists_Destination`).
struct MusicArtistAlbumsView: View {
    @EnvironmentObject private var navigator: MusicNavigator
    let albums: [MPMediaItemCollection]

    var body: some View {
        MusicSearchableList {
            if albums.count > 1 {
                // iOS 6 "All Songs" row: every album of the artist, in album order.
                Button {
                    navigator.push(.items(title: "All Songs", items: albums.flatMap { MusicLibrary.sortedTracks($0.items) }))
                } label: {
                    MusicArtworkRow(
                        image: albums.first?.oldMusicArtwork(120) ?? UIImage(),
                        title: "All Songs",
                        subtitle: "\(albums.reduce(0) { $0 + $1.count }) Songs"
                    )
                }
                .musicRow(minHeight: 60)
            }

            ForEach(albums, id: \.persistentID) { album in
                Button {
                    navigator.tap { navigator.push(.album(album)) }
                } label: {
                    MusicArtworkRow(
                        image: album.oldMusicArtwork(120),
                        title: album.representativeItem?.albumTitle ?? "---"
                    )
                }
                .musicAlbumActions(album)
                .musicRow(minHeight: 60)
            }
        }
    }
}

/// Album track list (OldOS `albums_destination`): artwork with reflection,
/// artist / album / year / length header and the zebra track table.
struct MusicAlbumView: View {
    @Environment(\.oldMusicTheme) private var theme
    @EnvironmentObject private var navigator: MusicNavigator
    @ObservedObject private var player = MusicPlayer.shared
    let album: MPMediaItemCollection

    var body: some View {
        let tracks = MusicLibrary.sortedTracks(album.items)
        let artwork = album.oldMusicArtwork(400)
        let totalTime = tracks.reduce(0) { $0 + $1.playbackDuration }

        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                header(artwork: artwork, count: tracks.count, totalTime: totalTime)

                // iOS 6: "Shuffle ⤮" row between the album header and the tracks.
                MusicShuffleRow {
                    MusicPlayer.shared.play(tracks, shuffle: true)
                    navigator.showNowPlaying()
                }
                .buttonStyle(.plain)
                .background(theme.listBackground)

                ForEach(Array(tracks.enumerated()), id: \.element.persistentID) { index, track in
                    Button {
                        navigator.tap {
                            MusicPlayer.shared.play(tracks, startingAt: track)
                            navigator.showNowPlaying()
                        }
                    } label: {
                        trackRow(track, index: index)
                    }
                    .buttonStyle(.plain)
                    .musicSongActions(track, in: tracks)
                    .frame(height: 44)
                }
            }
        }
        .background(tracks.count % 2 == 0 ? theme.albumRowEven : theme.albumRowOdd)
    }

    private func header(artwork: UIImage, count: Int, totalTime: TimeInterval) -> some View {
        HStack {
            ZStack(alignment: .top) {
                Image(uiImage: artwork)
                    .resizable().scaledToFill()
                    .frame(width: 100, height: 100).clipped()
                Image(uiImage: artwork.withHorizontallyFlippedOrientation())
                    .resizable().scaledToFill()
                    .frame(width: 100, height: 100).clipped()
                    .rotationEffect(.degrees(-180))
                    .offset(y: 100)
                    .opacity(0.15)
            }
            .frame(height: 120)
            .clipped()
            .padding(.leading, 6)

            VStack(alignment: .leading) {
                Text(album.representativeItem?.albumArtist ?? album.representativeItem?.artist ?? "")
                    .font(OldOSFont.bold(16))
                    .foregroundColor(theme.albumHeaderTitle)
                    .lineLimit(1)
                Text(album.representativeItem?.albumTitle ?? "")
                    .font(OldOSFont.bold(20))
                    .foregroundColor(theme.albumHeaderTitle)
                    .lineLimit(1)
                if let year = releaseYear {
                    Text("Released \(year)")
                        .font(OldOSFont.bold(10))
                        .foregroundColor(theme.albumHeaderDetail)
                        .lineLimit(1)
                }
                Text("\(count) \(count == 1 ? "Song" : "Songs"), \(oldMusicFormatMinutes(totalTime)) Mins.")
                    .font(OldOSFont.bold(10))
                    .foregroundColor(theme.albumHeaderDetail)
                    .lineLimit(1)
                Spacer()
            }
            .padding(.top, 10)
            Spacer()
        }
        .frame(height: 120)
        .background(LinearGradient(oldOS: theme.albumHeaderGradient))
    }

    private func trackRow(_ track: MPMediaItem, index: Int) -> some View {
        VStack(spacing: 0) {
            if index == 0 {
                Rectangle().fill(theme.albumRowLine).frame(height: 2)
            }
            Spacer(minLength: 0)
            HStack {
                HStack {
                    Spacer()
                    Text(String(track.albumTrackNumber == 0 ? index + 1 : track.albumTrackNumber))
                        .font(OldOSFont.bold(16))
                        .foregroundColor(theme.listRowText)
                        .lineLimit(1)
                    Spacer()
                }
                .frame(width: 40)
                Text(track.title ?? "---")
                    .font(OldOSFont.bold(16))
                    .foregroundColor(theme.listRowText)
                    .lineLimit(1)
                    .padding(.leading, 14)
                Spacer()
                if player.isNowPlaying(track) {
                    Image("NowPlayingListItemIcon").padding(.trailing, 5)
                }
                Text(oldMusicFormatTime(track.playbackDuration))
                    .font(OldOSFont.bold(15))
                    .foregroundColor(theme.albumTrackDuration)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(width: 40)
            }
            Spacer(minLength: 0)
            Rectangle().fill(theme.albumRowLine).frame(height: 2)
        }
        .overlay(
            HStack {
                Rectangle().fill(theme.albumRowLine).frame(width: 2).padding(.leading, 45)
                Spacer()
                Rectangle().fill(theme.albumRowLine).frame(width: 2).padding(.trailing, 45)
            }
        )
        .background(index % 2 == 0 ? theme.albumRowEven : theme.albumRowOdd)
        .contentShape(Rectangle())
    }

    private var releaseYear: String? {
        if let year = (album.representativeItem?.value(forProperty: "year") as? NSNumber)?.intValue, year > 0 {
            return String(year)
        }
        if let date = album.representativeItem?.releaseDate {
            return String(Calendar.current.component(.year, from: date))
        }
        return nil
    }
}
