//
//  PullToDismiss.swift
//  PullToDismiss
//
//  Created by Suguru Kishimoto on 11/13/16.
//  Copyright © 2016 Suguru Kishimoto. All rights reserved.
//

import Foundation
import UIKit
protocol PullToDismissDelegate {
    func addOffset(addOffset: CGFloat)
    func finishedDragging(withVelocity velocity: CGPoint)
}
open class PullToDismiss: NSObject {

    public struct Defaults {
        private init() {}
        public static let dismissableHeightPercentage: CGFloat = 0.13
    }


    var delegatePull: PullToDismissDelegate?
    public var dismissAction: (() -> Void)?
    public weak var delegate: UIScrollViewDelegate? {
        didSet {
            var delegates: [UIScrollViewDelegate] = [self]
            if let delegate = delegate {
                delegates.append(delegate)
            }
            proxy = ScrollViewDelegateProxy(delegates: delegates)
        }
    }
    public var dismissableHeightPercentage: CGFloat = Defaults.dismissableHeightPercentage {
        didSet {
            dismissableHeightPercentage = min(max(0.0, dismissableHeightPercentage), 1.0)
        }
    }

    fileprivate var viewPositionY: CGFloat = 0.0
    fileprivate var dragging: Bool = false
    fileprivate var previousContentOffsetY: CGFloat = 0.0
    fileprivate weak var viewController: UIViewController?

    private var __scrollView: UIScrollView?

    private var proxy: ScrollViewDelegateProxy? {
        didSet {
            __scrollView?.delegate = proxy
        }
    }

    private var panGesture: UIPanGestureRecognizer?
    private var navigationBarHeight: CGFloat = 0.0
    convenience public init?(scrollView: UIScrollView) {
        guard let viewController = type(of: self).viewControllerFromScrollView(scrollView) else {
            print("a scrollView must be on the view controller.")
            return nil
        }
        self.init(scrollView: scrollView, viewController: viewController)
    }

    public init(scrollView: UIScrollView, viewController: UIViewController, navigationBar: UIView? = nil) {
        super.init()
        self.proxy = ScrollViewDelegateProxy(delegates: [self])
        self.__scrollView = scrollView
        self.__scrollView?.delegate = self.proxy
        self.viewController = viewController
        
        if let navigationBar = navigationBar ?? viewController.navigationController?.navigationBar {
            let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
            navigationBar.addGestureRecognizer(gesture)
            self.navigationBarHeight = navigationBar.frame.height
            self.panGesture = gesture
        }
    }

    deinit {
        if let panGesture = panGesture {
            panGesture.view?.removeGestureRecognizer(panGesture)
        }

        proxy = nil
        __scrollView?.delegate = nil
        __scrollView = nil
    }

    fileprivate var targetViewController: UIViewController? {
        return viewController?.navigationController ?? viewController
    }

    fileprivate func dismiss() {
        targetViewController?.dismiss(animated: true, completion: nil)
    }

    

    private func updateBackgroundView(rate: CGFloat) {
        print("updateBackgroundView")
    }

    private func deleteBackgroundView() {
        targetViewController?.view.clipsToBounds = true
    }


    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            startDragging()
        case .changed:
            let diff = gesture.translation(in: gesture.view).y
            updateViewPosition(offset: diff)
            gesture.setTranslation(.zero, in: gesture.view)
        case .ended:
          finishDragging(withVelocity: .zero)
        default:
            break
        }
    }

    fileprivate func startDragging() {
        targetViewController?.view.layer.removeAllAnimations()
        viewPositionY = 0.0
    }

    fileprivate func updateViewPosition(offset: CGFloat) {
        var addOffset: CGFloat = offset
        // avoid statusbar gone
        if viewPositionY >= 0 && viewPositionY < 0.05 {
            addOffset = min(max(-0.01, addOffset), 0.01)
        }
        viewPositionY += addOffset
        //targetViewController?.view.frame.origin.y = max(0.0, viewPositionY)
        
        self.delegatePull?.addOffset(addOffset: addOffset)
        let targetViewOriginY: CGFloat = targetViewController?.view.frame.origin.y ?? 0.0
        let targetViewHeight: CGFloat = targetViewController?.view.frame.height ?? 0.0
        let rate: CGFloat = (1.0 - (targetViewOriginY / (targetViewHeight * dismissableHeightPercentage)))

        updateBackgroundView(rate: rate)
    }

    fileprivate func finishDragging(withVelocity velocity: CGPoint) {
        self.delegatePull?.finishedDragging(withVelocity: velocity)
        let originY = targetViewController?.view.frame.origin.y ?? 0.0
        let dismissableHeight = (targetViewController?.view.frame.height ?? 0.0) * dismissableHeightPercentage
        if originY > dismissableHeight || originY > 0 && velocity.y < 0 {
            deleteBackgroundView()
            targetViewController?.view.detachEdgeShadow()
            proxy = nil
            _ = dismissAction?() ?? dismiss()
        } else if originY != 0.0 {
            UIView.perform(.delete, on: [], options: [.allowUserInteraction], animations: { [weak self] in
                self?.targetViewController?.view.frame.origin.y = 0.0
            }) { [weak self] finished in
                if finished {
                    self?.deleteBackgroundView()
                    self?.targetViewController?.view.detachEdgeShadow()
                }
            }
        } else {
            self.deleteBackgroundView()
        }
        viewPositionY = 0.0
    }

    private static func viewControllerFromScrollView(_ scrollView: UIScrollView) -> UIViewController? {
        var responder: UIResponder? = scrollView
        while let r = responder {
            if let viewController = r as? UIViewController {
                return viewController
            }
            responder = r.next
        }
        return nil
    }
}

extension PullToDismiss: UITableViewDelegate {
}

extension PullToDismiss: UICollectionViewDelegate {
}

extension PullToDismiss: UICollectionViewDelegateFlowLayout {
}

extension PullToDismiss: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if dragging {
            let diff = -(scrollView.contentOffset.y - previousContentOffsetY)
            if scrollView.contentOffset.y < -scrollView.contentInset.top || (targetViewController?.view.frame.origin.y ?? 0.0) > 0.0 {
                updateViewPosition(offset: diff)
                scrollView.contentOffset.y = -scrollView.contentInset.top
            }
            previousContentOffsetY = scrollView.contentOffset.y
        }
    }

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        startDragging()
        dragging = true
        previousContentOffsetY = scrollView.contentOffset.y
    }

    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        finishDragging(withVelocity: velocity)
        dragging = false
        previousContentOffsetY = 0.0
    }
}
