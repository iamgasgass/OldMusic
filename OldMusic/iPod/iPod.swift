//
//  iPod.swift
//  OldOS → OldMusic
//
//  Created by Zane Kleinberg on 2/2/21.
//  Standalone port: every view of the original iPod app is kept (same names, same
//  gradients, same metrics). Fixes are marked with "OldMusic fix".
//

import SwiftUI
import MediaPlayer
import AVKit
import PureSwiftUITools

// MARK: - Main Views
let alphabet = ["Search", "A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z", "#"]
struct iPod: View {
    @EnvironmentObject var MusicObserver: MusicObserver
    @State var current_nav_view: String = "Main"
    @State var prior_nav_view_coverflow: String = "Main"
    @State var did_utilize_coverflow: Bool = false
    @State var selectedPage = 1
    @State var forward_or_backward = false
    @State var selectedTab = "Playlists"
    @State var view_height: CGFloat = 0
    @State var current_album: MPMediaItemCollection = MPMediaItemCollection.init(items: [])
    @State var albums: [MPMediaItemCollection] = [MPMediaItemCollection]()
    @State var artists_current_view: String = "Artists"
    @State var current_artist: String = ""
    @State var playlist_current_nav_view: String = "Playlists"
    @State var pre_nav_switch: String = "Main"
    @State var playlist: MPMediaItemCollection = MPMediaItemCollection.init(items: [])
    @State var more_stack: [ipod_more_route] = [] //OldMusic: the More tab is now fully navigable
    @State var coverflow_orientation: UIDeviceOrientation = .landscapeLeft
    let rotation_publisher = NotificationCenter.default
        .publisher(for: UIDevice.orientationDidChangeNotification).makeConnectable()
        .autoconnect()
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                //OldMusic fix: full-screen devices — paint the area behind the notch / Dynamic Island
                //with the color of the status bar that is drawn right below it.
                VStack(spacing: 0) {
                    (current_nav_view == "Main" ? Color(red: 237/255, green: 244/255, blue: 247/255) : Color.black)
                        .frame(height: 24)
                        .ignoresSafeArea(.container, edges: .top)
                    Spacer(minLength: 0)
                }.allowsHitTesting(false)
                VStack(spacing:0) {
                    switch current_nav_view {
                    case "Main":
                        status_bar_in_app(selected_page:selectedPage).frame(minHeight: 24, maxHeight:24).zIndex(1)
                        ipod_title_bar(forward_or_backward: $forward_or_backward, current_nav_view: $current_nav_view, artists_current_view: $artists_current_view, playlist_current_nav_view: $playlist_current_nav_view, selectedTab: $selectedTab, more_stack: $more_stack, back_artist_title: current_artist, title: main_title()).frame(height: 60).if(pre_nav_switch == "Coverflow") {
                            $0.transition(.opacity)
                        }.transition(AnyTransition.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)).combined(with: .opacity))
                        iPodTabView(selectedTab: $selectedTab, current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, artists_current_view: $artists_current_view, current_album: $current_album, current_artist: $current_artist, albums: $albums, playlist: $playlist, playlist_current_nav_view: $playlist_current_nav_view, more_stack: $more_stack).clipped().if(pre_nav_switch == "Coverflow") {
                            $0.transition(.opacity)
                        }.transition(AnyTransition.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                    case "Now Playing":
                        status_bar().frame(minHeight: 24, maxHeight:24).zIndex(1)
                        iPodNowPlaying(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, view_height: $view_height).clipped().if(pre_nav_switch == "Coverflow") {
                            $0.transition(.opacity)
                        }.transition(AnyTransition.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
                    case "Coverflow":
                        CoverFlowView(orientation: coverflow_orientation).transition(.opacity)
                    default:
                        status_bar_in_app(selected_page:selectedPage).frame(minHeight: 24, maxHeight:24).zIndex(1)
                        ipod_title_bar(forward_or_backward: $forward_or_backward, current_nav_view: $current_nav_view, artists_current_view: $artists_current_view, playlist_current_nav_view: $playlist_current_nav_view, selectedTab: $selectedTab, more_stack: $more_stack, back_artist_title: current_artist, title:selectedTab).frame(height: 60)
                        iPodTabView(selectedTab: $selectedTab, current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, artists_current_view: $artists_current_view, current_album: $current_album, current_artist: $current_artist, albums: $albums, playlist: $playlist, playlist_current_nav_view: $playlist_current_nav_view, more_stack: $more_stack).clipped().transition(.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal:  .move(edge:forward_or_backward == false ? .leading : .trailing)))
                    }
                }.clipped()
            }.onAppear() {
                view_height = geometry.size.height
                UIScrollView.appearance().bounces = true
                UITableView.appearance().backgroundColor = .clear
                UITableView.appearance().showsVerticalScrollIndicator = false
                UIDevice.current.beginGeneratingDeviceOrientationNotifications()
            }.onDisappear() {
                UIScrollView.appearance().bounces = false
                UITableView.appearance().showsVerticalScrollIndicator = true
            }.onReceive(rotation_publisher) { _ in
                let orientation = UIDevice.current.orientation
                if orientation.isPortrait {
                    if did_utilize_coverflow, current_nav_view == "Coverflow" {
                        withAnimation() {
                            current_nav_view = prior_nav_view_coverflow
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.36) {
                            pre_nav_switch = prior_nav_view_coverflow
                        }
                    }
                }
                else if orientation.isLandscape {
                    coverflow_orientation = orientation
                    if current_nav_view == "Coverflow" {
                        return //OldMusic fix: landscapeLeft <-> landscapeRight just re-orients Cover Flow
                    }
                    hideKeyboard()
                    if current_nav_view == "Now Playing" || current_nav_view == "Main" {
                        did_utilize_coverflow = true
                        prior_nav_view_coverflow = current_nav_view
                    }
                    pre_nav_switch = "Coverflow"
                    if pre_nav_switch == "Coverflow" {
                        withAnimation {
                            current_nav_view = "Coverflow"
                        }
                    }
                }
            }
        }.environment(\.ipodActions, iPodActions(openArtist: { artist in
            self.open_artist(artist)
        }, openAlbum: { album in
            self.open_album(album)
        }, showNowPlaying: {
            self.show_now_playing()
        }))
    }

    //OldMusic: title of the blue navigation bar
    func main_title() -> String {
        switch selectedTab {
        case "Artists":
            if artists_current_view == "Artists" {
                return selectedTab
            }
            if artists_current_view == "Artist_Album_Songs" {
                return current_album.representativeItem?.albumTitle ?? current_artist
            }
            return current_artist
        case "Playlists":
            return playlist_current_nav_view != "Playlists" ? (playlist.value(forProperty: MPMediaPlaylistPropertyName) as? String ?? "---") : selectedTab
        case "More":
            return more_stack.last?.title ?? selectedTab
        default:
            return selectedTab
        }
    }

    //OldMusic fix: artists in the search results were not tappable.
    func open_artist(_ artist: MPMediaItemCollection) {
        hideKeyboard()
        let artist_albums = MusicObserver.albums(for: artist)
        guard artist_albums.count != 0 else { return }
        albums = artist_albums
        current_artist = artist.representativeItem?.artist ?? ""
        playlist_current_nav_view = "Playlists"
        more_stack = []
        forward_or_backward = false
        withAnimation(.linear(duration: 0.28)) {
            selectedTab = "Artists"
            artists_current_view = "Artist_Albums"
        }
    }

    func open_album(_ album: MPMediaItemCollection) {
        hideKeyboard()
        albums = MusicObserver.albums(forArtistOf: album.representativeItem)
        if albums.isEmpty {
            albums = [album]
        }
        current_artist = album.representativeItem?.artist ?? ""
        current_album = album
        playlist_current_nav_view = "Playlists"
        more_stack = []
        forward_or_backward = false
        withAnimation(.linear(duration: 0.28)) {
            selectedTab = "Artists"
            artists_current_view = "Artist_Album_Songs"
        }
    }

    func show_now_playing() {
        hideKeyboard()
        forward_or_backward = false
        withAnimation(.linear(duration: 0.28)) {
            current_nav_view = "Now Playing"
        }
    }
}

var tabs = ["Playlists", "Artists", "Songs", "Videos", "More"]
struct iPodTabView : View {

    @Binding var selectedTab:String
    @State var edge = UIApplication.shared.windows.first?.safeAreaInsets
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    @Binding var artists_current_view: String
    @Binding var current_album: MPMediaItemCollection
    @Binding var current_artist: String
    @Binding var albums: [MPMediaItemCollection]
    @Binding var playlist: MPMediaItemCollection
    @Binding var playlist_current_nav_view: String
    @Binding var more_stack: [ipod_more_route]
    var body: some View{
        GeometryReader {geometry in
            VStack(spacing:0) {

                ScrollView([], showsIndicators: false) {

                    switch selectedTab {
                    case "Playlists":
                        ipod_playlists(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, playlist: $playlist, playlist_current_nav_view: $playlist_current_nav_view).frame(height: geometry.size.height - 57)
                            .tag("Playlists")
                    case "Artists":
                        ipod_artists(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, artists_current_view: $artists_current_view, albums: $albums, current_album: $current_album, current_artist: $current_artist).frame(height: geometry.size.height - 57)
                            .tag("Artists")
                    case "Songs":
                        ipod_songs(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward).frame(height: geometry.size.height - 57)
                            .tag("Songs")
                    case "Videos":
                        ipod_videos(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward).frame(height: geometry.size.height - 57)
                            .tag("Videos")
                    case "More":
                        ipod_more(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, more_stack: $more_stack).frame(height: geometry.size.height - 57).tag("More")
                    default:
                        ipod_playlists(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, playlist: $playlist, playlist_current_nav_view: $playlist_current_nav_view).frame(height: geometry.size.height - 57)
                            .tag("Playlists")
                    }
                }.background(LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 227/255, green: 231/255, blue: 236/255), location: 0), .init(color: Color(red: 227/255, green: 231/255, blue: 236/255), location: 0.5), .init(color: Color.white, location: 0.5), .init(color: Color.white, location: 1)]), startPoint: .top, endPoint: .bottom))
                // for bottom overflow...
                ZStack {
                    Rectangle().fill(LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 0, green: 0, blue: 0), location: 0), .init(color: Color(red: 84/255, green: 84/255, blue: 84/255), location: 0.02), .init(color: Color(red: 59/255, green: 59/255, blue: 59/255), location: 0.04), .init(color: Color(red: 29/255, green: 29/255, blue: 29/255), location: 0.5), .init(color: Color(red: 7.5/255, green: 7.5/255, blue: 7.5/255), location: 0.51), .init(color: Color(red: 7.5/255, green: 7.5/255, blue: 7.5/255), location: 1)]), startPoint: .top, endPoint: .bottom)).frame(height:57)
                    HStack(spacing: 0){

                        ForEach(tabs,id: \.self){image in
                            TabButton(image: image, selectedTab: $selectedTab, artists_current_view:$artists_current_view, playlist_current_nav_view: $playlist_current_nav_view, more_stack: $more_stack, geometry: geometry)

                            // equal spacing...

                            if image != tabs.last{

                                Spacer(minLength: 0)
                            }
                        }
                    }.frame(height:55)
                }.padding(.bottom, 0)
            }
        }
    }

}




struct FlippedUpsideDown: ViewModifier {
    func body(content: Content) -> some View {
        content
            .rotationEffect(Angle(degrees: 180))
            .scaleEffect(x: -1, y: 1, anchor: .center)
    }
}
extension View{
    func flippedUpsideDown() -> some View{
        self.modifier(FlippedUpsideDown())
    }
}


// MARK: - Now Playing
struct iPodNowPlaying: View {
    @State var edge = UIApplication.shared.windows.first?.safeAreaInsets
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    @Binding var view_height: CGFloat
    @State var album_artwork: UIImage = UIImage()
    @State var proxy_width: CGFloat = 0.0
    @State var proxy_height: CGFloat = 0.0
    @State var is_playing: MPMusicPlaybackState?
    @State var artist: String?
    @State var song: String?
    @State var album: String?
    @State var album_tracks = [MPMediaItem]()
    @State var switch_to_tracks: Bool = false
    @State var show_back_tracks: Bool = false
    @State var hide_album_image: Bool = false
    @State var playback_time: CGFloat = 0.0
    @State var show_timing_controls: Bool = true
    @State var flipper_background: Bool = false
    let song_publisher = NotificationCenter.default
        .publisher(for: .MPMusicPlayerControllerNowPlayingItemDidChange)
    let media_publisher = NotificationCenter.default
        .publisher(for: .MPMusicPlayerControllerPlaybackStateDidChange) //MPMusicPlayerControllerPlaybackStateDidChange
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            GeometryReader {geometry in
                //OldMusic fix (full screen): like the iPhone 5 on iOS 6 the artwork is a square at the top
                //and its reflection fills the remaining space above the controls.
                let available_height = max(0, geometry.size.height - 60 - 110)
                let art_height = min(geometry.size.width, available_height)
                VStack(spacing:0) {
                    now_playing_title_bar(forward_or_backward: $forward_or_backward, current_nav_view: $current_nav_view, artist: $artist, song: $song, album: $album, album_image: $album_artwork, switch_to_tracks: $switch_to_tracks, show_back_tracks: $show_back_tracks, hide_album_image: $hide_album_image, flipper_background: $flipper_background, title: "").frame(height: 60)
                    ZStack(alignment: .top) {
                        ZStack {
                            Image("NowPlayingTableBackground").resizable().scaledToFill().frame(width:geometry.size.width, height: available_height).clipped().rotation3DEffect(.degrees(show_back_tracks == false ? 90 : 0), axis: (x: 0, y:1, z: 0), anchor: UnitPoint(0, 0.5)).offset(x:show_back_tracks == false ? geometry.size.width/2 : 0).opacity(show_back_tracks == false ? 0.5: 1)
                            now_playing_tracks(tracks: $album_tracks, switch_to_tracks: $switch_to_tracks, show_back_tracks: $show_back_tracks, hide_album_image: $hide_album_image, flipper_background: $flipper_background).frame(width:geometry.size.width, height: available_height).rotation3DEffect(.degrees(show_back_tracks == false ? 90 : 0), axis: (x: 0, y:1, z: 0), anchor: UnitPoint(0, 0.5)).offset(x:show_back_tracks == false ? geometry.size.width/2 : 0).border_top(width: 1, edges: [.top], color: Color(red: 53/255, green: 53/255, blue: 53/255)).opacity(show_back_tracks == false ? 0.5: 1)
                        }.frame(width:geometry.size.width, height: available_height)
                        Image(uiImage: album_artwork).resizable().scaledToFill().frame(width:geometry.size.width, height: art_height).clipped().contentShape(Rectangle()).overlay(
                            GeometryReader { proxy in
                                Color.clear.hidden().onAppear() {
                                    proxy_width = proxy.size.width
                                    proxy_height = proxy.size.height
                                }.onChange(of: proxy.size) { size in
                                    proxy_width = size.width
                                    proxy_height = size.height
                                }
                            }
                        ).border_top(width: 1, edges: [.top], color: Color(red: 53/255, green: 53/255, blue: 53/255)).gesture(TapGesture(count: 2).onEnded({withAnimation(.easeIn(duration: 0.4)){switch_to_tracks.toggle();flipper_background.toggle()}
                                                                                                                                                            DispatchQueue.main.asyncAfter(deadline:.now()+0.39) { //maybe 0.45
                                                                                                                                                                withAnimation(.easeOut(duration: 0.4)){show_back_tracks.toggle()}
                                                                                                                                                            }
                                                                                                                                                            DispatchQueue.main.asyncAfter(deadline:.now()+0.8) {
                                                                                                                                                                hide_album_image = true
                                                                                                                                                            }}).exclusively(before: TapGesture(count: 1).onEnded({DispatchQueue.main.asyncAfter(deadline:.now() + 0.25) {self.show_timing_controls.toggle()}}))).overlay(
                                                                                                                                                                ZStack(alignment: .top) {
                                                                                                                                                                    Image(uiImage: album_artwork.withHorizontallyFlippedOrientation()).resizable().scaledToFill().frame(width:proxy_width, height: proxy_height).clipped().rotationEffect(.degrees(-180)).offset(y:proxy_height).opacity(switch_to_tracks == true ? 0.25 : 0.8).allowsHitTesting(false)
                                                                                                                                                                    LinearGradient(gradient:Gradient(stops: [.init(color: Color(red: 10/255, green: 10/255, blue: 10/255).opacity(0.0), location:0), .init(color: Color(red: 0/255, green: 0/255, blue: 0/255).opacity(1.0), location: 0.28), .init(color: Color(red: 0/255, green: 0/255, blue: 0/255).opacity(1.0), location:1)]), startPoint: .top, endPoint: .bottom).frame(minWidth: geometry.size.width, maxWidth:geometry.size.width, minHeight: proxy_height, maxHeight: proxy_height).clipped().offset(y:proxy_height).allowsHitTesting(false)
                                                                                                                                                                    VStack {
                                                                                                                                                                        now_playing_timing_controls().frame(width:proxy_width, height:90)
                                                                                                                                                                        Spacer()
                                                                                                                                                                    }.isHidden(show_timing_controls)
                                                                                                                                                                }

                                                                                                                                                            , alignment: .top).innerShadowBottomWithOffset(color: Color.black.opacity(0.9), radius: 0.0125, offset: proxy_height).rotation3DEffect(.degrees(switch_to_tracks == true ? -90 : 0), axis: (x: 0, y:1, z: 0), anchor: UnitPoint(1, 0.5)).offset(x:switch_to_tracks == true ? -geometry.size.width/2 : 0).isHidden(hide_album_image).opacity(switch_to_tracks == true ? 0.5: 1)

                    }.frame(width: geometry.size.width, height: available_height, alignment: .top).clipped()
                    now_playing_footer(is_playing: $is_playing).frame(minHeight: 110, maxHeight:110).clipped().zIndex(1)
                }
            }.onAppear() {
                load_now_playing(update_tracks_now: true)
                let music_player = MPMusicPlayerController.systemMusicPlayer
                is_playing = music_player.playbackState
            }  .onReceive(song_publisher) { (output) in
                load_now_playing(update_tracks_now: false)
            }  .onReceive(media_publisher) { (output) in
                let music_player = MPMusicPlayerController.systemMusicPlayer
                let play_status = music_player.playbackState
                is_playing = play_status

            }
        }.compositingGroup() //Compositing group fixes some of the animation issues
    }

    func load_now_playing(update_tracks_now: Bool) {
        let music_player = MPMusicPlayerController.systemMusicPlayer
        let current_song = music_player.nowPlayingItem
        let album_artwork_c = current_song?.artwork?.image(at: CGSize(width: 600, height: 600))
        album_artwork = album_artwork_c ?? UIImage(named:"noartplaceholder") ?? UIImage()
        artist = current_song?.artist
        song = current_song?.title
        album = current_song?.albumTitle
        //OldMusic fix: the original used MPMediaQuery.songs() which returns the album sorted by *title*.
        if update_tracks_now {
            album_tracks = ipod_album_tracks(for: current_song)
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now()+0.25) {
                let current = MPMusicPlayerController.systemMusicPlayer.nowPlayingItem
                let tracks = ipod_album_tracks(for: current)
                if tracks.map({ $0.persistentID }) != album_tracks.map({ $0.persistentID }) {
                    album_tracks = tracks
                }
            }
        }
    }
}

