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
        dealWithNotification(notification, player: playerImp)
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

    private func dealWithNotification(_ notification: Notification, player: IRPlayerManaging) {
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
        playerImp.delegate = self
        playerImp.viewTapAction = { player, view in
            print("Player display view did click!")
        }
        playerImp.decoder = IRPlayerDecoder.FFmpegDecoder()
        if let normalVideoPath = Bundle.main.path(forResource: "i-see-fire", ofType: "mp4") {
            let normalVideoURL = URL(fileURLWithPath: normalVideoPath)
            playerImp.replaceVideoWithURL(contentURL: normalVideoURL)
        }
    }

    private func setupPlayer() {
        player = IRPlayerController(playerManager: playerImp, containerView: containerView)
        player.gestureControl = IRGestureAdapter(playerImp.gestureControl!)
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

extension IRPlayerUIShellViewController: IRPlayerManagingDelegate {

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

public protocol IRPlayerManagingDelegate: AnyObject {
    func registerPlayerNotification()
}

// 非泛型弱盒，專門拿來做 associated object 的弱引用
private final class WeakAnyBox {
    weak var value: AnyObject?
    init(_ value: AnyObject?) { self.value = value }
}

private var kIRPMDelegateKey: UInt8 = 0

extension IRPlayerImp { // ← 前提：IRPlayerImp 是 class，且可用 ObjC runtime

    public var delegate: (any IRPlayerManagingDelegate)? {
        get {
            (objc_getAssociatedObject(self, &kIRPMDelegateKey) as? WeakAnyBox)?
                .value as? IRPlayerManagingDelegate
        }
        set {
            // 注意：這裡轉成 AnyObject? 放到弱盒，避免 'any 協議' + 泛型推斷的報錯
            let box = WeakAnyBox(newValue as AnyObject?)
            objc_setAssociatedObject(self, &kIRPMDelegateKey, box, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

extension IRPlayerImp: @retroactive IRPlayerManaging {

    public func replaceVideoWithURL(contentURL: URL?) {
        self.replaceVideoWithURL(contentURL: contentURL, videoType: .normal)
    }

    public func playerManagerCallback() {
        delegate?.registerPlayerNotification()
    }

    public var playbackState: IRPlaybackState {
        switch self.state {
        case .readyToPlay:  return .readyToPlay
        case .playing:      return .playing
        case .failed:       return .failed(error: NSError())
        case .none:
            return .none
        case .buffering:
            return .buffering
        case .suspend:
            return .suspend
        case .finished:
            return .finished
        @unknown default:   return .unknown
        }
    }

    // MARK: - Gravity mapping

    public var gravityMode: IRViewGravity {
        get {
            switch self.viewGravityMode {            // ← IRPlayerSwift.IRGravityMode
            case .resize:           return .resize
            case .resizeAspect:     return .aspect
            case .resizeAspectFill: return .aspectFill
            @unknown default:       return .aspect
            }
        }
        set {
            let mapped: IRGravityMode
            switch newValue {
            case .resize:      mapped = .resize
            case .aspect:      mapped = .resizeAspect
            case .aspectFill:  mapped = .resizeAspectFill
            }
            self.viewGravityMode = mapped            // 實際套到 IRPlayerImp
        }
    }
}

// ==== 假設 SDK 的型別（請對應你實際 SDK 名稱）====
public typealias SDKGestureController          = IRGestureControllerProtocol
public typealias SDKGestureType                = IRPlayerSwift.IRGestureType
public typealias SDKDisableGestureTypes        = IRPlayerSwift.IRDisableGestureTypes
public typealias SDKDisablePanMovingDirection  = IRPlayerSwift.IRDisablePanMovingDirection
public typealias SDKPanDirection               = IRPlayerSwift.IRPanDirection
public typealias SDKPanLocation                = IRPlayerSwift.IRPanLocation

// ==== 你的介面層型別（在 IRPlayerUIShell / 協議層）====
public typealias MyGestureType               = IRPlayerUIShell.IRGestureType
public typealias MyDisableGestureTypes       = IRPlayerUIShell.IRDisableGestureTypes
public typealias MyDisablePanMovingDirection = IRPlayerUIShell.IRDisablePanMovingDirection
public typealias MyPanDirection              = IRPlayerUIShell.IRPanDirection
public typealias MyPanLocation               = IRPlayerUIShell.IRPanLocation

// ==== 映射（SDK <-> 我方）====
private extension MyGestureType {
    init(_ s: SDKGestureType) {
        switch s {
        case .singleTap: self = .singleTap
        case .doubleTap: self = .doubleTap
        case .pan:       self = .pan
        case .pinch:     self = .pinch
        case .unknown: self = .pan
        @unknown default: self = .pan
        }
    }
}
private extension MyPanDirection {
    init(_ s: SDKPanDirection) {
        self = (s == .horizontal) ? .horizontal : .vertical
    }
}
private extension MyPanLocation {
    init(_ s: SDKPanLocation) {
        self = (s == .left) ? .left : .right
    }
}

// 如果兩邊是 OptionSet，需要做逐項對應；下面示意常見 case
private extension MyDisableGestureTypes {
    init(_ s: SDKDisableGestureTypes) {
        var r: MyDisableGestureTypes = .none
        if s.contains(.singleTap)  { r.insert(.singleTap) }
        if s.contains(.doubleTap)  { r.insert(.doubleTap) }
        if s.contains(.pan)        { r.insert(.pan) }
        if s.contains(.pinch)      { r.insert(.pinch) }
        self = r
    }
}
private extension SDKDisableGestureTypes {
    init(_ m: MyDisableGestureTypes) {
        var r: SDKDisableGestureTypes = .none
        if m.contains(.singleTap)  { r.insert(.singleTap) }
        if m.contains(.doubleTap)  { r.insert(.doubleTap) }
        if m.contains(.pan)        { r.insert(.pan) }
        if m.contains(.pinch)      { r.insert(.pinch) }
        self = r
    }
}
private extension MyDisablePanMovingDirection {
    init(_ s: SDKDisablePanMovingDirection) {
        switch s {
        case .none:       self = .none
        case .horizontal: self = .horizontal
        case .vertical:   self = .vertical
        default:          self = .none
        }
    }
}
private extension SDKDisablePanMovingDirection {
    init(_ m: MyDisablePanMovingDirection) {
        switch m {
        case .none:       self = .none
        case .horizontal: self = .horizontal
        case .vertical:   self = .vertical
        }
    }
}

// ==== Adapter 本體 ====
public final class IRGestureAdapter: IRGestureControlling {

    private let sdk: SDKGestureController
    private weak var hostView: UIView?

    // Inputs
    public var disableTypes: MyDisableGestureTypes {
        get { MyDisableGestureTypes(sdk.disableTypes) }
        set { sdk.disableTypes = SDKDisableGestureTypes(newValue) }
    }
    public var disablePanMovingDirection: MyDisablePanMovingDirection {
        get { MyDisablePanMovingDirection((sdk as? IRGestureController)?.disablePanMovingDirection ?? .none) }
        set { (sdk as? IRGestureController)?.disablePanMovingDirection = SDKDisablePanMovingDirection(newValue) }
    }

    public var triggerCondition: ((_ control: IRGestureControlling,
                                   _ type: MyGestureType,
                                   _ gesture: UIGestureRecognizer,
                                   _ point: UITouch) -> Bool)? {
        didSet { hookTriggerCondition() }
    }

    // Outputs
    public var singleTapped: ((_ control: IRGestureControlling) -> Void)? {
        didSet { sdk.singleTapped = { [weak self] _ in guard let self else { return }; self.singleTapped?(self) } }
    }
    public var doubleTapped: ((_ control: IRGestureControlling) -> Void)? {
        didSet { sdk.doubleTapped = { [weak self] _ in guard let self else { return }; self.doubleTapped?(self) } }
    }
    public var beganPan: ((_ control: IRGestureControlling, _ direction: MyPanDirection, _ location: MyPanLocation) -> Void)? {
        didSet { sdk.beganPan = { [weak self] _, d, l in guard let self else { return }
            self.beganPan?(self, MyPanDirection(d), MyPanLocation(l))
        } }
    }
    public var changedPan: ((_ control: IRGestureControlling, _ direction: MyPanDirection, _ location: MyPanLocation, _ velocity: CGPoint) -> Void)? {
        didSet { sdk.changedPan = { [weak self] _, d, l, v in guard let self else { return }
            self.changedPan?(self, MyPanDirection(d), MyPanLocation(l), v)
        } }
    }
    public var endedPan: ((_ control: IRGestureControlling, _ direction: MyPanDirection, _ location: MyPanLocation) -> Void)? {
        didSet { sdk.endedPan = { [weak self] _, d, l in guard let self else { return }
            self.endedPan?(self, MyPanDirection(d), MyPanLocation(l))
        } }
    }
    public var pinched: ((_ control: IRGestureControlling, _ scale: CGFloat) -> Void)? {
        didSet { sdk.pinched = { [weak self] _, s in guard let self else { return }; self.pinched?(self, s) } }
    }

    // Lifecycle
    public init(_ backend: IRGestureControllerProtocol) {
        self.sdk = backend
        self.triggerCondition = nil
        hookTriggerCondition() // 先橋一次，避免外部忘了設
    }

    // Attach / Detach
    public func addGesture(to view: UIView) {
        hostView = view
        sdk.addGesture(to: view)
    }
    public func removeGesture(from view: UIView) {
        if hostView === view { hostView = nil }
        sdk.removeGesture(to: view)
    }

    // MARK: - Private
    private func hookTriggerCondition() {
        sdk.triggerCondition = { [weak self] _, sdkType, g, touch in
            guard let self, let v = self.hostView else { return true }
//            let p = (g.numberOfTouches > 0) ? g.location(ofTouch: 0, in: v) : g.location(in: v)
            return self.triggerCondition?(self, MyGestureType(sdkType), g, touch) ?? true
        }
    }
}
