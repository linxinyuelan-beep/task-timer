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
            button.action = #selector(toggleFloatingWindow)
            button.target = self
        }
        
        // 创建菜单
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "显示/隐藏", action: #selector(toggleFloatingWindow), keyEquivalent: "t"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "设置", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "退出", action: #selector(quitApp), keyEquivalent: "q"))
        
        statusBarItem?.menu = menu
    }
    
    private func setupFloatingWindow() {
        floatingWindow = FloatingWindow()
        floatingWindow?.showWindow()
    }
    
    @objc private func toggleFloatingWindow() {
        floatingWindow?.toggle()
    }
    
    @objc private func openSettings() {
        // TODO: 打开设置窗口
        print("打开设置")
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
