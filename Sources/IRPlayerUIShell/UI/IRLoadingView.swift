//
//  IRLoadingView.swift
//  IRPlayerUIShell
//
//  Created by irons on 2025/1/12.
//

import UIKit

enum IRLoadingType: UInt {
    case keep
    case fadeOut
}

class IRLoadingView: UIView {

    // MARK: - Properties

    /// Default is IRLoadingType.keep
    var animType: IRLoadingType = .keep

    /// Default is white
    var lineColor: UIColor = .white {
        didSet {
            shapeLayer.strokeColor = lineColor.cgColor
        }
    }

    /// Sets the line width of the spinner's circle
    var lineWidth: CGFloat = 1 {
        didSet {
            shapeLayer.lineWidth = lineWidth
        }
    }

    /// Sets whether the view is hidden when not animating
    var hidesWhenStopped: Bool = true {
        didSet {
            self.isHidden = !isAnimating && hidesWhenStopped
        }
    }

    /// Property indicating the duration of the animation, default is 1.5s
    var duration: TimeInterval = 1.5

    /// Indicates whether the animation is currently active
    private(set) var isAnimating: Bool = false

    private lazy var shapeLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.strokeColor = lineColor.cgColor
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeStart = 0.1
        layer.strokeEnd = 1.0
        layer.lineCap = .round
        layer.lineWidth = lineWidth
        return layer
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

    private func initialize() {
        layer.addSublayer(shapeLayer)
        self.isUserInteractionEnabled = false
        self.isHidden = true
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        let size = min(bounds.size.width, bounds.size.height)
        shapeLayer.frame = CGRect(x: 0, y: 0, width: size, height: size)

        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = (size / 2) - (shapeLayer.lineWidth / 2)
        let startAngle: CGFloat = 0
        let endAngle: CGFloat = 2 * .pi

        let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        shapeLayer.path = path.cgPath
    }

    // MARK: - Animation Control

    func startAnimating() {
        guard !isAnimating else { return }
        isAnimating = true

        if animType == .fadeOut {
            applyFadeOutAnimation()
        } else {
            applyRotationAnimation()
        }

        if hidesWhenStopped {
            self.isHidden = false
        }
    }

    func stopAnimating() {
        guard isAnimating else { return }
        isAnimating = false
        shapeLayer.removeAllAnimations()
        if hidesWhenStopped {
            self.isHidden = true
        }
    }

    // MARK: - Private Methods

    private func applyRotationAnimation() {
        let rotationAnim = CABasicAnimation(keyPath: "transform.rotation.z")
        rotationAnim.toValue = 2 * Double.pi
        rotationAnim.duration = duration
        rotationAnim.repeatCount = .greatestFiniteMagnitude
        rotationAnim.isRemovedOnCompletion = false
        shapeLayer.add(rotationAnim, forKey: "rotation")
    }

    private func applyFadeOutAnimation() {
        let headAnimation = CABasicAnimation(keyPath: "strokeStart")
        headAnimation.duration = duration / 1.5
        headAnimation.fromValue = 0.0
        headAnimation.toValue = 0.25

        let tailAnimation = CABasicAnimation(keyPath: "strokeEnd")
        tailAnimation.duration = duration / 1.5
        tailAnimation.fromValue = 0.0
        tailAnimation.toValue = 1.0

        let endHeadAnimation = CABasicAnimation(keyPath: "strokeStart")
        endHeadAnimation.beginTime = duration / 1.5
        endHeadAnimation.duration = duration / 3.0
        endHeadAnimation.fromValue = 0.25
        endHeadAnimation.toValue = 1.0

        let endTailAnimation = CABasicAnimation(keyPath: "strokeEnd")
        endTailAnimation.beginTime = duration / 1.5
        endTailAnimation.duration = duration / 3.0
        endTailAnimation.fromValue = 1.0
        endTailAnimation.toValue = 1.0

        let animationGroup = CAAnimationGroup()
        animationGroup.duration = duration
        animationGroup.animations = [headAnimation, tailAnimation, endHeadAnimation, endTailAnimation]
        animationGroup.repeatCount = .greatestFiniteMagnitude
        animationGroup.isRemovedOnCompletion = false
        shapeLayer.add(animationGroup, forKey: "fadeOut")
    }
}
