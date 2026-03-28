import SwiftUI
import UIKit

struct ExampleWordRow: View {
    let example: Example
    let isPlaying: Bool
    let playAction: () -> Void

    var body: some View {
        Button(action: playAction) {
            HStack(spacing: 16) {
                imageView

                VStack(alignment: .leading, spacing: 4) {
                    Text(example.word)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text("Tap to hear pronunciation")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: isPlaying ? "speaker.wave.3.fill" : "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color(red: 0.85, green: 0.41, blue: 0.19))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.white)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(example.word)
        .accessibilityHint("Plays the pronunciation audio.")
    }

    @ViewBuilder
    private var imageView: some View {
        if
            let url = BundleAssetResolver.url(for: example.image),
            let image = UIImage(contentsOfFile: url.path)
        {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 68, height: 68)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(red: 0.93, green: 0.95, blue: 0.99))
                .frame(width: 68, height: 68)
                .overlay(
                    Image(systemName: "photo")
                        .foregroundStyle(.secondary)
                )
        }
    }
}

#Preview {
    ExampleWordRow(
        example: Example(word: "apple", image: "assets/images/en/apple.png", audio: "assets/audio/en/apple.mp3"),
        isPlaying: false,
        playAction: {}
    )
    .padding()
}

