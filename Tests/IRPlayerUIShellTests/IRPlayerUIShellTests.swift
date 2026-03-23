import Foundation
import Testing
@testable import IRPlayerUIShell

@Test func playlistState_SelectNextPreviousAndBounds() async throws {
    let state = IRPlaylistState()
    let urls = [
        URL(string: "https://example.com/0.mp4")!,
        URL(string: "https://example.com/1.mp4")!,
        URL(string: "https://example.com/2.mp4")!
    ]

    state.setURLs(urls)
    #expect(state.currentIndex == 0)
    #expect(state.isLast == false)

    #expect(state.select(index: 1) == urls[1])
    #expect(state.currentIndex == 1)
    #expect(state.isLast == false)

    #expect(state.next() == urls[2])
    #expect(state.currentIndex == 2)
    #expect(state.isLast == true)

    #expect(state.next() == nil)
    #expect(state.currentIndex == 2)
    #expect(state.isLast == true)

    #expect(state.previous() == urls[1])
    #expect(state.currentIndex == 1)
    #expect(state.isLast == false)

    #expect(state.select(index: -1) == nil)
    #expect(state.currentIndex == 1)
}

@Test func playlistState_SelectIfMatchedAndReset() async throws {
    let state = IRPlaylistState()
    let urls = [
        URL(string: "https://example.com/a.mp4")!,
        URL(string: "https://example.com/b.mp4")!
    ]

    state.setURLs(urls)
    state.selectIfMatched(url: urls[1])
    #expect(state.currentIndex == 1)
    #expect(state.isLast == true)

    state.selectIfMatched(url: URL(string: "https://example.com/not-found.mp4")!)
    #expect(state.currentIndex == 1)

    state.setURLs([])
    #expect(state.currentIndex == 0)
    #expect(state.isLast == false)
}

@Test func playlistState_ClampIndexWhenURLsShrink() async throws {
    let state = IRPlaylistState()
    let urls = [
        URL(string: "https://example.com/0.mp4")!,
        URL(string: "https://example.com/1.mp4")!,
        URL(string: "https://example.com/2.mp4")!
    ]

    state.setURLs(urls)
    _ = state.select(index: 2)
    #expect(state.currentIndex == 2)
    #expect(state.isLast == true)

    state.setURLs([urls[0], urls[1]])
    #expect(state.currentIndex == 1)
    #expect(state.isLast == true)
}