struct now_playing_timing_controls: View {
    @State var track_position: Double = 0
    @State var playback_remaining_duratation: Double?
    @State var playback_progress_duration: Double?
    @State var duration_full: Double?
    @State var should_update_from_timer: Bool? = true
    @State var shuffle: Bool?
    @State var repeat_mode: Int?
    let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    var body: some View {
        GeometryReader {geometry in
            ZStack {
                Color.black.opacity(0.5).frame(width: geometry.size.width, height:geometry.size.height).innerShadowBottomView(color: Color.white.opacity(0.6), radius: 0.0275).border_bottom(width: 1, edges:[.bottom], color: Color.black)
                VStack {
                    HStack {
                        Text(formatTimeFor(seconds: playback_progress_duration ?? 0)).font(.custom("Helvetica Neue Bold", fixedSize: 14)).foregroundColor(.white).lineLimit(1).shadow(color: Color.black.opacity(0.21), radius: 0, x: 0.0, y: -1).padding(.leading, 15)
                        CustomSlider(type: "Song", should_update_from_timer: $should_update_from_timer, duration: $duration_full, value: $track_position,  range: (0, 100)) { modifiers in
                            ZStack {

                                LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 205/255, green: 220/255, blue: 241/255), location: 0), .init(color: Color(red: 125/255, green: 174/255, blue: 245/255), location: 0.5), .init(color: Color(red: 45/255, green: 111/255, blue: 198/255), location: 0.5), .init(color: Color(red: 50/255, green: 151/255, blue: 236/255), location: 1)]), startPoint: .top, endPoint: .bottom).frame(height: 8).cornerRadius(4.25).padding(.leading, 4).modifier(modifiers.barLeft)

                                LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 218/255, green: 218/255, blue: 218/255), location: 0), .init(color: Color(red: 166/255, green: 166/255, blue: 166/255), location: 0.19), .init(color: Color(red: 204/255, green: 204/255, blue: 204/255), location: 0.5), .init(color: Color(red: 255/255, green: 255/255, blue: 255/255), location: 0.5), .init(color: Color(red: 255/255, green: 255/255, blue: 255/255), location: 1)]), startPoint: .top, endPoint: .bottom).frame(height: 8).cornerRadius(4.25).padding(.trailing, 4).modifier(modifiers.barRight)
                                ZStack {
                                    Image("volume-slider-fat-knob").resizable().scaledToFill()
                                }.modifier(modifiers.knob)
                            }
                        }.frame(height: 20)
                        Text("-\(formatTimeFor(seconds: playback_remaining_duratation ?? 0))").font(.custom("Helvetica Neue Bold", fixedSize: 14)).foregroundColor(.white).lineLimit(1).shadow(color: Color.black.opacity(0.75), radius: 0, x: 0.0, y: -1).padding(.trailing, 15)
                    }
                    HStack {
                        Button(action:{
                            let music_player = MPMusicPlayerController.systemMusicPlayer
                            //OldMusic fix: Off → Repeat All → Repeat One → Off (".default" counts as Off)
                            let current = ((repeat_mode ?? 1) == 0) ? 1 : (repeat_mode ?? 1)
                            repeat_mode = current == 1 ? 3 : (current == 3 ? 2 : 1)
                            music_player.repeatMode = MPMusicRepeatMode(rawValue: repeat_mode ?? 1) ?? MPMusicRepeatMode.none

                        }) {
                            Image((repeat_mode ?? 0) == 1 ? "repeat_off" : (repeat_mode ?? 0) == 2 ? "repeat_on_1" : (repeat_mode ?? 0) == 3 ? "repeat_on" : "repeat_off").animation(.none)
                        }.padding(.leading, 20)
                        Spacer()
                        Button(action:{}) {
                            Image("nowplaying_atom")
                        }
                        Spacer()
                        Button(action:{
                            shuffle = !(shuffle ?? false)
                            let music_player = MPMusicPlayerController.systemMusicPlayer
                            music_player.shuffleMode = (shuffle == true) ? .songs : .off

                        }) {
                            Image(shuffle == true ? "shuffle_on" : "shuffle_off")
                        }.padding(.trailing, 20)
                    }
                }
            }.frame(width: geometry.size.width, height:geometry.size.height).onReceive(timer) { _ in
                if should_update_from_timer == true {
                    refresh_from_player()
                }
            }.onAppear() {
                refresh_from_player()
            }.onChange(of: track_position) { _ in
                playback_progress_duration = track_position/100*(duration_full ?? 0)
                playback_remaining_duratation = max(0, (duration_full ?? 0) - (playback_progress_duration ?? 0))
            }
        }
    }

    //OldMusic fix: the original read the player and wrote @State from a background queue.
    func refresh_from_player() {
        let music_player = MPMusicPlayerController.systemMusicPlayer
        let current_song = music_player.nowPlayingItem
        let mode = music_player.shuffleMode
        shuffle = !(mode == .off || mode == .default)
        repeat_mode = music_player.repeatMode.rawValue
        let duration = current_song?.playbackDuration ?? 0
        let raw_time = music_player.currentPlaybackTime
        let time = raw_time.isFinite ? max(0, raw_time) : 0
        playback_progress_duration = time
        playback_remaining_duratation = max(0, duration - time)
        duration_full = duration
        track_position = duration > 0 ? min(100, time/duration*100) : 0
    }
}
struct now_playing_tracks: View {
    @Binding var tracks: [MPMediaItem]
    @State var new_track_delay: Bool = false
    @State var current_song: MPMediaItem?
    @State var current_track_rating: Int?
    @Binding var switch_to_tracks: Bool
    @Binding var show_back_tracks: Bool
    @Binding var hide_album_image: Bool
    @Binding var flipper_background: Bool
    let song_publisher = NotificationCenter.default
        .publisher(for: .MPMusicPlayerControllerNowPlayingItemDidChange)
    var body: some View {
        GeometryReader { geometry in
            let unique_tracks = removeDuplicates(tracks)
            VStack(spacing:0) {
                HStack {
                    rating_view(rating: $current_track_rating)
                }.background(LinearGradient(gradient:Gradient(stops: [.init(color: Color(red: 0/255, green: 0/255, blue: 0/255).opacity(1.0), location:0), .init(color: Color(red: 0/255, green: 0/255, blue: 0/255).opacity(1.0), location: 0.35), .init(color: Color(red: 26/255, green: 26/255, blue: 26/255), location:1)]), startPoint: .top, endPoint: .bottom).frame(width: geometry.size.width, height:44)).frame(width: geometry.size.width, height:44)
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(unique_tracks.enumerated()), id: \.element.persistentID) { index, track in
                            Button(action:{
                                if new_track_delay == false {
                                    new_track_delay = true
                                    play_song(song: track, in: unique_tracks)
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    new_track_delay = false
                                }
                            }) {
                                VStack {
                                    if index == 0 {
                                        Rectangle().fill(Color(red: 65/255, green: 64/255, blue: 65/255)).frame(height:2)
                                    }
                                    Spacer()
                                    HStack {
                                        HStack {
                                            Text("\(String(track.albumTrackNumber)).").font(.custom("Helvetica Neue Bold", fixedSize: 14)).foregroundColor(.white).lineLimit(1).padding(.leading, 5).padding(.trailing, 5).multilineTextAlignment(.leading)
                                            Spacer()
                                        }.frame(width:60)
                                        Text(track.title ?? "---").font(.custom("Helvetica Neue Bold", fixedSize: 14)).foregroundColor(.white).lineLimit(1).padding(.leading, 14)
                                        Spacer()
                                        HStack {
                                            Spacer()
                                            Text(formatTimeFor(seconds: track.playbackDuration)).font(.custom("Helvetica Neue Bold", fixedSize: 14)).foregroundColor(.white).lineLimit(1).padding(.trailing, 5).padding(.leading, 5).multilineTextAlignment(.trailing)
                                        }.frame(width:60)
                                    }
                                    Spacer()
                                    Rectangle().fill(Color(red: 65/255, green: 64/255, blue: 65/255)).frame(height:2)
                                }.overlay(
                                    ZStack {
                                        HStack(alignment:.center) {
                                            Rectangle().fill(Color(red: 65/255, green: 64/255, blue: 65/255)).frame(width:2).padding(.leading, 65)
                                            Spacer()
                                        }
                                        HStack(alignment:.center) {
                                            Spacer()
                                            Rectangle().fill(Color(red: 65/255, green: 64/255, blue: 65/255)).frame(width:2).padding(.trailing, 65)
                                        }
                                        if track.persistentID == current_song?.persistentID {
                                            HStack(alignment:.center) {
                                                Image("play").resizable().renderingMode(.template).scaledToFit().foregroundColor(Color(red: 54/255, green: 98/255, blue: 214/255)).frame(height:10).padding(.leading, 40)
                                                Spacer()
                                            }
                                        }
                                    }

                                ).background(index % 2  == 0 ? Color.clear : Color.black.opacity(0.2))
                            }.frame(height: 44)
                        }
                    }.skeuomorphicStyleList()
                }.onReceive(song_publisher) { (output) in
                    let music_player = MPMusicPlayerController.systemMusicPlayer
                    let current = music_player.nowPlayingItem
                    current_song = current
                    let current_rating = current?.rating
                    current_track_rating = current_rating
                }.onAppear() {
                    let music_player = MPMusicPlayerController.systemMusicPlayer
                    let current = music_player.nowPlayingItem
                    current_song = current
                    let current_rating = current?.rating
                    current_track_rating = current_rating
                }.onChange(of: current_track_rating) { rating in
                    // Third-party apps cannot write ratings to the system library (same as the original: "Ratings paused for now").
                    print("Ratings paused for now")
                }
            }.simultaneousGesture(TapGesture(count: 2).onEnded({withAnimation(.easeIn(duration: 0.4)){show_back_tracks.toggle()}
                                                                DispatchQueue.main.asyncAfter(deadline:.now()) {
                                                                    hide_album_image = false
                                                                }
                                                                DispatchQueue.main.asyncAfter(deadline:.now()+0.39) { //maybe 0.45
                                                                    withAnimation(.easeOut(duration: 0.4)){switch_to_tracks.toggle()}
                                                                }
                                                                DispatchQueue.main.asyncAfter(deadline:.now()+0.48) {
                                                                    withAnimation(.easeIn(duration: 0.4)){flipper_background.toggle()}
                                                                }}))
        }
    }
}

//Thanks to HackingWithSwift for a convient way to do ratings — I use this in so many apps.

struct rating_view: View {
    @Binding var rating: Int?

    var label = ""

    var maximumRating = 5


    var body: some View {
        ForEach(1..<6) { number in
            ZStack {
                ZStack {
                    Image(number > (rating ?? 0) ? "star_empty" : "star_filled").resizable().scaledToFit().frame(width: number > (rating ?? 0) ? 6 : 20, height: number > (rating ?? 0) ? 6 : 40)
                }.frame(width:40, height: 40).contentShape(Rectangle())
                .onTapGesture {
                    self.rating = number
                }
            }
        }
    }
}

//OldMusic fix: no more Apple Music subscription gate, and the whole list is queued.
func play_song(song: MPMediaItem, in list: [MPMediaItem]? = nil) {
    let queue = (list?.isEmpty == false) ? (list ?? [song]) : [song]
    ipod_play(queue, start: song)
}


//OldMusic fix: de-duplicate by persistentID (the original removed every song sharing a *title*,
//so an album with two tracks named e.g. "Intro" lost one of them).
func removeDuplicates(_ arrayOfDicts: [MPMediaItem]) -> [MPMediaItem] {
    var removeDuplicates = [MPMediaItem]()
    var seen = Set<MPMediaEntityPersistentID>()
    for dict in arrayOfDicts {
        if !seen.contains(dict.persistentID) {
            removeDuplicates.append(dict)
            seen.insert(dict.persistentID)
        }
    }
    return removeDuplicates
}

func removeDuplicates_Collection(_ arrayOfDicts: [MPMediaItemCollection]) -> [MPMediaItemCollection] {
    var removeDuplicates = [MPMediaItemCollection]()
    var arrOfDict = [String]()
    for dict in arrayOfDicts {
        if let title = dict.representativeItem?.albumTitle, !arrOfDict.contains(title) {
            removeDuplicates.append(dict)
            arrOfDict.append(title)
        }
    }
    return removeDuplicates
}
func getHoursMinutesSecondsFrom(seconds raw: Double) -> (hours: Int, minutes: Int, seconds: Int) {
    let s: Double
    if raw.isFinite && raw >= 0 {
        s = raw
    } else {
        s = 0
    }
    let clamped = min(max(s, 0), Double(Int.max))
    let total = Int(clamped.rounded(.down))

    let hours = total / 3600
    let minutes = (total % 3600) / 60
    let seconds = total % 60
    return (hours, minutes, seconds)
}

