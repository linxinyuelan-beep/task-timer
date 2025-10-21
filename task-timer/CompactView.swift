//
//  CompactView.swift
//  TaskTimer
//
//  Created on 2025-10-21.
//

import SwiftUI

struct CompactView: View {
    @EnvironmentObject var viewModel: TaskTimerViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // 时间显示
            Text(viewModel.currentTime)
                .font(.system(size: 48, weight: .ultraLight, design: .monospaced))
                .foregroundColor(.white)
            
            // 第一个未完成任务
            if let task = viewModel.firstIncompleteTask {
                HStack(spacing: 12) {
                    Button(action: { viewModel.toggleTaskCompletion(task) }) {
                        Image(systemName: "circle")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(task.title)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .lineLimit(2)
                        
                        if let duration = task.estimatedDuration {
                            Text("预计 \(duration) 分钟")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    
                    Spacer()
                    
                    // 优先级标记
                    Text(task.priority.rawValue)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                        .background(priorityColor(task.priority).opacity(0.5))
                        .cornerRadius(4)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.08))
                .cornerRadius(12)
            } else {
                Text("暂无待办任务")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.vertical, 12)
            }
            
            // 退出轻量化模式按钮
            Button(action: viewModel.toggleCompactMode) {
                HStack {
                    Image(systemName: "rectangle.expand.vertical")
                        .font(.caption)
                    Text("展开")
                        .font(.caption)
                }
                .foregroundColor(.white.opacity(0.6))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.08))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func priorityColor(_ priority: TaskPriority) -> Color {
        switch priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }
}
