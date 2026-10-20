import SwiftUI
import MediaPlayer
import AVKit

/// Videos tab. Shows the original "No Videos" screen when the library has no
/// videos, otherwise lists them and plays them full screen.
struct MusicVideosView: View {
    @Environment(\.oldMusicTheme) private var theme
    @EnvironmentObject private var library: MusicLibrary
    @EnvironmentObject private var navigator: MusicNavigator

    @State private var playing: MusicVideoLink?

    var body: some View {
        Group {
            if library.videos.isEmpty {
                noVideos
            } else {
                List {
                    ForEach(Array(library.videos.enumerated()), id: \.offset) { _, video in
                        Button {
                            play(video)
                        } label: {
                            MusicArtworkRow(
                                image: video.oldMusicArtwork(120),
                                title: video.title ?? "---",
                                subtitle: "\(oldMusicFormatTime(video.playbackDuration)) - \(video.artist ?? "---")"
                            )
                        }
                        .musicRow(minHeight: 60)
                    }
                }
                .musicListStyle()
            }
        }
        .fullScreenCover(item: $playing) { link in
            MusicVideoPlayerScreen(url: link.url) {
                playing = nil
            }
        }
    }

    private func play(_ video: MPMediaItem) {
        if let url = video.assetURL {
            playing = MusicVideoLink(url: url)
        } else {
            MusicPlayer.shared.play(library.videos, startingAt: video)
            navigator.showNowPlaying()
        }
    }

    /// OldOS `ipod_videos`.
    private var noVideos: some View {
        ZStack {
            theme.listBackground
            VStack {
                Image("no_videos_icon")
                    .resizable()
                    .scaledToFit()
                    .padding(.horizontal, 70)
                    .frame(maxWidth: 320)
                    .opacity(theme.isDark ? 0.8 : 1)
                Spacer().frame(height: 35)
                Text("No Videos")
                    .font(OldOSFont.bold(20))
                    .foregroundColor(theme.emptyText)
                Spacer().frame(height: 20)
                HStack(spacing: 5) {
                    Text("You can download videos from iTunes.")
                        .font(OldOSFont.bold(14))
                        .foregroundColor(theme.emptyText)
                    ZStack {
                        Circle().fill(theme.emptyArrowCircle).frame(width: 14, height: 14)
                        MusicArrowShape().fill(Color.white).frame(width: 7.5, height: 7.5)
                    }
                }
            }
        }
    }
}

/// OldOS `Arrow` ("I can't believe I am doing this.").
struct MusicArrowShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.width / 2, y: 0))
        path.addLine(to: CGPoint(x: rect.width / 2, y: rect.height / 3))
        path.addLine(to: CGPoint(x: 0, y: rect.height / 3))
        path.addLine(to: CGPoint(x: 0, y: rect.height / 3 * 2))
        path.addLine(to: CGPoint(x: rect.width / 2, y: rect.height / 3 * 2))
        path.addLine(to: CGPoint(x: rect.width / 2, y: rect.height))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height / 2))
        path.closeSubpath()
        return path
    }
}

struct MusicVideoLink: Identifiable {
    let id = UUID()
    let url: URL
}

private struct MusicVideoPlayerScreen: View {
    let url: URL
    let onDone: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()
            MusicVideoPlayer(url: url).ignoresSafeArea()
            Button(action: onDone) {
                Text("Done")
                    .font(OldOSFont.bold(13))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 5).fill(Color.black.opacity(0.6)))
            }
            .padding(.leading, 12)
            .padding(.top, 8)
        }
    }
}

private struct MusicVideoPlayer: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        let player = AVPlayer(url: url)
        controller.player = player
        player.play()
        return controller
    }

    func updateUIViewController(_ controller: AVPlayerViewController, context: Context) {}

    static func dismantleUIViewController(_ controller: AVPlayerViewController, coordinator: ()) {
        controller.player?.pause()
    }
}
