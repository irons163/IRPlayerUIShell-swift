//
//  IRLandScapeControlView.swift
//  IRPlayerUIShell
//
//  Created by irons on 2025/1/12.
//

import UIKit
import IRPlayerSwift

class IRLandScapeControlView: UIView, IRSliderViewDelegate {

    func sliderTouchBegan(value: CGFloat) {

    }
    
    func sliderValueChanged(value: CGFloat) {

    }
    
    func sliderTouchEnded(value: CGFloat) {

    }
    
    func sliderTapped(value: CGFloat) {

    }

    var backButtonClickCallback: (() -> Void)?


    // MARK: - Properties

    private(set) lazy var topToolView: UIView = {
        let view = UIView()
        if let image = IRUtilities.image(named: "IRPlayer_top_shadow") {
            view.layer.contents = image.cgImage
        }
        return view
    }()

    private(set) lazy var backBtn: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(IRUtilities.image(named: "IRPlayer_back_full"), for: .normal)
        button.addTarget(self, action: #selector(backBtnClickAction), for: .touchUpInside)
        return button
    }()

    private(set) lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 15.0)
        return label
    }()

    private(set) lazy var bottomToolView: UIView = {
        let view = UIView()
        if let image = IRUtilities.image(named: "IRPlayer_bottom_shadow") {
            view.layer.contents = image.cgImage
        }
        return view
    }()

    private(set) lazy var playOrPauseBtn: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(IRUtilities.image(named: "IRPlayer_play"), for: .normal)
        button.setImage(IRUtilities.image(named: "IRPlayer_pause"), for: .selected)
        button.addTarget(self, action: #selector(playPauseButtonClickAction), for: .touchUpInside)
        return button
    }()

    private(set) lazy var currentTimeLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14.0)
        label.textAlignment = .center
        return label
    }()

    private(set) lazy var slider: IRSliderView = {
        let slider = IRSliderView()
        slider.delegate = self
        slider.maximumTrackTintColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.8)
        slider.bufferTrackTintColor = UIColor(white: 1.0, alpha: 0.5)
        slider.minimumTrackTintColor = .white
        slider.setThumbImage(IRUtilities.image(named: "IRPlayer_slider"), for: .normal)
        slider.sliderHeight = 2
        return slider
    }()

    private(set) lazy var totalTimeLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14.0)
        label.textAlignment = .center
        return label
    }()

    private(set) lazy var lockBtn: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(IRUtilities.image(named: "IRPlayer_unlock-nor"), for: .normal)
        button.setImage(IRUtilities.image(named: "IRPlayer_lock-nor"), for: .selected)
        button.addTarget(self, action: #selector(lockButtonClickAction), for: .touchUpInside)
        return button
    }()

    weak var playerController: IRPlayerController?
    var sliderValueChanging: ((CGFloat, Bool) -> Void)?
    var sliderValueChanged: ((CGFloat) -> Void)?
    var backBtnClickCallback: (() -> Void)?
    var seekToPlay: Bool = true
    private var isShow: Bool = false

    // MARK: - Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(topToolView)
        topToolView.addSubview(backBtn)
        topToolView.addSubview(titleLabel)
        addSubview(bottomToolView)
        bottomToolView.addSubview(playOrPauseBtn)
        bottomToolView.addSubview(currentTimeLabel)
        bottomToolView.addSubview(slider)
        bottomToolView.addSubview(totalTimeLabel)
        addSubview(lockBtn)

        resetControlView()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(layOutControllerViews),
            name: UIApplication.didChangeStatusBarFrameNotification,
            object: nil
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didChangeStatusBarFrameNotification, object: nil)
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        let viewWidth = bounds.width
        let viewHeight = bounds.height
        let margin: CGFloat = 9

        topToolView.frame = CGRect(
            x: 0,
            y: 0,
            width: viewWidth,
            height: 110
        )

        let backBtnX: CGFloat = 44
        let backBtnY: CGFloat = 10
        backBtn.frame = CGRect(x: backBtnX, y: backBtnY, width: 40, height: 40)

        titleLabel.frame = CGRect(
            x: backBtn.frame.maxX + 5,
            y: 0,
            width: viewWidth - backBtn.frame.maxX - 15,
            height: 30
        )
        titleLabel.center.y = backBtn.center.y

        let bottomToolHeight: CGFloat = 73
        bottomToolView.frame = CGRect(
            x: 0,
            y: viewHeight - bottomToolHeight,
            width: viewWidth,
            height: bottomToolHeight
        )

        playOrPauseBtn.frame = CGRect(x: backBtnX, y: 32, width: 30, height: 30)

        currentTimeLabel.frame = CGRect(
            x: playOrPauseBtn.frame.maxX + 4,
            y: 0,
            width: 62,
            height: 30
        )
        currentTimeLabel.center.y = playOrPauseBtn.center.y

        totalTimeLabel.frame = CGRect(
            x: bottomToolView.frame.width - 62 - margin,
            y: 0,
            width: 62,
            height: 30
        )
        totalTimeLabel.center.y = playOrPauseBtn.center.y

        slider.frame = CGRect(
            x: currentTimeLabel.frame.maxX + 4,
            y: 0,
            width: totalTimeLabel.frame.minX - currentTimeLabel.frame.maxX - 4,
            height: 30
        )
        slider.center.y = playOrPauseBtn.center.y

        lockBtn.frame = CGRect(
            x: 50,
            y: 0,
            width: 40,
            height: 40
        )
        lockBtn.center.y = center.y
    }

    func videoPlayer(_ videoPlayer: IRPlayerController, presentationSizeChanged size: CGSize) {
        lockBtn.isHidden = playerController?.orientationObserver.fullScreenMode == .portrait
    }

    func videoPlayer(_ videoPlayer: IRPlayerController, currentTime: TimeInterval, totalTime: TimeInterval) {
        guard !(slider.isDragging) else { return }

        let currentTimeString = IRUtilities.convertTimeSecond(Int(currentTime))
        currentTimeLabel.text = currentTimeString

        let totalTimeString = IRUtilities.convertTimeSecond(Int(totalTime))
        totalTimeLabel.text = totalTimeString

        slider.value = videoPlayer.progress
    }

    func videoPlayer(_ videoPlayer: IRPlayerController, bufferTime: TimeInterval) {
        slider.bufferValue = Float(videoPlayer.bufferProgress)
    }

    func showTitle(_ title: String, fullScreenMode: IRFullScreenMode) {
        titleLabel.text = title
        playerController?.orientationObserver.fullScreenMode = fullScreenMode
        lockBtn.isHidden = fullScreenMode == .portrait
    }

    // MARK: - Actions

    @objc private func backBtnClickAction() {
        lockBtn.isSelected = false
        playerController?.lockedScreen = false
        if let supportsPortrait = playerController?.orientationObserver.supportInterfaceOrientation,
           supportsPortrait.contains(.portrait) {
            playerController?.enterFullScreen(false, animated: true)
        }
        backBtnClickCallback?()
    }

    @objc private func playPauseButtonClickAction() {
        playOrPause()
    }

    @objc private func lockButtonClickAction() {
        lockBtn.isSelected.toggle()
        playerController?.lockedScreen = lockBtn.isSelected
    }

    @objc private func layOutControllerViews() {
        setNeedsLayout()
    }

    // MARK: - Methods

    func resetControlView() {
        slider.value = 0
        slider.bufferValue = 0
        currentTimeLabel.text = "00:00"
        totalTimeLabel.text = "00:00"
        backgroundColor = .clear
        playOrPauseBtn.isSelected = true
        titleLabel.text = ""
        topToolView.alpha = 1
        bottomToolView.alpha = 1
        isShow = false
    }

    func playOrPause() {
        playOrPauseBtn.isSelected.toggle()
        if playOrPauseBtn.isSelected {
            playerController?.currentPlayerManager.play()
        } else {
            playerController?.currentPlayerManager.pause()
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

        // 如果屏幕已锁定且手势不是单击，则不响应手势
        if (playerController?.isLockedScreen ?? false) && type != .singleTap {
            return false
        }

        return true
    }

    /// 调节播放进度 slider 和当前时间更新
    func sliderValueChanged(_ value: CGFloat, currentTimeString: String) {
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
}
