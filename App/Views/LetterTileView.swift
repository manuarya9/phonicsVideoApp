import SwiftUI

struct LetterTileView: View {
    let letter: Letter

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(letter.letter)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.23, green: 0.19, blue: 0.36))

            Text(letter.pronunciation)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color(red: 0.85, green: 0.41, blue: 0.19))

            Text(letter.languageDisplayName)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 138, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.88))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.6), lineWidth: 1.5)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 12)
    }
}

#Preview {
    LetterTileView(
        letter: Letter(
            id: "en-A",
            letter: "A",
            videoFileName: "A.mp4",
            examples: [],
            pronunciation: "[ay]",
            language: "en",
            languageDisplayName: "English",
            script: "",
            sourceIndex: 0
        )
    )
    .padding()
}

