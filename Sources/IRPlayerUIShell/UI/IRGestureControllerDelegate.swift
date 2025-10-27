//
//  IRGestureControllerDelegate.swift
//  IRPlayerUIShell
//
//  Created by irons on 2025/10/27.
//

import UIKit

//@objc public enum IRGestureType: Int {
//    case singleTap
//    case doubleTap
//    case pan
//    case pinch
//}
//
//@objc public enum IRPanDirection: Int {
//    case horizontal
//    case vertical
//}
//
//@objc public enum IRPanLocation: Int {
//    case left
//    case right
//}

//@objc public class IRGestureController: NSObject, UIGestureRecognizerDelegate {
//
//    // MARK: Inputs (由外部配置)
//    public var disableTypes: IRDisableGestureTypes = .none              // 你現有的 enum
//    public var disablePanMovingDirection: IRDisablePanMovingDirection = .none
//
//    public var triggerCondition: ((_ control: IRGestureController,
//                                   _ type: IRGestureType,
//                                   _ gesture: UIGestureRecognizer,
//                                   _ touch: UITouch) -> Bool)?
//
//    // MARK: Outputs (事件回呼，與你現有簽名完全一致)
//    public var singleTapped: ((_ control: IRGestureController) -> Void)?
//    public var doubleTapped: ((_ control: IRGestureController) -> Void)?
//    public var beganPan: ((_ control: IRGestureController, _ direction: IRPanDirection, _ location: IRPanLocation) -> Void)?
//    public var changedPan: ((_ control: IRGestureController, _ direction: IRPanDirection, _ location: IRPanLocation, _ velocity: CGPoint) -> Void)?
//    public var endedPan: ((_ control: IRGestureController, _ direction: IRPanDirection, _ location: IRPanLocation) -> Void)?
//    public var pinched: ((_ control: IRGestureController, _ scale: CGFloat) -> Void)?
//
//    // MARK: Internal
//    private weak var hostView: UIView?
//    private weak var tap1: UITapGestureRecognizer?
//    private weak var tap2: UITapGestureRecognizer?
//    private weak var pan: UIPanGestureRecognizer?
//    private weak var pinch: UIPinchGestureRecognizer?
//
//    // MARK: Lifecycle
//    public override init() { super.init() }
//
//    // 供 IRPlayerController 呼叫
//    public func addGesture(to view: UIView) {
//        removeGesture(to: view) // 先移除避免重複加
//        hostView = view
//
//        let t1 = UITapGestureRecognizer(target: self, action: #selector(onSingleTap(_:)))
//        t1.numberOfTapsRequired = 1
//        t1.delegate = self
//        view.addGestureRecognizer(t1)
//        tap1 = t1
//
//        let t2 = UITapGestureRecognizer(target: self, action: #selector(onDoubleTap(_:)))
//        t2.numberOfTapsRequired = 2
//        t2.delegate = self
//        view.addGestureRecognizer(t2)
//        tap2 = t2
//
//        // 先讓雙擊判贏
//        t1.require(toFail: t2)
//
//        let p = UIPanGestureRecognizer(target: self, action: #selector(onPan(_:)))
//        p.maximumNumberOfTouches = 1
//        p.delegate = self
//        view.addGestureRecognizer(p)
//        pan = p
//
//        let ph = UIPinchGestureRecognizer(target: self, action: #selector(onPinch(_:)))
//        ph.delegate = self
//        view.addGestureRecognizer(ph)
//        pinch = ph
//    }
//
//    public func removeGesture(to view: UIView) {
//        if let t1 = tap1 { view.removeGestureRecognizer(t1) }
//        if let t2 = tap2 { view.removeGestureRecognizer(t2) }
//        if let p = pan   { view.removeGestureRecognizer(p) }
//        if let pi = pinch { view.removeGestureRecognizer(pi) }
//        tap1 = nil; tap2 = nil; pan = nil; pinch = nil
//    }
//
//    // MARK: Actions
//    @objc private func onSingleTap(_ g: UITapGestureRecognizer) {
//        guard disableTypes != .singleTap else { return }
//        guard shouldTrigger(type: .singleTap, gesture: g) else { return }
//        if g.state == .ended { singleTapped?(self) }
//    }
//
//    @objc private func onDoubleTap(_ g: UITapGestureRecognizer) {
//        guard disableTypes != .doubleTap else { return }
//        guard shouldTrigger(type: .doubleTap, gesture: g) else { return }
//        if g.state == .ended { doubleTapped?(self) }
//    }
//
//    @objc private func onPan(_ g: UIPanGestureRecognizer) {
//        guard shouldTrigger(type: .pan, gesture: g) else { return }
//        guard let v = hostView else { return }
//
//        let velocity = g.velocity(in: v)
//        let dir: IRPanDirection = abs(velocity.x) >= abs(velocity.y) ? .horizontal : .vertical
//
//        // 依照 controller 設定限制方向（來自 IRPlayerControlView 的流程）
//        if (dir == .horizontal && disablePanMovingDirection == .horizontal) ||
//           (dir == .vertical && disablePanMovingDirection == .vertical) {
//            return
//        }
//
//        let loc: IRPanLocation = (g.location(in: v).x <= v.bounds.midX) ? .left : .right
//
//        switch g.state {
//        case .began:
//            beganPan?(self, dir, loc)
//        case .changed:
//            changedPan?(self, dir, loc, velocity)
//        case .ended, .cancelled, .failed:
//            endedPan?(self, dir, loc)
//        default:
//            break
//        }
//    }
//
//    @objc private func onPinch(_ g: UIPinchGestureRecognizer) {
//        guard shouldTrigger(type: .pinch, gesture: g) else { return }
//        if g.state == .ended {
//            pinched?(self, g.scale)
//        }
//    }
//
//    // MARK: Helpers
//    private func shouldTrigger(type: IRGestureType, gesture: UIGestureRecognizer) -> Bool {
//        guard let view = hostView else { return false }
//        guard let touch = gesture.touches(in: view)?.first else { return false }
//        return triggerCondition?(self, type, gesture, touch) ?? true
//    }
//
//    // MARK: UIGestureRecognizerDelegate
//    public func gestureRecognizerShouldBegin(_ g: UIGestureRecognizer) -> Bool {
//        // 如果被整體禁用（single/double 以外），在這裡加規則
//        return true
//    }
//
//    public func gestureRecognizer(_ g: UIGestureRecognizer,
//                                  shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
//        // 單/雙擊以 requireToFail 控制；其他不需要同時辨識
//        return false
//    }
//}