func formatTimeFor(seconds: Double) -> String {
    let t = getHoursMinutesSecondsFrom(seconds: seconds)
    if t.hours > 0 {
        // Pad mm:ss when hours are present
        let mm = String(format: "%02d", t.minutes)
        let ss = String(format: "%02d", t.seconds)
        return "\(t.hours):\(mm):\(ss)"
    } else {
        // mm:ss
        let mm = String(t.minutes) // could also pad here if you prefer 0X for minutes < 10
        let ss = String(format: "%02d", t.seconds)
        return "\(mm):\(ss)"
    }
}
func formatTimeForMinutes(seconds raw: Double) -> String {
    guard raw.isFinite, raw >= 0 else { return "0" }

    let clamped = min(max(raw, 0), Double(Int.max))
    let total = Int(clamped.rounded(.down))

    let hours = total / 3600
    let minutes = (total % 3600) / 60
    let secs = total % 60

    if hours > 0 {
        let mm = String(format: "%02d", minutes)
        return "\(hours):\(mm)"
    } else {
        return "\(minutes + (secs >= 30 ? 1 : 0))"
    }
}


struct now_playing_footer: View {
    @StateObject private var volObserver = VolumeObserver()
    @Binding var is_playing: MPMusicPlaybackState?
    var body: some View {
        GeometryReader {geometry in
            ZStack {
                VStack(spacing:0) {
                    Rectangle().fill(LinearGradient(gradient: Gradient(colors: [Color.init(red: 71/255, green: 70/255, blue: 70/255).opacity(0.825), Color.init(red: 16/255, green: 15/255, blue: 15/255).opacity(0.875)]), startPoint: .top, endPoint: .bottom)).innerShadowBottom(color: Color.white.opacity(0.6), radius: 0.05).border_top(width: 1, edges:[.top], color: Color.black)
                    Rectangle().fill(Color(red: 7.5/255, green: 7.5/255, blue: 7.5/255).opacity(0.97))
                }
                VStack(spacing:0) {
                    HStack(alignment:.center) {
                        Spacer()
                        Button(action:{
                            let music_player = MPMusicPlayerController.systemMusicPlayer
                            if music_player.currentPlaybackTime < TimeInterval(5) {
                                music_player.skipToPreviousItem()
                            } else {
                                music_player.skipToBeginning()
                            }
                        }) {
                            Image("prevtrack").resizable().scaledToFit().frame(width:31, height: 23)
                        }
                        Spacer()
                        Button(action:{
                            let music_player = MPMusicPlayerController.systemMusicPlayer
                            if is_playing != .playing {
                                music_player.play()
                                is_playing = .playing
                            } else {
                                music_player.pause()
                                is_playing = .paused
                            }

                        }) {
                            Image(is_playing == .playing ? "pause" : "play").resizable().scaledToFit().frame(width:30, height: 26)
                        }
                        Spacer()
                        Button(action:{

                            let music_player = MPMusicPlayerController.systemMusicPlayer
                            music_player.skipToNextItem()

                        }) {
                            Image("nexttrack").resizable().scaledToFit().frame(width:31, height: 23)
                        }
                        Spacer()
                    }.frame(height:55)
                    Spacer().frame(height:5)
                    ZStack {
                        CustomSlider(type: "Volume", value: $volObserver.volume.double,  range: (0, 100)) { modifiers in
                            ZStack {

                                LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 205/255, green: 220/255, blue: 241/255), location: 0), .init(color: Color(red: 125/255, green: 174/255, blue: 245/255), location: 0.5), .init(color: Color(red: 45/255, green: 111/255, blue: 198/255), location: 0.5), .init(color: Color(red: 50/255, green: 151/255, blue: 236/255), location: 1)]), startPoint: .top, endPoint: .bottom).frame(height: 8.5).cornerRadius(4.25).padding(.leading, 4).modifier(modifiers.barLeft)

                                LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 218/255, green: 218/255, blue: 218/255), location: 0), .init(color: Color(red: 166/255, green: 166/255, blue: 166/255), location: 0.19), .init(color: Color(red: 204/255, green: 204/255, blue: 204/255), location: 0.5), .init(color: Color(red: 255/255, green: 255/255, blue: 255/255), location: 0.5), .init(color: Color(red: 255/255, green: 255/255, blue: 255/255), location: 1)]), startPoint: .top, endPoint: .bottom).frame(height: 8.5).cornerRadius(4.25).padding(.trailing, 4).modifier(modifiers.barRight)
                                ZStack {
                                    Image("volume-slider-fat-knob").resizable().scaledToFill()

                                }.modifier(modifiers.knob)
                            }
                        }.frame(height: 25).padding([.top, .bottom]).padding([.leading, .trailing], 30).padding(.bottom,15)
                    }.frame(height:50)
                }.frame(height:110)
            }
        }
    }
}

// MARK: - Shared search results (OldMusic: one implementation instead of five copies)

struct ipod_search_results: View {
    @Environment(\.ipodActions) var ipodActions
    @ObservedObject var MusicObserver: MusicObserver
    var search: String
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    var body: some View {
        let found_artists = MusicObserver.artists.filter { ($0.representativeItem?.artist ?? "").localizedCaseInsensitiveContains(search) }
        let found_albums = MusicObserver.ab.filter { ($0.representativeItem?.albumTitle ?? "").localizedCaseInsensitiveContains(search) }
        let found_songs = MusicObserver.songs.filter { ($0.title ?? "").localizedCaseInsensitiveContains(search) }
        List {
            if found_artists.count != 0 {
                Section(header: generic_text_list_header(letter: "Artists (\(found_artists.count) \(result_results_collection(found_artists)))").listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))) {
                    ForEach(found_artists, id: \.persistentID) { artist in
                        Button(action:{
                            ipodActions.openArtist(artist)
                        }) {
                            VStack(alignment: .leading, spacing: 0) {
                                HStack() {
                                    Image(uiImage: artist.representativeItem?.artwork?.image(at: CGSize(400, 400)) ?? UIImage(named:"noartplaceholder") ?? UIImage()).resizable().scaledToFill().frame(width: 60-0.95, height:60-0.95).clipped()
                                    Text(artist.representativeItem?.artist ?? "---").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(.black).lineLimit(1).padding(.leading, 6).padding(.trailing, 40)
                                    Spacer()
                                    Image("UITableNext").padding(.trailing, 12)
                                }
                                Rectangle().fill(Color(red: 224/255, green: 224/255, blue: 224/255)).frame(height:0.95).edgesIgnoringSafeArea(.all)

                            }
                        }
                    }.hideRowSeparator_larger().listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)).frame(height: 60).drawingGroup()
                }
            }
            if found_albums.count != 0 {
                Section(header: generic_text_list_header(letter: "Albums (\(found_albums.count) \(result_results_collection(found_albums)))").listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))) {
                    ForEach(found_albums, id: \.persistentID) { album in
                        Button(action:{
                            ipodActions.openAlbum(album)
                        }) {
                            VStack(alignment: .leading, spacing: 0) {
                                HStack() {
                                    Image(uiImage: album.representativeItem?.artwork?.image(at: CGSize(400, 400)) ?? UIImage(named:"noartplaceholder") ?? UIImage()).resizable().scaledToFill().frame(width: 60-0.95, height:60-0.95).clipped()
                                    VStack(alignment: .leading, spacing: 0) {
                                        Text(album.representativeItem?.albumTitle ?? "---").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(.black).lineLimit(1)
                                        Spacer().frame(height:1)
                                        Text(album.representativeItem?.albumArtist ?? album.representativeItem?.artist ?? "---")
                                            .font(.custom("Helvetica Neue Regular", fixedSize: 14)).foregroundColor(.cgLightGray).lineLimit(1)
                                    }.padding(.leading, 6).padding(.trailing, 40)
                                    Spacer()
                                    Image("UITableNext").padding(.trailing, 12)
                                }
                                Rectangle().fill(Color(red: 224/255, green: 224/255, blue: 224/255)).frame(height:0.95).edgesIgnoringSafeArea(.all)

                            }
                        }
                    }.hideRowSeparator_larger().listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)).frame(height: 60).drawingGroup()
                }
            }
            if found_songs.count != 0 {
                Section(header: generic_text_list_header(letter: "Songs (\(found_songs.count) \(result_results(found_songs)))").listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))) {
                    ForEach(found_songs, id: \.persistentID) { song in
                        Button(action:{
                            ipod_play(found_songs, start: song)
                            forward_or_backward = false; withAnimation(.linear(duration: 0.28)){current_nav_view = "Now Playing"}
                        }) {
                            VStack(alignment: .leading, spacing: 0) {
                                HStack() {
                                    Image(uiImage: song.artwork?.image(at: CGSize(400, 400)) ?? UIImage(named:"noartplaceholder") ?? UIImage()).resizable().scaledToFill().frame(width: 60-0.95, height:60-0.95).clipped()
                                    VStack(alignment: .leading, spacing: 0) {
                                        Text(song.title ?? "---").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(.black).lineLimit(1)
                                        Spacer().frame(height:1)
                                        Text("\(song.albumTitle ?? "---") - \(song.artist ?? "---")")
                                            .font(.custom("Helvetica Neue Regular", fixedSize: 14)).foregroundColor(.cgLightGray).lineLimit(1)
                                    }.padding(.leading, 6).padding(.trailing, 40)
                                    Spacer()
                                    Image("UITableNext").padding(.trailing, 12)
                                }
                                Rectangle().fill(Color(red: 224/255, green: 224/255, blue: 224/255)).frame(height:0.95).edgesIgnoringSafeArea(.all)

                            }
                        }
                    }.hideRowSeparator_larger().listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)).frame(height: 60).drawingGroup()
                }
            }
        }.skeuomorphicStyleList()
            .background(Color.white)
    }
}

/// The dimmed / white overlays shown while searching (identical in every list of the original).
struct ipod_search_overlay: View {
    @ObservedObject var MusicObserver: MusicObserver
    @Binding var editing_state: String
    var search: String
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    var body: some View {
        if editing_state == "Active_Empty" {
            Color.black.opacity(0.9).edgesIgnoringSafeArea(.all).offset(y: 44).onTapGesture {
                hideKeyboard()
            }
        }
        if editing_state == "Active" {
            Color.white.edgesIgnoringSafeArea(.all).offset(y: 44)
            ipod_search_results(MusicObserver: MusicObserver, search: search, current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward).padding(.top, 44)
        }
    }
}

// MARK: - Playlists

struct ipod_playlists: View {
    @EnvironmentObject var MusicObserver: MusicObserver
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    @Binding var playlist: MPMediaItemCollection
    @Binding var playlist_current_nav_view: String
    var body: some View {
        VStack(spacing:0) {
            switch playlist_current_nav_view {
            case "Playlists":
                SkeuomorphicList_Playlists(MusicObserver: MusicObserver, playlist: $playlist, forward_or_backward: $forward_or_backward, playlist_current_nav_view: $playlist_current_nav_view, current_nav_view: $current_nav_view).clipped().transition(AnyTransition.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
            case "Playlist_Desination":
                ipod_playlists_desination(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, playlist: $playlist).clipped().transition(AnyTransition.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
            default:
                SkeuomorphicList_Playlists(MusicObserver: MusicObserver, playlist: $playlist, forward_or_backward: $forward_or_backward, playlist_current_nav_view: $playlist_current_nav_view, current_nav_view: $current_nav_view).clipped().transition(AnyTransition.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
            }
        }.offset(y:-1.2)
    }
}

struct SkeuomorphicList_Playlists: View {
    @ObservedObject var MusicObserver: MusicObserver
    @Binding var playlist: MPMediaItemCollection
    @Binding var forward_or_backward: Bool
    @Binding var playlist_current_nav_view: String
    @Binding var current_nav_view: String
    @State var editing_state: String = "None"
    @State var search = ""
    var body: some View {
        ZStack(alignment: .top) {
            List {
                ipod_search(search: $search, no_right_padding: true, editing_state: $editing_state).id("Search").listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)).frame(height:44).hideRowSeparator()
                ForEach(MusicObserver.playists, id: \.persistentID) { playlist in
                    Button(action:{
                        self.playlist = playlist
                        if   self.playlist == playlist, playlist.items.count != 0 {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                forward_or_backward = false; withAnimation(.linear(duration: 0.28)){playlist_current_nav_view = "Playlist_Desination"}
                            }
                        }
                    }) {
                        VStack(alignment: .leading, spacing: 0) {
                            Spacer().frame(height:4.5)
                            HStack() {
                                Text(playlist.value(forProperty: MPMediaPlaylistPropertyName) as? String ?? "---").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(.black).lineLimit(1).padding(.leading, 11).padding(.trailing, 40)
                                Spacer()
                                Image("UITableNext").padding(.trailing, 12)
                            }
                            Spacer().frame(height:9.5)
                            Rectangle().fill(Color(red: 224/255, green: 224/255, blue: 224/255)).frame(height:0.95).edgesIgnoringSafeArea(.all)

                        }
                    }.padding(.top, playlist == MusicObserver.playists.first ? 2.5 : 0)
                }.hideRowSeparator().listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)).drawingGroup()
            }.skeuomorphicStyleList()
                .background(Color.white)
            ipod_search_overlay(MusicObserver: MusicObserver, editing_state: $editing_state, search: search, current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward)
        }
    }

}

func result_results(_ array: [MPMediaItem]) -> String {
    if array.count == 1 {
        return "Result"
    } else {
        return "Results"
    }
}

func result_results_collection(_ array: [MPMediaItemCollection]) -> String {
    if array.count == 1 {
        return "Result"
    } else {
        return "Results"
    }
}

struct ipod_playlists_desination: View {
    @EnvironmentObject var MusicObserver: MusicObserver
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    @Binding var playlist: MPMediaItemCollection
    var body: some View {
        VStack(spacing:0) {
            SkeuomorphicList_Playlists_Destination(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, playlist: $playlist, MusicObserver: MusicObserver)
        }.offset(y:-1.2)
    }
}

