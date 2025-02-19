//
//  IRSpeedLoadingView.swift
//  IRPlayerUIShell
//
//  Created by irons on 2025/1/12.
//

import UIKit

let IRNetworkSpeedNotificationKey = "IRNetworkSpeedNotificationKey"

class IRSpeedLoadingView: UIView {

    // MARK: - Properties

    lazy var loadingView: IRLoadingView = {
        let view = IRLoadingView()
        view.lineWidth = 0.8
        view.duration = 1
        view.hidesWhenStopped = true
        return view
    }()

    lazy var speedTextLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 12.0)
        label.textAlignment = .center
        return label
    }()

    private lazy var speedMonitor: IRNetworkSpeedMonitor = {
        return IRNetworkSpeedMonitor()
    }()

    // MARK: - Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialize()
    }

    deinit {
        speedMonitor.stopNetworkSpeedMonitor()
        NotificationCenter.default.removeObserver(self, name: .IRDownloadNetworkSpeedNotification, object: nil)
    }

    // MARK: - Setup

    private func initialize() {
        isUserInteractionEnabled = false
        addSubview(loadingView)
        addSubview(speedTextLabel)

        speedMonitor.startNetworkSpeedMonitor()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(networkSpeedChanged(_:)),
            name: .IRDownloadNetworkSpeedNotification,
            object: nil
        )
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let viewWidth = bounds.width
        let viewHeight = bounds.height

        let loadingViewSize: CGFloat = 44
        loadingView.frame = CGRect(
            x: (viewWidth - loadingViewSize) / 2,
            y: (viewHeight - loadingViewSize) / 2 - 10,
            width: loadingViewSize,
            height: loadingViewSize
        )

        speedTextLabel.frame = CGRect(
            x: 0,
            y: loadingView.frame.maxY + 5,
            width: viewWidth,
            height: 20
        )
    }

    // MARK: - Notifications

    @objc private func networkSpeedChanged(_ notification: Notification) {
        if let downloadSpeed = notification.userInfo?[IRNetworkSpeedNotificationKey] as? String {
            speedTextLabel.text = downloadSpeed
        }
    }

    // MARK: - Methods

    func startAnimating() {
        loadingView.startAnimating()
        isHidden = false
    }

    func stopAnimating() {
        loadingView.stopAnimating()
        isHidden = true
    }
}
