import AVFAudio
import Foundation

@MainActor
final class AudioPlaybackController: NSObject, ObservableObject {
    @Published private(set) var activeWord: String?

    private var player: AVAudioPlayer?

    func play(example: Example) {
        guard let url = BundleAssetResolver.url(for: example.audio) else { return }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.play()
            activeWord = example.word
        } catch {
            activeWord = nil
        }
    }

    func stop() {
        player?.stop()
        activeWord = nil
    }
}

