import Foundation
import MediaPlayer

/// One lettered section of the Songs / Artists lists ("A", "B", ... "#").
struct MusicSection<Element> {
    let letter: String
    let items: [Element]

    /// Index letters in display order (the magnifying glass is handled separately).
    static var letters: [String] { MusicIndex.letters }

    /// Groups `elements` using MPMediaQuery's own sections when they match the
    /// result set (same grouping as the Music app, "The Beatles" under B),
    /// otherwise falls back to the first letter of `title`.
    static func build(
        _ elements: [Element],
        querySections: [MPMediaQuerySection]?,
        title: (Element) -> String?
    ) -> [MusicSection<Element>] {
        var buckets: [String: [Element]] = [:]
        var usedQuerySections = false

        if let querySections, !querySections.isEmpty {
            let total = querySections.reduce(0) { $0 + $1.range.length }
            if total == elements.count {
                usedQuerySections = true
                for section in querySections {
                    let lower = section.range.location
                    let upper = section.range.location + section.range.length
                    guard lower >= 0, lower <= upper, upper <= elements.count else { continue }
                    buckets[MusicIndex.letter(for: section.title), default: []]
                        .append(contentsOf: elements[lower..<upper])
                }
            }
        }

        if !usedQuerySections {
            for element in elements {
                buckets[MusicIndex.letter(for: title(element)), default: []].append(element)
            }
        }

        return MusicIndex.letters.compactMap { letter in
            guard let items = buckets[letter], !items.isEmpty else { return nil }
            return MusicSection(letter: letter, items: items)
        }
    }
}

enum MusicIndex {
    /// The entry of the index bar that scrolls back to the search field.
    static let search = "Search"

    static let letters: [String] = [
        "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
        "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "#"
    ]

    /// Index bar entries, top to bottom.
    static let bar: [String] = [search] + letters

    static func letter(for raw: String?) -> String {
        guard let first = raw?.trimmingCharacters(in: .whitespacesAndNewlines).first else { return "#" }
        let folded = String(first)
            .folding(options: [.diacriticInsensitive, .caseInsensitive, .widthInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .uppercased()
        return (folded != "#" && letters.contains(folded)) ? folded : "#"
    }
}
