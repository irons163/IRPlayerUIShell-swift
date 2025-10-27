//
//  IRPlayerControlView.swift
//  IRPlayerUIShell
//
//  Created by irons on 2025/1/12.
//

import AVKit
import AVFoundation

public class IRPlayerControlView: UIView, IRPlayerMediaControl {

    // MARK: - Properties
    public var playerController: IRPlayerController? {
        didSet {
            guard playerController != oldValue else { return }

            landScapeControlView.playerController = playerController
            portraitControlView.playerController = playerController

            if let superview = playerController?.currentPlayerManager.view?.superview {
                superview.insertSubview(bgImageView, at: 0)
                bgImageView.addSubview(effectView)
                superview.insertSubview(coverImageView, at: 1)
            }

            coverImageView.frame = playerController?.currentPlayerManager.view?.bounds ?? .zero
            coverImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

            bgImageView.frame = playerController?.currentPlayerManager.view?.bounds ?? .zero
            bgImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

            effectView.frame = bgImageView.bounds
            effectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        }
    }

    /// Portrait control view.
    private(set) var portraitControlView = IRPortraitControlView()

    /// Landscape control view.
    private(set) var landScapeControlView = IRLandScapeControlView()

    /// Speed loading view.
    private(set) var activity = IRSpeedLoadingView()

    private lazy var volumeBrightnessView: IRVolumeBrightnessView = {
        let view = IRVolumeBrightnessView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        view.isHidden = true
        return view
    }()

