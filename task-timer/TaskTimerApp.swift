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
        
        // 倒计时控制
        let timerControlMenu = NSMenu()
        
        if let viewModel = floatingWindow?.viewModel {
            if viewModel.pomodoroMode {
                // 番茄钟模式已激活
                if viewModel.isTimerRunning {
                    // 计时器正在运行
                    let pauseItem = NSMenuItem(
                        title: "暂停倒计时",
                        action: #selector(pauseTimer),
                        keyEquivalent: "p"
                    )
                    pauseItem.target = self
                    timerControlMenu.addItem(pauseItem)
                } else {
                    // 计时器已暂停
                    let resumeItem = NSMenuItem(
                        title: "继续倒计时",
                        action: #selector(resumeTimer),
                        keyEquivalent: "p"
                    )
                    resumeItem.target = self
                    timerControlMenu.addItem(resumeItem)
                }
                
                let stopItem = NSMenuItem(
                    title: "结束倒计时",
                    action: #selector(endTimer),
                    keyEquivalent: "e"
                )
                stopItem.target = self
                timerControlMenu.addItem(stopItem)
            } else {
                // 计时器未激活时的选项
                // 快速开始 25 分钟番茄钟
                let quick25Item = NSMenuItem(
                    title: "开始 25 分钟番茄钟",
                    action: #selector(startTimer25),
                    keyEquivalent: "p"
                )
                quick25Item.target = self
                timerControlMenu.addItem(quick25Item)
                
                timerControlMenu.addItem(NSMenuItem.separator())
                
                let quickStartMenu = NSMenu()
            
            let start5Item = NSMenuItem(title: "5 分钟", action: #selector(startTimer5), keyEquivalent: "")
            start5Item.target = self
            quickStartMenu.addItem(start5Item)
            
            let start10Item = NSMenuItem(title: "10 分钟", action: #selector(startTimer10), keyEquivalent: "")
            start10Item.target = self
            quickStartMenu.addItem(start10Item)
            
            let start15Item = NSMenuItem(title: "15 分钟", action: #selector(startTimer15), keyEquivalent: "")
            start15Item.target = self
            quickStartMenu.addItem(start15Item)
            
            let start25Item = NSMenuItem(title: "25 分钟", action: #selector(startTimer25), keyEquivalent: "")
            start25Item.target = self
            quickStartMenu.addItem(start25Item)
            
            let start30Item = NSMenuItem(title: "30 分钟", action: #selector(startTimer30), keyEquivalent: "")
            start30Item.target = self
            quickStartMenu.addItem(start30Item)
            
            let start45Item = NSMenuItem(title: "45 分钟", action: #selector(startTimer45), keyEquivalent: "")
            start45Item.target = self
            quickStartMenu.addItem(start45Item)
            
            let start60Item = NSMenuItem(title: "60 分钟", action: #selector(startTimer60), keyEquivalent: "")
            start60Item.target = self
            quickStartMenu.addItem(start60Item)
            
            quickStartMenu.addItem(NSMenuItem.separator())
            
            let customItem = NSMenuItem(title: "自定义时间...", action: #selector(startCustomTimer), keyEquivalent: "")
            customItem.target = self
            quickStartMenu.addItem(customItem)
            
            let quickStartMenuItem = NSMenuItem(title: "快速开始倒计时", action: nil, keyEquivalent: "")
            quickStartMenuItem.submenu = quickStartMenu
            timerControlMenu.addItem(quickStartMenuItem)
            }
        }
        
        let timerControlMenuItem = NSMenuItem(title: "倒计时", action: nil, keyEquivalent: "")
        timerControlMenuItem.submenu = timerControlMenu
        menu.addItem(timerControlMenuItem)
        
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
    
    // MARK: - Timer Control Methods
    @objc private func startTimer5() {
        startTimerWithDuration(5)
    }
    
    @objc private func startTimer10() {
        startTimerWithDuration(10)
    }
    
    @objc private func startTimer15() {
        startTimerWithDuration(15)
    }
    
    @objc private func startTimer25() {
        startTimerWithDuration(25)
    }
    
    @objc private func startTimer30() {
        startTimerWithDuration(30)
    }
    
    @objc private func startTimer45() {
        startTimerWithDuration(45)
    }
    
    @objc private func startTimer60() {
        startTimerWithDuration(60)
    }
    
    private func startTimerWithDuration(_ minutes: Int) {
        floatingWindow?.viewModel.setTimerDuration(minutes: minutes)
        floatingWindow?.viewModel.toggleTimer()
        statusBarItem?.menu = createMenu()
    }
    
    @objc private func startCustomTimer() {
        let alert = NSAlert()
        alert.messageText = "设置倒计时时间"
        alert.informativeText = "请输入倒计时时长（分钟）："
        alert.alertStyle = .informational
        
        let inputField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        inputField.placeholderString = "例如：30"
        inputField.stringValue = "25"
        alert.accessoryView = inputField
        
        alert.addButton(withTitle: "开始")
        alert.addButton(withTitle: "取消")
        
        let response = alert.runModal()
        
        if response == .alertFirstButtonReturn {
            if let minutes = Int(inputField.stringValue), minutes > 0, minutes <= 999 {
                startTimerWithDuration(minutes)
            } else {
                let errorAlert = NSAlert()
                errorAlert.messageText = "输入错误"
                errorAlert.informativeText = "请输入 1-999 之间的有效数字"
                errorAlert.alertStyle = .warning
                errorAlert.runModal()
            }
        }
    }
    
    @objc private func pauseTimer() {
        floatingWindow?.viewModel.stopTimer()
        statusBarItem?.menu = createMenu()
    }
    
    @objc private func resumeTimer() {
        floatingWindow?.viewModel.startTimer()
        statusBarItem?.menu = createMenu()
    }
    
    @objc private func endTimer() {
        floatingWindow?.viewModel.stopPomodoroMode()
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
