//
//  CompactView.swift
//  TaskTimer
//
//  Created on 2025-10-21.
//

import SwiftUI

struct CompactView: View {
    @EnvironmentObject var viewModel: TaskTimerViewModel
    
    // 从设置中获取主题色
    private var themeColor: Color {
        Color(hex: viewModel.settings.compactColorHex) ?? Color(red: 8/255, green: 111/255, blue: 178/255)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 时间显示
            Text(viewModel.currentTime)
                .font(.system(size: viewModel.settings.compactTimeFontSize, weight: .ultraLight, design: .monospaced))
                .foregroundColor(themeColor)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // 专注倒计时显示（如果正在运行）
            if viewModel.pomodoroMode {
                HStack(spacing: 6) {
                    Image(systemName: viewModel.isTimerRunning ? "timer" : "timer.circle")
                        .foregroundColor(viewModel.isTimerRunning ? .orange : themeColor.opacity(0.7))
                        .font(.system(size: viewModel.settings.compactTaskFontSize))
                    
                    Text(viewModel.timerDisplay)
                        .font(.system(size: viewModel.settings.compactTaskFontSize * 1.2, weight: .semibold, design: .monospaced))
                        .foregroundColor(viewModel.isTimerRunning ? .orange : themeColor.opacity(0.7))
                    
                    Text(viewModel.isTimerRunning ? "专注中" : "已暂停")
                        .font(.system(size: viewModel.settings.compactTaskFontSize * 0.75))
                        .foregroundColor(viewModel.isTimerRunning ? .orange.opacity(0.8) : themeColor.opacity(0.5))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // 第一个未完成任务
            if let task = viewModel.firstIncompleteTask {
                Text(task.title)
                    .font(.system(size: viewModel.settings.compactTaskFontSize, weight: .medium))
                    .foregroundColor(themeColor)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text("暂无待办任务")
                    .font(.system(size: viewModel.settings.compactTaskFontSize * 0.875))
                    .foregroundColor(themeColor.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Color Extension
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    func toHex() -> String? {
        let components = NSColor(self).cgColor.components
        guard let r = components?[0], let g = components?[1], let b = components?[2] else { return nil }
        return String(format: "%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}
