import AVKit
import SwiftUI

struct LetterDetailView: View {
    let letter: Letter

    @StateObject private var audioController = AudioPlaybackController()
    @State private var player: AVPlayer?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    videoSection
                    mouthSection
                    examplesSection
                }
                .padding(20)
            }
            .background(Color(red: 0.98, green: 0.97, blue: 0.94))
            .navigationTitle(letter.letter)
            .navigationBarTitleDisplayMode(.inline)
            .task(id: letter.id) {
                configurePlayer()
            }
            .onDisappear {
                player?.pause()
                audioController.stop()
            }
        }
    }

    private var videoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(letter.letter) • \(letter.pronunciation)")
                .font(.largeTitle.weight(.bold))

            Text(letter.script)
                .font(.body)
                .foregroundStyle(.secondary)

            Group {
                if let player {
                    VideoPlayer(player: player)
                        .frame(minHeight: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                } else {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color.white)
                        .frame(minHeight: 240)
                        .overlay(
                            VStack(spacing: 12) {
                                Image(systemName: "video.slash")
                                    .font(.largeTitle)
                                    .foregroundStyle(.secondary)
                                Text("No generated video bundled yet")
                                    .font(.headline)
                                Text(letter.videoRelativePath)
                                    .font(.footnote.monospaced())
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                        )
                }
            }
            .accessibilityLabel("Lesson video")
        }
    }

    private var mouthSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pronunciation Cue")
                .font(.title2.weight(.semibold))
            MouthIndicatorView()
            Text("Use this as a simple visual timing cue while the avatar models mouth movement.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var examplesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Example Words")
                .font(.title2.weight(.semibold))

            ForEach(letter.examples) { example in
                ExampleWordRow(
                    example: example,
                    isPlaying: audioController.activeWord == example.word
                ) {
                    audioController.play(example: example)
                }
            }
        }
    }

    private func configurePlayer() {
        guard let url = BundleAssetResolver.url(for: letter.videoRelativePath) else {
            player = nil
            return
        }

        let item = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: item)
        player?.play()
    }
}

#Preview {
    LetterDetailView(
        letter: Letter(
            id: "en-A",
            letter: "A",
            videoFileName: "A.mp4",
            examples: [
                Example(word: "apple", image: "assets/images/en/apple.png", audio: "assets/audio/en/apple.mp3")
            ],
            pronunciation: "[ay]",
            language: "en",
            languageDisplayName: "English",
            script: "[calm tone] A is for apple...",
            sourceIndex: 0
        )
    )
}