struct SkeuomorphicList_Playlists_Destination: View {
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    @Binding var playlist: MPMediaItemCollection
    @ObservedObject var MusicObserver: MusicObserver
    @ObservedObject var player = iPodPlayer.shared
    @State var editing_state: String = "None"
    @State var search = ""
    var body: some View {
        ZStack(alignment:.top) {
            List {
                ipod_search(search: $search, no_right_padding: true, editing_state:$editing_state).id("Search").listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)).frame(height:44).hideRowSeparator()
                VStack(spacing:0) {
                    HStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8).fill(LinearGradient(gradient: Gradient(colors: [Color(red: 229/255, green: 230/255, blue: 231/255), Color(red: 210/255, green: 210/255, blue: 213/255)]), startPoint: .top, endPoint: .bottom))
                            Text("Edit").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(Color(red: 51/255, green: 51/255, blue: 51/255)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9)
                        }.overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(red:154/255, green:154/255, blue:154/255), lineWidth: 1)
                        ).padding(.leading, 8).padding([.top], 8).padding(.bottom, 2)
                        ZStack {
                            RoundedRectangle(cornerRadius: 8).fill(LinearGradient(gradient: Gradient(colors: [Color(red: 229/255, green: 230/255, blue: 231/255), Color(red: 210/255, green: 210/255, blue: 213/255)]), startPoint: .top, endPoint: .bottom))
                            Text("Clear").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(Color(red: 51/255, green: 51/255, blue: 51/255)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9)
                        }.overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(red:154/255, green:154/255, blue:154/255), lineWidth: 1)
                        ).padding([.top], 8).padding(.bottom, 2)
                        ZStack {
                            RoundedRectangle(cornerRadius: 8).fill(LinearGradient(gradient: Gradient(colors: [Color(red: 229/255, green: 230/255, blue: 231/255), Color(red: 210/255, green: 210/255, blue: 213/255)]), startPoint: .top, endPoint: .bottom))
                            Text("Delete").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(Color(red: 51/255, green: 51/255, blue: 51/255)).shadow(color: Color.white.opacity(0.9), radius: 0, x: 0.0, y: 0.9)
                        }.overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(red:154/255, green:154/255, blue:154/255), lineWidth: 1)
                        ).padding(.trailing, 8).padding([.top], 8).padding(.bottom, 2)
                    }.offset(y:-2)
                    Rectangle().fill(Color(red: 224/255, green: 224/255, blue: 224/255)).frame(height:0.95).edgesIgnoringSafeArea(.all)
                }.listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)).frame(height:44).hideRowSeparator()
                Button(action:{
                    ipod_play(playlist.items, shuffle: true)
                    forward_or_backward = false; withAnimation(.linear(duration: 0.28)){current_nav_view = "Now Playing"}
                }) {
                    VStack(alignment: .leading, spacing: 0) {
                        Spacer().frame(height:4.5)
                        HStack() {

                            ZStack(alignment: .leading) {
                                HStack {
                                    Text("Shuffle").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(.black).lineLimit(1)
                                    Image("shuffle_icon")
                                }
                            }.padding(.leading, 11).padding(.trailing, 40)
                        }.frame(minHeight: 44-0.95-9, maxHeight:44-0.95-9)
                        Spacer().frame(height:4.5)
                        Rectangle().fill(Color(red: 224/255, green: 224/255, blue: 224/255)).frame(height:0.95).edgesIgnoringSafeArea(.all)
                    }
                }.frame(minHeight: 44, maxHeight:44).listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)).hideRowSeparator()
                ForEach(Array(playlist.items.enumerated()), id: \.offset) { index, song in
                    Button(action:{
                        ipod_play(playlist.items, start: song)
                        forward_or_backward = false; withAnimation(.linear(duration: 0.28)){current_nav_view = "Now Playing"}
                    }) {
                        VStack(alignment: .leading, spacing: 0) {
                            Spacer().frame(height:4.5)
                            HStack() {

                                VStack(alignment: .leading) {
                                    Text(song.title ?? "---").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(.black).lineLimit(1)
                                    Spacer().frame(height:1)
                                    Text("\(song.albumTitle ?? "---") - \(song.artist ?? "---")")
                                        .font(.custom("Helvetica Neue Regular", fixedSize: 14)).foregroundColor(.cgLightGray).lineLimit(1)
                                }.padding(.leading, 11)
                                if player.isNowPlaying(song) {
                                    Spacer()
                                    Image("NowPlayingListItemIcon")
                                }
                            }.padding(.trailing, 11)
                            Spacer().frame(height:4.5)
                            Rectangle().fill(Color(red: 224/255, green: 224/255, blue: 224/255)).frame(height:0.95).edgesIgnoringSafeArea(.all)
                        }

                    }.padding(.top, index == 0 ? 2.5 : 0)
                }.hideRowSeparator().listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)).drawingGroup()
            }.skeuomorphicStyleList()
                .background(Color.white)
            ipod_search_overlay(MusicObserver: MusicObserver, editing_state: $editing_state, search: search, current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward)

        }

    }
}

struct shuffle_bottom_divider: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height:4.5)
            HStack() {

                VStack(alignment: .leading) {
                    Spacer()
                    HStack {
                        Text("Shuffle").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(.black).lineLimit(1)
                        Image("shuffle_icon")
                    }
                    Spacer()
                }.padding(.leading, 11).padding(.trailing, 40)
            }
            Spacer().frame(height:4.5)
            Rectangle().fill(Color(red: 224/255, green: 224/255, blue: 224/255)).frame(height:0.95).edgesIgnoringSafeArea(.all)
        }.frame(maxHeight:44)
    }
}

extension Array where Element : Equatable {
    func wrap(around selectedElement: Element) -> Array<Element> {

        var oldArray = [Element]()
        var priorElements = [Element]()
        var newArray = [Element]()

        for element in self {
            if element == selectedElement || oldArray.count > 0 {
                oldArray.append(element)
            } else {
                priorElements.append(element)
            }
            newArray = oldArray + priorElements
        }
        return newArray
    }
}

// MARK: - Artists


struct ipod_artists: View {
    @EnvironmentObject var MusicObserver: MusicObserver
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    @Binding var artists_current_view: String
    @Binding var albums: [MPMediaItemCollection]
    @Binding var current_album: MPMediaItemCollection
    @Binding var current_artist: String
    @State var editing_state: String = "None"
    var body: some View {
        VStack(spacing:0) {
            switch artists_current_view {
            case "Artist_Albums":
                artists_destination(artists_current_view: $artists_current_view, current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, albums: $albums, current_album: $current_album).clipped().transition(AnyTransition.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
            case "Artist_Album_Songs":
                albums_destination(album: $current_album, current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward).clipped().transition(AnyTransition.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
            default:
                SkeuomorphicList_Artists(forward_or_backward: $forward_or_backward, artists_current_view: $artists_current_view, albums: $albums, current_artist: $current_artist, current_nav_view: $current_nav_view, editing_state: $editing_state, MusicObserver: MusicObserver, indexes: MusicObserver.artist_sections.map { $0.letter }).modifier(VerticalIndex(indexableList: alphabet, indexes: MusicObserver.artist_sections.map { $0.letter }, editing_state: $editing_state)).clipped().transition(AnyTransition.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
            }
        }.offset(y:-1.2).onChange(of: artists_current_view) { _ in
            editing_state = "None"
        }
    }
}

struct SkeuomorphicList_Artists: View {
    @Binding var forward_or_backward: Bool
    @Binding var artists_current_view: String
    @Binding var albums: [MPMediaItemCollection]
    @Binding var current_artist: String
    @Binding var current_nav_view: String
    @Binding var editing_state: String
    @ObservedObject var MusicObserver: MusicObserver
    var indexes: [String]
    @State var search = ""
    var body: some View {
        ZStack(alignment: .top) {
            List {
                Section(header: EmptyView().frame(height: 0), footer: EmptyView().frame(height: 0)) {
                    ipod_search(
                        search: $search,
                        no_right_padding: editing_state != "None",
                        editing_state: $editing_state
                    )
                    .id("Search")
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .padding(.top, 0)
                    .frame(height: 44)
                    .hideRowSeparator()


                } //Ok so this is a little bit of a whacky fix, but we need to suppress the pixelish of height added to the top of this
                ForEach(MusicObserver.artist_sections, id: \.letter) { section in
                    Section(header: alpha_list_header(letter: section.letter).id(section.letter) .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))) {
                        ForEach(section.items, id: \.persistentID) { artist in
                            Button(action:{
                                let artist_albums = MusicObserver.albums(for: artist)
                                albums = artist_albums
                                current_artist = artist.representativeItem?.artist ?? ""
                                if albums.count != 0, current_artist == artist.representativeItem?.artist ?? "" {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                        forward_or_backward = false; withAnimation(.linear(duration: 0.28)){artists_current_view = "Artist_Albums"}
                                    }
                                }
                            }) {
                                VStack(alignment: .leading, spacing: 0) {
                                    Spacer()
                                    HStack() {
                                        Text(artist.representativeItem?.artist ?? "").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(.black).lineLimit(1).padding(.leading, 11).padding(.trailing, 40)
                                        Spacer()
                                    }
                                    Spacer().frame(height:9.5)
                                    Rectangle().fill(Color(red: 224/255, green: 224/255, blue: 224/255)).frame(height:0.95).edgesIgnoringSafeArea(.all)
                                }
                            }
                        }.hideRowSeparator()
                    }
                }.listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)).drawingGroup()
                HStack {
                    Spacer()
                    Text("\(MusicObserver.artists.count) Artists").font(.custom("Helvetica Neue Regular", fixedSize: 20)).foregroundColor(.cgLightGray).lineLimit(1)
                    Spacer()
                }.hideRowSeparator().listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            }.skeuomorphicStyleList()
            ipod_search_overlay(MusicObserver: MusicObserver, editing_state: $editing_state, search: search, current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward)

        }

    }
}



struct artists_destination: View {
    @EnvironmentObject var MusicObserver: MusicObserver
    @Binding var artists_current_view: String
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    @Binding var albums: [MPMediaItemCollection]
    @Binding var current_album: MPMediaItemCollection
    var body: some View {
        VStack(spacing:0) {
            SkeuomorphicList_Artists_Destination(albums: albums, current_album: $current_album, forward_or_backward: $forward_or_backward, artists_current_view: $artists_current_view, current_nav_view: $current_nav_view, MusicObserver: MusicObserver)
        }
    }
}

struct SkeuomorphicList_Artists_Destination: View {
    var albums: [MPMediaItemCollection]
    @Binding var current_album: MPMediaItemCollection
    @Binding var forward_or_backward: Bool
    @Binding var artists_current_view: String
    @Binding var current_nav_view: String
    @ObservedObject var MusicObserver: MusicObserver
    @State var editing_state: String = "None"
    @State var search = ""
    var body: some View {
        ZStack(alignment: .top) {
            List {
                ipod_search(search: $search, no_right_padding: true, editing_state:$editing_state).id("Search").listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)).frame(height:44).hideRowSeparator()
                ForEach(albums, id: \.persistentID) { album in
                    Button(action:{
                        current_album = album
                        DispatchQueue.main.asyncAfter(deadline: .now()+0.25) {
                            forward_or_backward = false; withAnimation(.linear(duration: 0.28)){artists_current_view = "Artist_Album_Songs"}
                        }
                    }) {
                        VStack(alignment: .leading, spacing: 0) {
                            //Spacer().frame(height:4.5)
                            HStack() {
                                Image(uiImage: album.representativeItem?.artwork?.image(at: CGSize(400, 400)) ?? UIImage(named:"noartplaceholder") ?? UIImage()).resizable().scaledToFill().frame(width: 60-0.95, height:60-0.95).clipped()
                                Text(album.representativeItem?.albumTitle ?? "---").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(.black).lineLimit(1).padding(.leading, 6).padding(.trailing, 40)
                                Spacer()
                                Image("UITableNext").padding(.trailing, 12)
                            }
                            //  Spacer().frame(height:9.5)
                            Rectangle().fill(Color(red: 224/255, green: 224/255, blue: 224/255)).frame(height:0.95).edgesIgnoringSafeArea(.all)

                        }
                    }//.padding(.top, album == albums.first ? 2.5 : 0)
                }.hideRowSeparator_larger().listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)).frame(height: 60).drawingGroup()
            }.skeuomorphicStyleList()
                .background(Color.white)
            ipod_search_overlay(MusicObserver: MusicObserver, editing_state: $editing_state, search: search, current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward)

        }
    }
}


struct albums_destination: View {
    @Binding var album: MPMediaItemCollection
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    @ObservedObject var player = iPodPlayer.shared
    var body: some View {
        GeometryReader { geometry in
            //OldMusic fix: tracks in disc/track order, unique by persistentID, whole album queued on tap.
            let tracks = removeDuplicates(ipod_sorted_album_tracks(album.items))
            let artwork = album.representativeItem?.artwork?.image(at: CGSize(width: 400, height: 400)) ?? UIImage(named:"noartplaceholder") ?? UIImage()
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0) {

                    HStack() {
                        ZStack(alignment: .top) {
                            Image(uiImage: artwork).resizable().scaledToFill().frame(width: 100, height: 100).clipped()
                            Image(uiImage: artwork.withHorizontallyFlippedOrientation()).resizable().scaledToFill().frame(width:100, height: 100).clipped().rotationEffect(.degrees(-180)).offset(y:100).opacity(0.15)
                        }.frame(height: 120).clipped().padding(.leading, 6)
                        VStack(alignment:.leading) {
                            Text(album.representativeItem?.albumArtist ?? album.representativeItem?.artist ?? "").font(.custom("Helvetica Neue Bold", fixedSize: 16)).foregroundColor(.black).lineLimit(1).multilineTextAlignment(.leading)
                            Text(album.representativeItem?.albumTitle ?? "").font(.custom("Helvetica Neue Bold", fixedSize: 20)).foregroundColor(.black).lineLimit(1).multilineTextAlignment(.leading)
                            Text("Released \(release_year())").font(.custom("Helvetica Neue Bold", fixedSize: 10)).foregroundColor(Color(red: 128/255, green: 128/255, blue: 128/255)).lineLimit(1).multilineTextAlignment(.leading).isHidden(release_year() == "")
                            Text("\(tracks.count) \(tracks.count == 1 ? "Song" : "Songs"), \(formatTimeForMinutes(seconds: tracks.reduce(0) { $0 + $1.playbackDuration })) Mins.").font(.custom("Helvetica Neue Bold", fixedSize: 10)).foregroundColor(Color(red: 128/255, green: 128/255, blue: 128/255)).lineLimit(1).multilineTextAlignment(.leading)
                            Spacer()
                        }.padding(.top, 10)
                        Spacer()
                    }.background(LinearGradient(gradient: Gradient(colors: [Color(red: 248/255, green: 248/255, blue: 248/255), Color(red: 236/255, green: 236/255, blue: 236/255)]), startPoint: .top, endPoint: .bottom)).frame(height:120).padding(.bottom, 0)

                    ForEach(Array(tracks.enumerated()), id: \.element.persistentID) { index, track in
                        Button(action:{
                            ipod_play(tracks, start: track)
                            forward_or_backward = false; withAnimation(.linear(duration: 0.28)){current_nav_view = "Now Playing"}
                        }) {
                            VStack {
                                if index == 0 {
                                    Rectangle().fill(Color(red: 228/255, green: 228/255, blue: 228/255)).frame(height:2)
                                }
                                Spacer()
                                HStack {
                                    HStack {
                                        Spacer()
                                        Text("\(String(track.albumTrackNumber == 0 ? index + 1 : track.albumTrackNumber))").font(.custom("Helvetica Neue Bold", fixedSize: 16)).foregroundColor(.black).lineLimit(1).multilineTextAlignment(.leading)
                                        Spacer()
                                    }.frame(width:40)
                                    Text(track.title ?? "---").font(.custom("Helvetica Neue Bold", fixedSize: 16)).foregroundColor(.black).lineLimit(1).padding(.leading, 14)
                                    Spacer()
                                    if player.isNowPlaying(track) {
                                        Image("NowPlayingListItemIcon").padding(.trailing, 5)
                                    }
                                    HStack {
                                        Text(formatTimeFor(seconds: track.playbackDuration)).font(.custom("Helvetica Neue Bold", fixedSize: 15)).foregroundColor(Color(red: 128/255, green: 128/255, blue: 128/255)).lineLimit(1).multilineTextAlignment(.trailing)
                                    }.frame(width:40)
                                }
                                Spacer()
                                Rectangle().fill(Color(red: 228/255, green: 228/255, blue: 228/255)).frame(height:2)
                            }.overlay(
                                ZStack {
                                    HStack(alignment:.center) {
                                        Rectangle().fill(Color(red: 228/255, green: 228/255, blue: 228/255)).frame(width:2).padding(.leading, 45)
                                        Spacer()
                                    }
                                    HStack(alignment:.center) {
                                        Spacer()
                                        Rectangle().fill(Color(red: 228/255, green: 228/255, blue: 228/255)).frame(width:2).padding(.trailing, 45)
                                    }
                                }

                            ).background(index % 2  == 0 ? Color.white : Color(red: 243/255, green: 243/255, blue: 243/255))
                        }.frame(height: 44)
                    }
                }.drawingGroup()
            }.background(tracks.count % 2  == 0 ? Color.white : Color(red: 240/255, green: 240/255, blue: 240/255))
        }
    }
    func release_year() -> String {
        if let year = (album.representativeItem?.value(forProperty: "year") as? NSNumber)?.intValue, year > 0 {
            return String(year)
        }
        if let date = album.representativeItem?.releaseDate {
            return get_release_date(date)
        }
        return ""
    }
    func get_release_date(_ date: Date) -> String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy"
        let yearString = dateFormatter.string(from: date)
        return yearString
    }
}


// MARK: - Songs

