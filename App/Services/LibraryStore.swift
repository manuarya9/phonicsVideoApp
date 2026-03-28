import Foundation

@MainActor
final class LibraryStore: ObservableObject {
    @Published private(set) var languages: [LanguagePack] = []
    @Published var selectedLanguageCode: String = "" {
        didSet {
            guard isScrambled, oldValue != selectedLanguageCode else { return }
            refreshShuffle()
        }
    }
    @Published var isScrambled: Bool = false {
        didSet {
            guard isScrambled, oldValue != isScrambled else { return }
            refreshShuffle()
        }
    }
    @Published var selectedLetter: Letter?

    private var shuffledLettersByLanguage: [String: [Letter]] = [:]

    init() {
        loadLanguages()
    }

    var selectedLanguage: LanguagePack? {
        languages.first(where: { $0.id == selectedLanguageCode }) ?? languages.first
    }

    var displayedLetters: [Letter] {
        guard let selectedLanguage else { return [] }
        if isScrambled {
            return shuffledLettersByLanguage[selectedLanguage.id] ?? selectedLanguage.letters
        }
        return selectedLanguage.letters.sorted(by: { $0.sourceIndex < $1.sourceIndex })
    }

    func refreshShuffle() {
        guard let selectedLanguage else { return }
        shuffledLettersByLanguage[selectedLanguage.id] = selectedLanguage.letters.shuffled()
    }

    private func loadLanguages() {
        let decoder = JSONDecoder()
        let urls = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: "data") ?? []

        let loadedLanguages = urls.compactMap { url -> LanguagePack? in
            guard
                let data = try? Data(contentsOf: url),
                let payloads = try? decoder.decode([LetterPayload].self, from: data)
            else {
                return nil
            }

            let languageCode = url.deletingPathExtension().lastPathComponent
            let displayName = Locale.current.localizedString(forLanguageCode: languageCode)?
                .localizedCapitalized ?? languageCode.uppercased()

            let letters = payloads.enumerated().map { index, payload in
                Letter(
                    id: "\(languageCode)-\(payload.letter)",
                    letter: payload.letter,
                    videoFileName: "\(ResourcePath.slug(from: payload.letter)).mp4",
                    examples: payload.exampleWords,
                    pronunciation: payload.pronunciation,
                    language: languageCode,
                    languageDisplayName: displayName,
                    script: payload.script,
                    sourceIndex: index
                )
            }

            return LanguagePack(id: languageCode, displayName: displayName, letters: letters)
        }
        .sorted(by: { $0.displayName < $1.displayName })

        languages = loadedLanguages
        if selectedLanguageCode.isEmpty {
            selectedLanguageCode = loadedLanguages.first?.id ?? ""
        }
    }
}
