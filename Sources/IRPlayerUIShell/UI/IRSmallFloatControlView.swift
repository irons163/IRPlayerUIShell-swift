//
//  IRSmallFloatControlView.swift
//  IRPlayerUIShell
//
//  Created by irons on 2025/1/12.
//

import UIKit

class IRSmallFloatControlView: UIView {

    // MARK: - Properties

    /// Callback for close button click
    var closeClickCallback: (() -> Void)?

    /// Close button
    private lazy var closeBtn: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(IRUtilities.image(named: "IRPlayer_close"), for: .normal)
        button.addTarget(self, action: #selector(closeBtnClick), for: .touchUpInside)
        return button
    }()

    // MARK: - Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(closeBtn)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        addSubview(closeBtn)
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        let minViewWidth = bounds.width
        let closeButtonWidth: CGFloat = 30
        let closeButtonX = minViewWidth - 20
        let closeButtonY: CGFloat = -10
        closeBtn.frame = CGRect(x: closeButtonX, y: closeButtonY, width: closeButtonWidth, height: closeButtonWidth)
    }

    // MARK: - Actions

    @objc private func closeBtnClick() {
        closeClickCallback?()
    }
}
