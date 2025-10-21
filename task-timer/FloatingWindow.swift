//
//  FloatingWindow.swift
//  TaskTimer
//
//  Created on 2025-10-21.
//

import SwiftUI
import AppKit
import Combine

class FloatingWindow {
    private var window: NSWindow?
    let viewModel = TaskTimerViewModel()
    private var cancellables = Set<AnyCancellable>()
    private var timerCompleteObserver: Any?
    
    // 窗口是否可见
    var isVisible: Bool {
        return window?.isVisible ?? false
    }
    
    init() {
        setupWindow()
        observeCompactMode()
        observeTheme()
        observeWindowMovable()

        // 监听倒计时完成通知，弹窗提醒
        timerCompleteObserver = NotificationCenter.default.addObserver(forName: TaskTimerViewModel.timerDidCompleteNotification, object: nil, queue: .main) { [weak self] _ in
            self?.showTimerCompleteAlert()
        }
    }
    
    deinit {
        if let observer = timerCompleteObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    private func showTimerCompleteAlert() {
        let alert = NSAlert()
        alert.messageText = "专注倒计时结束"
        alert.informativeText = "专注时间已完成，休息一下吧！"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "确定")
        alert.runModal()
    }
    
    private func setupWindow() {
        // 创建内容视图
        let contentView = RootView()
            .environmentObject(viewModel)
        
        // 创建窗口
        window = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 350, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        guard let window = window else { return }
        
        // 窗口基本设置
        window.title = "Task Timer"
        window.contentView = NSHostingView(rootView: contentView)
        window.isReleasedWhenClosed = false
        
        // 关键：设置窗口层级和行为
        window.level = .floating  // 置顶显示
        window.collectionBehavior = [
            .canJoinAllSpaces,      // 在所有空间显示
            .stationary,            // 不随空间切换
            .fullScreenAuxiliary    // 全屏辅助窗口（覆盖全屏应用）
        ]
        
        // 透明度和外观（注意：不要使用 .clear 背景，否则标题栏不可见）
        window.isOpaque = false
        window.alphaValue = viewModel.settings.opacity
        window.hasShadow = true
        
        // 窗口可移动设置
        window.isMovable = viewModel.settings.isWindowMovable
        window.isMovableByWindowBackground = viewModel.settings.isWindowMovable
        
        // 窗口位置
        window.center()
        
        // 监听应用切换，确保窗口始终置顶
        setupWindowObserver()
    }
    
    private func observeCompactMode() {
        // 监听轻量化模式变化
        viewModel.$settings
            .map { $0.isCompactMode }
            .removeDuplicates()
            .sink { [weak self] isCompact in
                self?.updateWindowStyle(isCompact: isCompact)
            }
            .store(in: &cancellables)
    }
    
    private func observeTheme() {
        // 监听主题变化
        viewModel.$settings
            .map { $0.theme }
            .removeDuplicates()
            .sink { [weak self] theme in
                self?.updateAppearance(theme: theme)
            }
            .store(in: &cancellables)
    }
    
    private func observeWindowMovable() {
        // 监听窗口可移动状态变化
        viewModel.$settings
            .map { $0.isWindowMovable }
            .removeDuplicates()
            .sink { [weak self] isMovable in
                self?.updateWindowMovable(isMovable: isMovable)
            }
            .store(in: &cancellables)
    }
    
    private func updateAppearance(theme: Theme) {
        guard let window = window else { return }
        
        switch theme {
        case .light:
            window.appearance = NSAppearance(named: .aqua)
        case .dark:
            window.appearance = NSAppearance(named: .darkAqua)
        case .system:
            window.appearance = nil // 跟随系统
        }
    }
    