struct ipod_songs: View {
    @EnvironmentObject var MusicObserver: MusicObserver
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    @State var editing_state: String = "None"
    var body: some View {
        VStack(spacing:0) {
            SkeuomorphicList_Songs(current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, editing_state: $editing_state, MusicObserver: MusicObserver, indexes: MusicObserver.song_sections.map { $0.letter })
            .modifier(VerticalIndex(indexableList: alphabet, indexes: MusicObserver.song_sections.map { $0.letter }, editing_state: $editing_state))
        }.offset(y:-1.2)
    }
}

struct SkeuomorphicList_Songs: View {
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    @Binding var editing_state:String
    @ObservedObject var MusicObserver: MusicObserver
    @ObservedObject var player = iPodPlayer.shared
    var indexes: [String]
    @State var search = ""
    var body: some View {
        ZStack(alignment:.top) {
            List {
                Section(header: EmptyView().frame(height: 0), footer: EmptyView().frame(height: 0)) {
                    ipod_search(
                        search: $search,
                        no_right_padding: editing_state != "None",
                        editing_state: $editing_state
                    )
                    .id("Search")
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .padding(.top, 0)
                    .frame(height: 44)
                    .hideRowSeparator()
                } //Ok so this is a little bit of a whacky fix, but we need to suppress the added pixelish of height added to the top of this
                shuffle(songs: MusicObserver.songs, forward_or_backward: $forward_or_backward, current_nav_view: $current_nav_view).listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)).frame(height:44).hideRowSeparator()
                ForEach(MusicObserver.song_sections, id: \.letter) { section in
                    Section(header: alpha_list_header(letter: section.letter).id(section.letter) .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))) {
                        ForEach(section.items, id: \.persistentID) { song in
                            Button(action:{
                                //OldMusic fix: queue the whole Songs list starting at the tapped song (next/previous now work).
                                ipod_play(MusicObserver.songs, start: song)
                                forward_or_backward = false; withAnimation(.linear(duration: 0.28)){current_nav_view = "Now Playing"}
                            }) {
                                VStack(alignment: .leading, spacing: 0) {
                                    Spacer().frame(height:4.5)
                                    HStack() {

                                        VStack(alignment: .leading) {
                                            Text(song.title ?? "---").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(.black).lineLimit(1)
                                            Spacer().frame(height:1)
                                            Text("\(song.albumTitle ?? "---") - \(song.artist ?? "---")")
                                                .font(.custom("Helvetica Neue Regular", fixedSize: 14)).foregroundColor(.cgLightGray).lineLimit(1)
                                        }.padding(.leading, 11)
                                        if player.isNowPlaying(song) {
                                            Spacer()
                                            Image("NowPlayingListItemIcon")
                                        }
                                    }.padding(.trailing, 40)
                                    Spacer().frame(height:4.5)
                                    Rectangle().fill(Color(red: 224/255, green: 224/255, blue: 224/255)).frame(height:0.95).edgesIgnoringSafeArea(.all)
                                }
                            }
                        }.hideRowSeparator()
                    }
                }.listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)).drawingGroup()
                HStack {
                    Spacer()
                    Text("\(MusicObserver.songs.count) Songs").font(.custom("Helvetica Neue Regular", fixedSize: 20)).foregroundColor(.cgLightGray).lineLimit(1)
                    Spacer()
                }.hideRowSeparator().listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            }.skeuomorphicStyleList()
            ipod_search_overlay(MusicObserver: MusicObserver, editing_state: $editing_state, search: search, current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward)

        }
    }
}

struct shuffle: View {
    var songs: [MPMediaItem]
    @Binding var forward_or_backward: Bool
    @Binding var current_nav_view: String
    var body: some View {
        Button(action:{
            guard songs.count != 0 else { return }
            ipod_play(songs, shuffle: true)
            forward_or_backward = false; withAnimation(.linear(duration: 0.28)){current_nav_view = "Now Playing"}
        }) {
            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height:4.5 + 0.95/2)
                HStack() {

                    VStack(alignment: .leading) {
                        HStack {
                            Text("Shuffle").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(.black).lineLimit(1)
                            Image("shuffle_icon")
                        }
                    }.padding(.leading, 11).padding(.trailing, 40)
                }
                Spacer().frame(height:4.5 + 0.95/2)
            }
        }
    }
}




// MARK: - Videos

struct ipod_video_link: Identifiable {
    let id = UUID()
    let url: URL
}

struct ipod_video_player: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        let player = AVPlayer(url: url)
        controller.player = player
        player.play()
        return controller
    }
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
    }
    static func dismantleUIViewController(_ uiViewController: AVPlayerViewController, coordinator: ()) {
        uiViewController.player?.pause()
    }
}

struct ipod_videos: View {
    @EnvironmentObject var MusicObserver: MusicObserver
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    @State var video_link: ipod_video_link?
    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)
            if MusicObserver.videos.count == 0 {
                VStack() {
                    HStack {
                        Image("no_videos_icon").resizable().scaledToFit().padding([.leading, .trailing], 70)
                    }.frame(maxWidth: 320)
                    Spacer().frame(height:35)
                    HStack {
                        Spacer()
                        Text("No Videos") .font(.custom("Helvetica Neue Bold", fixedSize: 20))
                            .foregroundColor(Color(red: 98/255, green: 106/255, blue: 121/255))
                        Spacer()
                    }
                    Spacer().frame(height:20)
                    HStack {
                        Spacer()
                        Text("You can download videos from iTunes.") .font(.custom("Helvetica Neue Bold", fixedSize: 14))
                            .foregroundColor(Color(red: 98/255, green: 106/255, blue: 121/255))
                        Spacer().frame(width:5)
                        ZStack {
                            Circle().fill(Color(red: 125/255, green: 127/255, blue: 133/255)).frame(width: 14, height: 14)
                            Arrow().frame(width:7.5, height: 7.5).foregroundColor(.white)
                        }
                        Spacer()
                    }
                }
            } else {
                //OldMusic: the original always showed "No Videos"; videos present in the library are now listed and playable.
                List {
                    ForEach(Array(MusicObserver.videos.enumerated()), id: \.offset) { index, video in
                        Button(action:{
                            if let url = video.assetURL {
                                video_link = ipod_video_link(url: url)
                            } else {
                                ipod_play(MusicObserver.videos, start: video)
                                forward_or_backward = false; withAnimation(.linear(duration: 0.28)){current_nav_view = "Now Playing"}
                            }
                        }) {
                            VStack(alignment: .leading, spacing: 0) {
                                HStack() {
                                    Image(uiImage: video.artwork?.image(at: CGSize(400, 400)) ?? UIImage(named:"noartplaceholder") ?? UIImage()).resizable().scaledToFill().frame(width: 60-0.95, height:60-0.95).clipped()
                                    VStack(alignment: .leading, spacing: 0) {
                                        Text(video.title ?? "---").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(.black).lineLimit(1)
                                        Spacer().frame(height:1)
                                        Text("\(formatTimeFor(seconds: video.playbackDuration)) - \(video.artist ?? "---")")
                                            .font(.custom("Helvetica Neue Regular", fixedSize: 14)).foregroundColor(.cgLightGray).lineLimit(1)
                                    }.padding(.leading, 6).padding(.trailing, 40)
                                    Spacer()
                                    Image("UITableNext").padding(.trailing, 12)
                                }
                                Rectangle().fill(Color(red: 224/255, green: 224/255, blue: 224/255)).frame(height:0.95).edgesIgnoringSafeArea(.all)
                            }
                        }
                    }.hideRowSeparator_larger().listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)).frame(height: 60).drawingGroup()
                }.skeuomorphicStyleList().background(Color.white)
            }
        }.fullScreenCover(item: $video_link) { link in
            ZStack(alignment: .topLeading) {
                Color.black.edgesIgnoringSafeArea(.all)
                ipod_video_player(url: link.url).edgesIgnoringSafeArea(.all)
                Button(action:{ video_link = nil }) {
                    Text("Done").font(.custom("Helvetica Neue Bold", fixedSize: 13)).foregroundColor(.white).padding([.leading, .trailing], 12).padding([.top, .bottom], 6).background(RoundedRectangle(cornerRadius: 5).fill(Color.black.opacity(0.6)))
                }.padding(.leading, 12).padding(.top, 8)
            }
        }
    }
}

//I can't beleive I am doing this.

struct Arrow: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.size.width/2, y: 0))
        path.addLine(to: CGPoint(x: rect.size.width/2, y: rect.size.height/3))
        path.addLine(to: CGPoint(x: 0, y: rect.size.height/3))
        path.addLine(to: CGPoint(x: 0, y: rect.size.height/3*2))
        path.addLine(to: CGPoint(x: rect.size.width/2, y: rect.size.height/3*2))
        path.addLine(to: CGPoint(x: rect.size.width/2, y: rect.size.height))
        path.addLine(to: CGPoint(x: rect.size.width, y: rect.size.height/2))
        path.closeSubpath()

        return path
    }
}

// MARK: - More

struct ipod_more: View {
    @EnvironmentObject var MusicObserver: MusicObserver
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    @Binding var more_stack: [ipod_more_route]
    var bar_items = ["Albums": "BarAlbums", "Audiobooks": "BarAudioBooks", "Composers":"BarComposers", "Genres": "BarGenres", "iTunes U": "BarITunesU", "Podcasts":"BarPodcasts"]
    var body: some View {
        VStack(spacing: 0) {
            if let route = more_stack.last {
                ipod_more_destination(route: route, current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, more_stack: $more_stack).id(more_stack.count).clipped().transition(AnyTransition.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
            } else {
                NoSepratorList {
                    ForEach(bar_items.sorted(by: <), id: \.key) { key, value in
                        Button(action:{
                            open_category(key)
                        }) {
                            VStack(alignment: .leading, spacing: 0) {
                                //Spacer().frame(height:4.5)
                                HStack(alignment: .center) {
                                    Spacer().frame(width:1, height: 44-0.95)
                                    Image(value).frame(width:25, height: 44-0.95)
                                    Text(key).font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(.black).lineLimit(1).padding(.leading, 6).padding(.trailing, 40)
                                    Spacer()
                                    Image("UITableNext").padding(.trailing, 12)
                                }.padding(.leading, 15)
                                //  Spacer().frame(height:9.5)
                                Rectangle().fill(Color(red: 224/255, green: 224/255, blue: 224/255)).frame(height:0.95).edgesIgnoringSafeArea(.all)

                            }.contentShape(Rectangle())
                        }
                    }.hideRowSeparator().listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)).frame(height: 44).drawingGroup()

                }.background(Color.white).id(0).clipped().transition(AnyTransition.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)))
            }
        }.offset(y:-1.2)
    }

    func open_category(_ key: String) {
        let route: ipod_more_route
        switch key {
        case "Albums":
            route = .collections("Albums", MusicObserver.ab, .albums)
        case "Audiobooks":
            route = .collections("Audiobooks", MusicObserver.audiobooks, .grouped)
        case "Composers":
            route = .collections("Composers", MusicObserver.composers, .composers)
        case "Genres":
            route = .collections("Genres", MusicObserver.genres, .genres)
        case "iTunes U":
            route = .collections("iTunes U", MusicObserver.itunes_u, .grouped)
        case "Podcasts":
            route = .collections("Podcasts", MusicObserver.podcasts, .podcasts)
        default:
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            forward_or_backward = false; withAnimation(.linear(duration: 0.28)){more_stack.append(route)}
        }
    }
}

enum ipod_more_kind {
    case albums
    case genres
    case composers
    case podcasts
    case grouped
}

enum ipod_more_route {
    case collections(String, [MPMediaItemCollection], ipod_more_kind)
    case album(MPMediaItemCollection)
    case items(String, [MPMediaItem])

    var title: String {
        switch self {
        case .collections(let title, _, _):
            return title
        case .album(let album):
            return album.representativeItem?.albumTitle ?? "---"
        case .items(let title, _):
            return title
        }
    }
}

func ipod_collection_name(_ collection: MPMediaItemCollection, kind: ipod_more_kind) -> String {
    let item = collection.representativeItem
    switch kind {
    case .albums, .grouped:
        return item?.albumTitle ?? item?.title ?? "---"
    case .genres:
        return item?.genre ?? "---"
    case .composers:
        return item?.composer ?? "---"
    case .podcasts:
        return item?.podcastTitle ?? item?.albumTitle ?? "---"
    }
}

func ipod_collection_subtitle(_ collection: MPMediaItemCollection, kind: ipod_more_kind) -> String {
    let item = collection.representativeItem
    switch kind {
    case .albums, .grouped:
        return item?.albumArtist ?? item?.artist ?? ""
    case .podcasts:
        return item?.artist ?? ""
    case .genres, .composers:
        return "\(collection.count) \(collection.count == 1 ? "Song" : "Songs")"
    }
}

struct ipod_more_destination: View {
    @EnvironmentObject var MusicObserver: MusicObserver
    var route: ipod_more_route
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    @Binding var more_stack: [ipod_more_route]
    var body: some View {
        switch route {
        case .collections(let title, let collections, let kind):
            ipod_more_collections_list(title: title, collections: collections, kind: kind, current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward, more_stack: $more_stack)
        case .album(let album):
            albums_destination(album: .constant(album), current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward)
        case .items(let title, let items):
            ipod_more_items_list(title: title, items: items, current_nav_view: $current_nav_view, forward_or_backward: $forward_or_backward)
        }
    }
}

struct ipod_more_empty: View {
    var title: String
    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)
            VStack {
                Spacer()
                Text("No \(title)").font(.custom("Helvetica Neue Bold", fixedSize: 20))
                    .foregroundColor(Color(red: 98/255, green: 106/255, blue: 121/255))
                Spacer()
            }
        }
    }
}

struct ipod_more_collections_list: View {
    @EnvironmentObject var MusicObserver: MusicObserver
    var title: String
    var collections: [MPMediaItemCollection]
    var kind: ipod_more_kind
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    @Binding var more_stack: [ipod_more_route]
    var body: some View {
        if collections.count == 0 {
            ipod_more_empty(title: title)
        } else {
            List {
                ForEach(Array(collections.enumerated()), id: \.offset) { index, collection in
                    Button(action:{
                        open_collection(collection)
                    }) {
                        if kind == .genres || kind == .composers {
                            VStack(alignment: .leading, spacing: 0) {
                                Spacer().frame(height:4.5)
                                HStack() {
                                    Text(ipod_collection_name(collection, kind: kind)).font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(.black).lineLimit(1).padding(.leading, 11).padding(.trailing, 40)
                                    Spacer()
                                    Image("UITableNext").padding(.trailing, 12)
                                }
                                Spacer().frame(height:9.5)
                                Rectangle().fill(Color(red: 224/255, green: 224/255, blue: 224/255)).frame(height:0.95).edgesIgnoringSafeArea(.all)
                            }.frame(height: 44)
                        } else {
                            VStack(alignment: .leading, spacing: 0) {
                                HStack() {
                                    Image(uiImage: collection.representativeItem?.artwork?.image(at: CGSize(400, 400)) ?? UIImage(named:"noartplaceholder") ?? UIImage()).resizable().scaledToFill().frame(width: 60-0.95, height:60-0.95).clipped()
                                    VStack(alignment: .leading, spacing: 0) {
                                        Text(ipod_collection_name(collection, kind: kind)).font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(.black).lineLimit(1)
                                        Spacer().frame(height:1)
                                        Text(ipod_collection_subtitle(collection, kind: kind))
                                            .font(.custom("Helvetica Neue Regular", fixedSize: 14)).foregroundColor(.cgLightGray).lineLimit(1)
                                    }.padding(.leading, 6).padding(.trailing, 40)
                                    Spacer()
                                    Image("UITableNext").padding(.trailing, 12)
                                }
                                Rectangle().fill(Color(red: 224/255, green: 224/255, blue: 224/255)).frame(height:0.95).edgesIgnoringSafeArea(.all)
                            }.frame(height: 60)
                        }
                    }
                }.hideRowSeparator().listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)).drawingGroup()
                HStack {
                    Spacer()
                    Text("\(collections.count) \(title)").font(.custom("Helvetica Neue Regular", fixedSize: 20)).foregroundColor(.cgLightGray).lineLimit(1)
                    Spacer()
                }.hideRowSeparator().listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            }.skeuomorphicStyleList()
                .background(Color.white)
        }
    }

    func open_collection(_ collection: MPMediaItemCollection) {
        let route: ipod_more_route
        switch kind {
        case .albums:
            route = .album(collection)
        case .genres:
            route = .collections(ipod_collection_name(collection, kind: kind), MusicObserver.albums(forGenre: collection), .albums)
        case .composers, .podcasts, .grouped:
            route = .items(ipod_collection_name(collection, kind: kind), kind == .podcasts ? collection.items : ipod_sorted_album_tracks(collection.items))
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            forward_or_backward = false; withAnimation(.linear(duration: 0.28)){more_stack.append(route)}
        }
    }
}

