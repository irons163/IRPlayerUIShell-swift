//
//  IRVolumeBrightnessView.swift
//  IRPlayerUIShell
//
//  Created by irons on 2025/1/12.
//

import UIKit
import MediaPlayer

enum IRVolumeBrightnessType: Int {
    case volume           // Volume
    case brightness       // Brightness
}

class IRVolumeBrightnessView: UIView {

    // MARK: - Properties

    /// The type of control: volume or brightness.
    private(set) var volumeBrightnessType: IRVolumeBrightnessType = .volume

    /// The progress view to show volume/brightness levels.
    private lazy var progressView: UIProgressView = {
        let progress = UIProgressView()
        progress.progressTintColor = .white
        progress.trackTintColor = UIColor.lightGray.withAlphaComponent(0.4)
        return progress
    }()

    /// The icon representing the type (volume/brightness) or its state.
    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()

    /// The system volume view (hidden off-screen).
    private lazy var volumeView: MPVolumeView = {
        let volume = MPVolumeView()
        volume.frame = CGRect(x: -1000, y: -1000, width: 100, height: 100)
        return volume
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    // MARK: - Setup

    private func setupView() {
        addSubview(iconImageView)
        addSubview(progressView)
        backgroundColor = UIColor.black.withAlphaComponent(0.7)
        layer.cornerRadius = frame.height / 2
        layer.masksToBounds = true
        hideTipView() // Initially hide the view
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let margin: CGFloat = 10
        let iconSize: CGFloat = 20

        // Icon image view
        iconImageView.frame = CGRect(
            x: margin,
            y: (bounds.height - iconSize) / 2,
            width: iconSize,
            height: iconSize
        )

        // Progress view
        let progressX = iconImageView.frame.maxX + margin
        progressView.frame = CGRect(
            x: progressX,
            y: (bounds.height - 2) / 2,
            width: bounds.width - progressX - margin,
            height: 2
        )
    }

    // MARK: - Methods

    /// Updates the progress and changes the icon image based on the volume/brightness type.
    func updateProgress(_ progress: CGFloat, with type: IRVolumeBrightnessType) {
        var adjustedProgress = progress
        if adjustedProgress > 1 { adjustedProgress = 1 }
        if adjustedProgress < 0 { adjustedProgress = 0 }

        self.progressView.progress = Float(adjustedProgress)
        self.volumeBrightnessType = type

        // Update the icon image based on the type and progress level
        let iconImage: UIImage?
        switch type {
        case .volume:
            if adjustedProgress == 0 {
                iconImage = IRUtilities.image(named: "IRPlayer_muted")
            } else if adjustedProgress < 0.5 {
                iconImage = IRUtilities.image(named: "IRPlayer_volume_low")
            } else {
                iconImage = IRUtilities.image(named: "IRPlayer_volume_high")
            }
        case .brightness:
            if adjustedProgress < 0.5 {
                iconImage = IRUtilities.image(named: "IRPlayer_brightness_low")
            } else {
                iconImage = IRUtilities.image(named: "IRPlayer_brightness_high")
            }
        }

        iconImageView.image = iconImage
        showTipView()
    }

    /// Adds the system volume view.
    func addSystemVolumeView() {
        volumeView.removeFromSuperview()
    }

    /// Removes the system volume view.
    func removeSystemVolumeView() {
        UIApplication.shared.keyWindow?.addSubview(volumeView)
    }

    /// Hides the tip view with an animation.
    @objc private func hideTipView() {
        UIView.animate(withDuration: 0.5, animations: {
            self.alpha = 0
        }) { _ in
            self.isHidden = true
        }
    }

    /// Shows the tip view and schedules hiding it after 1.5 seconds.
    private func showTipView() {
        isHidden = false
        alpha = 1
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(hideTipView), object: nil)
        perform(#selector(hideTipView), with: nil, afterDelay: 1.5)
    }
}
