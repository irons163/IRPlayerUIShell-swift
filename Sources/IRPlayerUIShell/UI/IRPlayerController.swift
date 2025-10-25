//
//  IRPlayerController.swift
//  IRPlayerUIShell
//
//  Created by irons on 2025/1/12.
//

import Foundation
import UIKit
import IRPlayerSwift
import AVFAudio

@objc public protocol IRPlayerMediaPlayback {}
public protocol IRPlayerMediaControl {
    /// Current playerController
    var playerController: IRPlayerController? { get set }

    func videoPlayer(_ videoPlayer: IRPlayerController, currentTime: TimeInterval, totalTime: TimeInterval)
    func videoPlayer(_ videoPlayer: IRPlayerController, prepareToPlay assetURL: URL)
    func videoPlayer(_ videoPlayer: IRPlayerController, loadStateChanged state: IRPlayerLoadState)
    /**
     When play failed.
     */
    func videoPlayerPlayFailed(_ videoPlayer: IRPlayerController, error: Any)

    func gestureTriggerCondition(
        _ gestureControl: IRGestureController,
        gestureType: IRGestureType,
        gestureRecognizer: UIGestureRecognizer,
        touch: UITouch
    ) -> Bool
    func gestureSingleTapped(_ gestureControl: IRGestureController)
    func gestureDoubleTapped(_ gestureControl: IRGestureController)
    func gestureBeganPan(_ gestureControl: IRGestureController, panDirection direction: IRPanDirection, panLocation location: IRPanLocation)
    func gestureChangedPan(
        _ gestureControl: IRGestureController,
        panDirection direction: IRPanDirection,
        panLocation location: IRPanLocation,
        withVelocity velocity: CGPoint
    )
    func gestureEndedPan(
        _ gestureControl: IRGestureController,
        panDirection direction: IRPanDirection,
        panLocation location: IRPanLocation
    )
    func gesturePinched(_ gestureControl: IRGestureController, scale: Float)
}

extension IRPlayerMediaControl {
    func videoPlayer(_ videoPlayer: IRPlayerController, currentTime: TimeInterval, totalTime: TimeInterval) { }
    func videoPlayer(_ videoPlayer: IRPlayerController, prepareToPlay assetURL: URL) { }
    func videoPlayer(_ videoPlayer: IRPlayerController, loadStateChanged state: IRPlayerLoadState) { }
    func videoPlayerPlayFailed(_ videoPlayer: IRPlayerController, error: Any) { }
    func gestureTriggerCondition(
        _ gestureControl: IRGestureController,
        gestureType: IRGestureType,
        gestureRecognizer: UIGestureRecognizer,
        touch: UITouch
    ) -> Bool { return false }
    func gestureSingleTapped(_ gestureControl: IRGestureController) { }
    func gestureDoubleTapped(_ gestureControl: IRGestureController) { }
    func gestureBeganPan(_ gestureControl: IRGestureController, panDirection direction: IRPanDirection, panLocation location: IRPanLocation) { }
    func gestureChangedPan(
        _ gestureControl: IRGestureController,
        panDirection direction: IRPanDirection,
        panLocation location: IRPanLocation,
        withVelocity velocity: CGPoint
    ) { }
    func gestureEndedPan(
        _ gestureControl: IRGestureController,
        panDirection direction: IRPanDirection,
        panLocation location: IRPanLocation
    ) { }
    func gesturePinched(_ gestureControl: IRGestureController, scale: Float) { }
}

@objc public enum IRPlayerContainerType: Int {
    case unknown
    case normal
    case float
}

@objc public enum IRPlayerPlaybackState: Int {
    case unknown
    case playing
    case paused
    case stopped
    case failed
}

@objc public enum IRPlayerLoadState: Int {
    case unknown
    case preparing
    case ready
    case automaticallyPlay
    case automaticallyPaused
    case failed
}

@objc public class IRPlayerControllerNotification: NSObject {}

@objc public class IRFloatView: UIView {}

@objc public enum IRDisableGestureTypes: Int {
    case none
    case singleTap
    case doubleTap
}

