import SwiftUI
import MediaPlayer

/// OldOS `iPodNowPlaying`. Like the iPhone 5 on iOS 6, the artwork is a
/// square under the bar and its reflection fills the space above the
/// controls; double tap (or the bar's album button) flips to the track list.
struct MusicNowPlayingView: View {
    @EnvironmentObject private var navigator: MusicNavigator
    @EnvironmentObject private var library: MusicLibrary
    @ObservedObject private var userData = MusicUserData.shared
    @ObservedObject private var player = MusicPlayer.shared
    let topInset: CGFloat
    let bottomInset: CGFloat
    /// Vertical offset while the sheet is dragged down to close it.
    @Binding var dragOffset: CGFloat

    @State private var artwork: UIImage = UIImage(named: "noartplaceholder") ?? UIImage()
    @State private var albumTracks: [MPMediaItem] = []
    @State private var lyrics: String = ""

    // Flip state, same choreography as OldOS.
    @State private var switchToTracks = false
    @State private var showBackTracks = false
    @State private var hideArtwork = false
    @State private var flipperBackground = false
    @State private var flipLocked = false
    @State private var showTimingControls = false

    private let barHeight: CGFloat = 60
    private let footerHeight: CGFloat = 110

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let available = max(0, geometry.size.height - topInset - barHeight - footerHeight - bottomInset)
            let artHeight = min(width, available)

