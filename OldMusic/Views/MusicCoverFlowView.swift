import SwiftUI
import UIKit
import MediaPlayer

/// Cover Flow (OldOS `CoverFlowView`): shown when the device is turned
/// sideways. The interface stays portrait, so the view rotates itself.
struct MusicCoverFlowView: View {
    @EnvironmentObject private var library: MusicLibrary
    @EnvironmentObject private var navigator: MusicNavigator
    @ObservedObject private var player = MusicPlayer.shared

    @State private var currentAlbum = MPMediaItemCollection(items: [])
    @State private var showingBack = false

    var body: some View {
        GeometryReader { geometry in
            // Landscape canvas: width and height swapped.
            let canvas = CGSize(width: geometry.size.height, height: geometry.size.width)

            ZStack {
                Color.black

                if library.albums.isEmpty {
                    Text("No Albums")
                        .font(OldOSFont.bold(20))
                        .foregroundColor(.oldOS(159, 159, 159))
                        .frame(width: canvas.width, height: canvas.height)
                } else {
                    MusicCoverFlowCarousel(
                        size: canvas,
                        albums: library.albums,
                        currentAlbum: $currentAlbum,
                        showingBack: $showingBack
                    )
                    .frame(width: canvas.width, height: canvas.height)
                }

                VStack {
                    Spacer()
                    HStack(alignment: .bottom) {
                        Button {
                            player.togglePlayPause()
                        } label: {
                            MusicCoverFlowPlayButton(isPlaying: player.isPlaying)
                        }
                        .buttonStyle(.plain)
                        .padding(.leading, 8)

                        Spacer()

                        VStack {
                            Text(currentAlbum.representativeItem?.albumArtist ?? currentAlbum.representativeItem?.artist ?? "Unknown")
                            Text(currentAlbum.representativeItem?.albumTitle ?? "Unknown")
                        }
                        .font(OldOSFont.bold(15))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .isHidden(showingBack || library.albums.isEmpty)

                        Spacer()

                        MusicCoverFlowInfoIcon()
                            .padding(.trailing, 8)
                    }
                    .padding(.bottom, 10)
                }
                .frame(width: canvas.width, height: canvas.height)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .rotationEffect(.degrees(navigator.coverFlowOrientation == .landscapeRight ? -90 : 90))
        .onAppear {
            let nowPlayingAlbum = player.nowPlayingItem?.albumPersistentID
            let index = library.albums.firstIndex { $0.representativeItem?.albumPersistentID == nowPlayingAlbum } ?? 0
            currentAlbum = library.albums[optional: index] ?? MPMediaItemCollection(items: [])
        }
    }
}

// MARK: - Bottom glyphs

/// The original referenced "CoverFlowPlayIndicator" / "CoverFlowInfoIcon"
/// images that were never part of the OldOS catalog; they are drawn here.
struct MusicCoverFlowPlayButton: View {
    let isPlaying: Bool

    var body: some View {
        ZStack {
            Circle().fill(Color.black.opacity(0.45)).frame(width: 30, height: 30)
            Circle().stroke(Color.white.opacity(0.85), lineWidth: 1.5).frame(width: 30, height: 30)
            Image(isPlaying ? "pause" : "play")
                .resizable()
                .scaledToFit()
                .frame(width: 12, height: 12)
                .offset(x: isPlaying ? 0 : 1)
        }
        .shadow(color: Color.black.opacity(0.6), radius: 1, x: 0, y: 1)
    }
}

struct MusicCoverFlowInfoIcon: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(oldOS: [.oldOS(120, 120, 120), .oldOS(40, 40, 40)]))
                .frame(width: 22, height: 22)
            Circle().stroke(Color.white.opacity(0.9), lineWidth: 1.5).frame(width: 22, height: 22)
            Text("i")
                .font(.custom("Georgia-BoldItalic", size: 15))
                .foregroundColor(.white)
        }
        .shadow(color: Color.black.opacity(0.6), radius: 1, x: 0, y: 1)
    }
}

// MARK: - Album back side

/// OldOS `coverflow_selected_item`: the album's tracks on the flipped cover.
struct MusicCoverFlowAlbumBack: View {
    @ObservedObject private var player = MusicPlayer.shared
    let album: MPMediaItemCollection