    private func updateWindowMovable(isMovable: Bool) {
        guard let window = window else { return }
        window.isMovable = isMovable
        window.isMovableByWindowBackground = isMovable
        
        // 确保窗口样式与当前模式一致
        // 避免在切换模式时出现样式不一致的问题
        let isCompact = viewModel.settings.isCompactMode
        if !isCompact {
            // 如果是普通模式，确保有标题栏
            if !window.styleMask.contains(.titled) {
                window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
                window.hasShadow = true
                window.title = "Task Timer"
            }
        }
    }
    
    private func updateWindowStyle(isCompact: Bool) {
        guard let currentWindow = window else { return }
        
        // 保存当前窗口位置和状态
        let currentFrame = currentWindow.frame
        let isVisible = currentWindow.isVisible
        
        if isCompact {
            // 轻量化模式：无标题栏、完全透明背景、更小尺寸
            currentWindow.styleMask = [.borderless, .resizable]
            currentWindow.backgroundColor = .clear
            currentWindow.alphaValue = viewModel.settings.opacity
            currentWindow.isOpaque = false
            currentWindow.hasShadow = false
            
            // 调整窗口大小
            let newSize = NSSize(width: 280, height: 200)
            currentWindow.setFrame(
                NSRect(origin: currentFrame.origin, size: newSize),
                display: true,
                animate: true
            )
        } else {
            // 正常模式：重新创建窗口以确保标题栏正确显示
            // 这是处理 macOS 窗口样式切换的最可靠方法
            
            // 创建新窗口
            let contentView = RootView()
                .environmentObject(viewModel)
            
            let newWindow = NSWindow(
                contentRect: NSRect(x: currentFrame.origin.x, y: currentFrame.origin.y, width: 350, height: 500),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            
            // 应用窗口设置（关键：不要设置 backgroundColor 为 .clear，这会导致标题栏不可见）
            newWindow.title = "Task Timer"
            newWindow.contentView = NSHostingView(rootView: contentView)
            newWindow.isReleasedWhenClosed = false
            newWindow.level = .floating
            newWindow.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
            
            // 关键修复：正常模式下不设置 isOpaque 为 false，保持默认值以确保标题栏可见
            // newWindow.isOpaque = false  // 注释掉这行
            newWindow.backgroundColor = nil  // 使用默认背景，确保标题栏可见
            newWindow.alphaValue = viewModel.settings.opacity
            newWindow.hasShadow = true
            newWindow.isMovable = viewModel.settings.isWindowMovable
            newWindow.isMovableByWindowBackground = viewModel.settings.isWindowMovable
            
            // 应用主题
            switch viewModel.settings.theme {
            case .light:
                newWindow.appearance = NSAppearance(named: .aqua)
            case .dark:
                newWindow.appearance = NSAppearance(named: .darkAqua)
            case .system:
                newWindow.appearance = nil
            }
            
            // 关闭旧窗口
            currentWindow.orderOut(nil)
            
            // 替换为新窗口
            self.window = newWindow
            
            // 显示新窗口
            if isVisible {
                newWindow.makeKeyAndOrderFront(nil)
                newWindow.orderFrontRegardless()
            }
        }
    }
    
    private func setupWindowObserver() {
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.window?.orderFrontRegardless()
        }
    }
    
    func showWindow() {
        window?.makeKeyAndOrderFront(nil)
        window?.orderFrontRegardless()
    }
    
    func hideWindow() {
        window?.orderOut(nil)
    }
    
    func toggle() {
        if window?.isVisible == true {
            hideWindow()
        } else {
            showWindow()
        }
    }
    
    func setOpacity(_ opacity: Double) {
        guard let window = window else { return }
        window.alphaValue = opacity
        viewModel.settings.opacity = opacity
        viewModel.saveSettings()
    }
}

// MARK: - Root View
struct RootView: View {
    @EnvironmentObject var viewModel: TaskTimerViewModel
    
    var body: some View {
        Group {
            if viewModel.settings.isCompactMode {
                CompactView()
                    .environmentObject(viewModel)
            } else {
                ContentView()
                    .environmentObject(viewModel)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