struct ipod_more_items_list: View {
    var title: String
    var items: [MPMediaItem]
    @Binding var current_nav_view: String
    @Binding var forward_or_backward: Bool
    @ObservedObject var player = iPodPlayer.shared
    var body: some View {
        if items.count == 0 {
            ipod_more_empty(title: title)
        } else {
            List {
                shuffle(songs: items, forward_or_backward: $forward_or_backward, current_nav_view: $current_nav_view).listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)).frame(height:44).hideRowSeparator()
                ForEach(Array(items.enumerated()), id: \.offset) { index, song in
                    Button(action:{
                        ipod_play(items, start: song)
                        forward_or_backward = false; withAnimation(.linear(duration: 0.28)){current_nav_view = "Now Playing"}
                    }) {
                        VStack(alignment: .leading, spacing: 0) {
                            Spacer().frame(height:4.5)
                            HStack() {
                                VStack(alignment: .leading) {
                                    Text(song.title ?? "---").font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(.black).lineLimit(1)
                                    Spacer().frame(height:1)
                                    Text("\(song.albumTitle ?? "---") - \(song.artist ?? "---")")
                                        .font(.custom("Helvetica Neue Regular", fixedSize: 14)).foregroundColor(.cgLightGray).lineLimit(1)
                                }.padding(.leading, 11)
                                Spacer()
                                if player.isNowPlaying(song) {
                                    Image("NowPlayingListItemIcon")
                                }
                            }.padding(.trailing, 11)
                            Spacer().frame(height:4.5)
                            Rectangle().fill(Color(red: 224/255, green: 224/255, blue: 224/255)).frame(height:0.95).edgesIgnoringSafeArea(.all)
                        }
                    }.padding(.top, index == 0 ? 2.5 : 0)
                }.hideRowSeparator().listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)).drawingGroup()
            }.skeuomorphicStyleList()
                .background(Color.white)
        }
    }
}

// MARK: - CoverFlow Views
struct containerCoverflow: View {
    //  var geometry: GeometryProxy
    var body: some View {
        CoverFlowView()
    }
}

struct CoverFlowView: View {
    @EnvironmentObject var MusicObserver: MusicObserver
    @ObservedObject var player = iPodPlayer.shared
    var orientation: UIDeviceOrientation = .landscapeLeft
    @State var current_album: MPMediaItemCollection = MPMediaItemCollection.init(items: [])
    @State var is_showing_back: Bool = false
    //  var geometry: GeometryProxy
    var body: some View {
        GeometryReader {geometry in
            ZStack {
                Color.black
                CoverFlow_Sub(geometry: geometry, albums: MusicObserver.ab, current_album: $current_album, is_showing_back: $is_showing_back).frame(width: geometry.size.height, height: geometry.size.width) //.rotationEffect(.degrees(-90))
                VStack {
                    status_bar().frame(width: geometry.size.height, height: 24)
                    Spacer()
                    HStack(alignment: .bottom) {
                        Button(action:{
                            iPodPlayer.shared.togglePlayPause()
                        }) {
                            coverflow_play_indicator(is_playing: player.isPlaying)
                        }.padding(.leading, 8)
                        Spacer()
                        VStack {
                            Text(current_album.representativeItem?.albumArtist ?? current_album.representativeItem?.artist ?? "Unknown").font(.custom("Helvetica Neue Bold", fixedSize: 15)).foregroundColor(.white).multilineTextAlignment(.center).lineLimit(1)
                            Text(current_album.representativeItem?.albumTitle ?? "Unknown").font(.custom("Helvetica Neue Bold", fixedSize: 15)).foregroundColor(.white).multilineTextAlignment(.center).lineLimit(1)
                        }.isHidden(is_showing_back)
                        Spacer()
                        coverflow_info_icon().padding(.trailing, 8)
                    }.padding(.bottom, 10)
                }.frame(width: geometry.size.height, height: geometry.size.width)
            }.frame(width: geometry.size.width, height: geometry.size.height)
        }.rotationEffect(.degrees(orientation == .landscapeRight ? -90 : 90)).onAppear() {
            let music_player = MPMusicPlayerController.systemMusicPlayer
            current_album = MusicObserver.ab[optional: MusicObserver.ab.firstIndex(where: {
                $0.representativeItem?.albumPersistentID == music_player.nowPlayingItem?.albumPersistentID
            }) ?? 0] ?? MPMediaItemCollection.init(items: [])
        }

    }
}

//OldMusic: the original referenced the image assets "CoverFlowPlayIndicator" and "CoverFlowInfoIcon"
//which were never added to the OldOS asset catalog (they rendered as nothing). Drawn here instead.
struct coverflow_play_indicator: View {
    var is_playing: Bool
    var body: some View {
        ZStack {
            Circle().fill(Color.black.opacity(0.45)).frame(width: 30, height: 30)
            Circle().stroke(Color.white.opacity(0.85), lineWidth: 1.5).frame(width: 30, height: 30)
            Image(is_playing ? "pause" : "play").resizable().scaledToFit().frame(width: 12, height: 12).offset(x: is_playing ? 0 : 1)
        }.shadow(color: Color.black.opacity(0.6), radius: 1, x: 0, y: 1)
    }
}

struct coverflow_info_icon: View {
    var body: some View {
        ZStack {
            Circle().fill(LinearGradient(gradient: Gradient(colors: [Color(red: 120/255, green: 120/255, blue: 120/255), Color(red: 40/255, green: 40/255, blue: 40/255)]), startPoint: .top, endPoint: .bottom)).frame(width: 22, height: 22)
            Circle().stroke(Color.white.opacity(0.9), lineWidth: 1.5).frame(width: 22, height: 22)
            Text("i").font(.custom("Georgia-BoldItalic", fixedSize: 15)).foregroundColor(.white)
        }.shadow(color: Color.black.opacity(0.6), radius: 1, x: 0, y: 1)
    }
}


struct coverflow_selected_item: View {
    @State var current_song: MPMediaItem?
    @State var new_track_delay: Bool = false
    @Binding var current_album: MPMediaItemCollection
    let song_publisher = NotificationCenter.default
        .publisher(for: .MPMusicPlayerControllerNowPlayingItemDidChange)
    var body: some View {
        GeometryReader { geometry in
            let tracks = removeDuplicates(ipod_sorted_album_tracks(current_album.items))
            ZStack {
                Image("NowPlayingTableBackground").resizable().scaledToFill().frame(width:geometry.size.width, height: geometry.size.height).clipped()
                VStack(spacing: 0) {
                    ZStack {
                        Rectangle().fill(LinearGradient([Color(red: 171/255, green: 183/255, blue: 209/255), Color(red: 120/255, green: 144/255, blue: 188/255)], from: .top, to: .bottom)).frame(width: geometry.size.width, height: 50)
                        HStack(spacing: 0) {
                            VStack(alignment: .leading) {
                                Text(current_album.representativeItem?.albumArtist ?? current_album.representativeItem?.artist ?? "Unknown").font(.custom("Helvetica Neue Bold", fixedSize: 13)).foregroundColor(.white).lineLimit(1)
                                Text(current_album.representativeItem?.albumTitle ?? "Unknown").font(.custom("Helvetica Neue Bold", fixedSize: 20)).foregroundColor(.white).lineLimit(1)
                            }.padding([.leading, .trailing], 5)
                            Spacer()
                            Image(uiImage: current_album.representativeItem?.artwork?.image(at: CGSize(400, 400)) ?? UIImage(named:"noartplaceholder") ?? UIImage()).resizable().scaledToFill().frame(width: 50, height: 50).clipped()
                        }.frame(width: geometry.size.width, height: 50)
                    }.frame(width: geometry.size.width, height: 50)
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(tracks.enumerated()), id: \.element.persistentID) { index, track in
                                Button(action:{
                                    if new_track_delay == false {
                                        new_track_delay = true
                                        play_song(song: track, in: tracks)
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                        new_track_delay = false
                                    }
                                }) {
                                    VStack {
                                        if index == 0 {
                                            Rectangle().fill(Color(red: 65/255, green: 64/255, blue: 65/255)).frame(height:2)
                                        }
                                        Spacer()
                                        HStack {
                                            HStack {
                                                Text("\(String(track.albumTrackNumber)).").font(.custom("Helvetica Neue Bold", fixedSize: 14)).foregroundColor(.white).lineLimit(1).padding(.leading, 5).padding(.trailing, 5).multilineTextAlignment(.leading)
                                                Spacer()
                                            }.frame(width:60)
                                            Text(track.title ?? "---").font(.custom("Helvetica Neue Bold", fixedSize: 14)).foregroundColor(.white).lineLimit(1).padding(.leading, 14)
                                            Spacer()
                                            HStack {
                                                Spacer()
                                                Text(formatTimeFor(seconds: track.playbackDuration)).font(.custom("Helvetica Neue Bold", fixedSize: 14)).foregroundColor(.white).lineLimit(1).padding(.trailing, 5).padding(.leading, 5).multilineTextAlignment(.trailing)
                                            }.frame(width:60)
                                        }
                                        Spacer()
                                        Rectangle().fill(Color(red: 65/255, green: 64/255, blue: 65/255)).frame(height:2)
                                    }.overlay(
                                        ZStack {
                                            HStack(alignment:.center) {
                                                Rectangle().fill(Color(red: 65/255, green: 64/255, blue: 65/255)).frame(width:2).padding(.leading, 65)
                                                Spacer()
                                            }
                                            HStack(alignment:.center) {
                                                Spacer()
                                                Rectangle().fill(Color(red: 65/255, green: 64/255, blue: 65/255)).frame(width:2).padding(.trailing, 65)
                                            }
                                            if track.persistentID == current_song?.persistentID {
                                                HStack(alignment:.center) {
                                                    Image("play").resizable().renderingMode(.template).scaledToFit().foregroundColor(Color(red: 54/255, green: 98/255, blue: 214/255)).frame(height:10).padding(.leading, 40)
                                                    Spacer()
                                                }
                                            }
                                        }

                                    ).background(index % 2  == 0 ? Color.clear : Color.black.opacity(0.2))
                                }.frame(height: 44)
                            }
                        }
                    }
                }
            }.frame(width: geometry.size.width, height: geometry.size.height).border_bottom(width: 1, edges: [.top, .leading, .trailing], color: Color.white)
        }.onReceive(song_publisher) { (output) in
            let music_player = MPMusicPlayerController.systemMusicPlayer
            let current = music_player.nowPlayingItem
            current_song = current
        }.onAppear() {
            let music_player = MPMusicPlayerController.systemMusicPlayer
            let current = music_player.nowPlayingItem
            current_song = current
        }
    }
}

struct TapView: UIViewRepresentable {
    var tappedCallback: (() -> Void)

    func makeUIView(context: Context) -> UIView {
        let v = UIView(frame: .zero)
        let gesture = SingleTouchDownGestureRecognizer(target: context.coordinator,
                                                       action: #selector(Coordinator.tapped))
        v.addGestureRecognizer(gesture)
        return v
    }

    class Coordinator: NSObject {
        var tappedCallback: (() -> Void)

        init(tappedCallback: @escaping (() -> Void)) {
            self.tappedCallback = tappedCallback
        }

        @objc func tapped(gesture:UITapGestureRecognizer) {
            self.tappedCallback()
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(tappedCallback:self.tappedCallback)
    }

    func updateUIView(_ uiView: UIView,
                      context: Context) {
    }
}

class SingleTouchDownGestureRecognizer: UIGestureRecognizer {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        if self.state == .possible {
            self.state = .recognized
        }
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        self.state = .failed
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        self.state = .failed
    }
}

struct CoverFlow_Sub: UIViewControllerRepresentable {

    typealias UIViewControllerType = UIViewController


    var VC = UIViewController()
    var geometry: GeometryProxy
    var albums: [MPMediaItemCollection]
    @Binding var current_album: MPMediaItemCollection
    @Binding var is_showing_back: Bool
    var v2 = UIView()
    var v3 = UIView()
    var backside: UIHostingController<coverflow_selected_item>?
    var carousel = iCarousel()
    var v = UIView()
    init(geometry: GeometryProxy, albums: [MPMediaItemCollection], current_album: Binding<MPMediaItemCollection>, is_showing_back: Binding<Bool>) {
        self.geometry = geometry
        self.albums = albums
        _current_album = current_album
        _is_showing_back = is_showing_back
        backside = UIHostingController(rootView: coverflow_selected_item(current_album: $current_album))
    }

