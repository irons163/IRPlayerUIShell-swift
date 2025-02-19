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
        button.setImage(IRUtilities.image(named: "play"), for: .normal)
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
        playBtn.frame = CGRect(x: (containerView.frame.width - buttonSize) / 2, y: (containerView.frame.height - buttonSize) / 2, width: buttonSize, height: buttonSize)

        let buttonWidth: CGFloat = 100
        let buttonHeight: CGFloat = 30
        changeBtn.frame = CGRect(x: (view.frame.width - buttonWidth) / 2, y: containerView.frame.maxY + 50, width: buttonWidth, height: buttonHeight)
        nextBtn.frame = CGRect(x: (view.frame.width - buttonWidth) / 2, y: changeBtn.frame.maxY + 50, width: buttonWidth, height: buttonHeight)
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
            playerImp.replaceVideoWithURL(contentURL: normalVideoURL)
        }
    }

    private func setupPlayer() {
        player = IRPlayerController(playerManager: playerImp, containerView: containerView)
        player.controlView = controlView
        player.pauseWhenAppResignActive = false

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
        containerView.addSubview(playBtn)
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
