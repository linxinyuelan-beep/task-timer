//
//  SettingsView.swift
//  TaskTimer
//
//  Created on 2025-10-21.
//

import SwiftUI

struct SettingsView: View {
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: TaskTimerViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var tempSettings: UserSettings
    
    init(isPresented: Binding<Bool>, viewModel: TaskTimerViewModel) {
        self._isPresented = isPresented
        self.viewModel = viewModel
        self._tempSettings = State(initialValue: viewModel.settings)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏（仅在 popover 模式下显示关闭按钮）
            HStack {
                Text("设置")
                    .font(.headline)
                Spacer()
                if isPresented {
                    Button(action: { 
                        isPresented = false
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            
            Divider()
            
            // 设置内容
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 轻量化模式设置
                    compactModeSettings
                    
                    Divider()
                    
                    // 外观设置
                    appearanceSettings
                    
                    Divider()
                    
                    // 番茄钟设置
                    pomodoroSettings
                }
                .padding()
            }
            
            Divider()
            
            // 底部按钮
            HStack {
                Button("恢复默认") {
                    tempSettings = UserSettings()
                }
                
                Spacer()
                
                Button("取消") {
                    isPresented = false
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("保存") {
                    saveSettings()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 500, height: 600)
    }
    
    // MARK: - Compact Mode Settings
    private var compactModeSettings: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("轻量化模式")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 16) {
                // 时间字体大小
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("时间字体大小")
                        Spacer()
                        Text("\(Int(tempSettings.compactTimeFontSize))")
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $tempSettings.compactTimeFontSize, in: 24...72, step: 2)
                    Text("预览: ")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    + Text("12:34")
                        .font(.system(size: tempSettings.compactTimeFontSize / 2, weight: .ultraLight, design: .monospaced))
                }
                
                // 任务字体大小
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("任务字体大小")
                        Spacer()
                        Text("\(Int(tempSettings.compactTaskFontSize))")
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $tempSettings.compactTaskFontSize, in: 10...24, step: 1)
                    Text("预览: ")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    + Text("示例任务")
                        .font(.system(size: tempSettings.compactTaskFontSize / 1.5, weight: .medium))
                }
                
                // 主题颜色
                VStack(alignment: .leading, spacing: 8) {
                    Text("主题颜色")
                    
                    HStack(spacing: 12) {
                        ColorPicker("", selection: Binding(
                            get: { Color(hex: tempSettings.compactColorHex) ?? .blue },
                            set: { newColor in
                                if let hex = newColor.toHex() {
                                    tempSettings.compactColorHex = hex
                                }
                            }
                        ))
                        .labelsHidden()
                        
                        TextField("颜色代码", text: $tempSettings.compactColorHex)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                        
                        Rectangle()
                            .fill(Color(hex: tempSettings.compactColorHex) ?? .blue)
                            .frame(width: 60, height: 30)
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                            )
                        
                        Spacer()
                    }
                    
                    // 预设颜色
                    HStack(spacing: 8) {
                        ForEach(presetColors, id: \.self) { colorHex in
                            Button(action: {
                                tempSettings.compactColorHex = colorHex
                            }) {
                                Circle()
                                    .fill(Color(hex: colorHex) ?? .blue)
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Circle()
                                            .stroke(tempSettings.compactColorHex == colorHex ? Color.primary : Color.clear, lineWidth: 2)
                                    )
                            }
                            .buttonStyle(.plain)
                            .help(colorHex)
                        }
                    }
                }
            }
            .padding(.leading, 8)
        }
    }
    
    // MARK: - Appearance Settings
    private var appearanceSettings: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("外观")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                Picker("主题", selection: $tempSettings.theme) {
                    Text("跟随系统").tag(Theme.system)
                    Text("亮色").tag(Theme.light)
                    Text("暗色").tag(Theme.dark)
                }
                .pickerStyle(.segmented)
                
                HStack {
                    Text("窗口透明度")
                    Spacer()
                    Text("\(Int(tempSettings.opacity * 100))%")
                        .foregroundColor(.secondary)
                }
                Slider(value: $tempSettings.opacity, in: 0.5...1.0, step: 0.05)
                
                Toggle("窗口可移动", isOn: $tempSettings.isWindowMovable)
            }
            .padding(.leading, 8)
        }
    }
    
    // MARK: - Pomodoro Settings
    private var pomodoroSettings: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("番茄钟")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("工作时长")
                    Spacer()
                    TextField("", value: $tempSettings.pomodoroWorkDuration, formatter: NumberFormatter())
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                    Text("分钟")
                }
                
                HStack {
                    Text("短休息")
                    Spacer()
                    TextField("", value: $tempSettings.pomodoroShortBreak, formatter: NumberFormatter())
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                    Text("分钟")
                }
                
                HStack {
                    Text("长休息")
                    Spacer()
                    TextField("", value: $tempSettings.pomodoroLongBreak, formatter: NumberFormatter())
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                    Text("分钟")
                }
                
                Toggle("提示音", isOn: $tempSettings.notificationSound)
            }
            .padding(.leading, 8)
        }
    }
    
    // MARK: - Preset Colors
    private let presetColors = [
        "086FB2", // 默认蓝色
        "FF5733", // 红色
        "33FF57", // 绿色
        "5733FF", // 紫色
        "FF33F5", // 粉色
        "33F5FF", // 青色
        "FFB533", // 橙色
        "8E44AD"  // 深紫色
    ]
    
    // MARK: - Actions
    private func saveSettings() {
        viewModel.settings = tempSettings
        viewModel.saveSettings()
        isPresented = false
        dismiss()
    }
}
