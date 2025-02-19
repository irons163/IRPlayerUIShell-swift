//
//  IRSliderView.swift
//  IRPlayerUIShell
//
//  Created by irons on 2025/1/12.
//

import UIKit

// MARK: - Delegate Protocol
protocol IRSliderViewDelegate: AnyObject {
    // Slider touch began
    func sliderTouchBegan(value: CGFloat)
    // Slider value changed
    func sliderValueChanged(value: CGFloat)
    // Slider touch ended
    func sliderTouchEnded(value: CGFloat)
    // Slider tapped
    func sliderTapped(value: CGFloat)
}

// MARK: - IRSliderButton
class IRSliderButton: UIButton {
    // Expand the touch area of the button
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let bounds = self.bounds.insetBy(dx: -20, dy: -20)
        return bounds.contains(point)
    }
}

// MARK: - IRSliderView
class IRSliderView: UIView {

    // MARK: - Public Properties
    weak var delegate: IRSliderViewDelegate?

    /// Default track color
    var maximumTrackTintColor: UIColor = .gray {
        didSet {
            bgProgressView.backgroundColor = maximumTrackTintColor
        }
    }

    /// Progress track color
    var minimumTrackTintColor: UIColor = .red {
        didSet {
            sliderProgressView.backgroundColor = minimumTrackTintColor
        }
    }

    /// Buffer track color
    var bufferTrackTintColor: UIColor = .white {
        didSet {
            bufferProgressView.backgroundColor = bufferTrackTintColor
        }
    }

    /// Loading bar color
    var loadingTintColor: UIColor = .white {
        didSet {
            loadingBarView.backgroundColor = loadingTintColor
        }
    }

    /// Default track image
    var maximumTrackImage: UIImage? {
        didSet {
            bgProgressView.image = maximumTrackImage
            maximumTrackTintColor = .clear
        }
    }

    /// Progress track image
    var minimumTrackImage: UIImage? {
        didSet {
            sliderProgressView.image = minimumTrackImage
            minimumTrackTintColor = .clear
        }
    }

    /// Buffer track image
    var bufferTrackImage: UIImage? {
        didSet {
            bufferProgressView.image = bufferTrackImage
            bufferTrackTintColor = .clear
        }
    }

    /// Slider value
    var value: CGFloat = 0 {
        didSet {
            updateSliderPosition()
        }
    }

    /// Buffer value
    var bufferValue: Float = 0 {
        didSet {
            bufferProgressView.frame.size.width = bgProgressView.frame.width * CGFloat(bufferValue)
        }
    }

    /// Allow tapping
    var allowTapped: Bool = true {
        didSet {
            tapGesture.isEnabled = allowTapped
        }
    }

    /// Animate slider interactions
    var animate: Bool = true

    /// Slider height
    var sliderHeight: CGFloat = 1 {
        didSet {
            updateSliderHeight()
        }
    }

    /// Slider corner radius
    var sliderRadius: CGFloat = 0 {
        didSet {
            updateSliderCornerRadius()
        }
    }

    /// Hide slider block
    var isHideSliderBlock: Bool = false {
        didSet {
            sliderBtn.isHidden = isHideSliderBlock
            allowTapped = !isHideSliderBlock
        }
    }

    // MARK: - Private Properties
    private let bgProgressView = UIImageView()
    private let bufferProgressView = UIImageView()
    private let sliderProgressView = UIImageView()
    let sliderBtn = IRSliderButton()
    private let loadingBarView = UIView()
    var isDragging = false
    private(set) var isForward = false
    private let tapGesture = UITapGestureRecognizer()

    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    // MARK: - View Setup
    private func setupViews() {
        backgroundColor = .clear

        // Add subviews
        addSubview(bgProgressView)
        addSubview(bufferProgressView)
        addSubview(sliderProgressView)
        addSubview(sliderBtn)
        addSubview(loadingBarView)

        // Configure loading bar
        loadingBarView.backgroundColor = .white
        loadingBarView.isHidden = true

        // Configure gestures
        tapGesture.addTarget(self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tapGesture)

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(panGesture)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let height = sliderHeight
        bgProgressView.frame = CGRect(x: 0, y: (bounds.height - height) / 2, width: bounds.width, height: height)
        bufferProgressView.frame = CGRect(x: 0, y: (bounds.height - height) / 2, width: CGFloat(bufferValue) * bounds.width, height: height)
        sliderProgressView.frame = CGRect(x: 0, y: (bounds.height - height) / 2, width: CGFloat(value) * bounds.width, height: height)
        sliderBtn.frame.size = CGSize(width: 19, height: 19)
        sliderBtn.center = CGPoint(x: CGFloat(value) * bounds.width, y: bounds.height / 2)
        loadingBarView.frame = CGRect(x: 0, y: (bounds.height - height) / 2, width: 0.1, height: height)
    }

    // MARK: - Gesture Handlers
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: bgProgressView)
        value = point.x / bounds.width
        delegate?.sliderTapped(value: value)
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let point = gesture.location(in: bgProgressView)
        let newValue = point.x / bounds.width
        switch gesture.state {
        case .began:
            isDragging = true
            delegate?.sliderTouchBegan(value: newValue)
        case .changed:
            value = newValue
            isForward = value > newValue
            delegate?.sliderValueChanged(value: value)
        case .ended, .cancelled:
            isDragging = false
            delegate?.sliderTouchEnded(value: value)
        default:
            break
        }
    }

    // MARK: - Helper Methods
    private func updateSliderPosition() {
        sliderBtn.center.x = CGFloat(value) * bgProgressView.frame.width
        sliderProgressView.frame.size.width = sliderBtn.center.x
    }

    private func updateSliderHeight() {
        [bgProgressView, bufferProgressView, sliderProgressView].forEach {
            $0.frame.size.height = sliderHeight
        }
    }

    private func updateSliderCornerRadius() {
        [bgProgressView, bufferProgressView, sliderProgressView].forEach {
            $0.layer.cornerRadius = sliderRadius
            $0.clipsToBounds = true
        }
    }

    func startAnimating() {
        loadingBarView.isHidden = false
        sliderBtn.isHidden = true
        bufferProgressView.isHidden = true
        sliderProgressView.isHidden = true
    }

    func stopAnimating() {
        loadingBarView.isHidden = true
        sliderBtn.isHidden = isHideSliderBlock
        bufferProgressView.isHidden = false
        sliderProgressView.isHidden = false
    }


    /// Sets the thumb image for a specific control state
    func setThumbImage(_ image: UIImage?, for state: UIControl.State) {
        sliderBtn.setImage(image, for: state)
    }
}
