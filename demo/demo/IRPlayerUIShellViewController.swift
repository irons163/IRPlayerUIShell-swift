//
//  IRPlayerUIShellViewController.swift
//  demo
//
//  Created by irons on 2025/1/23.
//

import UIKit
import IRPlayerSwift
import IRPlayerUIShell
import SDWebImage

class MyImageView: UIImageView {

    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        super.hitTest(point, with: event)
    }
}

class IRPlayerUIShellViewController: UIViewController {

    // MARK: - Properties

    private var playerImp: IRPlayerImp!
    private var playerManager: IRPlayerManagerAdapter!
    private var player: IRPlayerController!
    
    private lazy var containerView: UIImageView = {
        let imageView = UIImageView()
        let placeholder = IRUtilities.image(withColor: UIColor(red: 220/255.0, green: 220/255.0, blue: 220/255.0, alpha: 1), size: CGSize(width: 1, height: 1))
        imageView.sd_setImage(with: URL(string: kVideoCover), placeholderImage: placeholder)
        return imageView
    }()

    private lazy var controlView: IRPlayerControlView = {
        let view = IRPlayerControlView()
        view.fastViewAnimated = true
        view.autoHiddenTimeInterval = 5
        view.autoFadeTimeInterval = 0.5
        view.prepareShowLoading = true
        view.prepareShowControlView = true
        return view
    }()

