//
//  IROrientationObserver.swift
//  IRPlayerUIShell
//
//  Created by irons on 2025/1/12.
//

import UIKit

// MARK: - Full Screen Mode
public enum IRFullScreenMode: UInt {
    case automatic // Determine full screen mode automatically
    case landscape // Landscape full screen mode
    case portrait  // Portrait full screen mode
}

// MARK: - Rotate Type
enum IRRotateType {
    case normal         // Normal
    case cell           // Cell
    case cellOther      // Cell mode add to other view
}

// MARK: - Orientation Mask
struct IRInterfaceOrientationMask: OptionSet {
    let rawValue: UInt

    static let portrait = IRInterfaceOrientationMask(rawValue: 1 << 0)
    static let landscapeLeft = IRInterfaceOrientationMask(rawValue: 1 << 1)
    static let landscapeRight = IRInterfaceOrientationMask(rawValue: 1 << 2)
    static let portraitUpsideDown = IRInterfaceOrientationMask(rawValue: 1 << 3)
    static let landscape: IRInterfaceOrientationMask = [.landscapeLeft, .landscapeRight]
    static let all: IRInterfaceOrientationMask = [.portrait, .landscapeLeft, .landscapeRight, .portraitUpsideDown]
    static let allButUpsideDown: IRInterfaceOrientationMask = [.portrait, .landscapeLeft, .landscapeRight]
}

// MARK: - Orientation Observer
class IROrientationObserver {

    // MARK: - Public Properties
    weak var fullScreenContainerView: UIView?
    weak var containerView: UIView?
    var isFullScreen: Bool { fullScreen }
    var forceDeviceOrientation = false
    var lockedScreen = false {
        didSet { lockedScreen ? removeDeviceOrientationObserver() : addDeviceOrientationObserver() }
    }
    var orientationWillChange: ((IROrientationObserver, Bool) -> Void)?
    var orientationDidChanged: ((IROrientationObserver, Bool) -> Void)?
    var fullScreenMode: IRFullScreenMode = .landscape
    var duration: CGFloat = 0.30
    var isStatusBarHidden = false
    var currentOrientation: UIInterfaceOrientation = .portrait
    var allowOrientationRotation = true
    var supportInterfaceOrientation: IRInterfaceOrientationMask = .allButUpsideDown