@objc public enum IRDisablePanMovingDirection: Int {
    case none
    case vertical
    case horizontal
}

@objc public class IRPlayerController: NSObject {

    // MARK: - Properties

    /// The video containerView in normal mode.
    public var containerView: UIView {
        didSet {
            guard containerView != oldValue else { return }
//            if (self.scrollView) {
//                self.scrollView.ir_containerView = containerView;
//            }
            containerView.isUserInteractionEnabled = true
            layoutPlayerSubViews()
        }
    }

    /// The current player manager.
    public var currentPlayerManager: IRPlayerImp {
        didSet {
            guard currentPlayerManager != oldValue else { return }

            if oldValue.state == .readyToPlay {
                oldValue.pause()
                oldValue.view?.removeFromSuperview()
                orientationObserver.removeDeviceOrientationObserver()
                if let view = oldValue.view {
                    gestureControl.removeGesture(to: view)
                }
            }

            handleCurrentPlayerManagerChange()
        }
    }

    /// The custom control view that conforms to `IRPlayerMediaControl`.
    public var controlView: (UIView & IRPlayerMediaControl)? {
        didSet {
            guard controlView !== oldValue else { return }
            controlView?.playerController = self
            layoutPlayerSubViews()
        }
    }

    func playerManagerCallback() {
        currentPlayerManager.registerPlayerNotification(
            target: self,
            stateAction: #selector(stateAction),
            progressAction: #selector(progressAction(_:)),
            playableAction: #selector(playableAction(_:)),
            errorAction: #selector(errorAction(_:))
        )
    }

    /// The notification manager class.
    public lazy var notification: IRPlayerControllerNotification = {
        let notification = IRPlayerControllerNotification()

        //        notification.willResignActive = { [weak self] registrar in
        //            guard let self = self else { return }
        //
        //            if self.isViewControllerDisappear {
        //                return
        //            }
        //            if self.pauseWhenAppResignActive, self.currentPlayerManager.state == .playing {
        //                self.pauseByEvent = true
        //            }
        //            if self.isFullScreen, !self.isLockedScreen {
        //                self.orientationObserver.lockedScreen = true
        //            }
        //
        //            UIApplication.shared.keyWindow?.endEditing(true)
        //
        //            if !self.pauseWhenAppResignActive {
        //                UIApplication.shared.beginReceivingRemoteControlEvents()
        //                try? AVAudioSession.sharedInstance().setActive(true)
        //            }
        //        }
        //
        //        notification.didBecomeActive = { [weak self] registrar in
        //            guard let self = self else { return }
        //
        //            if self.isViewControllerDisappear {
        //                return
        //            }
        //            if self.pauseByEvent {
        //                self.pauseByEvent = false
        //            }
        //            if self.isFullScreen, !self.isLockedScreen {
        //                self.orientationObserver.lockedScreen = false
        //            }
        //        }
        //
        //        notification.oldDeviceUnavailable = { [weak self] registrar in
        //            guard let self = self else { return }
        //
        //            if self.currentPlayerManager.state == .playing {
        //                self.currentPlayerManager.play()
        //            }
        //        }

        return notification
    }()

    /// The current player controller is disappear, not dealloc
    public var viewControllerDisappear: Bool = false

    public var pauseWhenAppResignActive: Bool = false

    public var customAudioSession: Bool = false

    public private(set) var isLastAssetURL: Bool = false

    public private(set) var currentPlayIndex: Int = 0

    // 0...1.0, where 1.0 is maximum brightness. Only supported by main screen.
    @Clamped(0...1) public var brightness: CGFloat = 0 {
        didSet {
            UIScreen.main.brightness = brightness
        }
    }

    /// 0...1.0
    /// Only affects audio volume for the device instance and not for the player.
    /// You can change device volume or player volume as needed,change the player volume you can conform the `IRPlayerMediaPlayback` protocol.
    public var volume: CGFloat {
        get {
            CGFloat(volumeController.currentVolume ?? 0)
        }
        set {
            volumeController.setVolume(Float(newValue))
        }
    }