    /// Fast view.
    private(set) var fastView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0, alpha: 0.7)
        view.layer.cornerRadius = 4
        view.layer.masksToBounds = true
        view.isHidden = true
        return view
    }()

    /// Fast progress view.
    private(set) var fastProgressView = IRSliderView()

    /// Fast time label.
    private(set) var fastTimeLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14.0)
        label.adjustsFontSizeToFitWidth = true
        return label
    }()

    /// Fast image view.
    private(set) var fastImageView = UIImageView()

    /// Button for loading video failure.
    private(set) var failButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Loading failed", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14.0)
        button.backgroundColor = UIColor(white: 0, alpha: 0.7)
        button.isHidden = true
        return button
    }()

    /// Bottom progress bar.
    private(set) var bottomProgress = IRSliderView()

    /// Cover image view.
    private(set) var coverImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.isUserInteractionEnabled = true
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    /// Background image view for blur effect.
    private(set) var bgImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.isUserInteractionEnabled = true
        return imageView
    }()

    /// Blur effect view.
    private(set) var effectView: UIView = {
        if #available(iOS 8.0, *) {
            let blurEffect = UIBlurEffect(style: .dark)
            return UIVisualEffectView(effect: blurEffect)
        } else {
            let toolbar = UIToolbar()
            toolbar.barStyle = .blackTranslucent
            return toolbar
        }
    }()

    /// Float control view.
    private(set) var floatControlView = IRSmallFloatControlView()

    private var controlViewAppeared: Bool = false

    /// Indicates if the fast view should be animated. Default is `false`.
    public var fastViewAnimated: Bool = false

    /// Indicates if the blur effect view should be shown. Default is `true`.
    var effectViewShow: Bool = true {
        didSet {
            bgImageView.isHidden = !effectViewShow
        }
    }

    /// Indicates if the control view is shown.
    private(set) var isControlViewAppeared: Bool = false

    var controlViewAppearedCallback: ((Bool) -> Void)?

    /// Indicates if full-screen mode is enabled. Default is `false`.
    var fullScreenOnly: Bool = false

    /// Indicates if auto-play should be enabled after seeking. Default is `true`.
    var seekToPlay: Bool = true {
        didSet {
            portraitControlView.seekToPlay = seekToPlay
            landScapeControlView.seekToPlay = seekToPlay
        }
    }

    /// Callback for back button click.
    var backButtonClickCallback: (() -> Void)? {
        didSet {
            landScapeControlView.backButtonClickCallback = backButtonClickCallback
        }
    }

    /// Time for auto-hide of the control view. Default is 2.5 seconds.
    public var autoHiddenTimeInterval: TimeInterval = 2.5

    /// Fade animation duration for the control view. Default is 0.25 seconds.
    public var autoFadeTimeInterval: TimeInterval = 0.25

    /// Indicates if horizontal pan gesture shows the control view. Default is `true`.
    var horizontalPanShowControlView: Bool = true

    /// Indicates if the control view is shown during preparation. Default is `false`.
    public var prepareShowControlView: Bool = false

    /// Indicates if the loading view is shown during preparation. Default is `false`.
    public var prepareShowLoading: Bool = false

    /// Indicates if custom pan gestures are disabled. Default is `false`.
    var customDisablePanMovingDirection: Bool = false

    private var sumTime: TimeInterval = 0
    private var afterBlock: DispatchWorkItem?

    // MARK: - Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)
        addAllSubviews()
        setupAutoLayout()
        configureDefaults()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(volumeChanged(notification:)),
            name: NSNotification.Name("AVSystemController_SystemVolumeDidChangeNotification"),
            object: nil
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name("AVSystemController_SystemVolumeDidChangeNotification"),
            object: nil
        )
        cancelAutoFadeOutControlView()
    }

    // MARK: - Subview Management

    private func addAllSubviews() {
        addSubview(portraitControlView)
        addSubview(landScapeControlView)
        addSubview(floatControlView)
        addSubview(activity)
        addSubview(failButton)
        addSubview(fastView)
        fastView.addSubview(fastImageView)
        fastView.addSubview(fastTimeLabel)
        fastView.addSubview(fastProgressView)
        addSubview(bottomProgress)
        addSubview(volumeBrightnessView)
    }

    // MARK: - Setup Auto Layout

    private func setupAutoLayout() {
        // Fill the bounds for these views
        let fillBoundViews = [portraitControlView, landScapeControlView, floatControlView]
        fillBoundViews.forEach { view in
            view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                view.topAnchor.constraint(equalTo: topAnchor),
                view.leadingAnchor.constraint(equalTo: leadingAnchor),
                view.trailingAnchor.constraint(equalTo: trailingAnchor),
                view.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
        }

        // Activity indicator
        activity.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            activity.widthAnchor.constraint(equalToConstant: 80),
            activity.heightAnchor.constraint(equalToConstant: 80),
            activity.centerXAnchor.constraint(equalTo: centerXAnchor),
            activity.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 10)
        ])

        // Fail button
        failButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            failButton.widthAnchor.constraint(equalToConstant: 150),
            failButton.heightAnchor.constraint(equalToConstant: 30),
            failButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            failButton.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        // Fast view
        fastView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            fastView.widthAnchor.constraint(equalToConstant: 140),
            fastView.heightAnchor.constraint(equalToConstant: 80),
            fastView.centerXAnchor.constraint(equalTo: centerXAnchor),
            fastView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        // Fast image view
        fastImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            fastImageView.widthAnchor.constraint(equalToConstant: 32),
            fastImageView.heightAnchor.constraint(equalToConstant: 32),
            fastImageView.centerXAnchor.constraint(equalTo: fastView.centerXAnchor),
            fastImageView.topAnchor.constraint(equalTo: fastView.topAnchor, constant: 5)
        ])

        // Fast time label
        fastTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            fastTimeLabel.leadingAnchor.constraint(equalTo: fastView.leadingAnchor),
            fastTimeLabel.trailingAnchor.constraint(equalTo: fastView.trailingAnchor),
            fastTimeLabel.topAnchor.constraint(equalTo: fastImageView.bottomAnchor, constant: 2),
            fastTimeLabel.heightAnchor.constraint(equalToConstant: 20)
        ])

        // Fast progress view
        fastProgressView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            fastProgressView.leadingAnchor.constraint(equalTo: fastView.leadingAnchor, constant: 12),
            fastProgressView.trailingAnchor.constraint(equalTo: fastView.trailingAnchor, constant: -12),
            fastProgressView.topAnchor.constraint(equalTo: fastTimeLabel.bottomAnchor, constant: 5),
            fastProgressView.heightAnchor.constraint(equalToConstant: 10)
        ])

        // Bottom progress bar
        bottomProgress.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bottomProgress.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomProgress.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomProgress.bottomAnchor.constraint(equalTo: bottomAnchor),
            bottomProgress.heightAnchor.constraint(equalToConstant: 1)
        ])

        // Volume brightness view
        volumeBrightnessView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            volumeBrightnessView.widthAnchor.constraint(equalToConstant: 170),
            volumeBrightnessView.heightAnchor.constraint(equalToConstant: 35),
            volumeBrightnessView.centerXAnchor.constraint(equalTo: centerXAnchor),
            volumeBrightnessView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 30)
        ])
    }

    private func configureDefaults() {
        landScapeControlView.isHidden = true
        floatControlView.isHidden = true
    }

    // MARK: - Public Methods

    public func videoPlayer(_ videoPlayer: IRPlayerController, prepareToPlay assetURL: URL) {
        hideControlView(animated: false)
    }

    func videoPlayer(_ videoPlayer: IRPlayerController, playStateChanged state: IRPlayerPlaybackState) {
        if state == .playing {
            portraitControlView.playOrPauseBtn.isSelected = true
            landScapeControlView.playOrPauseBtn.isSelected = true
            failButton.isHidden = true

            /// Check for show loading view or not.
            if (videoPlayer.currentPlayerManager.playbackState == .playing && !prepareShowLoading) {
                activity.startAnimating()
            } else if ((videoPlayer.currentPlayerManager.playbackState == .playing || videoPlayer.currentPlayerManager.playbackState == .readyToPlay) && prepareShowLoading) {
                activity.startAnimating()
            }
        } else if state == .paused {
            portraitControlView.playOrPauseBtn.isSelected = false
            landScapeControlView.playOrPauseBtn.isSelected = false
            /// Hide loading view
            activity.stopAnimating()
            failButton.isHidden = true
        } else if state == .failed {
            failButton.isHidden = false
            activity.stopAnimating()
        }
    }

    public func videoPlayer(_ videoPlayer: IRPlayerController, loadStateChanged state: IRPlayerLoadState) {
        if state == .preparing {
            coverImageView.isHidden = false
            portraitControlView.playOrPauseBtn.isSelected = true
            landScapeControlView.playOrPauseBtn.isSelected = true
        } else if state == .automaticallyPlay || state == .ready {
            coverImageView.isHidden = true
            if effectViewShow {
                effectView.isHidden = false
            } else {
                effectView.isHidden = true
                playerController?.currentPlayerManager.view?.backgroundColor = .black
            }
        }
        if state == .automaticallyPaused && videoPlayer.currentPlayerManager.playbackState == .buffering && !prepareShowLoading {
            activity.startAnimating()
        } else if (state == .automaticallyPaused || state == .preparing) && videoPlayer.currentPlayerManager.playbackState == .buffering && prepareShowLoading {
            activity.startAnimating()
        } else {
            activity.stopAnimating()
        }
    }

    public func videoPlayer(_ videoPlayer: IRPlayerController, currentTime: TimeInterval, totalTime: TimeInterval) {
        portraitControlView.videoPlayer(videoPlayer, currentTime: currentTime, totalTime: totalTime)
        landScapeControlView.videoPlayer(videoPlayer, currentTime: currentTime, totalTime: totalTime)
        bottomProgress.value = videoPlayer.progress
    }

    func videoPlayer(_ videoPlayer: IRPlayerController, bufferTime: TimeInterval) {
        portraitControlView.videoPlayer(videoPlayer, bufferTime: bufferTime)
        landScapeControlView.videoPlayer(videoPlayer, bufferTime: bufferTime)
        bottomProgress.bufferValue = Float(videoPlayer.bufferProgress)
    }

    func videoPlayer(_ videoPlayer: IRPlayerController, presentationSizeChanged size: CGSize) {
        landScapeControlView.videoPlayer(videoPlayer, presentationSizeChanged: size)
    }

    func videoPlayer(_ videoPlayer: IRPlayerController, orientationWillChange observer: IROrientationObserver) {
        portraitControlView.isHidden = observer.isFullScreen
        landScapeControlView.isHidden = !observer.isFullScreen

        if videoPlayer.isSmallFloatViewShow {
            floatControlView.isHidden = observer.isFullScreen
            portraitControlView.isHidden = true

            if observer.isFullScreen {
                controlViewAppeared = false
                cancelAutoFadeOutControlView()
            }
        }

        if controlViewAppeared {
            showControlView(animated: false)
        } else {
            hideControlView(animated: false)
        }

        if observer.isFullScreen {
            volumeBrightnessView.removeSystemVolumeView()
        } else {
            volumeBrightnessView.addSystemVolumeView()
        }
    }

    func videoPlayer(_ videoPlayer: IRPlayerController, orientationDidChange observer: IROrientationObserver) {
        if controlViewAppeared {
            showControlView(animated: false)
        } else {
            hideControlView(animated: false)
        }
    }

    /**
     When play failed.
     */
    public func videoPlayerPlayFailed(_ videoPlayer: IRPlayerController, error: Any) {

    }

    public func showTitle(_ title: String, coverURLString: String, fullScreenMode: IRFullScreenMode) {
        resetControlView()
        portraitControlView.showTitle(title, fullScreenMode: fullScreenMode)
        landScapeControlView.showTitle(title, fullScreenMode: fullScreenMode)
        // Load cover images if needed
    }

    func resetControlView() {
        portraitControlView.resetControlView()
        landScapeControlView.resetControlView()
        cancelAutoFadeOutControlView()
        bottomProgress.value = 0
        bottomProgress.bufferValue = 0
        floatControlView.isHidden = true
        failButton.isHidden = true
        isControlViewAppeared = false
    }

    // MARK: - IRPlayerControlViewDelegate

    public func gestureTriggerCondition(
        _ gestureControl: IRGestureControlling,
        gestureType: IRGestureType,
        gestureRecognizer: UIGestureRecognizer,
        touch: UITouch
    ) -> Bool {
        let point = touch.location(in: self)
        if (playerController?.isSmallFloatViewShow ?? false) &&
            (playerController?.isFullScreen ?? false) &&
            gestureType != .singleTap {
            return false
        }
        if playerController?.isFullScreen ?? false {
            if !customDisablePanMovingDirection {
                // Allow pan gestures
                playerController?.disablePanMovingDirection = .none
            }
            return landScapeControlView.shouldResponseGesture(withPoint: point, withGestureType: gestureType, touch: touch)
        } else {
            if !customDisablePanMovingDirection {
                playerController?.disablePanMovingDirection = .none
            }
            return portraitControlView.shouldResponseGesture(withPoint: point, withGestureType: gestureType, touch: touch)
        }
    }

    public func gestureSingleTapped(_ gestureControl: IRGestureControlling) {
        guard let playerController else { return }
        if playerController.isSmallFloatViewShow && !playerController.isFullScreen {
            playerController.enterFullScreen(true, animated: true)
        } else {
            if controlViewAppeared {
                hideControlView(animated: true)
            } else {
                hideControlView(animated: false)
                showControlView(animated: true)
            }
        }
    }

    public func gestureDoubleTapped(_ gestureControl: IRGestureControlling) {
        if playerController?.isFullScreen ?? false {
            landScapeControlView.playOrPause()
        } else {
            portraitControlView.playOrPause()
        }
    }

    public func gestureBeganPan(_ gestureControl: IRGestureControlling, panDirection direction: IRPanDirection, panLocation location: IRPanLocation) {
        if direction == .horizontal {
            sumTime = playerController?.currentTime ?? 0
        }
    }

    public func gestureChangedPan(
        _ gestureControl: IRGestureControlling,
        panDirection direction: IRPanDirection,
        panLocation location: IRPanLocation,
        withVelocity velocity: CGPoint
    ) {
        if direction == .horizontal {
            sumTime += velocity.x / 200
            let totalDuration = playerController?.totalTime ?? 0
            if totalDuration == 0 { return }
            sumTime = max(0, min(totalDuration, sumTime))
            let isForward = velocity.x > 0
            sliderValueChanging(value: sumTime / totalDuration, isForward: isForward)
        } else if direction == .vertical {
            if location == .left {
                // Control brightness
                playerController?.brightness -= velocity.y / 10000
                volumeBrightnessView.updateProgress(playerController?.brightness ?? 0, with: .brightness)
            } else if location == .right {
                // Control volume
                playerController?.volume -= velocity.y / 10000
                if playerController?.isFullScreen ?? false {
                    volumeBrightnessView.updateProgress(playerController?.volume ?? 0, with: .volume)
                }
            }
        }
    }

    public func gestureEndedPan(
        _ gestureControl: IRGestureControlling,
        panDirection direction: IRPanDirection,
        panLocation location: IRPanLocation
    ) {
        if direction == .horizontal, sumTime >= 0, (playerController?.totalTime ?? 0) > 0 {
            playerController?.seek(to: sumTime) { [weak self] finished in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.portraitControlView.sliderChangeEnded()
                    self.landScapeControlView.sliderChangeEnded()
                    if self.controlViewAppeared {
                        self.autoFadeOutControlView()
                    }
                }
            }
            if seekToPlay {
                playerController?.currentPlayerManager.play()
            }
            sumTime = 0
        }
    }

    public func gesturePinched(_ gestureControl: IRGestureControlling, scale: Float) {
        playerController?.currentPlayerManager.gravityMode = scale > 1 ? .aspectFill : .aspectFill
    }


    // MARK: - Private Methods

    private func sliderValueChanging(value: CGFloat, isForward forward: Bool) {
        if horizontalPanShowControlView {
            // 显示控制层
            showControlView(animated: false)
            cancelAutoFadeOutControlView()
        }

        fastProgressView.value = value
        fastView.isHidden = false
        fastView.alpha = 1

        if forward {
            fastImageView.image = IRUtilities.image(named: "IRPlayer_fast_forward")
        } else {
            fastImageView.image = IRUtilities.image(named: "IRPlayer_fast_backward")
        }

        let totalTime = playerController?.totalTime ?? 0
        let roundedValue = totalTime.rounded(.down)

        // Safely clamp the Double within Int's valid range
        let safeValue: Double = min(max(roundedValue, Double(Int.min)), Double(Int.max))

        // Convert safely
        let totalIntTime = Int(safeValue)

        let clampedDraggedTime = min(max(totalTime * value, Double(Int.min)), Double(Int.max))
        let draggedIntTime = Int(clampedDraggedTime.rounded(.down))

        let draggedTimeStr = IRUtilities.convertTimeSecond(draggedIntTime)
        let totalTimeStr = IRUtilities.convertTimeSecond(totalIntTime)
        fastTimeLabel.text = "\(draggedTimeStr) / \(totalTimeStr)"

        portraitControlView.sliderValueChanged(value: value, currentTimeString: draggedTimeStr)
        landScapeControlView.sliderValueChanged(value, currentTimeString: draggedTimeStr)

        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(hideFastView), object: nil)
        perform(#selector(hideFastView), with: nil, afterDelay: 0.1)

        if fastViewAnimated {
            UIView.animate(withDuration: 0.4) {
                self.fastView.transform = CGAffineTransform(translationX: forward ? 8 : -8, y: 0)
            }
        }
    }

    @objc private func hideFastView() {
        UIView.animate(withDuration: 0.4, animations: {
            self.fastView.transform = .identity
            self.fastView.alpha = 0
        }) { finished in
            self.fastView.isHidden = true
        }
    }

    @objc private func volumeChanged(notification: Notification) {
        // Handle volume changes
    }

    private func autoFadeOutControlView() {
        cancelAutoFadeOutControlView()
        let block = DispatchWorkItem { [weak self] in
            self?.hideControlView(animated: true)
        }
        afterBlock = block
        DispatchQueue.main.asyncAfter(deadline: .now() + autoHiddenTimeInterval, execute: block)
    }

    private func cancelAutoFadeOutControlView() {
        afterBlock?.cancel()
        afterBlock = nil
    }

    private func hideControlView(animated: Bool) {
        isControlViewAppeared = false
        controlViewAppearedCallback?(false)
        UIView.animate(withDuration: animated ? autoFadeTimeInterval : 0, animations: {
            if self.playerController?.isFullScreen ?? false {
                self.landScapeControlView.isHidden = true
            } else if self.playerController?.isSmallFloatViewShow == false {
                self.portraitControlView.isHidden = true
            }
        }) { _ in
            self.bottomProgress.isHidden = false
        }
    }

    private func showControlView(animated: Bool) {
        isControlViewAppeared = true
        controlViewAppearedCallback?(true)
        autoFadeOutControlView()
        UIView.animate(withDuration: animated ? autoFadeTimeInterval : 0, animations: {
            if self.playerController?.isFullScreen ?? false {
                self.landScapeControlView.isHidden = false
            } else {
                if self.playerController?.isSmallFloatViewShow == false {
                    self.portraitControlView.isHidden = false
                }
            }
        }) { _ in
            self.bottomProgress.isHidden = true
        }
    }
}

public struct IRPlayerProgress: Equatable {
    public let current: TimeInterval      // 秒
    public let total: TimeInterval        // 秒
    public let buffered: TimeInterval     // 秒

    public init(current: TimeInterval, total: TimeInterval, buffered: TimeInterval = 0) {
        // 合法化（避免 NaN / ∞；並夾在合理範圍）
        let safeTotal = (total.isFinite && total >= 0) ? total : 0
        let upper = safeTotal > 0 ? safeTotal : .greatestFiniteMagnitude
        self.current  = min(max(current, 0), upper)
        self.total    = safeTotal
        self.buffered = min(max(buffered, 0), upper)
    }
}
