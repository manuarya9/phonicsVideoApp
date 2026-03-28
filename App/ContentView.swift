import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var libraryStore: LibraryStore

    private let columns = [
        GridItem(.adaptive(minimum: 116), spacing: 18)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.98, green: 0.95, blue: 0.83),
                        Color(red: 0.97, green: 0.84, blue: 0.71),
                        Color(red: 0.91, green: 0.93, blue: 0.98)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                if libraryStore.languages.isEmpty {
                    ContentUnavailableView(
                        "No Language Data",
                        systemImage: "character.book.closed",
                        description: Text("Add JSON files to generator/data and bundle them with the app.")
                    )
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            header
                            controls
                            letterGrid
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Phonics Studio")
            .sheet(item: $libraryStore.selectedLetter) { letter in
                LetterDetailView(letter: letter)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tap a letter to hear it, watch it, and practice example words.")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.primary)

            if let selectedLanguage = libraryStore.selectedLanguage {
                Text("\(selectedLanguage.displayName) • \(libraryStore.displayedLetters.count) lessons")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 14) {
            Picker("Language", selection: $libraryStore.selectedLanguageCode) {
                ForEach(libraryStore.languages) { language in
                    Text(language.displayName).tag(language.id)
                }
            }
            .pickerStyle(.menu)
            .accessibilityHint("Choose which alphabet to explore.")

            Toggle(isOn: $libraryStore.isScrambled) {
                Text("Scrambled Order")
                    .font(.headline)
            }
            .toggleStyle(.switch)

            if libraryStore.isScrambled {
                Button("Shuffle Again") {
                    libraryStore.refreshShuffle()
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.85, green: 0.41, blue: 0.19))
            }
        }
        .padding(18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var letterGrid: some View {
        LazyVGrid(columns: columns, spacing: 18) {
            ForEach(libraryStore.displayedLetters) { letter in
                Button {
                    libraryStore.selectedLetter = letter
                } label: {
                    LetterTileView(letter: letter)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(letter.letter), \(letter.pronunciation)")
                .accessibilityHint("Opens the lesson for this letter.")
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(LibraryStore())
}
