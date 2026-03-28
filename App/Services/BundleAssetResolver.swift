import Foundation

enum BundleAssetResolver {
    static func url(for relativePath: String) -> URL? {
        let normalizedPath = relativePath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let path = normalizedPath as NSString
        let subdirectory = path.deletingLastPathComponent
        let fileName = path.lastPathComponent as NSString
        let resourceName = fileName.deletingPathExtension
        let resourceExtension = fileName.pathExtension

        return Bundle.main.url(
            forResource: resourceName,
            withExtension: resourceExtension.isEmpty ? nil : resourceExtension,
            subdirectory: subdirectory == "." ? nil : subdirectory
        )
    }
}