    private lazy var playBtn: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "play"), for: .normal)
        button.addTarget(self, action: #selector(playClick(_:)), for: .touchUpInside)
        return button
    }()

    private lazy var changeBtn: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Change video", for: .normal)
        button.addTarget(self, action: #selector(changeVideo(_:)), for: .touchUpInside)
        return button
    }()

    private lazy var nextBtn: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Next", for: .normal)
        button.addTarget(self, action: #selector(nextClick(_:)), for: .touchUpInside)
        return button
    }()

    private lazy var assetURLs: [URL] = {
        return [
            URL(string: "https://www.apple.com/105/media/us/iphone-x/2017/01df5b43-28e4-4848-bf20-490c34a926a7/films/feature/iphone-x-feature-tpl-cc-us-20170912_1280x720h.mp4")!,
            URL(string: "https://www.apple.com/105/media/cn/mac/family/2018/46c4b917_abfd_45a3_9b51_4e3054191797/films/bruce/mac-bruce-tpl-cn-2018_1280x720h.mp4")!,
            URL(string: "https://www.apple.com/105/media/us/mac/family/2018/46c4b917_abfd_45a3_9b51_4e3054191797/films/peter/mac-peter-tpl-cc-us-2018_1280x720h.mp4")!,
            URL(string: "https://www.apple.com/105/media/us/mac/family/2018/46c4b917_abfd_45a3_9b51_4e3054191797/films/grimes/mac-grimes-tpl-cc-us-2018_1280x720h.mp4")!,
            URL(string: "http://www.flashls.org/playlists/test_001/stream_1000k_48k_640x360.m3u8")!,
            URL(string: "http://tb-video.bdstatic.com/tieba-video/7_517c8948b166655ad5cfb563cc7fbd8e.mp4")!,
            URL(string: "http://tb-video.bdstatic.com/tieba-smallvideo/68_20df3a646ab5357464cd819ea987763a.mp4")!
        ]
    }()

    private let kVideoCover = "https://upload-images.jianshu.io/upload_images/635942-14593722fe3f0695.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240"

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        setupStaticURLs()
        setupPlayer()
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        player.viewControllerDisappear = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player.viewControllerDisappear = true
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        let x: CGFloat = 0
        let y = navigationController?.navigationBar.frame.maxY ?? 0
        let w = view.frame.width
        let h = w * 9 / 16
        containerView.frame = CGRect(x: x, y: y, width: w, height: h)

        let buttonSize: CGFloat = 44
        playBtn.frame = CGRect(x: (view.frame.width - buttonSize) / 2, y: containerView.frame.maxY + 10, width: buttonSize, height: buttonSize)

        let buttonWidth: CGFloat = 100
        let buttonHeight: CGFloat = 30
        changeBtn.frame = CGRect(x: (view.frame.width - buttonWidth) / 2, y: containerView.frame.maxY + 80, width: buttonWidth, height: buttonHeight)
        nextBtn.frame = CGRect(x: (view.frame.width - buttonWidth) / 2, y: changeBtn.frame.maxY + 50, width: buttonWidth, height: buttonHeight)
    }

    @objc private func progressAction(_ notification: Notification) {
        if let userInfo = notification.userInfo {
            let progress = IRProgress.progress(fromUserInfo: userInfo)
            controlView.videoPlayer(player, currentTime: progress.current, totalTime: progress.total)
        }
    }

    @objc private func stateAction(_ notification: Notification) {
        dealWithNotification(notification)
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

    private func dealWithNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo else {
            return
        }

        let state = IRState.state(fromUserInfo: userInfo)
        let playbackState: IRPlaybackState
        switch state.current {
        case .none:
            playbackState = .none
        case .buffering:
            playbackState = .buffering
        case .readyToPlay:
            playbackState = .readyToPlay
        case .playing:
            playbackState = .playing
        case .suspend:
            playbackState = .suspend
        case .finished:
            playbackState = .finished
        case .failed:
            let error = IRError.error(fromUserInfo: userInfo)
            playbackState = .failed(error: error.error)
        }
        self.player.dealWithNotification(state: playbackState)
    }

    // MARK: - Setup Methods

    private func setupStaticURLs() {
        playerImp = IRPlayerImp.player()
        playerImp.viewTapAction = { player, view in
            print("Player display view did click!")
        }
        playerImp.decoder = IRPlayerDecoder.FFmpegDecoder()
        if let normalVideoPath = Bundle.main.path(forResource: "i-see-fire", ofType: "mp4") {
            let normalVideoURL = URL(fileURLWithPath: normalVideoPath)
            playerImp.replaceVideoWithURL(contentURL: normalVideoURL as NSURL)
        }
        registerPlayerNotification()
    }

    private func setupPlayer() {
        playerManager = IRPlayerManagerAdapter(playerImp: playerImp)
        player = IRPlayerController(playerManager: playerManager, containerView: containerView)
        player.gestureControl = IRGestureAdapter()
        if let playerView = player.currentPlayerManager.view {
            player.gestureControl?.addGesture(to: playerView)
        }
        player.controlView = controlView
        player.pauseWhenAppResignActive = true

        player.orientationWillChange = { [weak self] player, isFullScreen in
            self?.setNeedsStatusBarAppearanceUpdate()
        }

        player.playerDidToEnd = { [weak self] asset in
            guard let self = self else { return }
            self.player.currentPlayerManager.pause()
            self.player.currentPlayerManager.play()

            self.player.playTheNext()
            if !self.player.isLastAssetURL {
                let title = "title: \(self.player.currentPlayIndex)"
                self.controlView.showTitle(title, coverURLString: self.kVideoCover, fullScreenMode: .landscape)
            } else {
                self.player.stop()
            }
        }

        player.assetURLs = assetURLs
    }

    private func setupUI() {
        view.backgroundColor = .white
        view.addSubview(containerView)
        view.addSubview(playBtn)
        view.addSubview(changeBtn)
        view.addSubview(nextBtn)
    }

    // MARK: - Actions

    @objc private func changeVideo(_ sender: UIButton) {
        let urlString = "https://www.apple.com/105/media/cn/mac/family/2018/46c4b917_abfd_45a3_9b51_4e3054191797/films/bruce/mac-bruce-tpl-cn-2018_1280x720h.mp4"
        player.assetURL = URL(string: urlString)
        controlView.showTitle("Apple", coverURLString: kVideoCover, fullScreenMode: .automatic)
    }

    @objc private func playClick(_ sender: UIButton) {
        player.playTheIndex(0)
        controlView.showTitle("Video Title", coverURLString: kVideoCover, fullScreenMode: .automatic)
    }

    @objc private func nextClick(_ sender: UIButton) {
        if !player.isLastAssetURL {
            player.playTheNext()
            let title = "Video index: \(player.currentPlayIndex)"
            controlView.showTitle(title, coverURLString: kVideoCover, fullScreenMode: .automatic)
        } else {
            print("Last Video")
        }
    }

    // MARK: - Status Bar Configuration

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return player.isFullScreen ? .lightContent : .default
    }

    override var prefersStatusBarHidden: Bool {
        return player.isStatusBarHidden
    }

    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide
    }

    override var shouldAutorotate: Bool {
        return player.shouldAutorotate
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}