    // MARK: - Private Properties
    private weak var view: UIView?
    private weak var cell: UIView?
    private var playerViewTag: Int = 0
    private var rotateType: IRRotateType = .normal
    private var fullScreen = false
    private lazy var blackView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }()
    private lazy var customWindow: UIWindow = UIWindow(frame: .zero)

    // MARK: - Initialization
    init() {
        addDeviceOrientationObserver()
    }

    deinit {
        removeDeviceOrientationObserver()
        blackView.removeFromSuperview()
    }

    // MARK: - Public Methods
    func updateRotateView(_ rotateView: UIView, containerView: UIView) {
        self.view = rotateView
        self.containerView = containerView
    }

    func cellModelRotateView(_ rotateView: UIView, rotateViewAtCell cell: UIView, playerViewTag: Int) {
        self.rotateType = .cell
        self.view = rotateView
        self.cell = cell
        self.playerViewTag = playerViewTag
    }

    func cellOtherModelRotateView(_ rotateView: UIView, containerView: UIView) {
        self.rotateType = .cellOther
        self.view = rotateView
        self.containerView = containerView
    }

    func addDeviceOrientationObserver() {
        guard !UIDevice.current.isGeneratingDeviceOrientationNotifications else { return }
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(handleDeviceOrientationChange), name: UIDevice.orientationDidChangeNotification, object: nil)
    }

    func removeDeviceOrientationObserver() {
        guard UIDevice.current.isGeneratingDeviceOrientationNotifications else { return }
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
    }

    func enterLandscapeFullScreen(orientation: UIInterfaceOrientation, animated: Bool) {
        guard fullScreenMode != .portrait else { return }
        currentOrientation = orientation
        if forceDeviceOrientation {
            forceDeviceOrientation(orientation: orientation, animated: animated)
        } else {
            normalOrientation(orientation: orientation, animated: animated)
        }
    }

    func enterPortraitFullScreen(_ fullScreen: Bool, animated: Bool) {
        guard fullScreenMode != .landscape else { return }
        self.fullScreen = fullScreen
        guard let view = view else { return }
        let superview: UIView? = fullScreen ? fullScreenContainerView : containerView

        if fullScreen {
            self.view?.frame = view.convert(view.bounds, to: superview)
            superview?.addSubview(view)
        }

        orientationWillChange?(self, fullScreen)
        let frame = superview?.convert(superview!.bounds, to: fullScreenContainerView) ?? .zero

        if animated {
            UIView.animate(withDuration: duration) {
                view.frame = frame
                view.layoutIfNeeded()
            } completion: { _ in
                superview?.addSubview(view)
                view.frame = superview?.bounds ?? .zero
                self.orientationDidChanged?(self, self.fullScreen)
            }
        } else {
            superview?.addSubview(view)
            view.frame = superview?.bounds ?? .zero
            view.layoutIfNeeded()
            orientationDidChanged?(self, self.fullScreen)
        }
    }

    func exitFullScreen(animated: Bool) {
        if fullScreenMode == .landscape {
            enterLandscapeFullScreen(orientation: .portrait, animated: animated)
        } else if fullScreenMode == .portrait {
            enterPortraitFullScreen(false, animated: animated)
        }
    }

    // MARK: - Private Methods
    @objc private func handleDeviceOrientationChange() {
        guard fullScreenMode != .portrait, allowOrientationRotation else { return }
        guard let orientation = UIDevice.current.orientation.interfaceOrientation else { return }
        currentOrientation = orientation
        guard orientation != UIApplication.shared.statusBarOrientation else { return }

        switch orientation {
        case .portrait:
            if supportInterfaceOrientation.contains(.portrait) {
                enterLandscapeFullScreen(orientation: .portrait, animated: true)
            }
        case .landscapeLeft:
            if supportInterfaceOrientation.contains(.landscapeLeft) {
                enterLandscapeFullScreen(orientation: .landscapeLeft, animated: true)
            }
        case .landscapeRight:
            if supportInterfaceOrientation.contains(.landscapeRight) {
                enterLandscapeFullScreen(orientation: .landscapeRight, animated: true)
            }
        default:
            break
        }
    }

    private func forceDeviceOrientation(orientation: UIInterfaceOrientation, animated: Bool) {
        guard let view = view else { return }
        let superview = fullScreen ? fullScreenContainerView : containerView
        view.frame = superview?.bounds ?? .zero
        orientationWillChange?(self, fullScreen)

        if animated {
            UIView.animate(withDuration: duration) {
                view.frame = superview?.bounds ?? .zero
                view.layoutIfNeeded()
            } completion: { _ in
                self.orientationDidChanged?(self, self.fullScreen)
            }
        } else {
            view.frame = superview?.bounds ?? .zero
            view.layoutIfNeeded()
            orientationDidChanged?(self, fullScreen)
        }
    }

    private func normalOrientation(_ orientation: UIInterfaceOrientation, animated: Bool) {
        var superview: UIView?
        var frame: CGRect

        if orientation.isLandscape {
            superview = fullScreenContainerView

            /// Ensure the transition isn't from one side of the screen to the other
            if !isFullScreen {
                view.frame = view.convert(view.frame, to: superview)
            }
            superview?.addSubview(view)
            isFullScreen = true
            orientationWillChange?(self, isFullScreen)

            let fullVC = IRFullViewController()
            fullVC.interfaceOrientationMask = (orientation == .landscapeLeft) ? .landscapeLeft : .landscapeRight
            customWindow.rootViewController = fullVC
        } else {
            isFullScreen = false
            orientationWillChange?(self, isFullScreen)

            let fullVC = IRFullViewController()
            fullVC.interfaceOrientationMask = .portrait
            customWindow.rootViewController = fullVC

            if roateType == .cell {
                superview = cell?.viewWithTag(playerViewTag)
            } else {
                superview = containerView
            }

            if blackView.superview != nil {
                blackView.removeFromSuperview()
            }
        }

        frame = superview?.convert(superview!.bounds, to: fullScreenContainerView) ?? .zero

        if animated {
            UIView.animate(withDuration: duration, animations: {
                self.view.transform = self.getTransformRotationAngle(orientation)
                UIView.animate(withDuration: self.duration, animations: {
                    self.view.frame = frame
                    self.view.layoutIfNeeded()
                })
            }, completion: { _ in
                superview?.addSubview(self.view)
                self.view.frame = superview?.bounds ?? .zero
                if self.isFullScreen {
                    superview?.insertSubview(self.blackView, belowSubview: self.view)
                    self.blackView.frame = superview?.bounds ?? .zero
                }
                self.orientationDidChanged?(self, self.isFullScreen)
            })
        } else {
            view.transform = getTransformRotationAngle(orientation)
            superview?.addSubview(view)
            view.frame = superview?.bounds ?? .zero
            view.layoutIfNeeded()

            if isFullScreen {
                superview?.insertSubview(blackView, belowSubview: view)
                blackView.frame = superview?.bounds ?? .zero
            }

            orientationDidChanged?(self, isFullScreen)
        }
    }

}

// MARK: - Extensions
extension UIDeviceOrientation {
    var interfaceOrientation: UIInterfaceOrientation? {
        switch self {
        case .portrait: return .portrait
        case .landscapeLeft: return .landscapeRight
        case .landscapeRight: return .landscapeLeft
        case .portraitUpsideDown: return .portraitUpsideDown
        default: return nil
        }
    }
}