    @State private var tapLocked = false

    var body: some View {
        let tracks = MusicLibrary.sortedTracks(album.items)
        GeometryReader { geometry in
            ZStack {
                Image("NowPlayingTableBackground")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()

                VStack(spacing: 0) {
                    ZStack {
                        LinearGradient(oldOS: [.oldOS(171, 183, 209), .oldOS(120, 144, 188)])
                        HStack(spacing: 0) {
                            VStack(alignment: .leading) {
                                Text(album.representativeItem?.albumArtist ?? album.representativeItem?.artist ?? "Unknown")
                                    .font(OldOSFont.bold(13))
                                Text(album.representativeItem?.albumTitle ?? "Unknown")
                                    .font(OldOSFont.bold(20))
                            }
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .padding(.horizontal, 5)
                            Spacer()
                            Image(uiImage: album.oldMusicArtwork(120))
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipped()
                        }
                    }
                    .frame(width: geometry.size.width, height: 50)

                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(tracks.enumerated()), id: \.element.persistentID) { index, track in
                                Button {
                                    guard !tapLocked else { return }
                                    tapLocked = true
                                    MusicPlayer.shared.play(tracks, startingAt: track)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { tapLocked = false }
                                } label: {
                                    MusicDarkTrackRow(track: track, index: index, isPlaying: player.isNowPlaying(track))
                                }
                                .buttonStyle(.plain)
                                .frame(height: 44)
                            }
                        }
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .oldOSBorder(width: 1, edges: [.top, .leading, .trailing], color: .white)
        }
    }
}

/// Front of each cover: artwork plus its reflection (OldOS `ios_14_image_hosting`).
struct MusicCoverFlowItem: View {
    let image: UIImage

    var body: some View {
        ZStack {
            Image(uiImage: image)
                .resizable()
                .frame(width: 250, height: 250)
                .opacity(0.7)
                .rotationEffect(.degrees(-180))
                .offset(y: 250)
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            Image(uiImage: image)
                .resizable()
                .frame(width: 250, height: 250)
                .oldOSInnerShadowBottomWithOffset(color: Color.black.opacity(0.9), radius: 0.0125, offset: 250)
        }
        .frame(height: 250)
    }
}

// MARK: - Carousel

/// Single-touch recogniser used to flip the cover back.
final class MusicSingleTouchRecognizer: UIGestureRecognizer {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        if state == .possible { state = .recognized }
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        state = .failed
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        state = .failed
    }
}

/// iCarousel in `coverFlow2` mode (OldOS `CoverFlow_Sub`). Tapping the
/// centred cover flips it to the album's track list; tapping anywhere flips back.
struct MusicCoverFlowCarousel: UIViewControllerRepresentable {
    let size: CGSize
    let albums: [MPMediaItemCollection]
    @Binding var currentAlbum: MPMediaItemCollection
    @Binding var showingBack: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(albums: albums, currentAlbum: $currentAlbum, showingBack: $showingBack)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let coordinator = context.coordinator
        let controller = UIViewController()
        controller.view.frame = CGRect(origin: .zero, size: size)
        controller.view.backgroundColor = .black

        let container = UIView(frame: CGRect(origin: .zero, size: size))
        controller.view.addSubview(container)
        coordinator.container = container

        let carousel = iCarousel(frame: CGRect(origin: .zero, size: size))
        carousel.type = .coverFlow2
        carousel.backgroundColor = .clear
        carousel.dataSource = coordinator
        carousel.delegate = coordinator
        container.addSubview(carousel)
        coordinator.carousel = carousel

        let back = UIHostingController(rootView: MusicCoverFlowAlbumBack(album: currentAlbum))
        back.view.frame = CGRect(x: 0, y: 0, width: size.width * 0.5, height: max(size.height - 24, 0))
        back.view.center = CGPoint(x: size.width / 2, y: size.height / 2 + 12)
        back.view.backgroundColor = .clear
        back.view.isHidden = true
        back.view.alpha = 0
        container.addSubview(back.view)
        coordinator.back = back