// 小工具：從 UIGestureRecognizer 取當前 touches
private extension UIGestureRecognizer {
    func touches(in view: UIView) -> Set<UITouch>? {
        // iOS 沒有公開 API 直接拿到 touches；這個方法只在回傳 triggerCondition 時需要 touch。
        // 我們退而求其次：從 event 的第一顆 touch 取，或改由外層直接用 gesture.location(in:)
        return (self.value(forKey: "_touches") as? Set<UITouch>)
    }
}


public enum IRGestureType { case singleTap, doubleTap, pan, pinch }
public enum IRPanDirection { case horizontal, vertical }
public enum IRPanLocation { case left, right }

public protocol IRGestureControlling: AnyObject {
    // Inputs
    var disableTypes: IRDisableGestureTypes { get set }
    var disablePanMovingDirection: IRDisablePanMovingDirection { get set }

    var triggerCondition: ((_ control: IRGestureControlling,
                            _ type: IRGestureType,
                            _ gesture: UIGestureRecognizer,
                            _ point: UITouch) -> Bool)? { get set }

    // Outputs
    var singleTapped: ((_ control: IRGestureControlling) -> Void)? { get set }
    var doubleTapped: ((_ control: IRGestureControlling) -> Void)? { get set }
    var beganPan: ((_ control: IRGestureControlling, _ direction: IRPanDirection, _ location: IRPanLocation) -> Void)? { get set }
    var changedPan: ((_ control: IRGestureControlling, _ direction: IRPanDirection, _ location: IRPanLocation, _ velocity: CGPoint) -> Void)? { get set }
    var endedPan: ((_ control: IRGestureControlling, _ direction: IRPanDirection, _ location: IRPanLocation) -> Void)? { get set }
    var pinched: ((_ control: IRGestureControlling, _ scale: CGFloat) -> Void)? { get set }

    func addGesture(to view: UIView)
    func removeGesture(from view: UIView)
}
