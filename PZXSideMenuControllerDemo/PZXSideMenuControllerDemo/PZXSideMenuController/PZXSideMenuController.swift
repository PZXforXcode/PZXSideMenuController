//
//  PZXSideMenuController.swift
//  iOS-PGFlight-app
//
//  Created by 彭祖鑫 on 2025/6/10.
//  Copyright © 2025 Pingalax. All rights reserved.
//

// 改进版 PZXSideMenuController.swift
// 支持：1. 侧边栏在主界面上层弹出 2. 随手势滑动回弹 3. 支持边缘右滑手势触发
// 4. 解决与ScrollView/CollectionView的手势冲突问题

import UIKit

class PZXSideMenuController: UIViewController, UIGestureRecognizerDelegate {

    // MARK: - Public Properties
    
    /// 当前活跃的侧边栏控制器实例，用于外部访问
    public static weak var shared: PZXSideMenuController?

    let menuWidth: CGFloat = UIScreen.main.bounds.width * 0.8
    let sideMenuViewController: UIViewController
    let mainViewController: UIViewController
    
    /// 边缘手势触发区域的宽度，默认为20点
    public var edgeGestureWidth: CGFloat = 20
    
    /// 快速滑动的速度阈值，默认为300点/秒
    public var fastSwipeVelocityThreshold: CGFloat = 300

    // MARK: - 触感反馈生成器
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    // 标记是否已经触发过触感反馈
    private var hasTriggeredHaptic = false

    // MARK: - Private Properties

    private let overlayView = UIView()
    private var isMenuOpen = false
    private var panGesture: UIPanGestureRecognizer!
    private var edgePanGesture: UIScreenEdgePanGestureRecognizer!
    
    /// 追踪边缘手势是否正在进行中
    private var isEdgeGestureInProgress = false

    // MARK: - Init

    init(sideMenu: UIViewController, main: UIViewController) {
        self.sideMenuViewController = sideMenu
        self.mainViewController = main
        super.init(nibName: nil, bundle: nil)
        
        // 设置为当前活跃实例
        PZXSideMenuController.shared = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupChildControllers()
        setupOverlay()
        setupGestures()
    }

    // MARK: - Setup

    private func setupChildControllers() {
        addChild(mainViewController)
        view.addSubview(mainViewController.view)
        mainViewController.view.frame = view.bounds
        mainViewController.didMove(toParent: self)

        addChild(sideMenuViewController)
        view.addSubview(sideMenuViewController.view)
        sideMenuViewController.view.frame = CGRect(x: -menuWidth, y: 0, width: menuWidth, height: view.bounds.height)
        sideMenuViewController.view.layer.zPosition = 1000
        sideMenuViewController.didMove(toParent: self)
    }