            VStack(spacing: 0) {
                MusicNowPlayingBar(
                    topInset: topInset,
                    artwork: artwork,
                    switchToTracks: switchToTracks,
                    showBackTracks: showBackTracks,
                    flipperBackground: flipperBackground,
                    flipLocked: flipLocked,
                    onBack: { navigator.showLibrary() },
                    onFlip: flip,
                    onOptions: { presentOptions() }
                )
                .gesture(dismissDrag)
                .zIndex(2)

                ZStack(alignment: .top) {
                    // Back side: the album's track list.
                    ZStack {
                        Image("NowPlayingTableBackground")
                            .resizable()
                            .scaledToFill()
                            .frame(width: width, height: available)
                            .clipped()
                        MusicNowPlayingTracks(tracks: albumTracks, onDoubleTap: flip)
                            .frame(width: width, height: available)
                    }
                    .frame(width: width, height: available)
                    .oldOSBorder(width: 1, edges: [.top], color: .oldOS(53, 53, 53))
                    .rotation3DEffect(.degrees(showBackTracks ? 0 : 90), axis: (x: 0, y: 1, z: 0), anchor: .leading)
                    .offset(x: showBackTracks ? 0 : width / 2)
                    .opacity(showBackTracks ? 1 : 0.5)

                    // Front side: artwork, reflection and the timing controls.
                    ZStack(alignment: .top) {
                        Image(uiImage: artwork.withHorizontallyFlippedOrientation())
                            .resizable()
                            .scaledToFill()
                            .frame(width: width, height: artHeight)
                            .clipped()
                            .rotationEffect(.degrees(-180))
                            .offset(y: artHeight)
                            .opacity(switchToTracks ? 0.25 : 0.8)
                            .allowsHitTesting(false)

                        LinearGradient(oldOS: [
                            OldOSStop(Color.oldOS(10, 10, 10).opacity(0), 0),
                            OldOSStop(Color.black, 0.28),
                            OldOSStop(Color.black, 1)
                        ])
                        .frame(width: width, height: artHeight)
                        .offset(y: artHeight)
                        .allowsHitTesting(false)

                        Image(uiImage: artwork)
                            .resizable()
                            .scaledToFill()
                            .frame(width: width, height: artHeight)
                            .clipped()
                            .contentShape(Rectangle())
                            .oldOSBorder(width: 1, edges: [.top], color: .oldOS(53, 53, 53))
                            .simultaneousGesture(dismissDrag)
                            .gesture(
                                TapGesture(count: 2).onEnded { flip() }
                                    .exclusively(before: TapGesture(count: 1).onEnded {
                                        withAnimation(.easeOut(duration: 0.2)) { showTimingControls.toggle() }
                                    })
                            )

                        if showTimingControls {
                            VStack(spacing: 0) {
                                MusicTimingControls()
                                    .frame(width: width, height: 90)
                                // iOS 6 showed the song's lyrics over the artwork
                                // together with the scrubber.
                                if !lyrics.isEmpty {
                                    MusicLyricsView(lyrics: lyrics)
                                        .frame(width: width, height: max(artHeight - 90, 0))
                                }
                            }
                            .transition(.opacity)
                        }
                    }
                    .frame(width: width, height: available, alignment: .top)
                    .rotation3DEffect(.degrees(switchToTracks ? -90 : 0), axis: (x: 0, y: 1, z: 0), anchor: .trailing)
                    .offset(x: switchToTracks ? -width / 2 : 0)
                    .opacity(switchToTracks ? 0.5 : 1)
                    .isHidden(hideArtwork)
                }
                .frame(width: width, height: available, alignment: .top)
                .clipped()

                MusicNowPlayingFooter(bottomInset: bottomInset)
                    .zIndex(2)
            }
        }
        .background(Color.black)
        .compositingGroup()
        .onAppear { reload(tracks: true) }
        .onChange(of: player.nowPlayingItem?.persistentID) { _ in reload(tracks: true) }
    }

    /// Now Playing options, hanging from the bar like OldSafari's drop-downs.
    private func presentOptions() {
        guard let song = player.nowPlayingItem else { return }
        var items: [MusicPanelItem] = []
        if song.albumPersistentID != 0 {
            items.append(MusicPanelItem(title: "Go to Album", subtitle: song.albumTitle ?? "", icon: "square.stack") {
                navigator.dismissPanel()
                MusicActions.goToAlbum(of: song, library: library, navigator: navigator)
            })
        }
        if song.artistPersistentID != 0 {
            items.append(MusicPanelItem(title: "Go to Artist", subtitle: song.artist ?? "", icon: "person") {
                navigator.dismissPanel()
                MusicActions.goToArtist(of: song, library: library, navigator: navigator)
            })
        }
        let favorite = userData.isFavorite(song)
        items.append(MusicPanelItem(title: favorite ? "Remove from Favorites" : "Add to Favorites", icon: favorite ? "heart.fill" : "heart", showsChevron: false) {
            navigator.dismissPanel()
            userData.toggleFavorite(song)
        })
        items.append(MusicPanelItem(title: "Genius Mix", subtitle: "Songs like this one", icon: "atom", showsChevron: false) {
            navigator.dismissPanel()
            player.playGenius(from: library.songs)
        })
        items.append(MusicPanelItem(title: "Up Next", subtitle: "\(player.upNext.count) songs", icon: "list.bullet") {
            navigator.dismissPanel()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                navigator.presentPanel(MusicPanels.upNext(navigator: navigator, anchor: 0.92, edge: .top, inset: topInset + barHeight))
            }
        })
        items.append(MusicPanelItem(title: "Share Song", icon: "square.and.arrow.up", showsChevron: false) {
            navigator.dismissPanel()
            MusicActions.share(song, navigator: navigator)
        })
        navigator.presentPanel(MusicPanelRequest(
            title: song.title ?? "Now Playing",
            items: items,
            anchor: 0.92,
            edge: .top,
            inset: topInset + barHeight
        ))
    }

    /// Bottom sheet: drag the bar or the artwork down to close Now Playing.
    private var dismissDrag: some Gesture {
        DragGesture(minimumDistance: 14)
            .onChanged { value in
                guard value.translation.height > 0,
                      value.translation.height > abs(value.translation.width) else { return }
                dragOffset = value.translation.height
            }
            .onEnded { value in
                let shouldClose = value.translation.height > 130 || value.predictedEndTranslation.height > 380
                if shouldClose, dragOffset > 0 {
                    OldMusicHaptics.tap()
                    navigator.showLibrary()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { dragOffset = 0 }
                } else {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) { dragOffset = 0 }
                }
            }
    }

    private func reload(tracks: Bool) {
        let item = player.nowPlayingItem
        artwork = item?.oldMusicArtwork(600) ?? UIImage(named: "noartplaceholder") ?? UIImage()
        lyrics = item?.lyrics?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if tracks {
            let newTracks = MusicLibrary.albumTracks(for: item)
            if newTracks.map(\.persistentID) != albumTracks.map(\.persistentID) {
                albumTracks = newTracks
            }
        }
    }

    /// OldOS flip choreography (front rotates away, then the back rotates in).
    private func flip() {
        guard !flipLocked else { return }
        flipLocked = true
        if !switchToTracks {
            withAnimation(.easeIn(duration: 0.4)) {
                switchToTracks = true
                flipperBackground = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.39) {
                withAnimation(.easeOut(duration: 0.4)) { showBackTracks = true }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                hideArtwork = true
                flipLocked = false
            }
        } else {
            withAnimation(.easeIn(duration: 0.4)) { showBackTracks = false }
            hideArtwork = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.39) {
                withAnimation(.easeOut(duration: 0.4)) { switchToTracks = false }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.48) {
                withAnimation(.easeIn(duration: 0.4)) { flipperBackground = false }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                flipLocked = false
            }
        }
    }
}

