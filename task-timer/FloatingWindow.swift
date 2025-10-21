//
//  FloatingWindow.swift
//  TaskTimer
//
//  Created on 2025-10-21.
//

import SwiftUI
import AppKit

class FloatingWindow {
    private var window: NSWindow?
    private let viewModel = TaskTimerViewModel()
    
    init() {
        setupWindow()
    }
    
    private func setupWindow() {
        // 创建内容视图
        let contentView = ContentView()
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