    func makeUIViewController(context: Context) -> UIViewController {
        VC.view.frame = CGRect(x:0, y: 0, width: geometry.size.height, height: geometry.size.width)
        VC.view.backgroundColor = .black
        v3.frame = CGRect(x: 0, y: 0, width: geometry.size.height, height: geometry.size.width)
        carousel.frame = CGRect(x: 0, y:0, width: geometry.size.height, height: geometry.size.width)
        carousel.dataSource = context.coordinator
        carousel.delegate = context.coordinator
        carousel.type = .coverFlow2
        v2.frame = CGRect(0, 0, geometry.size.height * 3/5, geometry.size.width - 24)
        backside?.view.frame = CGRect(0, 0, geometry.size.height * 0.5, geometry.size.width - 24)
        backside?.view.backgroundColor = .clear
        v2.backgroundColor = .red
        VC.view.addSubview(v3)
        v3.addSubview(carousel)
        v3.addSubview(backside?.view ?? UIView())
        backside?.view.alpha = 0.5
        backside?.view.center = CGPoint(geometry.size.height/2, geometry.size.width/2 + 12)
        backside?.view.isHidden = true
        let music_player = MPMusicPlayerController.systemMusicPlayer
        if albums.count != 0 {
            carousel.currentItemIndex = albums.firstIndex(where: {
                $0.representativeItem?.albumPersistentID == music_player.nowPlayingItem?.albumPersistentID
            }) ?? 0
        }
        v.frame = CGRect(x: 0, y:0, width: geometry.size.height, height: geometry.size.width)
        let gesture = SingleTouchDownGestureRecognizer(target: context.coordinator,
                                                       action: #selector(Coordinator.flip_back))
        v.addGestureRecognizer(gesture)

        return VC
    }


    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        //OldMusic fix: if the library finished loading after Cover Flow appeared, reload the carousel.
        let coordinator = context.coordinator
        if coordinator.parent.albums.count != albums.count {
            coordinator.parent.albums = albums
            coordinator.parent.carousel.reloadData()
        }
    }
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    class Coordinator: NSObject, iCarouselDelegate, iCarouselDataSource {
        var parent: CoverFlow_Sub
        init(_ parent: CoverFlow_Sub) {
            self.parent = parent
        }
        func numberOfItems(in carousel: iCarousel) -> Int {
            return parent.albums.count
        }

        @objc func flip_back() {
            print("flip back")
            parent.v.removeFromSuperview()
            let orientation = UIDevice.current.orientation
            UIView.transition(with: self.parent.backside?.view ?? UIView(), duration: 1.0, options: [orientation == .landscapeRight ? .transitionFlipFromTop : .transitionFlipFromBottom, .showHideTransitionViews], animations: {
                self.parent.backside?.view.isHidden = true
                self.parent.backside?.view.alpha = 0
            })
            if let item_view = parent.carousel.currentItemView {
                UIView.transition(with: item_view, duration: 1.0, options: [.allowAnimatedContent, .transitionFlipFromLeft, .showHideTransitionViews], animations: {
                    item_view.clipsToBounds = false
                    item_view.alpha = 1.0
                })
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                self.parent.carousel.isUserInteractionEnabled = true
                withAnimation(.linear(duration: 0.1)) {
                    self.parent.is_showing_back = false
                }
            }
        }

        func carouselCurrentItemIndexDidChange(_ carousel: iCarousel) {
            guard parent.albums.indices.contains(carousel.currentItemIndex) else { return }
            parent.current_album = parent.albums[carousel.currentItemIndex]
        }

        func carousel(_ carousel: iCarousel, didSelectItemAt index: Int) {
            guard parent.albums.indices.contains(index) else { return }
            parent.current_album = parent.albums[index]
            if parent.current_album == parent.albums[index] {
                parent.v3.insertSubview(parent.v, belowSubview: parent.backside?.view ?? UIView())
                carousel.isUserInteractionEnabled = false
                withAnimation(.linear(duration: 0.1)) {
                    parent.is_showing_back = true
                }
                if let item_view = carousel.currentItemView {
                    UIView.transition(with: item_view, duration: 1.0, options: [.transitionFlipFromRight, .allowAnimatedContent, .showHideTransitionViews], animations: {
                        item_view.alpha = 0.0
                        item_view.clipsToBounds = false
                    })
                }
                let orientation = UIDevice.current.orientation
                UIView.transition(with: self.parent.backside?.view ?? UIView(), duration: 1.0, options: [orientation == .landscapeRight ? .transitionFlipFromBottom : .transitionFlipFromTop, .showHideTransitionViews], animations: {
                    self.parent.backside?.view.isHidden = false
                    self.parent.backside?.view.alpha = 1.0
                })
            }
            print("tap")
        }

        func carousel(_ carousel: iCarousel, viewForItemAt index: Int, reusing view: UIView?) -> UIView {
            let placeholder: UIImage = UIImage(named: "noartplaceholder") ?? UIImage()
            var image: UIImage = placeholder
            if parent.albums.indices.contains(index), let artwork = parent.albums[index].representativeItem?.artwork?.image(at: CGSize(width: 250, height: 250)) {
                image = artwork
            }
            let view = UIHostingController(rootView: ios_14_image_hosting(image: image))
            view.view.frame = CGRect(0, 0, 250, 250)
            view.view.backgroundColor = .clear
            return view.view

        }


    }


}

struct ios_14_image_hosting: View {
    var image: UIImage
    var body: some View {
        ZStack {
            Image(uiImage: image).resizable().frame(width:250, height: 250).opacity(0.7).rotationEffect(.degrees(-180)).offset(y:250).rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            Image(uiImage: image).resizable().frame(width:250, height: 250).innerShadowBottomWithOffset(color: Color.black.opacity(0.9), radius: 0.0125, offset: 250)
        }.frame(height:250)
    }
}



func resizeCoverFlowImage(image: UIImage, newWidth: CGFloat) -> UIImage {

    let scale = newWidth / image.size.width
    let newHeight = image.size.height * scale
    UIGraphicsBeginImageContext(CGSize(newWidth, newHeight))
    image.draw(in: CGRect(0, 0, newWidth, newHeight))
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    return newImage ?? UIImage()
}


struct skeuomorphicStyleListModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .listSectionSpacing(0)
                .environment(\.defaultMinListRowHeight, 44)
        } else {
            content
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.white)
                .environment(\.defaultMinListRowHeight, 44)
        }
    }
}

extension View {
    func skeuomorphicStyleList() -> some View {
        self.modifier(skeuomorphicStyleListModifier())
    }
}


// MARK: - Common

struct ipod_search: View {
    @Binding var search: String
    @State var place_holder = ""
    var no_right_padding: Bool?
    @Binding var editing_state: String
    private let gradient = LinearGradient([.white, .white], to: .trailing)
    private let cancel_gradient = LinearGradient([(color: Color(red: 164/255, green: 175/255, blue:191/255), location: 0), (color: Color(red: 124/255, green: 141/255, blue:164/255), location: 0.51), (color: Color(red: 113/255, green: 131/255, blue:156/255), location: 0.51), (color: Color(red: 112/255, green: 130/255, blue:155/255), location: 1)], from: .top, to: .bottom)
    var body: some View {
        ZStack {
            Rectangle().fill(LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 252/255, green: 250/255, blue: 250/255), location: 0), .init(color: Color(red: 224/255, green: 228/255, blue: 231/255), location: 0.04), .init(color: Color(red: 180/255, green: 190/255, blue: 198/255), location: 1)]), startPoint: .top, endPoint: .bottom)).border_top(width: 0.75, edges: [.top], color: Color(red: 163/255, green: 173/255, blue: 182/255))
            VStack {
                Spacer()
                HStack {
                    HStack {
                        Spacer(minLength: 5)
                        HStack (alignment: .center,
                                spacing: 10) {
                            Image("search_icon").resizable().font(Font.title.weight(.medium)).frame(width: 15, height: 15).padding(.leading, 5)

                            TextField ("Search", text: $search, onEditingChanged: { (changed) in
                                if changed  {
                                    withAnimation() {
                                        editing_state = search == "" ? "Active_Empty" : "Active"
                                    }
                                } else {
                                    withAnimation() {
                                        editing_state = "None"
                                    }
                                }
                            }) {
                                withAnimation() {
                                    editing_state = "None"
                                }
                            }.onChange(of: search) { _ in
                                if search != "" {
                                    editing_state = "Active"
                                } else {
                                    if editing_state != "None" {
                                        editing_state = "Active_Empty"
                                    }
                                }
                            }.keyboardType(.alphabet).submitLabel(.search).disableAutocorrection(true).oldOSKeyboard(.search)
                            if search.count != 0 {
                                Button(action:{search = ""}) {
                                    Image("UITextFieldClearButton")
                                }.fixedSize()
                            }
                        }

                        .padding([.top,.bottom], 5)
                        .padding(.leading, 5)
                        .cornerRadius(40)
                        Spacer(minLength: 8)
                    } .ps_innerShadow(.capsule(gradient), radius:1.6, offset: CGPoint(0, 1), intensity: 0.7).strokeCapsule(Color(red: 166/255, green: 166/255, blue: 166/255), lineWidth: 0.33).padding(.leading, 5.5).padding(.trailing, no_right_padding == true ? 5.5 : 35)
                    if editing_state != "None" {
                        Button(action:{
                            //OldMusic fix: Cancel also clears the query, like iOS 6.
                            search = ""
                            hideKeyboard()
                            withAnimation() {
                                editing_state = "None"
                            }
                        }) {
                            ZStack {
                                Text("Cancel").font(.custom("Helvetica Neue Bold", fixedSize: 13.25)).foregroundColor(.white).shadow(color: Color.black.opacity(0.75), radius: 1, x: 0, y: -0.25)
                            }.frame(width: 59, height: 32).ps_innerShadow(.roundedRectangle(5.5, cancel_gradient), radius:0.8, offset: CGPoint(0, 0.6), intensity: 0.7).shadow(color: Color.white.opacity(0.28), radius: 0, x: 0, y: 0.8)
                            .padding(.trailing, 5)
                        }.frame(width: 59, height: 32).transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .trailing))).fixedSize()
                    }
                }
                Spacer()
            }
        }
    }
}

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif

struct HideRowSeparatorModifier: ViewModifier {

    static let defaultListRowHeight: CGFloat = 44

    var insets: EdgeInsets
    var background: Color

    init(insets: EdgeInsets, background: Color) {
        self.insets = insets
        self.background = background
    }

    func body(content: Content) -> some View {
        content
            .padding(insets)
            .frame(
                minWidth: 0, maxWidth: .infinity,
                minHeight: Self.defaultListRowHeight,
                alignment: .leading
            )
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .background(background)
    }
}

struct HideRowSeparatorModifier_Larger: ViewModifier {

    static let defaultListRowHeight: CGFloat = 60

    var insets: EdgeInsets
    var background: Color

    init(insets: EdgeInsets, background: Color) {
        self.insets = insets
        self.background = background
    }

    func body(content: Content) -> some View {
        content
            .padding(insets)
            .frame(
                minWidth: 0, maxWidth: .infinity,
                minHeight: Self.defaultListRowHeight,
                alignment: .leading
            )
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .background(background)
    }
}

extension EdgeInsets {

    static let defaultListRowInsets = Self(top: 0, leading: 0, bottom: 0, trailing: 0)
}

extension View {

    func hideRowSeparator(
        insets: EdgeInsets = .defaultListRowInsets,
        background: Color = .white
    ) -> some View {
        modifier(HideRowSeparatorModifier(
            insets: insets,
            background: background
        ))
    }
    func hideRowSeparator_larger(
        insets: EdgeInsets = .defaultListRowInsets,
        background: Color = .white
    ) -> some View {
        modifier(HideRowSeparatorModifier_Larger(
            insets: insets,
            background: background
        ))
    }
}

struct HideRowSeparator_Previews: PreviewProvider {

    static var previews: some View {
        List {
            ForEach(0..<10) { _ in
                Text("Text")
                    .hideRowSeparator()
            }
        }
        .previewLayout(.sizeThatFits)
    }
}
struct VerticalIndex: ViewModifier {
    let indexableList: [String]
    var indexes: [String]

    @State private var selected: Bool = false
    @State private var offsetHeight: CGFloat = 0.0
    @State private var last_letter: String = ""
    @Binding var editing_state: String

    //OldMusic fix: like iOS, a letter without entries scrolls to the closest following section.
    func target(for letter: String) -> String? {
        if letter == "Search" { return "Search" }
        if indexes.contains(letter) { return letter }
        guard let start = indexableList.firstIndex(of: letter) else { return nil }
        for candidate in indexableList[start...] where indexes.contains(candidate) {
            return candidate
        }
        for candidate in indexableList[..<start].reversed() where indexes.contains(candidate) {
            return candidate
        }
        return nil
    }

    func body(content: Content) -> some View {
        GeometryReader { outerGeo in
            ScrollViewReader { scrollProxy in
                ZStack(alignment: .topTrailing) {
                    content

                    if selected {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 106/255, green: 115/255, blue: 125/255).opacity(0.5))
                            .frame(width: 24)
                            .padding(.trailing, 7)
                            .padding([.top, .bottom], 2)
//                            .padding(.bottom, 10)
                    }

                    VStack(spacing: 2) {
                        ForEach(indexableList, id: \.self) { letter in
                            HStack {
                                Spacer()
                                Button(action: {
                                    if let target = target(for: letter) {
                                        scrollProxy.scrollTo(target, anchor: .top)
                                    }
                                }) {
                                    Group {
                                        if letter == "Search" {
                                            Image(systemName: "magnifyingglass")
                                                .font(.custom("Helvetica Neue Bold", fixedSize: 13.25))
                                                .frame(width: 14, height: 16.5)
                                        } else {
                                            Text(letter)
                                                .font(.custom("Helvetica Neue Bold", fixedSize: 13.25))
                                                .frame(width: 14, height: 16.5)
                                        }
                                    }
                                    .foregroundColor(Color(red: 106/255, green: 115/255, blue: 125/255))
                                    .padding(.trailing, 12)
                                }
                            }
                        }
                    }
                    .frame(height: offsetHeight) // Force index bar height
                    .onLongPressGesture(minimumDuration: 0, pressing: { inProgress in
                        selected = inProgress
                    }) {
                        selected = false
                    }
                    .simultaneousGesture(
                        DragGesture()
                            .onChanged { gesture in
                                guard offsetHeight > 0 else { return }
                                let sectionHeight = (offsetHeight - 17) / CGFloat(indexableList.count)
                                guard sectionHeight > 0 else { return }
                                let index = Int(gesture.location.y / sectionHeight)
                                if index >= 0 && index < indexableList.count {
                                    let letter = indexableList[index]
                                    if let target = target(for: letter), target != last_letter {
                                        last_letter = target
                                        scrollProxy.scrollTo(target, anchor: .top)
                                    }
                                }
                            }
                            .onEnded { _ in
                                last_letter = ""
                            }
                    )
                    .onAppear {
                        offsetHeight = outerGeo.size.height
                    }
                    .onChange(of: outerGeo.size.height) { height in
                        offsetHeight = height
                    }
                    .isHidden(editing_state != "None" ? true : false)
                }
                // Force height of the ZStack to match outer geo height
                .frame(height: outerGeo.size.height)
//                .opacity(editing_state == "None" ? 1 : 0)

            }
        }
    }
}



struct TabButton : View {

    var image : String
    @Binding var selectedTab : String
    @Binding var artists_current_view: String
    @Binding var playlist_current_nav_view: String
    @Binding var more_stack: [ipod_more_route]
    var geometry: GeometryProxy
    var body: some View{
        Button(action: {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            playlist_current_nav_view = "Playlists"
            artists_current_view = "Artists"
            more_stack = []
            selectedTab = image
        }) {
            ZStack {
                if selectedTab == image {
                    RoundedRectangle(cornerRadius: 3).fill(Color.white.opacity(0.1)).frame(width: geometry.size.width/5 - 5, height: 51).blendMode(.screen)
                    VStack(spacing: 2) {
                        ZStack {
                            Image("\(image)_iPod").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(width: image == "Songs" ? 20.5 : image == "Artists" ? 37.5 : 30.5, height: 30.5).overlay(
                                LinearGradient(gradient: Gradient(colors: [Color(red: 205/255, green: 233/255, blue: 249/255), Color(red: 75/255, green: 220/255, blue: 251/255)]), startPoint: .top, endPoint: .bottom)
                            ).mask(Image("\(image)_iPod").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(width: image == "Songs" ? 20.5 : image == "Artists" ? 37.5 : 30.5, height: 30.5)).offset(y:-0.5)

                            Image("\(image)_iPod").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(width: image == "Songs" ? 20 : image == "Artists" ? 37.5 : 30, height: 30).overlay(
                                ZStack {
                                    if image == "More" {
                                        LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 0/255, green: 145/255, blue: 230/255), location: 0), .init(color: Color(red: 21/255, green: 197/255, blue: 252/255), location: 1)]), startPoint: .top, endPoint: .bottom).rotationEffect(Angle(degrees: image == "More" ? 0 : -15)).frame(width: image == "More" ? 40 : 40, height: image == "More" ? 10 : 30).brightness(0.095)
                                    } else {
                                        LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 197/255, green: 210/255, blue: 229/255), location: 0), .init(color: Color(red: 99/255, green: 162/255, blue: 216/255), location: 0.47), .init(color: Color(red: 0/255, green: 145/255, blue: 230/255), location: 0.49), .init(color: Color(red: 21/255, green: 197/255, blue: 252/255), location: 1)]), startPoint: .top, endPoint: .bottom).rotationEffect(Angle(degrees: image == "More" ? 0 : -15)).frame(width: image == "More" ? 40 : 40, height: image == "Artists" ? 34 : 30).brightness(0.095).offset(y: image == "Artists" ? 2 : 0)
                                    }
                                }
                            ).mask(Image("\(image)_iPod").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(width: image == "Songs" ? 20 : image == "Artists" ? 37.5 : 30, height: 30)).shadow(color: Color.black.opacity(0.6), radius:2.5, x: 0, y:2.5)
                        }
                        HStack {
                            Spacer()
                            Text(image).foregroundColor(.white).font(.custom("Helvetica Neue Bold", fixedSize: 11))
                            Spacer()
                        }
                    }
                } else {
                    VStack(spacing: 2) {
                        Image("\(image)_iPod").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(width: image == "Songs" ? 20 : image == "Artists" ? 37.5 : 30, height: 30).overlay(
                            LinearGradient(gradient: Gradient(colors: [Color(red: 157/255, green: 157/255, blue: 157/255), Color(red: 89/255, green: 89/255, blue: 89/255)]), startPoint: .top, endPoint: .bottom)
                        ).mask(Image("\(image)_iPod").renderingMode(.template).resizable().aspectRatio(contentMode: .fit).frame(width: image == "Songs" ? 20 : image == "Artists" ? 37.5 : 30, height: 30)).shadow(color: Color.black.opacity(0.75), radius: 0, x: 0, y: -1)
                        HStack {
                            Spacer()
                            Text(image).foregroundColor(Color(red: 168/255, green: 168/255, blue: 168/255)).font(.custom("Helvetica Neue Bold", fixedSize: 11))
                            Spacer()
                        }
                    }
                }
            }
        }
    }
}