// MARK: - Bar

/// OldOS `now_playing_title_bar`, extended behind the status bar.
struct MusicNowPlayingBar: View {
    @ObservedObject private var player = MusicPlayer.shared
    let topInset: CGFloat
    let artwork: UIImage
    let switchToTracks: Bool
    let showBackTracks: Bool
    let flipperBackground: Bool
    let flipLocked: Bool
    let onBack: () -> Void
    let onFlip: () -> Void
    var onOptions: () -> Void = {}

    @State private var didLongPress = false

    private let side: CGFloat = 34.33783783783784

    var body: some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: topInset)
            HStack {
                Button(action: onBack) {
                    ZStack {
                        Image("button_back_ipod2")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 102 / (69 / side), height: side)
                        Image("UINavigationBarBackArrow")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 23, height: 19)
                            .padding(.leading, 2)
                    }
                }
                .buttonStyle(.plain)
                .padding(.leading, 8)

                Spacer()

                VStack(spacing: 0) {
                    Text(player.nowPlayingItem?.artist ?? "")
                        .foregroundColor(.oldOS(159, 159, 159))
                    Text(player.nowPlayingItem?.title ?? "")
                        .foregroundColor(.white)
                    Text(player.nowPlayingItem?.albumTitle ?? "")
                        .foregroundColor(.oldOS(159, 159, 159))
                }
                .font(OldOSFont.bold(13))
                .shadow(color: Color.black.opacity(0.8), radius: 0, x: 0, y: -1)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .offset(y: -1)

                Spacer()

                Button {
                    if didLongPress {
                        didLongPress = false
                        return
                    }
                    onFlip()
                } label: {
                    ZStack {
                        Image("NowPlayingFlipperBackground")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 37.5, height: 37.5)
                            .opacity(flipperBackground ? 1 : 0)
                            .offset(x: (37.5 - side) / 2, y: -(37.5 - side) / 12)
                        Image(uiImage: artwork)
                            .resizable()
                            .scaledToFit()
                            .frame(width: side, height: side)
                            .clipped()
                            .rotation3DEffect(.degrees(showBackTracks ? 0 : 90), axis: (x: 0, y: 1, z: 0), anchor: .leading)
                            .offset(x: showBackTracks ? 0 : side / 2)
                            .opacity(showBackTracks ? 1 : 0.5)
                        Image("NowPlayingAlbumInfo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: side, height: side)
                            .clipped()
                            .rotation3DEffect(.degrees(switchToTracks ? -90 : 0), axis: (x: 0, y: 1, z: 0), anchor: .trailing)
                            .offset(x: switchToTracks ? -side / 2 : 0)
                    }
                    .frame(width: 102 / (69 / side), alignment: .trailing)
                }
                .buttonStyle(.plain)
                .disabled(flipLocked)
                // Long press on the album button: options drop-down.
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.4).onEnded { _ in
                        didLongPress = true
                        OldMusicHaptics.press()
                        onOptions()
                    }
                )
                .padding(.trailing, 8)
            }
            .frame(height: 60)
        }
        .background(
            VStack(spacing: 0) {
                Color.black.frame(height: topInset)
                LinearGradient(oldOS: OldMusicBlackChrome.barGradient)
                    .frame(height: 60)
                    .oldOSInnerShadowBottom(color: .oldOS(230, 230, 230), radius: 0.025)
            }
        )
        .oldOSBorder(width: 1, edges: [.bottom], color: OldMusicBlackChrome.hairline)
    }
}

// MARK: - Timing controls

