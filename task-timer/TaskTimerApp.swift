//
//  TaskTimerApp.swift
//  TaskTimer
//
//  Created on 2025-10-21.
//

import SwiftUI
import AppKit

@main
struct TaskTimerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var floatingWindow: FloatingWindow?
    var statusBarItem: NSStatusItem?
    var settingsWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 隐藏 Dock 图标（可选）
        NSApp.setActivationPolicy(.accessory)
        
        // 创建菜单栏图标
        setupStatusBar()
        
        // 创建置顶窗口
        setupFloatingWindow()
    }
    
    private func setupStatusBar() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusBarItem?.button {
            button.image = NSImage(systemSymbolName: "timer", accessibilityDescription: "Task Timer")
        }
        
        // 创建菜单（每次点击时动态更新）
        statusBarItem?.menu = createMenu()
    }
    
    private func createMenu() -> NSMenu {
        let menu = NSMenu()
        
        // 显示/隐藏窗口
        let toggleWindowItem = NSMenuItem(
            title: (floatingWindow?.isVisible ?? false) ? "隐藏窗口" : "显示窗口",
            action: #selector(toggleFloatingWindow),
            keyEquivalent: "t"
        )
        toggleWindowItem.target = self
        menu.addItem(toggleWindowItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 视图模式
        let viewModeMenu = NSMenu()
        let compactModeItem = NSMenuItem(
            title: "轻量化模式",
            action: #selector(toggleCompactMode),
            keyEquivalent: "l"
        )
        compactModeItem.target = self
        compactModeItem.state = (floatingWindow?.viewModel.settings.isCompactMode ?? false) ? .on : .off
        viewModeMenu.addItem(compactModeItem)
        
        let viewModeMenuItem = NSMenuItem(title: "视图模式", action: nil, keyEquivalent: "")
        viewModeMenuItem.submenu = viewModeMenu
        menu.addItem(viewModeMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 窗口行为
        let windowBehaviorMenu = NSMenu()
        let windowMovableItem = NSMenuItem(
            title: "窗口可拖拽移动",
            action: #selector(toggleWindowMovable),
            keyEquivalent: "m"
        )
        windowMovableItem.target = self
        windowMovableItem.state = (floatingWindow?.viewModel.settings.isWindowMovable ?? true) ? .on : .off
        windowBehaviorMenu.addItem(windowMovableItem)
        
        let windowBehaviorMenuItem = NSMenuItem(title: "窗口行为", action: nil, keyEquivalent: "")
        windowBehaviorMenuItem.submenu = windowBehaviorMenu
        menu.addItem(windowBehaviorMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 主题切换
        let themeMenu = NSMenu()
        
        let lightThemeItem = NSMenuItem(title: "亮色", action: #selector(setLightTheme), keyEquivalent: "")
        lightThemeItem.target = self
        lightThemeItem.state = (floatingWindow?.viewModel.settings.theme == .light) ? .on : .off
        themeMenu.addItem(lightThemeItem)
        
        let darkThemeItem = NSMenuItem(title: "暗色", action: #selector(setDarkTheme), keyEquivalent: "")
        darkThemeItem.target = self
        darkThemeItem.state = (floatingWindow?.viewModel.settings.theme == .dark) ? .on : .off
        themeMenu.addItem(darkThemeItem)
        
        let systemThemeItem = NSMenuItem(title: "跟随系统", action: #selector(setSystemTheme), keyEquivalent: "")
        systemThemeItem.target = self
        systemThemeItem.state = (floatingWindow?.viewModel.settings.theme == .system) ? .on : .off
        themeMenu.addItem(systemThemeItem)
        
        let themeMenuItem = NSMenuItem(title: "主题", action: nil, keyEquivalent: "")
        themeMenuItem.submenu = themeMenu
        menu.addItem(themeMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 不透明度调节
        let opacityMenu = NSMenu()
        
        let opacity100Item = NSMenuItem(title: "100%", action: #selector(setOpacity100), keyEquivalent: "")
        opacity100Item.target = self
        opacityMenu.addItem(opacity100Item)
        
        let opacity90Item = NSMenuItem(title: "90%", action: #selector(setOpacity90), keyEquivalent: "")
        opacity90Item.target = self
        opacityMenu.addItem(opacity90Item)
        
        let opacity80Item = NSMenuItem(title: "80%", action: #selector(setOpacity80), keyEquivalent: "")
        opacity80Item.target = self
        opacityMenu.addItem(opacity80Item)
        
        let opacity70Item = NSMenuItem(title: "70%", action: #selector(setOpacity70), keyEquivalent: "")
        opacity70Item.target = self
        opacityMenu.addItem(opacity70Item)
        
        let opacityMenuItem = NSMenuItem(title: "不透明度", action: nil, keyEquivalent: "")
        opacityMenuItem.submenu = opacityMenu
        menu.addItem(opacityMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 设置
        let settingsItem = NSMenuItem(title: "设置...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 关于
        let aboutItem = NSMenuItem(title: "关于 Task Timer", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 退出
        let quitItem = NSMenuItem(title: "退出", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        // 设置菜单代理以动态更新
        menu.delegate = self
        
        return menu
    }
    
    private func setupFloatingWindow() {
        floatingWindow = FloatingWindow()
        floatingWindow?.showWindow()
    }
    
    @objc private func toggleFloatingWindow() {
        floatingWindow?.toggle()
        // 更新菜单
        statusBarItem?.menu = createMenu()
    }
    
    @objc private func toggleCompactMode() {
        floatingWindow?.viewModel.toggleCompactMode()
        // 更新菜单
        statusBarItem?.menu = createMenu()
    }
    
    @objc private func toggleWindowMovable() {
        floatingWindow?.viewModel.toggleWindowMovable()
        // 更新菜单
        statusBarItem?.menu = createMenu()
    }
    
    @objc private func setLightTheme() {
        floatingWindow?.viewModel.setTheme(.light)
        statusBarItem?.menu = createMenu()
    }
    
    @objc private func setDarkTheme() {
        floatingWindow?.viewModel.setTheme(.dark)
        statusBarItem?.menu = createMenu()
    }
    
    @objc private func setSystemTheme() {
        floatingWindow?.viewModel.setTheme(.system)
        statusBarItem?.menu = createMenu()
    }
    
    @objc private func setOpacity100() {
        floatingWindow?.setOpacity(1.0)
    }
    
    @objc private func setOpacity90() {
        floatingWindow?.setOpacity(0.9)
    }
    
    @objc private func setOpacity80() {
        floatingWindow?.setOpacity(0.8)
    }
    
    @objc private func setOpacity70() {
        floatingWindow?.setOpacity(0.7)
    }
    
    @objc private func openSettings() {
        // 如果设置窗口已经存在且可见，则激活它
        if let settingsWindow = settingsWindow, settingsWindow.isVisible {
            settingsWindow.makeKeyAndOrderFront(nil)
            return
        }
        
        // 创建设置视图
        guard let viewModel = floatingWindow?.viewModel else { return }
        
        // 创建一个包装视图来处理窗口关闭
        let settingsWrapper = SettingsWindowWrapper(
            viewModel: viewModel,
            onClose: { [weak self] in
                self?.settingsWindow?.close()
                self?.settingsWindow = nil
            }
        )
        
        // 创建设置窗口
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 600),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "设置"
        window.contentView = NSHostingView(rootView: settingsWrapper)
        window.center()
        window.isReleasedWhenClosed = false
        window.level = .floating
        
        self.settingsWindow = window
        window.makeKeyAndOrderFront(nil)
    }
    
    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "Task Timer"
        alert.informativeText = """
        版本 1.0.0
        
        一款轻量级的任务管理和时间追踪应用
        支持番茄钟、任务管理、轻量化模式等功能
        
        © 2025 Task Timer
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "确定")
        alert.runModal()
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - NSMenuDelegate
extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        // 菜单打开前更新状态
        statusBarItem?.menu = createMenu()
    }
}

// MARK: - Settings Window Wrapper
struct SettingsWindowWrapper: View {
    @ObservedObject var viewModel: TaskTimerViewModel
    @State private var isPresented = true
    let onClose: () -> Void
    
    var body: some View {
        SettingsView(isPresented: $isPresented, viewModel: viewModel)
            .onChange(of: isPresented) { oldValue, newValue in
                if !newValue {
                    onClose()
                }
            }
    }
}
