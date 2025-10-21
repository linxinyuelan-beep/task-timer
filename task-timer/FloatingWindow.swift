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
    private let viewModel = TaskTimerViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupWindow()
        observeCompactMode()
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
        
        // 透明度和外观
        window.isOpaque = false
        window.backgroundColor = .clear
        window.alphaValue = 0.95
        
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
    
    private func updateWindowStyle(isCompact: Bool) {
        guard let window = window else { return }
        
        if isCompact {
            // 轻量化模式：无标题栏、完全透明背景、更小尺寸
            window.styleMask = [.borderless, .resizable]
            window.backgroundColor = .clear
            window.alphaValue = 1.0
            window.isOpaque = false
            window.hasShadow = false
            
            // 调整窗口大小
            let newSize = NSSize(width: 280, height: 200)
            let currentOrigin = window.frame.origin
            window.setFrame(
                NSRect(origin: currentOrigin, size: newSize),
                display: true,
                animate: true
            )
        } else {
            // 正常模式：有标题栏
            window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
            window.alphaValue = 0.95
            window.hasShadow = true
            window.title = "Task Timer"
            
            // 恢复窗口大小
            let newSize = NSSize(width: 350, height: 500)
            let currentOrigin = window.frame.origin
            window.setFrame(
                NSRect(origin: currentOrigin, size: newSize),
                display: true,
                animate: true
            )
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