    private func setupOverlay() {
        overlayView.frame = view.bounds
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        overlayView.alpha = 0
        overlayView.isUserInteractionEnabled = true
        overlayView.layer.zPosition = 999
        view.insertSubview(overlayView, aboveSubview: mainViewController.view)

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTapToCloseMenu))
        overlayView.addGestureRecognizer(tap)
    }

    private func setupGestures() {
        // 主界面边缘右滑打开菜单
        edgePanGesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleEdgePan(_:)))
        edgePanGesture.edges = .left
        edgePanGesture.delegate = self
        view.addGestureRecognizer(edgePanGesture)

        // 菜单界面滑动关闭
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.delegate = self
        view.addGestureRecognizer(panGesture)
    }

    // MARK: - Gesture Handling

    @objc private func handleEdgePan(_ gesture: UIScreenEdgePanGestureRecognizer) {
        let translation = gesture.translation(in: view).x
        let velocity = gesture.velocity(in: view).x
        let offset = min(max(translation, 0), menuWidth)

        switch gesture.state {
        case .began:
            // 标记边缘手势开始
            isEdgeGestureInProgress = true
            hasTriggeredHaptic = false
            print("🔄 边缘手势开始，位置: \(gesture.location(in: view))")
            
        case .changed:
            // 实时跟随手势滑动，营造流畅的滑动感觉
            sideMenuViewController.view.frame.origin.x = -menuWidth + offset
            overlayView.alpha = offset / menuWidth * 0.4
            
            // 当菜单首次滑出时触发触感反馈
            if !hasTriggeredHaptic && offset > 0 {
                impactLight.impactOccurred()
                hasTriggeredHaptic = true
            }
            
            print("🔄 边缘手势变化，偏移: \(offset), 菜单X: \(-menuWidth + offset)")
            
        case .ended, .cancelled:
            // 重置边缘手势状态
            isEdgeGestureInProgress = false
            hasTriggeredHaptic = false
            
            // 考虑速度和位置来决定是否打开
            let shouldOpen = offset > menuWidth / 3 || velocity > fastSwipeVelocityThreshold
            print("🔄 边缘手势结束，偏移: \(offset), 速度: \(velocity), 是否打开: \(shouldOpen)")
            
            if shouldOpen {
                openMenu(animated: true)
            } else {
                closeMenu(animated: true)
            }
            
        case .failed:
            // 重置边缘手势状态
            isEdgeGestureInProgress = false
            hasTriggeredHaptic = false
            print("🔄 边缘手势失败")
            
        default:
            break
        }
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard isMenuOpen else { return }
        let translation = gesture.translation(in: view).x
        let velocity = gesture.velocity(in: view).x
        let offset = min(max(menuWidth + translation, 0), menuWidth)

        switch gesture.state {
        case .began:
            hasTriggeredHaptic = false
            print("📱 返回手势开始，当前偏移: \(offset)")
            
        case .changed:
            sideMenuViewController.view.frame.origin.x = -menuWidth + offset
            overlayView.alpha = offset / menuWidth * 0.4
            print("📱 返回手势变化，偏移: \(offset), 菜单X: \(-menuWidth + offset)")
            
        case .ended, .cancelled:
            // 考虑速度和位置来决定是否关闭
            // 如果向左滑动速度大于阈值，或者偏移距离小于一半宽度，则关闭菜单
            let shouldClose = offset < menuWidth / 2 || velocity < -fastSwipeVelocityThreshold
            
            print("📱 返回手势结束")
            print("   - 当前偏移: \(offset) / \(menuWidth)")
            print("   - 滑动速度: \(velocity)")
            print("   - 位置判断: \(offset < menuWidth / 2 ? "应关闭" : "应保持")")
            print("   - 速度判断: \(velocity < -fastSwipeVelocityThreshold ? "快速左滑，应关闭" : "速度不够")")
            print("   - 最终决定: \(shouldClose ? "关闭菜单" : "保持打开")")
            
            if shouldClose {
                closeMenu(animated: true)
            } else {
                openMenu(animated: true)
            }
            
        default:
            break
        }
    }

    // MARK: - Public Methods
    
    /// 从外部代码打开侧边栏的类方法
    /// - Parameter animated: 是否使用动画，默认为true
    /// - Returns: 是否成功执行操作
    @discardableResult
    public static func openSideMenu(animated: Bool = true) -> Bool {
        guard let instance = shared else {
            print("⚠️ PZXSideMenuController实例不存在，无法打开侧边栏")
            return false
        }
        
        guard !instance.isMenuOpen else {
            print("⚠️ 侧边栏已经打开")
            return false
        }
        
        print("🌐 通过外部代码打开侧边栏")
        instance.openMenu(animated: animated)
        return true
    }
    
    /// 从外部代码关闭侧边栏的类方法
    /// - Parameter animated: 是否使用动画，默认为true
    /// - Returns: 是否成功执行操作
    @discardableResult
    public static func closeSideMenu(animated: Bool = true) -> Bool {
        guard let instance = shared else {
            print("⚠️ PZXSideMenuController实例不存在，无法关闭侧边栏")
            return false
        }
        
        guard instance.isMenuOpen else {
            print("⚠️ 侧边栏已经关闭")
            return false
        }
        
        print("🌐 通过外部代码关闭侧边栏")
        instance.closeMenu(animated: animated)
        return true
    }
    
    /// 获取当前侧边栏是否打开的状态
    /// - Returns: true表示打开，false表示关闭，nil表示实例不存在
    public static func isMenuOpen() -> Bool? {
        return shared?.isMenuOpen
    }

    func openMenu(animated: Bool = true) {
        isMenuOpen = true
        print("✅ 打开侧边栏")
        
        // 触发侧边栏视图控制器的生命周期事件
        sideMenuViewController.beginAppearanceTransition(true, animated: animated)
        
        UIView.animate(withDuration: animated ? 0.3 : 0, animations: {
            self.sideMenuViewController.view.frame.origin.x = 0
            self.overlayView.alpha = 0.4
        }) { _ in
            // 动画完成后触发DidAppear
            self.sideMenuViewController.endAppearanceTransition()
        }
    }

    /// 专门处理点击overlay关闭菜单的方法
    @objc private func handleTapToCloseMenu() {
        print("👆 点击overlay关闭侧边栏")
        closeMenu(animated: true)
    }

    @objc func closeMenu(animated: Bool = true) {
        isMenuOpen = false
        isEdgeGestureInProgress = false // 确保状态重置
        print("❌ 关闭侧边栏")
        
        // 触发侧边栏视图控制器的生命周期事件
        sideMenuViewController.beginAppearanceTransition(false, animated: animated)
        
        UIView.animate(withDuration: animated ? 0.3 : 0, animations: {
            self.sideMenuViewController.view.frame.origin.x = -self.menuWidth
            self.overlayView.alpha = 0
        }) { _ in
            // 动画完成后触发DidDisappear
            self.sideMenuViewController.endAppearanceTransition()
        }
    }

    // MARK: - Gesture Recognizer Delegate

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gestureRecognizer == panGesture {
            return isMenuOpen
        }
        
        // 对于边缘手势，只在边缘区域响应
        if gestureRecognizer == edgePanGesture {
            let location = touch.location(in: view)
            // 只在屏幕左边缘指定范围内响应，并且菜单当前是关闭的
            return location.x <= edgeGestureWidth && !isMenuOpen
        }
        
        return true
    }
    
    // 允许边缘手势与其他手势同时识别
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // 如果是边缘手势与ScrollView或CollectionView的手势
        if gestureRecognizer == edgePanGesture {
            // 在边缘手势进行中，不允许同时识别其他手势，确保流畅性
            if isEdgeGestureInProgress {
                return false
            }
            
            let location = gestureRecognizer.location(in: view)
            // 只在边缘区域允许同时识别
            if location.x <= edgeGestureWidth {
                return true
            }
        }
        return false
    }
    
    // 边缘手势在特定条件下应该优先于其他手势
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == edgePanGesture {
            // 在边缘区域，边缘手势优先
            if let touch = otherGestureRecognizer.view?.gestureRecognizers?.first?.location(in: view),
               touch.x <= edgeGestureWidth {
                // 如果其他手势是水平滚动相关的，让边缘手势优先
                if otherGestureRecognizer is UIPanGestureRecognizer {
                    return true
                }
            }
        }
        return false
    }
}

//用法
/**
 // 1. 初始化和设置
 let sideMenu = PZXSideMenuController(sideMenu: vc, main: homeVC)
 let sideMenuNavVC = UINavigationController.init(rootViewController: sideMenu)
 window?.rootViewController = sideMenuNavVC
 
 // 2. 外部代码控制侧边栏
 PZXSideMenuController.openSideMenu()     // 打开侧边栏
 PZXSideMenuController.closeSideMenu()    // 关闭侧边栏
 PZXSideMenuController.openSideMenu(animated: false)  // 无动画打开
 
 // 3. 检查状态
 if let isOpen = PZXSideMenuController.isMenuOpen() {
     print("侧边栏状态: \(isOpen ? "打开" : "关闭")")
 }
 */