    private lazy var volumeController = {
        let volumeController = SystemVolumeController(parentView: controlView)
        return volumeController
    }()

    /// The play asset URL.
    public var assetURL: URL? {
        didSet {
            currentPlayerManager.replaceVideoWithURL(contentURL: assetURL)
        }
    }

    public var assetURLs: [URL]?

    /// The gesture types that the player not support.
    public var disableGestureTypes: IRPlayerSwift.IRDisableGestureTypes = .none

    /// An instance of IRPlayerGestureControl.
    public lazy var gestureControl: IRGestureController = {

        let gestureControl = IRGestureController()

        gestureControl.triggerCondition = { [weak self] control, type, gesture, touch in
            guard let self = self else { return false }
            return controlView?.gestureTriggerCondition(control, gestureType: type, gestureRecognizer: gesture, touch: touch) ?? false
        }

        gestureControl.singleTapped = { [weak self] control in
            guard let self = self else { return }
            controlView?.gestureSingleTapped(control)
        }

        gestureControl.doubleTapped = { [weak self] control in
            guard let self = self else { return }
            controlView?.gestureDoubleTapped(control)
        }

        gestureControl.beganPan = { [weak self] control, direction, location in
            guard let self = self else { return }
            controlView?.gestureBeganPan(control, panDirection: direction, panLocation: location)
        }

        gestureControl.changedPan = { [weak self] control, direction, location, velocity in
            guard let self = self else { return }
            controlView?.gestureChangedPan(control, panDirection: direction, panLocation: location, withVelocity: velocity)
        }

        gestureControl.endedPan = { [weak self] control, direction, location in
            guard let self = self else { return }
            controlView?.gestureEndedPan(control, panDirection: direction, panLocation: location)
        }

        gestureControl.pinched = { [weak self] control, scale in
            guard let self = self else { return }
            controlView?.gesturePinched(control, scale: Float(scale))
        }

        return gestureControl
    }()

    /// The pan gesture moving direction that the player not support.
    public var disablePanMovingDirection: IRDisablePanMovingDirection = .none

    /// Lock the screen orientation.
    public var isLockedScreen: Bool = false

    /// The container view type.
    public private(set) var containerType: IRPlayerContainerType

    /// The player's small container view.
    public private(set) var smallFloatView: IRFloatView

    /// Indicates whether the small window is displayed.
    public private(set) var isSmallFloatViewShow: Bool

    /// When the player is playing, it is paused by some event,not by user click to pause.
    /// For example, when the player is playing, application goes into the background or pushed to another viewController
    public var pauseByEvent: Bool = false {
        didSet {
            if pauseByEvent {
                currentPlayerManager.pause()
            } else {
                currentPlayerManager.play()
            }
        }
    }

    /// Indicates whether the screen is locked.
    var lockedScreen: Bool = false {
        didSet {
            self.orientationObserver.lockedScreen = lockedScreen
//            self.controlView.lockedVideoPlayer:self lockedScreen:lockedScreen
        }
    }

    // MARK: - Initializers

    /**
     Creates an `IRPlayerController` that plays a single audiovisual item.

     - Parameters:
       - playerManager: The player manager that conforms to `IRPlayerMediaPlayback`.
       - containerView: The view to display the video frames.
     - Returns: An instance of `IRPlayerController`.
     */
    public static func playerWith(playerManager: IRPlayerImp, containerView: UIView) -> IRPlayerController {
        return IRPlayerController(playerManager: playerManager, containerView: containerView)
    }

    /**
     Initializes an `IRPlayerController` that plays a single audiovisual item.

     - Parameters:
       - playerManager: The player manager that conforms to `IRPlayerMediaPlayback`.
       - containerView: The view to display the video frames.
     */
    public init(playerManager: IRPlayerImp, containerView: UIView) {
        self.currentPlayerManager = playerManager
        self.containerView = containerView
        self.containerView.isUserInteractionEnabled = true
        self.containerType = .normal
        self.smallFloatView = IRFloatView()
        self.isSmallFloatViewShow = false
        super.init()
        handleCurrentPlayerManagerChange()
    }

