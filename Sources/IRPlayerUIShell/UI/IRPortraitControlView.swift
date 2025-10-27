//
//  IRPortraitControlView.swift
//  IRPlayerUIShell
//
//  Created by irons on 2025/1/12.
//

import UIKit

class IRPortraitControlView: UIView, IRSliderViewDelegate {

    // MARK: - Properties

    /// Bottom tool view
    private(set) lazy var bottomToolView: UIView = {
        let view = UIView()
        if let image = IRUtilities.image(named: "IRPlayer_bottom_shadow") {
            view.layer.contents = image.cgImage
        }
        return view
    }()

    /// Top tool view
    private(set) lazy var topToolView: UIView = {
        let view = UIView()
        if let image = IRUtilities.image(named: "IRPlayer_top_shadow") {
            view.layer.contents = image.cgImage
        }
        return view
    }()

    /// Title label
    private(set) var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 15.0)
        return label
    }()

    /// Play or pause button
    private(set) var playOrPauseBtn: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(IRUtilities.image(named: "new_allPlay_44x44_"), for: .normal)
        button.setImage(IRUtilities.image(named: "new_allPause_44x44_"), for: .selected)
        return button
    }()

    /// Current time label
    private(set) var currentTimeLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14.0)
        label.textAlignment = .center
        return label
    }()

    /// Slider view
    private(set) var slider: IRSliderView = {
        let slider = IRSliderView()
        slider.maximumTrackTintColor = UIColor(white: 0.5, alpha: 0.8)
        slider.bufferTrackTintColor = UIColor(white: 1.0, alpha: 0.5)
        slider.minimumTrackTintColor = .white
        slider.sliderHeight = 2
        slider.setThumbImage(IRUtilities.image(named: "IRPlayer_slider"), for: .normal)
        return slider
    }()

    /// Total time label
    private(set) var totalTimeLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14.0)
        label.textAlignment = .center
        return label
    }()

    /// Fullscreen button
    private(set) var fullScreenBtn: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(IRUtilities.image(named: "IRPlayer_fullscreen"), for: .normal)
        return button
    }()

    /// Player
    weak var playerController: IRPlayerController?

    /// Indicates if the slider is dragging
    private var isSliderDragging: Bool = false

    /// Slider value changing callback
    var sliderValueChanging: ((CGFloat, Bool) -> Void)?

    /// Slider value changed callback
    var sliderValueChanged: ((CGFloat) -> Void)?

    /// Whether to play after seeking, default is true
    var seekToPlay: Bool = true

    /// Indicates if the control view is showing
    private(set) var isShowing: Bool = false

    // MARK: - Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
        makeSubViewsAction()
        resetControlView()
        clipsToBounds = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupSubviews() {
        addSubview(topToolView)
        addSubview(bottomToolView)
        addSubview(playOrPauseBtn)
        topToolView.addSubview(titleLabel)
        bottomToolView.addSubview(currentTimeLabel)
        bottomToolView.addSubview(slider)
        bottomToolView.addSubview(totalTimeLabel)
        bottomToolView.addSubview(fullScreenBtn)
    }

    private func makeSubViewsAction() {
        playOrPauseBtn.addTarget(self, action: #selector(playPauseButtonClickAction), for: .touchUpInside)
        fullScreenBtn.addTarget(self, action: #selector(fullScreenButtonClickAction), for: .touchUpInside)
        slider.delegate = self
    }

    func videoPlayer(_ videoPlayer: IRPlayerController, currentTime: TimeInterval, totalTime: TimeInterval) {
        guard !slider.isDragging else { return }

        currentTimeLabel.text = IRUtilities.convertTimeSecond(Int(currentTime))
        totalTimeLabel.text = IRUtilities.convertTimeSecond(Int(totalTime))
        slider.value = videoPlayer.progress
    }

    func videoPlayer(_ videoPlayer: IRPlayerController, bufferTime: TimeInterval) {
        slider.bufferValue = Float(videoPlayer.bufferProgress)
    }

    func showTitle(_ title: String, fullScreenMode: IRFullScreenMode) {
        titleLabel.text = title
        playerController?.orientationObserver.fullScreenMode = fullScreenMode
    }

    // MARK: - Actions

    @objc private func playPauseButtonClickAction() {
        playOrPause()
    }

    @objc private func fullScreenButtonClickAction() {
        playerController?.enterFullScreen(true, animated: true)
    }

    func playOrPause() {
        playOrPauseBtn.isSelected.toggle()
        if playOrPauseBtn.isSelected {
            playerController?.currentPlayerManager.play()
        } else {
            playerController?.currentPlayerManager.pause()
        }
    }

    // MARK: - IRSliderViewDelegate

    func sliderTouchBegan(value: CGFloat) {
        slider.isDragging = true
    }

    func sliderTouchEnded(value: CGFloat) {
        guard let playerController, playerController.totalTime > 0 else {
            slider.isDragging = false
            return
        }
        let seekTime = playerController.totalTime * Double(value)
        playerController.seek(to: seekTime) { [weak self] finished in
            guard let self = self else { return }
            self.slider.isDragging = !finished
        }
        if seekToPlay {
            playerController.currentPlayerManager.play()
        }
        sliderValueChanged?(value)
    }

    func sliderValueChanged(value: CGFloat) {
        guard let playerController, playerController.totalTime > 0 else {
            slider.value = 0
            return
        }
        slider.isDragging = true
        let currentTime = playerController.totalTime * Double(value)
        currentTimeLabel.text = IRUtilities.convertTimeSecond(Int(currentTime))
        sliderValueChanging?(value, slider.isForward)
    }

    /// 调节播放进度slider和当前时间更新
    func sliderValueChanged(value: CGFloat, currentTimeString: String) {
        slider.value = value
        currentTimeLabel.text = currentTimeString
        slider.isDragging = true

        UIView.animate(withDuration: 0.3) {
            self.slider.sliderBtn.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }
    }

    /// 滑杆结束滑动
    func sliderChangeEnded() {
        slider.isDragging = false
        UIView.animate(withDuration: 0.3) {
            self.slider.sliderBtn.transform = .identity
        }
    }

    func sliderTapped(value: CGFloat) {
        guard let playerController, playerController.totalTime > 0 else {
            slider.isDragging = false
            slider.value = 0
            return
        }
        slider.isDragging = true
        let seekTime = playerController.totalTime * Double(value)
        playerController.seek(to: seekTime) { [weak self] finished in
            guard let self = self else { return }
            self.slider.isDragging = !finished
            if finished {
                playerController.currentPlayerManager.play()
            }
        }
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()

        let minViewWidth = bounds.width
        let minViewHeight = bounds.height
        let margin: CGFloat = 9

        topToolView.frame = CGRect(x: 0, y: 0, width: minViewWidth, height: 40)
        titleLabel.frame = CGRect(x: 15, y: 5, width: minViewWidth - 30, height: 30)
        bottomToolView.frame = CGRect(x: 0, y: minViewHeight - 40, width: minViewWidth, height: 40)

        playOrPauseBtn.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        playOrPauseBtn.center = center

        currentTimeLabel.frame = CGRect(x: margin, y: (bottomToolView.frame.height - 28) / 2, width: 62, height: 28)

        fullScreenBtn.frame = CGRect(x: bottomToolView.frame.width - 28 - margin, y: (bottomToolView.frame.height - 28) / 2, width: 28, height: 28)

        totalTimeLabel.frame = CGRect(x: fullScreenBtn.frame.minX - 62 - 4, y: currentTimeLabel.frame.minY, width: 62, height: 28)

        slider.frame = CGRect(x: currentTimeLabel.frame.maxX + 4, y: currentTimeLabel.frame.midY - 15, width: totalTimeLabel.frame.minX - currentTimeLabel.frame.maxX - 8, height: 30)
    }

    // MARK: - Public Methods

    func resetControlView() {
        bottomToolView.alpha = 1
        slider.value = 0
        slider.bufferValue = 0
        currentTimeLabel.text = "00:00"
        totalTimeLabel.text = "00:00"
        backgroundColor = .clear
        playOrPauseBtn.isSelected = true
        titleLabel.text = ""
    }

    func showControlView() {
        isShowing = true
        UIView.animate(withDuration: 0.3) {
            self.topToolView.alpha = 1
            self.bottomToolView.alpha = 1
            self.playOrPauseBtn.alpha = 1
        }
    }

    func hideControlView() {
        isShowing = false
        UIView.animate(withDuration: 0.3) {
            self.topToolView.alpha = 0
            self.bottomToolView.alpha = 0
            self.playOrPauseBtn.alpha = 0
        }
    }

    func shouldResponseGesture(
        withPoint point: CGPoint,
        withGestureType type: IRGestureType,
        touch: UITouch
    ) -> Bool {
        // 将 slider 的 frame 转换为当前视图的坐标系
        let sliderRect = bottomToolView.convert(slider.frame, to: self)

        // 如果触控点在 slider 范围内，则不响应手势
        if sliderRect.contains(point) {
            return false
        }

        return true
    }
}