        let catcher = UIView(frame: CGRect(origin: .zero, size: size))
        catcher.addGestureRecognizer(
            MusicSingleTouchRecognizer(target: coordinator, action: #selector(Coordinator.flipBack))
        )
        coordinator.tapCatcher = catcher

        let nowPlayingAlbum = MusicPlayer.shared.system.nowPlayingItem?.albumPersistentID
        if let index = albums.firstIndex(where: { $0.representativeItem?.albumPersistentID == nowPlayingAlbum }) {
            carousel.currentItemIndex = index
        }
        return controller
    }

    func updateUIViewController(_ controller: UIViewController, context: Context) {
        let coordinator = context.coordinator
        if coordinator.albums.count != albums.count {
            coordinator.albums = albums
            coordinator.carousel?.reloadData()
        }
    }

    final class Coordinator: NSObject, iCarouselDataSource, iCarouselDelegate {
        var albums: [MPMediaItemCollection]
        @Binding var currentAlbum: MPMediaItemCollection
        @Binding var showingBack: Bool

        weak var container: UIView?
        weak var carousel: iCarousel?
        var back: UIHostingController<MusicCoverFlowAlbumBack>?
        var tapCatcher: UIView?

        init(albums: [MPMediaItemCollection], currentAlbum: Binding<MPMediaItemCollection>, showingBack: Binding<Bool>) {
            self.albums = albums
            _currentAlbum = currentAlbum
            _showingBack = showingBack
        }

        private var landscapeRight: Bool {
            UIDevice.current.orientation == .landscapeRight
        }

        func numberOfItems(in carousel: iCarousel) -> Int {
            albums.count
        }

        func carousel(_ carousel: iCarousel, viewForItemAt index: Int, reusing view: UIView?) -> UIView {
            let placeholder = UIImage(named: "noartplaceholder") ?? UIImage()
            let image = albums[optional: index]?.representativeItem?.artwork?.image(at: CGSize(width: 250, height: 250)) ?? placeholder
            let host = UIHostingController(rootView: MusicCoverFlowItem(image: image))
            host.view.frame = CGRect(x: 0, y: 0, width: 250, height: 250)
            host.view.backgroundColor = .clear
            return host.view
        }

        func carouselCurrentItemIndexDidChange(_ carousel: iCarousel) {
            guard let album = albums[optional: carousel.currentItemIndex] else { return }
            currentAlbum = album
        }

        func carousel(_ carousel: iCarousel, didSelectItemAt index: Int) {
            guard let album = albums[optional: index], let back, let container else { return }
            currentAlbum = album
            back.rootView = MusicCoverFlowAlbumBack(album: album)

            if let catcher = tapCatcher {
                container.insertSubview(catcher, belowSubview: back.view)
            }
            carousel.isUserInteractionEnabled = false
            withAnimation(.linear(duration: 0.1)) { showingBack = true }

            if let itemView = carousel.currentItemView {
                UIView.transition(with: itemView, duration: 1.0, options: [.transitionFlipFromRight, .allowAnimatedContent, .showHideTransitionViews], animations: {
                    itemView.alpha = 0
                    itemView.clipsToBounds = false
                })
            }
            UIView.transition(with: back.view, duration: 1.0, options: [landscapeRight ? .transitionFlipFromBottom : .transitionFlipFromTop, .showHideTransitionViews], animations: {
                back.view.isHidden = false
                back.view.alpha = 1
            })
        }

        @objc func flipBack() {
            tapCatcher?.removeFromSuperview()
            if let back {
                UIView.transition(with: back.view, duration: 1.0, options: [landscapeRight ? .transitionFlipFromTop : .transitionFlipFromBottom, .showHideTransitionViews], animations: {
                    back.view.isHidden = true
                    back.view.alpha = 0
                })
            }
            if let itemView = carousel?.currentItemView {
                UIView.transition(with: itemView, duration: 1.0, options: [.allowAnimatedContent, .transitionFlipFromLeft, .showHideTransitionViews], animations: {
                    itemView.clipsToBounds = false
                    itemView.alpha = 1
                })
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
                self?.carousel?.isUserInteractionEnabled = true
                withAnimation(.linear(duration: 0.1)) { self?.showingBack = false }
            }
        }
    }
}