    private func handleCurrentPlayerManagerChange() {
        if let view = currentPlayerManager.view {
            view.isHidden = true
            if let glView = currentPlayerManager.view as? IRGLView {
                gestureControl.disableTypes = disableGestureTypes
                gestureControl.addGesture(to: glView)
            }
            playerManagerCallback()
            orientationObserver.updateRotateView(view, containerView: containerView)
        }
        controlView?.playerController = self
        layoutPlayerSubViews()
    }

    private func layoutPlayerSubViews() {
        guard let playerView = currentPlayerManager.view else {
            return
        }

        if playerView.superview == nil {
            var superview: UIView?
            if isFullScreen {
                superview = orientationObserver.fullScreenContainerView
            } else {
                superview = containerView
            }

            if let superview = superview {
                superview.addSubview(playerView)

                playerView.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    playerView.topAnchor.constraint(equalTo: superview.topAnchor),
                    playerView.bottomAnchor.constraint(equalTo: superview.bottomAnchor),
                    playerView.leadingAnchor.constraint(equalTo: superview.leadingAnchor),
                    playerView.trailingAnchor.constraint(equalTo: superview.trailingAnchor)
                ])
            }

            orientationObserver.updateRotateView(playerView, containerView: containerView)
        }

        if let controlView = controlView, controlView.superview == nil {
            playerView.addSubview(controlView)

            controlView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                controlView.topAnchor.constraint(equalTo: playerView.topAnchor),
                controlView.bottomAnchor.constraint(equalTo: playerView.bottomAnchor),
                controlView.leadingAnchor.constraint(equalTo: playerView.leadingAnchor),
                controlView.trailingAnchor.constraint(equalTo: playerView.trailingAnchor)
            ])
        }
    }


    // MARK: - Playback Control

    /**
     Plays the next URL in the playlist, if available.
     */
    public func playTheNext() {
        guard let assetURLs = assetURLs, assetURLs.count > 0 else { return }
        let index = currentPlayIndex + 1
        if index >= assetURLs.count { return }

        let assetURL = assetURLs[index]
        self.assetURL = assetURL
        self.currentPlayIndex = index
    }

    /**
     Plays the previous URL in the playlist, if available.
     */
    public func playThePrevious() {
        guard let assetURLs = assetURLs, assetURLs.count > 0 else { return }
        let index = currentPlayIndex - 1
        if index < 0 { return }

        let assetURL = assetURLs[index]
        self.assetURL = assetURL
        self.currentPlayIndex = index
    }

    /**
     Plays the URL at the specified index in the playlist.

     - Parameter index: The index of the URL to play.
     */
    public func playTheIndex(_ index: Int) {
        guard let assetURLs = assetURLs, assetURLs.count > 0 else { return }
        if index >= assetURLs.count { return }

        let assetURL = assetURLs[index]
        self.assetURL = assetURL
        self.currentPlayIndex = index
    }

    /**
     Stops the player and removes the player view.
     */
    public func stop() {
//        notification.removeNotification()
        orientationObserver.removeDeviceOrientationObserver()

        if isFullScreen && exitFullScreenWhenStop {
            orientationObserver.exitFullScreen(animated: false)
        }

        currentPlayerManager.pause()
        currentPlayerManager.view?.removeFromSuperview()

//        if let scrollView = scrollView {
//            scrollView.ir_stopPlay = true
//        }
    }

    /**
     Seeks to a specific time in the video.

     - Parameters:
       - time: The time to seek to, in seconds.
       - completionHandler: A block that is called when the seek operation is complete.
     */
    public func seek(to time: TimeInterval, completionHandler: @escaping (Bool) -> Void) {
        currentPlayerManager.seekToTime(time: time, completeHandler: completionHandler)
    }


    /// The player's current playback time, in seconds.
    public var currentTime: TimeInterval {
        return currentPlayerManager.progress
    }

    /// The player's total playback time, in seconds.
    public var totalTime: TimeInterval {
        return currentPlayerManager.duration
    }

    /// The player's buffered time, in seconds.
    public var bufferTime: TimeInterval {
        return currentPlayerManager.playableBufferInterval
    }

    /// The player's playback progress, ranging from 0 to 1.
    public var progress: CGFloat {
        guard totalTime > 0 else { return 0 }
        return currentTime / totalTime
    }

    /// The player's buffer progress, ranging from 0 to 1.
    public var bufferProgress: CGFloat {
        guard totalTime > 0 else { return 0 }
        return bufferTime / totalTime
    }

    // MARK: - Orientation Rotation

    /// The orientation observer instance.
    lazy var orientationObserver: IROrientationObserver = {
        let observer = IROrientationObserver()

        observer.orientationWillChange = { [weak self] observer, isFullScreen in
            guard let self else { return }
            orientationWillChange?(self, isFullScreen)
            if let controlView = controlView as? IRPlayerControlView {
                controlView.videoPlayer(self, orientationWillChange: observer)
            }
//            self.shouldAutorotate = !isFullScreen
            controlView?.setNeedsLayout()
            controlView?.layoutIfNeeded()
        }

        observer.orientationDidChanged = { [weak self] observer, isFullScreen in
            guard let self = self else { return }
            self.orientationDidChanged?(self, isFullScreen)
            if let controlView = self.controlView as? IRPlayerControlView {
                controlView.videoPlayer(self, orientationDidChange: observer)
            }
        }

        return observer
    }()

    public var orientationWillChange: ((IRPlayerController, Bool) -> Void)?
    public var orientationDidChanged: ((IRPlayerController, Bool) -> Void)?

    public var playerDidToEnd: ((IRPlayerMediaPlayback) -> Void)?

    /// Indicates whether automatic screen rotation is supported.
    public var shouldAutorotate: Bool = true

    /// Indicates whether the video orientation rotation is allowed.
    public var allowOrientationRotation: Bool = true

    /// Indicates whether the player is in full-screen mode.
    public var isFullScreen: Bool {
        return orientationObserver.isFullScreen
    }

    /// The statusbar hidden.
    public var isStatusBarHidden: Bool = false

    /// Indicates whether to exit full-screen mode when stopping the player.
    public var exitFullScreenWhenStop: Bool = true

    /**
     Determines whether to enter full-screen mode.

     - Parameters:
       - fullScreen: Indicates whether to enter full-screen mode.
       - animated: Determines if the transition should be animated.
     */
    public func enterFullScreen(_ fullScreen: Bool, animated: Bool) {
        if orientationObserver.fullScreenMode == .portrait {
            orientationObserver.enterPortraitFullScreen(fullScreen, animated: animated)
        } else {
            let orientation: UIInterfaceOrientation = fullScreen ? .landscapeRight : .portrait
            orientationObserver.enterLandscapeFullScreen(orientation: orientation, animated: animated)
        }
    }

    /**
     Enters full-screen mode in landscape orientation.

     - Parameters:
       - orientation: The desired orientation (e.g., `.landscapeLeft` or `.landscapeRight`).
       - animated: Determines if the transition should be animated.
     */
    public func enterLandscapeFullScreen(_ orientation: UIInterfaceOrientation, animated: Bool) {
        orientationObserver.fullScreenMode = .landscape
        orientationObserver.enterLandscapeFullScreen(orientation: orientation, animated: animated)
    }

    /**
     Enters full-screen mode in portrait orientation.

     - Parameters:
       - fullScreen: Indicates whether to enter full-screen mode.
       - animated: Determines if the transition should be animated.
     */
    public func enterPortraitFullScreen(_ fullScreen: Bool, animated: Bool) {
        orientationObserver.fullScreenMode = .portrait
        orientationObserver.enterPortraitFullScreen(fullScreen, animated: animated)
    }

    /**
     Adds the device orientation observer.
     */
    public func addDeviceOrientationObserver() {
        orientationObserver.addDeviceOrientationObserver()
    }

    /**
     Removes the device orientation observer.
     */
    public func removeDeviceOrientationObserver() {
        orientationObserver.removeDeviceOrientationObserver()
    }

    @objc private func stateAction(_ notification: Notification) {
        dealWithNotification(notification, player: currentPlayerManager)
    }

    @objc private func progressAction(_ notification: Notification) {
        if let userInfo = notification.userInfo {
            let progress = IRProgress.progress(fromUserInfo: userInfo)
            controlView?.videoPlayer(self, currentTime: progress.current, totalTime: progress.total)
        }
    }

    private func timeString(fromSeconds seconds: CGFloat) -> String {
        let minutes = Int(seconds) / 60
        let seconds = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    @objc private func playableAction(_ notification: Notification) {
        if let userInfo = notification.userInfo {
            let playable = IRPlayable.playable(fromUserInfo: userInfo)
            print("Playable time: \(playable.current)")
        }
    }

    @objc private func errorAction(_ notification: Notification) {
        if let userInfo = notification.userInfo {
            let error = IRError.error(fromUserInfo: userInfo)
            print("Player did error: \(error.error)")
        }
    }

    private func dealWithNotification(_ notification: Notification, player: IRPlayerImp) {
        guard let userInfo = notification.userInfo else {
            return
        }

        let state = IRState.state(fromUserInfo: userInfo)

        var text: String
        switch state.current {
        case .none:
            text = "None"

        case .buffering:
            text = "Buffering..."

            currentPlayerManager.view?.isHidden = false
            addDeviceOrientationObserver()

//            if let scrollView = scrollView {
//                scrollView.ir_stopPlay = false
//            }

            layoutPlayerSubViews()

            // Notify control view about prepareToPlay
            if let url = player.contentURL {
                controlView?.videoPlayer(self, prepareToPlay: url)
            }

            // Notify control view about loadStateChanged
            controlView?.videoPlayer(self, loadStateChanged: .automaticallyPaused)

        case .readyToPlay:
            text = "Prepare"

            // Notify control view about loadStateChanged
            controlView?.videoPlayer(self, loadStateChanged: .ready)

            // Configure audio session if not custom
            if !customAudioSession {
                try? AVAudioSession.sharedInstance().setCategory(.playback, options: .allowBluetooth)
                try? AVAudioSession.sharedInstance().setActive(true)
            }

            if viewControllerDisappear {
                pauseByEvent = true
            }

            player.play()

        case .playing:
            text = "Playing"

            // Notify control view about loadStateChanged
            controlView?.videoPlayer(self, loadStateChanged: .automaticallyPlay)

        case .suspend:
            text = "Suspend"

        case .finished:
            text = "Finished"

        case .failed:
            text = "Error"

            // Notify control view about playFailed
            if let userInfo = notification.userInfo {
                let error = IRError.error(fromUserInfo: userInfo)
                controlView?.videoPlayerPlayFailed(self, error: error)
            }

        @unknown default:
            text = "Unknown State"
        }
    }

}

