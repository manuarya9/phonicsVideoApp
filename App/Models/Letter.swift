import Foundation

struct Example: Decodable, Hashable, Identifiable {
    let word: String
    let image: String
    let audio: String

    var id: String { word }
}

struct Letter: Hashable, Identifiable {
    let id: String
    let letter: String
    let videoFileName: String
    let examples: [Example]
    let pronunciation: String
    let language: String
    let languageDisplayName: String
    let script: String
    let sourceIndex: Int

    var videoRelativePath: String {
        "assets/videos/\(language)/\(videoFileName)"
    }
}

struct LanguagePack: Identifiable, Hashable {
    let id: String
    let displayName: String
    let letters: [Letter]
}

struct LetterPayload: Decodable {
    let letter: String
    let pronunciation: String
    let script: String
    let exampleWords: [Example]
    let avatarImage: String

    enum CodingKeys: String, CodingKey {
        case letter
        case pronunciation
        case script
        case exampleWords = "example_words"
        case avatarImage = "avatar_image"
    }
}

enum ResourcePath {
    static func slug(from input: String) -> String {
        let scalars = input.unicodeScalars.map { scalar -> String in
            if CharacterSet.alphanumerics.contains(scalar) {
                return String(scalar)
            }
            return "_"
        }

        let collapsed = scalars.joined()
            .replacingOccurrences(of: "__+", with: "_", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "_"))

        return collapsed.isEmpty ? "item" : collapsed
    }
}

