//
//  IRPlaylistState.swift
//  IRPlayerUIShell
//
//  Created by Codex on 2026/3/23.
//

import Foundation

final class IRPlaylistState {
    private(set) var urls: [URL] = []
    private(set) var currentIndex: Int = 0

    var isLast: Bool {
        guard !urls.isEmpty else { return false }
        return currentIndex >= urls.count - 1
    }

    func setURLs(_ newURLs: [URL]?) {
        urls = newURLs ?? []

        guard !urls.isEmpty else {
            currentIndex = 0
            return
        }

        currentIndex = min(max(currentIndex, 0), urls.count - 1)
    }

    func select(index: Int) -> URL? {
        guard urls.indices.contains(index) else { return nil }
        currentIndex = index
        return urls[index]
    }

    func selectIfMatched(url: URL?) {
        guard let url else { return }
        guard let matchedIndex = urls.firstIndex(of: url) else { return }
        currentIndex = matchedIndex
    }

    func next() -> URL? {
        select(index: currentIndex + 1)
    }

    func previous() -> URL? {
        select(index: currentIndex - 1)
    }
}