@propertyWrapper
public struct Clamped<Value: Comparable> {
    private var value: Value
    private let range: ClosedRange<Value>

    init(wrappedValue: Value, _ range: ClosedRange<Value>) {
        self.range = range
        self.value = range.clamp(wrappedValue)
    }

    public var wrappedValue: Value {
        get { value }
        set { value = range.clamp(newValue) }
    }
}

private extension ClosedRange where Bound: Comparable {
    func clamp(_ value: Bound) -> Bound {
        return min(max(lowerBound, value), upperBound)
    }
}

import UIKit
import MediaPlayer

final class SystemVolumeController {
    private let volumeView: MPVolumeView = {
        let view = MPVolumeView(frame: .zero)
        view.isHidden = true
        return view
    }()

    private var volumeSlider: UISlider? {
        return volumeView.subviews.compactMap { $0 as? UISlider }.first
    }

    init(parentView: UIView? = nil) {
        if let parent = parentView {
            parent.addSubview(volumeView)
        } else {
            UIApplication.shared.windows.first?.addSubview(volumeView)
        }
    }

    func setVolume(_ value: Float) {
        let clamped = min(max(value, 0.0), 1.0)
        volumeSlider?.value = clamped
    }

    var currentVolume: Float? {
        return volumeSlider?.value
    }
}