struct alpha_list_header: View {
    var letter: String
    var body: some View {
        ZStack {
            Rectangle().fill(LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 148/255, green: 162/255, blue: 173/255), location: 0), .init(color: Color(red: 177/255, green: 186/255, blue: 195/255), location: 0.52), .init(color: Color(red: 183/255, green: 192/255, blue: 199/255), location: 0.93), .init(color: Color(red: 148/255, green: 158/255, blue: 166/255), location: 0.97), .init(color: Color(red: 152/255, green: 163/255, blue: 170/255), location: 1)]), startPoint: .top, endPoint: .bottom)).border_gradient(width: 2.4, edges: [.top], color: LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 176/255, green: 186/255, blue: 194/255), location: 0), .init(color: Color(red: 176/255, green: 186/255, blue: 194/255), location: 0.45), .init(color: Color(red: 165/255, green: 177/255, blue: 186/255), location: 0.5), .init(color: Color(red: 165/255, green: 177/255, blue: 186/255), location: 1)]), startPoint: .top, endPoint: .bottom)).border_gradient(width: 1.2, edges: [.top], color: LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 122/255, green: 134/255, blue: 142/255), location: 0), .init(color: Color(red: 122/255, green: 134/255, blue: 143/255), location: 0.45), .init(color: Color(red: 140/255, green: 152/255, blue: 160/255), location: 0.5), .init(color: Color(red: 140/255, green: 152/255, blue: 160/255), location: 1)]), startPoint: .top, endPoint: .bottom)).edgesIgnoringSafeArea([.leading, .trailing])
            HStack {
                Text(letter).font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(Color.white).shadow(color: Color(red: 94/255, green: 90/255, blue: 90/255).opacity(0.75), radius: 0, x: 0, y: 1.2).padding(.leading, 12)
                Spacer()
            }
        }.clipped()
    }
}

struct generic_text_list_header: View {
    var letter: String
    var body: some View {
        ZStack {
            Rectangle().fill(LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 148/255, green: 162/255, blue: 173/255), location: 0), .init(color: Color(red: 177/255, green: 186/255, blue: 195/255), location: 0.52), .init(color: Color(red: 183/255, green: 192/255, blue: 199/255), location: 0.93), .init(color: Color(red: 148/255, green: 158/255, blue: 166/255), location: 0.97), .init(color: Color(red: 152/255, green: 163/255, blue: 170/255), location: 1)]), startPoint: .top, endPoint: .bottom)).border_gradient(width: 2.4, edges: [.top], color: LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 176/255, green: 186/255, blue: 194/255), location: 0), .init(color: Color(red: 176/255, green: 186/255, blue: 194/255), location: 0.45), .init(color: Color(red: 165/255, green: 177/255, blue: 186/255), location: 0.5), .init(color: Color(red: 165/255, green: 177/255, blue: 186/255), location: 1)]), startPoint: .top, endPoint: .bottom)).border_gradient(width: 1.2, edges: [.top], color: LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 122/255, green: 134/255, blue: 142/255), location: 0), .init(color: Color(red: 122/255, green: 134/255, blue: 143/255), location: 0.45), .init(color: Color(red: 140/255, green: 152/255, blue: 160/255), location: 0.5), .init(color: Color(red: 140/255, green: 152/255, blue: 160/255), location: 1)]), startPoint: .top, endPoint: .bottom)).edgesIgnoringSafeArea([.leading, .trailing])
            HStack {
                Text(letter).font(.custom("Helvetica Neue Bold", fixedSize: 18)).foregroundColor(Color.white).shadow(color: Color(red: 94/255, green: 90/255, blue: 90/255).opacity(0.75), radius: 0, x: 0, y: 1.2).padding(.leading, 12).textCase(.none)
                Spacer()
            }
        }
    }
}


struct ipod_title_bar : View {
    @ObservedObject var player = iPodPlayer.shared
    @Binding var forward_or_backward: Bool
    @Binding var current_nav_view: String
    @Binding var artists_current_view: String
    @Binding var playlist_current_nav_view: String
    @Binding var selectedTab:String
    @Binding var more_stack: [ipod_more_route]
    var back_artist_title: String = ""
    var title:String
    var body :some View {
        ZStack {
            LinearGradient(gradient: Gradient(stops: [.init(color:Color(red: 180/255, green: 191/255, blue: 205/255), location: 0.0), .init(color:Color(red: 136/255, green: 155/255, blue: 179/255), location: 0.49), .init(color:Color(red: 128/255, green: 149/255, blue: 175/255), location: 0.49), .init(color:Color(red: 110/255, green: 133/255, blue: 162/255), location: 1.0)]), startPoint: .top, endPoint: .bottom).border_bottom(width: 1, edges: [.bottom], color: Color(red: 45/255, green: 48/255, blue: 51/255)).innerShadowBottom(color: Color(red: 230/255, green: 230/255, blue: 230/255), radius: 0.025)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text(title).ps_innerShadow(Color.white, radius: 0, offset: 1, angle: 180.degrees, intensity: 0.07).font(.custom("Helvetica Neue Bold", fixedSize: 22)).shadow(color: Color.black.opacity(0.21), radius: 0, x: 0.0, y: -1).transition(AnyTransition.asymmetric(insertion: .move(edge:forward_or_backward == false ? .trailing : .leading), removal: .move(edge:forward_or_backward == false ? .leading : .trailing)).combined(with: .opacity)).id(title).frame(maxWidth: 180).lineLimit(1)
                    Spacer()
                }
                Spacer()
            }
            if player.nowPlayingItem != nil {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action:{UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil); forward_or_backward = false; withAnimation(.linear(duration: 0.28)){current_nav_view = "Now Playing"};UITableViewCell.appearance().backgroundColor = .clear}) {
                            ZStack {
                                Image("now_playing_icon").resizable().scaledToFit().frame(width:67, height: 40)
                                VStack(alignment: .center, spacing: 0) {
                                    Text("Now").font(.custom("Helvetica Neue Bold", fixedSize: 11)).foregroundColor(.white).shadow(color: Color.black.opacity(0.6), radius: 0, x: 0.0, y: -1).multilineTextAlignment(.center)
                                    Text("Playing").font(.custom("Helvetica Neue Bold", fixedSize: 11)).foregroundColor(.white).shadow(color: Color.black.opacity(0.6), radius: 0, x: 0.0, y: -1).multilineTextAlignment(.center)
                                }.offset(x:-3)
                            }.padding(.trailing, 5.5)
                        }
                    }
                    Spacer()
                }
            }
            if artists_current_view != "Artists", selectedTab == "Artists" {
                VStack {
                    Spacer()
                    HStack {
                        Button(action:{
                            forward_or_backward = true; withAnimation(.linear(duration: 0.28)){artists_current_view = (artists_current_view == "Artist_Albums" ? "Artists" : "Artist_Albums")}
                        }){
                            ZStack {
                                Image(artists_current_view == "Artist_Albums" ? "Button2" : "Button_wp4").resizable().scaledToFit().frame(width:84*(33/34.33783783783784), height: 33)
                                HStack(alignment: .center) {
                                    Text(artists_current_view == "Artist_Albums" ? "Artists" : (back_artist_title == "" ? title : back_artist_title)).foregroundColor(Color.white).font(.custom("Helvetica Neue Bold", fixedSize: 13)).shadow(color: Color.black.opacity(0.45), radius: 0, x: 0, y: -0.6).padding(.leading,5).offset(y:-1.1).offset(x: 1).frame(maxWidth: 75).lineLimit(1)
                                }
                            }.padding(.leading, 5.5)
                        }
                        Spacer()
                    }
                    Spacer()
                }.offset(y:-0.5)
            }
            if playlist_current_nav_view != "Playlists", selectedTab == "Playlists" {
                VStack {
                    Spacer()
                    HStack {
                        Button(action:{
                            forward_or_backward = true; withAnimation(.linear(duration: 0.28)){playlist_current_nav_view = "Playlists"}
                        }){
                            ZStack {
                                Image("Button_wp4").resizable().scaledToFit().frame(width:84*(33/34.33783783783784), height: 33)
                                HStack(alignment: .center) {
                                    Text("Playlists").foregroundColor(Color.white).font(.custom("Helvetica Neue Bold", fixedSize: 13)).shadow(color: Color.black.opacity(0.45), radius: 0, x: 0, y: -0.6).padding(.leading,5).offset(y:-1.1).offset(x: 1).frame(maxWidth: 75).lineLimit(1)
                                }
                            }.padding(.leading, 5.5)
                        }
                        Spacer()
                    }
                    Spacer()
                }.offset(y:-0.5)
            }
            //OldMusic: back button of the More tab
            if more_stack.count != 0, selectedTab == "More" {
                VStack {
                    Spacer()
                    HStack {
                        Button(action:{
                            forward_or_backward = true; withAnimation(.linear(duration: 0.28)){ if more_stack.count != 0 { more_stack.removeLast() } }
                        }){
                            ZStack {
                                Image("Button_wp4").resizable().scaledToFit().frame(width:84*(33/34.33783783783784), height: 33)
                                HStack(alignment: .center) {
                                    Text(more_stack.count >= 2 ? more_stack[more_stack.count - 2].title : "More").foregroundColor(Color.white).font(.custom("Helvetica Neue Bold", fixedSize: 13)).shadow(color: Color.black.opacity(0.45), radius: 0, x: 0, y: -0.6).padding(.leading,5).offset(y:-1.1).offset(x: 1).frame(maxWidth: 75).lineLimit(1)
                                }
                            }.padding(.leading, 5.5)
                        }
                        Spacer()
                    }
                    Spacer()
                }.offset(y:-0.5)
            }

        }
    }
}

struct now_playing_title_bar : View {
    @Binding var forward_or_backward: Bool
    @Binding var current_nav_view: String
    @Binding var artist: String?
    @Binding var song: String?
    @Binding var album: String?
    @Binding var album_image: UIImage
    @Binding var switch_to_tracks: Bool
    @Binding var show_back_tracks: Bool
    @Binding var hide_album_image: Bool
    @State var momentary_disable: Bool = false
    @Binding var flipper_background: Bool
    var title:String
    var body :some View {
        ZStack {
            LinearGradient(gradient: Gradient(stops: [.init(color: Color(red: 0, green: 0, blue: 0), location: 0), .init(color: Color(red: 84/255, green: 84/255, blue: 84/255), location: 0.02), .init(color: Color(red: 59/255, green: 59/255, blue: 59/255), location: 0.04), .init(color: Color(red: 29/255, green: 29/255, blue: 29/255), location: 0.5), .init(color: Color(red: 7.5/255, green: 7.5/255, blue: 7.5/255), location: 0.51), .init(color: Color(red: 7.5/255, green: 7.5/255, blue: 7.5/255), location: 1)]), startPoint: .top, endPoint: .bottom).border_bottom(width: 1, edges: [.bottom], color: Color(red: 45/255, green: 48/255, blue: 51/255)).innerShadowBottom(color: Color(red: 230/255, green: 230/255, blue: 230/255), radius: 0.025)
            HStack {
                Button(action:{forward_or_backward = true; withAnimation(.linear(duration: 0.28)){current_nav_view = "Main"}}) {
                    ZStack {
                        Image("button_back_ipod2").resizable().scaledToFit().frame(width:102/(69/34.33783783783784), height: 34.33783783783784)
                        Image("UINavigationBarBackArrow").resizable().scaledToFit().frame(width:23, height: 19).padding(.leading, 2)
                    }.padding(.leading, 8)
                }
                Spacer()
                VStack(spacing:0) {
                    Spacer()
                    Text(artist ?? "").font(.custom("Helvetica Neue Bold", fixedSize: 13)).foregroundColor(Color(red: 159/255, green: 159/255, blue: 159/255)).shadow(color: Color.black.opacity(0.8), radius: 0, x: 0.0, y: -1).multilineTextAlignment(.center).lineLimit(1)
                    Text(song ?? "").font(.custom("Helvetica Neue Bold", fixedSize: 13)).foregroundColor(.white).shadow(color: Color.black.opacity(0.8), radius: 0, x: 0.0, y: -1).multilineTextAlignment(.center).lineLimit(1)
                    Text(album ?? "").font(.custom("Helvetica Neue Bold", fixedSize: 13)).foregroundColor(Color(red: 159/255, green: 159/255, blue: 159/255)).shadow(color: Color.black.opacity(0.8), radius: 0, x: 0.0, y: -1).multilineTextAlignment(.center).lineLimit(1)
                    Spacer()
                }.offset(y:-1)
                Spacer()
                ZStack {
                    Button(action:{
                        momentary_disable = true
                        if switch_to_tracks == false { //maybe + 0.1 -> orig 0.5
                            withAnimation(.easeIn(duration: 0.4)){switch_to_tracks.toggle();flipper_background.toggle()}
                            DispatchQueue.main.asyncAfter(deadline:.now()+0.39) { //maybe 0.45
                                withAnimation(.easeOut(duration: 0.4)){show_back_tracks.toggle()}
                            }
                            DispatchQueue.main.asyncAfter(deadline:.now()+0.8) {
                                momentary_disable = false
                                hide_album_image = true
                            }
                        } else {
                            withAnimation(.easeIn(duration: 0.4)){show_back_tracks.toggle()}
                            DispatchQueue.main.asyncAfter(deadline:.now()) {
                                hide_album_image = false
                            }
                            DispatchQueue.main.asyncAfter(deadline:.now()+0.39) { //maybe 0.45
                                withAnimation(.easeOut(duration: 0.4)){switch_to_tracks.toggle()}
                            }
                            DispatchQueue.main.asyncAfter(deadline:.now()+0.48) {
                                withAnimation(.easeIn(duration: 0.4)){flipper_background.toggle()}
                            }
                            DispatchQueue.main.asyncAfter(deadline:.now()+0.8) {
                                momentary_disable = false
                            }
                        }
                    }) {
                        ZStack {
                            HStack {
                                Spacer()
                                Image("NowPlayingFlipperBackground").resizable().scaledToFit().frame(width:37.5, height: 37.5).clipped().opacity(flipper_background == false ? 0 : 1).offset(x: (37.5-34.33783783783784)/2, y: -(37.5-34.33783783783784)/12)
                            }
                            HStack {
                                Spacer()
                                Image(uiImage: album_image).resizable().scaledToFit().frame(width:34.33783783783784, height: 34.33783783783784).clipped().rotation3DEffect(.degrees(show_back_tracks == false ? 90 : 0), axis: (x: 0, y:1, z: 0), anchor: UnitPoint(0, 0.5)).offset(x:show_back_tracks == false ? 34.33783783783784/2 : 0).opacity(show_back_tracks == false ? 0.5: 1)
                            }
                            HStack {
                                Spacer()
                                Image("NowPlayingAlbumInfo").resizable().scaledToFit().frame(width:34.33783783783784, height: 34.33783783783784).clipped().rotation3DEffect(.degrees(switch_to_tracks == true ? -90 : 0), axis: (x: 0, y:1, z: 0), anchor: UnitPoint(1, 0.5)).offset(x:switch_to_tracks == true ? -34.33783783783784/2 : 0)
                            }
                        }
                    }.disabled(momentary_disable)
                }.frame(width:102/(69/34.33783783783784)).padding(.trailing, 8) //I, personally, didn't want to do it this way...but this is how Apple did it. Why???
            }
        }
    }
}




func isDigit(c: Character) -> Bool {
    return "0" <= c && c <= "9"
}

func sortedLettersFirst(lhs: String, rhs: String) -> Bool {
    for (lc, rc) in zip(lhs, rhs) {
        if lc == rc { continue }

        if isDigit(c: lc) && !isDigit(c: rc) {
            return false
        }
        if !isDigit(c: lc) && isDigit(c: rc) {
            return true
        }
        return lc < rc
    }
    return lhs.count < rhs.count
}