/// OldOS `now_playing_timing_controls`: scrubber, repeat, Genius atom, shuffle.
struct MusicTimingControls: View {
    @EnvironmentObject private var library: MusicLibrary
    @ObservedObject private var player = MusicPlayer.shared
    @State private var geniusFailed = false
    @State private var position: Double = 0
    @State private var scrubbing = false
    @State private var elapsed: Double = 0
    @State private var duration: Double = 0

    private let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .oldOSInnerShadowBottomView(color: Color.white.opacity(0.6), radius: 0.0275)
                .oldOSBorder(width: 1, edges: [.bottom], color: .black)

            VStack {
                HStack {
                    Text(oldMusicFormatTime(elapsed))
                        .font(OldOSFont.bold(14))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .shadow(color: Color.black.opacity(0.21), radius: 0, x: 0, y: -1)
                        .padding(.leading, 15)

                    OldMusicSlider(
                        value: $position,
                        onChanged: { value in
                            scrubbing = true
                            elapsed = value / 100 * duration
                        },
                        onEnded: { value in
                            player.seek(to: value / 100 * duration)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                scrubbing = false
                            }
                        }
                    ) { parts in
                        OldMusicSliderSkin(parts: parts, barHeight: 8)
                    }
                    .frame(height: 20)

                    Text("-\(oldMusicFormatTime(max(0, duration - elapsed)))")
                        .font(OldOSFont.bold(14))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .shadow(color: Color.black.opacity(0.75), radius: 0, x: 0, y: -1)
                        .padding(.trailing, 15)
                }

                HStack {
                    if player.supportsSpeed {
                        // iOS 6 podcasts / audiobooks: speed instead of repeat.
                        Button {
                            OldMusicHaptics.tap()
                            player.cycleSpeed()
                        } label: {
                            MusicSpeedBadge(rate: player.playbackRate)
                        }
                        .buttonStyle(.plain)
                        .padding(.leading, 16)
                    } else {
                        Button {
                            OldMusicHaptics.tap()
                            player.cycleRepeat()
                        } label: {
                            Image(repeatImage)
                        }
                        .buttonStyle(.plain)
                        .padding(.leading, 20)
                    }

                    Spacer()
                    Button {
                        OldMusicHaptics.press()
                        geniusFailed = !player.playGenius(from: library.songs)
                        if geniusFailed {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { geniusFailed = false }
                        }
                    } label: {
                        Image(geniusFailed ? "nowplaying_atom_pressed" : "nowplaying_atom")
                    }
                    .buttonStyle(MusicPressedImageStyle(pressedImage: "nowplaying_atom_pressed"))
                    Spacer()

                    Button {
                        player.toggleShuffle()
                    } label: {
                        Image(player.shuffleOn ? "shuffle_on" : "shuffle_off")
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 20)
                }
            }
        }
        .onAppear(perform: refresh)
        .onReceive(timer) { _ in
            if !scrubbing { refresh() }
            player.applyRateIfNeeded()
        }
    }

    private var repeatImage: String {
        switch player.repeatMode {
        case .all: return "repeat_on"
        case .one: return "repeat_on_1"
        default: return "repeat_off"
        }
    }

    private func refresh() {
        duration = player.currentDuration
        elapsed = min(player.currentTime, duration)
        position = duration > 0 ? elapsed / duration * 100 : 0
    }
}

// MARK: - Track list (back side)

/// OldOS `now_playing_tracks`: star rating strip and the dark album table.
struct MusicNowPlayingTracks: View {
    @ObservedObject private var player = MusicPlayer.shared
    let tracks: [MPMediaItem]
    let onDoubleTap: () -> Void

    @ObservedObject private var userData = MusicUserData.shared
    @State private var tapLocked = false

    /// Ratings are saved by OldMusic (the library itself is read-only).
    private var rating: Binding<Int> {
        Binding(
            get: { userData.rating(for: player.nowPlayingItem) },
            set: { value in
                if let item = player.nowPlayingItem {
                    OldMusicHaptics.tap()
                    userData.setRating(value, for: item)
                }
            }
        )
    }

    private let line = Color.oldOS(65, 64, 65)

