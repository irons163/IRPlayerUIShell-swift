//
//  IRPlayerManaging.swift
//  IRPlayerUIShell
//
//  Created by irons on 2025/10/27.
//

import UIKit

public enum IRPlaybackState {
    case unknown
    case none
    case buffering
    case readyToPlay
    case playing
    case paused
    case suspend
    case finished
    case failed(error: Error)
}

extension IRPlaybackState: Equatable {
    public static func == (lhs: IRPlaybackState, rhs: IRPlaybackState) -> Bool {
        switch (lhs, rhs) {
        case (.unknown, .unknown),
             (.none, .none),
             (.buffering, .buffering),
             (.readyToPlay, .readyToPlay),
             (.playing, .playing),
             (.paused, .paused),
             (.suspend, .suspend),
             (.finished, .finished):
            return true
        case (.failed, .failed):
            return true      // 忽略實際 error
        default:
            return false
        }
    }
}

public enum IRViewGravity: Int {
    case resize
    case aspect
    case aspectFill
}

public protocol IRPlayerManaging: AnyObject {

    var contentURL: URL? { get }
    // Rendering
    var view: UIView? { get }
    var gravityMode: IRViewGravity { get set }

    // State / timing
    var playbackState: IRPlaybackState { get }
    var progress: TimeInterval { get }
    var duration: TimeInterval { get }
    var playableBufferInterval: TimeInterval { get }

    // Playback controls
    func play()
    func pause()
    func replaceVideoWithURL(contentURL: URL?)

    func seekToTime(time: TimeInterval, completeHandler: ((Bool) -> Void)?)

    func playerManagerCallback()
}