extension IRPlayerUIShellViewController {

    func registerPlayerNotification() {
        playerImp.registerPlayerNotification(
            target: self,
            stateAction: #selector(stateAction),
            progressAction: #selector(progressAction(_:)),
            playableAction: #selector(playableAction(_:)),
            errorAction: #selector(errorAction(_:))
        )
    }

}

final class IRPlayerManagerAdapter: NSObject, IRPlayerManaging {
    private let playerImp: IRPlayerImp

    private(set) var playbackState: IRPlaybackState = .none
    private(set) var progress: TimeInterval = 0
    private(set) var playableTime: TimeInterval = 0

    init(playerImp: IRPlayerImp) {
        self.playerImp = playerImp
        super.init()
        playerImp.registerPlayerNotification(
            target: self,
            stateAction: #selector(handleState(_:)),
            progressAction: #selector(handleProgress(_:)),
            playableAction: #selector(handlePlayable(_:)),
            errorAction: #selector(handleError(_:))
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    var contentURL: URL? {
        playerImp.contentURL as URL?
    }

    var view: UIView? {
        playerImp.view
    }

    var gravityMode: IRViewGravity {
        get {
            switch playerImp.viewGravityMode {
            case .resize: return .resize
            case .resizeAspect: return .aspect
            case .resizeAspectFill: return .aspectFill
            @unknown default: return .aspect
            }
        }
        set {
            switch newValue {
            case .resize: playerImp.viewGravityMode = .resize
            case .aspect: playerImp.viewGravityMode = .resizeAspect
            case .aspectFill: playerImp.viewGravityMode = .resizeAspectFill
            }
        }
    }

    var duration: TimeInterval {
        playerImp.duration
    }

    var playableBufferInterval: TimeInterval {
        playableTime
    }

    func play() {
        playerImp.play()
    }

    func pause() {
        playerImp.pause()
    }

    func replaceVideoWithURL(contentURL: URL?) {
        playerImp.replaceVideoWithURL(contentURL: contentURL as NSURL?, videoType: .normal)
    }

    func seekToTime(time: TimeInterval, completeHandler: ((Bool) -> Void)?) {
        playerImp.seekToTime(time: time, completeHandler: completeHandler)
    }

    func playerManagerCallback() {
        // Notifications are already registered in init.
    }

    @objc private func handleState(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        let state = IRState.state(fromUserInfo: userInfo)
        switch state.current {
        case .none:
            playbackState = .none
        case .buffering:
            playbackState = .buffering
        case .readyToPlay:
            playbackState = .readyToPlay
        case .playing:
            playbackState = .playing
        case .suspend:
            playbackState = .suspend
        case .finished:
            playbackState = .finished
        case .failed:
            if let error = playerImp.error?.error {
                playbackState = .failed(error: error)
            } else {
                playbackState = .failed(error: NSError(domain: "IRPlayer", code: -1))
            }
        }
    }

    @objc private func handleProgress(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        let value = IRProgress.progress(fromUserInfo: userInfo)
        progress = value.current
    }

    @objc private func handlePlayable(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        let value = IRPlayable.playable(fromUserInfo: userInfo)
        playableTime = value.current
    }

    @objc private func handleError(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        let value = IRError.error(fromUserInfo: userInfo)
        playbackState = .failed(error: value.error)
    }
}

final class IRGestureAdapter: NSObject, IRGestureControlling, UIGestureRecognizerDelegate {
    var disableTypes: IRDisableGestureTypes = .none
    var disablePanMovingDirection: IRDisablePanMovingDirection = .none
    var triggerCondition: ((_ control: any IRGestureControlling, _ type: IRGestureType, _ gesture: UIGestureRecognizer, _ point: UITouch) -> Bool)?

    var singleTapped: ((_ control: any IRGestureControlling) -> Void)?
    var doubleTapped: ((_ control: any IRGestureControlling) -> Void)?
    var beganPan: ((_ control: any IRGestureControlling, _ direction: IRPanDirection, _ location: IRPanLocation) -> Void)?
    var changedPan: ((_ control: any IRGestureControlling, _ direction: IRPanDirection, _ location: IRPanLocation, _ velocity: CGPoint) -> Void)?
    var endedPan: ((_ control: any IRGestureControlling, _ direction: IRPanDirection, _ location: IRPanLocation) -> Void)?
    var pinched: ((_ control: any IRGestureControlling, _ scale: CGFloat) -> Void)?

    private weak var hostView: UIView?
    private weak var singleTapGR: UITapGestureRecognizer?
    private weak var doubleTapGR: UITapGestureRecognizer?
    private weak var panGR: UIPanGestureRecognizer?
    private weak var pinchGR: UIPinchGestureRecognizer?

    private var touchCache: [ObjectIdentifier: UITouch] = [:]

    func addGesture(to view: UIView) {
        removeGesture(from: view)
        hostView = view
        view.isUserInteractionEnabled = true

        let single = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap(_:)))
        single.numberOfTapsRequired = 1
        single.delegate = self
        view.addGestureRecognizer(single)
        singleTapGR = single

        let double = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        double.numberOfTapsRequired = 2
        double.delegate = self
        view.addGestureRecognizer(double)
        doubleTapGR = double
        single.require(toFail: double)

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.maximumNumberOfTouches = 1
        pan.delegate = self
        view.addGestureRecognizer(pan)
        panGR = pan

        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        pinch.delegate = self
        view.addGestureRecognizer(pinch)
        pinchGR = pinch
    }

