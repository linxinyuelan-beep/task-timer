//
//  CompactView.swift
//  TaskTimer
//
//  Created on 2025-10-21.
//

import SwiftUI

struct CompactView: View {
    @EnvironmentObject var viewModel: TaskTimerViewModel
    
    // 自定义主题色
    private let themeColor = Color(red: 8/255, green: 111/255, blue: 178/255) // #086FB2
    
    var body: some View {
        VStack(spacing: 16) {
            // 时间显示
            Text(viewModel.currentTime)
                .font(.system(size: 48, weight: .ultraLight, design: .monospaced))
                .foregroundColor(themeColor)
            
            // 第一个未完成任务
            if let task = viewModel.firstIncompleteTask {
                HStack(spacing: 12) {
                    Button(action: { viewModel.toggleTaskCompletion(task) }) {
                        Image(systemName: "circle")
                            .font(.title2)
                            .foregroundColor(themeColor.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    
                    Text(task.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(themeColor)
                        .lineLimit(2)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(themeColor.opacity(0.08))
                .cornerRadius(12)
            } else {
                Text("暂无待办任务")
                    .font(.system(size: 14))
                    .foregroundColor(themeColor.opacity(0.5))
                    .padding(.vertical, 12)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