    var body: some View {
        VStack(spacing: 0) {
            MusicRatingStrip(rating: rating)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    LinearGradient(oldOS: [
                        OldOSStop(.black, 0),
                        OldOSStop(.black, 0.35),
                        OldOSStop(.oldOS(26, 26, 26), 1)
                    ])
                )

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(Array(tracks.enumerated()), id: \.element.persistentID) { index, track in
                        Button {
                            guard !tapLocked else { return }
                            tapLocked = true
                            MusicPlayer.shared.play(tracks, startingAt: track)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { tapLocked = false }
                        } label: {
                            MusicDarkTrackRow(
                                track: track,
                                index: index,
                                isPlaying: player.isNowPlaying(track)
                            )
                        }
                        .buttonStyle(.plain)
                        .frame(height: 44)
                    }
                }
            }
        }
        .simultaneousGesture(TapGesture(count: 2).onEnded { onDoubleTap() })
    }
}

/// One row of the dark track tables (Now Playing back side and Cover Flow).
struct MusicDarkTrackRow: View {
    let track: MPMediaItem
    let index: Int
    let isPlaying: Bool

    private let line = Color.oldOS(65, 64, 65)

    var body: some View {
        VStack(spacing: 0) {
            if index == 0 {
                Rectangle().fill(line).frame(height: 2)
            }
            Spacer(minLength: 0)
            HStack {
                HStack {
                    Text("\(track.albumTrackNumber == 0 ? index + 1 : track.albumTrackNumber).")
                        .font(OldOSFont.bold(14))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .padding(.horizontal, 5)
                    Spacer()
                }
                .frame(width: 60)
                Text(track.title ?? "---")
                    .font(OldOSFont.bold(14))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .padding(.leading, 14)
                Spacer()
                HStack {
                    Spacer()
                    Text(oldMusicFormatTime(track.playbackDuration))
                        .font(OldOSFont.bold(14))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .padding(.horizontal, 5)
                }
                .frame(width: 60)
            }
            Spacer(minLength: 0)
            Rectangle().fill(line).frame(height: 2)
        }
        .overlay(
            ZStack {
                HStack {
                    Rectangle().fill(line).frame(width: 2).padding(.leading, 65)
                    Spacer()
                    Rectangle().fill(line).frame(width: 2).padding(.trailing, 65)
                }
                if isPlaying {
                    HStack {
                        Image("play")
                            .resizable()
                            .renderingMode(.template)
                            .scaledToFit()
                            .foregroundColor(.oldOS(54, 98, 214))
                            .frame(height: 10)
                            .padding(.leading, 40)
                        Spacer()
                    }
                }
            }
        )
        .background(index % 2 == 0 ? Color.clear : Color.black.opacity(0.2))
        .contentShape(Rectangle())
    }
}

/// OldOS `rating_view`. Third-party apps cannot write ratings to the library,
/// so — as in the original — the stars are interactive but not saved.
struct MusicRatingStrip: View {
    @Binding var rating: Int

    var body: some View {
        HStack(spacing: 0) {
            ForEach(1..<6, id: \.self) { number in
                let filled = number <= rating
                Image(filled ? "star_filled" : "star_empty")
                    .resizable()
                    .scaledToFit()
                    .frame(width: filled ? 20 : 6, height: filled ? 40 : 6)
                    .frame(width: 40, height: 40)
                    .contentShape(Rectangle())
                    .onTapGesture { rating = number }
            }
        }
    }
}

// MARK: - Footer