    func removeGesture(from view: UIView) {
        if let singleTapGR { view.removeGestureRecognizer(singleTapGR) }
        if let doubleTapGR { view.removeGestureRecognizer(doubleTapGR) }
        if let panGR { view.removeGestureRecognizer(panGR) }
        if let pinchGR { view.removeGestureRecognizer(pinchGR) }
        touchCache.removeAll()
    }

    @objc private func handleSingleTap(_ gesture: UITapGestureRecognizer) {
        if gesture.state == .ended {
            singleTapped?(self)
        }
    }

    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        if gesture.state == .ended {
            doubleTapped?(self)
        }
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let view = hostView else { return }
        let velocity = gesture.velocity(in: view)
        let location: IRPanLocation = gesture.location(in: view).x < view.bounds.midX ? .left : .right
        let direction: IRPanDirection = abs(velocity.x) >= abs(velocity.y) ? .horizontal : .vertical

        switch gesture.state {
        case .began:
            beganPan?(self, direction, location)
        case .changed:
            changedPan?(self, direction, location, velocity)
        case .ended, .cancelled, .failed:
            endedPan?(self, direction, location)
        default:
            break
        }
    }

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        if gesture.state == .ended {
            pinched?(self, gesture.scale)
        }
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == panGR, disableTypes.contains(.pan) {
            return false
        }
        if gestureRecognizer == pinchGR, disableTypes.contains(.pinch) {
            return false
        }
        if gestureRecognizer == singleTapGR, disableTypes.contains(.singleTap) {
            return false
        }
        if gestureRecognizer == doubleTapGR, disableTypes.contains(.doubleTap) {
            return false
        }

        if let pan = gestureRecognizer as? UIPanGestureRecognizer, let view = hostView {
            let velocity = pan.velocity(in: view)
            if abs(velocity.x) >= abs(velocity.y), disablePanMovingDirection == .horizontal {
                return false
            }
            if abs(velocity.x) < abs(velocity.y), disablePanMovingDirection == .vertical {
                return false
            }
        }
        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        touchCache[ObjectIdentifier(gestureRecognizer)] = touch
        guard let triggerCondition else { return true }

        let type: IRGestureType
        if gestureRecognizer == singleTapGR {
            type = .singleTap
        } else if gestureRecognizer == doubleTapGR {
            type = .doubleTap
        } else if gestureRecognizer == panGR {
            type = .pan
        } else if gestureRecognizer == pinchGR {
            type = .pinch
        } else {
            return true
        }

        return triggerCondition(self, type, gestureRecognizer, touch)
    }
}
