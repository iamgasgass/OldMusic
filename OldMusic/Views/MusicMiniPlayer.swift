import SwiftUI
import MediaPlayer

/// The bottom sheet's collapsed state: a 54pt strip of iOS 6 black glass
/// sitting on the tab bar, like the modern Music mini player but drawn with
/// the OldOS chrome (black tab-bar glass, glossy blue progress line from the
/// OldSafari address bar, the original transport artwork).
///
/// Tap or drag up → opens Now Playing as a sheet. Swipe left / right → next /
/// previous song. Long press → Up Next drop-down.
struct MusicMiniPlayer: View {
    @Environment(\.oldMusicTheme) private var theme
    @ObservedObject private var player = MusicPlayer.shared
    let onOpen: () -> Void
    let onLongPress: () -> Void

    @State private var progress: Double = 0
    @State private var dragX: CGFloat = 0
    @State private var didLongPress = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    static let height: CGFloat = 54

    var body: some View {
        if let item = player.nowPlayingItem {
            content(item)
                .onAppear(perform: refreshProgress)
                .onReceive(timer) { _ in refreshProgress() }
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private func content(_ item: MPMediaItem) -> some View {
        ZStack(alignment: .top) {
            // Black glass (OldOS tab bar) with the top hairline highlight.
            LinearGradient(oldOS: OldMusicBlackChrome.barGradient)
                .opacity(0.97)
                .oldOSInnerShadowBottom(color: Color.white.opacity(0.35), radius: 0.06)

            HStack(spacing: 10) {
                Image(uiImage: item.oldMusicArtwork(120))
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipped()
                    .overlay(Rectangle().stroke(Color.white.opacity(0.25), lineWidth: 0.5))
                    .shadow(color: Color.black.opacity(0.8), radius: 1.5, x: 0, y: 1)

                VStack(alignment: .leading, spacing: 1) {
                    Text(item.title ?? "Unknown Song")
                        .font(OldOSFont.bold(14))
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.8), radius: 0, x: 0, y: -1)
                    Text([item.artist, item.albumTitle].compactMap { $0 }.joined(separator: " — "))
                        .font(OldOSFont.bold(12))
                        .foregroundColor(.oldOS(159, 159, 159))
                        .shadow(color: Color.black.opacity(0.8), radius: 0, x: 0, y: -1)
                }
                .lineLimit(1)
                .offset(x: dragX * 0.35)
                .opacity(Double(1 - min(abs(dragX) / CGFloat(220), CGFloat(0.6))))

                Spacer(minLength: 4)

                Button {
                    OldMusicHaptics.tap()
                    player.togglePlayPause()
                } label: {
                    Image(player.isPlaying ? "pause" : "play")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 21)
                        .frame(width: 40, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button {
                    OldMusicHaptics.tap()
                    player.next()
                } label: {
                    Image("nexttrack")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 26, height: 19)
                        .frame(width: 40, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.leading, 8)
            .padding(.trailing, 6)
            .frame(height: Self.height)

            // Glossy progress line (OldSafari address-bar fill).
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle().fill(Color.black.opacity(0.6))
                    Rectangle()
                        .fill(LinearGradient(oldOS: theme.progressGradient))
                        .frame(width: geometry.size.width * CGFloat(progress))
                }
            }
            .frame(height: 2.5)
        }
        .frame(height: Self.height)
        .oldOSBorder(width: 1, edges: [.top], color: .black)
        .contentShape(Rectangle())
        .onTapGesture {
            if didLongPress {
                didLongPress = false
                return
            }
            onOpen()
        }
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.4).onEnded { _ in
                didLongPress = true
                OldMusicHaptics.press()
                onLongPress()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { didLongPress = false }
            }
        )
        .gesture(
            DragGesture(minimumDistance: 12)
                .onChanged { value in
                    if abs(value.translation.width) > abs(value.translation.height) {
                        dragX = value.translation.width
                    }
                }
                .onEnded { value in
                    let dx = value.translation.width
                    let dy = value.translation.height
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { dragX = 0 }
                    if dy < -30, abs(dy) > abs(dx) {
                        onOpen()
                    } else if dx < -60 {
                        OldMusicHaptics.tap()
                        player.next()
                    } else if dx > 60 {
                        OldMusicHaptics.tap()
                        player.previous()
                    }
                }
        )
    }

    private func refreshProgress() {
        let duration = player.currentDuration
        progress = duration > 0 ? min(max(player.currentTime / duration, 0), 1) : 0
    }
}