/// OldOS `now_playing_footer`: previous / play-pause / next and the volume
/// slider, extended down behind the home indicator.
struct MusicNowPlayingFooter: View {
    @EnvironmentObject private var navigator: MusicNavigator
    @EnvironmentObject private var library: MusicLibrary
    @ObservedObject private var player = MusicPlayer.shared
    @ObservedObject private var volume = MusicVolume.shared
    @ObservedObject private var airPlay = MusicAirPlay.shared
    let bottomInset: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                Spacer()
                // Long press: Recently Played drop-down (OldSafari Back history).
                MusicTransportButton(image: "prevtrack", width: 31, height: 23) {
                    player.previous()
                } onLongPress: {
                    navigator.presentPanel(MusicPanels.recentlyPlayed(
                        navigator: navigator, library: library, anchor: 0.25, edge: .bottom, inset: bottomInset + 110
                    ))
                }
                Spacer()
                Button {
                    player.togglePlayPause()
                } label: {
                    Image(player.isPlaying ? "pause" : "play").resizable().scaledToFit().frame(width: 30, height: 26)
                }
                .buttonStyle(.plain)
                Spacer()
                // Long press: Up Next drop-down (OldSafari Forward history).
                MusicTransportButton(image: "nexttrack", width: 31, height: 23) {
                    player.next()
                } onLongPress: {
                    navigator.presentPanel(MusicPanels.upNext(
                        navigator: navigator, anchor: 0.75, edge: .bottom, inset: bottomInset + 110
                    ))
                }
                Spacer()
            }
            .frame(height: 55)

            // iOS 6: the AirPlay button sits right of the volume slider when
            // AirPlay devices are around.
            HStack(spacing: 8) {
                OldMusicSlider(
                    value: $volume.level,
                    onChanged: { volume.set($0) },
                    onEnded: { volume.set($0) }
                ) { parts in
                    OldMusicSliderSkin(parts: parts, barHeight: 8.5)
                }
                .frame(height: 25)
                if airPlay.routesAvailable {
                    MusicAirPlayButton()
                }
            }
            .padding(.leading, 30)
            .padding(.trailing, airPlay.routesAvailable ? 14 : 30)
            .padding(.top, 5)
            .onAppear { airPlay.startWatching() }
            .onDisappear { airPlay.stopWatching() }

            Spacer(minLength: 0)
        }
        .frame(height: 110)
        .padding(.bottom, bottomInset)
        .background(
            VStack(spacing: 0) {
                LinearGradient(oldOS: [
                    Color.oldOS(71, 70, 70).opacity(0.825),
                    Color.oldOS(16, 15, 15).opacity(0.875)
                ])
                .frame(height: 55)
                .oldOSInnerShadowBottom(color: Color.white.opacity(0.6), radius: 0.05)
                Color.oldOS(7.5, 7.5, 7.5).opacity(0.97)
            }
        )
        .oldOSBorder(width: 1, edges: [.top], color: .black)
    }
}

// MARK: - Lyrics, speed, pressed artwork

/// Lyrics panel shown under the scrubber (iOS 6 Now Playing).
struct MusicLyricsView: View {
    let lyrics: String

    var body: some View {
        ScrollView(showsIndicators: true) {
            Text(lyrics)
                .font(OldOSFont.bold(15))
                .foregroundColor(.white)
                .shadow(color: Color.black.opacity(0.8), radius: 0, x: 0, y: -1)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
        }
        .background(Color.black.opacity(0.62))
    }
}

/// The iOS 6 "1×" speed pill for spoken content.
struct MusicSpeedBadge: View {
    let rate: Float

    private var label: String {
        switch rate {
        case 2: return "2×"
        case 0.5: return "½×"
        default: return "1×"
        }
    }

    var body: some View {
        Text(label)
            .font(OldOSFont.bold(14))
            .foregroundColor(.white)
            .shadow(color: Color.black.opacity(0.75), radius: 0, x: 0, y: -1)
            .frame(width: 40, height: 24)
            .oldOSInnerShadowBackground(
                RoundedRectangle(cornerRadius: 5.5),
                oldOSButtonGradient(.black),
                radius: 0.8,
                offset: CGPoint(x: 0, y: 0.6),
                intensity: 0.7
            )
            .overlay(RoundedRectangle(cornerRadius: 5.5).stroke(Color.white.opacity(0.25), lineWidth: 0.5))
    }
}

/// Swaps an artwork button to its "_pressed" asset while touched (OldOS atom).
struct MusicPressedImageStyle: ButtonStyle {
    let pressedImage: String

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            configuration.label.opacity(configuration.isPressed ? 0 : 1)
            if configuration.isPressed {
                Image(pressedImage)
            }
        }
    }
}

/// Transport artwork button with an optional long press (OldSafari
/// `OldOSToolBarButton` behaviour: the long press swallows the tap).
struct MusicTransportButton: View {
    let image: String
    let width: CGFloat
    let height: CGFloat
    let action: () -> Void
    var onLongPress: (() -> Void)? = nil

    @State private var didLongPress = false

    var body: some View {
        Button {
            if didLongPress {
                didLongPress = false
                return
            }
            OldMusicHaptics.tap()
            action()
        } label: {
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(width: width, height: height)
                .frame(width: width + 24, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.38).onEnded { _ in
                guard let onLongPress else { return }
                didLongPress = true
                OldMusicHaptics.press()
                onLongPress()
            }
        )
    }
}
