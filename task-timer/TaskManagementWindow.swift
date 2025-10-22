//
//  TaskManagementWindow.swift
//  TaskTimer
//
//  Created on 2025-10-22.
//

import SwiftUI
import AppKit

struct TaskManagementView: View {
    @ObservedObject var viewModel: TaskTimerViewModel
    @State private var showingAddTask = false
    @State private var searchText = ""
    
    var filteredTasks: [Task] {
        if searchText.isEmpty {
            return viewModel.tasks
        } else {
            return viewModel.tasks.filter { task in
                task.title.localizedCaseInsensitiveContains(searchText) ||
                (task.taskDescription?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            headerSection
            
            Divider()
            
            // 搜索栏
            searchSection
            
            Divider()
            
            // 任务统计
            statsSection
            
            Divider()
            
            // 任务列表
            taskListSection
            
            Divider()
            
            // 底部工具栏
            bottomToolbar
        }
        .frame(width: 600, height: 700)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            Image(systemName: "checklist")
                .font(.title2)
                .foregroundColor(.blue)
            
            Text("任务管理")
                .font(.title2)
                .fontWeight(.semibold)
            
            Spacer()
            
            Button(action: { showingAddTask = true }) {
                Label("添加任务", systemImage: "plus.circle.fill")
                    .font(.body)
            }
            .buttonStyle(.borderedProminent)
            .popover(isPresented: $showingAddTask) {
                AddTaskView(isPresented: $showingAddTask, viewModel: viewModel)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Search Section
    private var searchSection: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("搜索任务...", text: $searchText)
                .textFieldStyle(.plain)
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Stats Section
    private var statsSection: some View {
        HStack(spacing: 30) {
            StatView(
                icon: "checkmark.circle.fill",
                color: .green,
                title: "已完成",
                count: viewModel.tasks.filter { $0.isCompleted }.count
            )
            
            StatView(
                icon: "circle",
                color: .blue,
                title: "进行中",
                count: viewModel.tasks.filter { !$0.isCompleted }.count
            )
            
            StatView(
                icon: "list.bullet",
                color: .orange,
                title: "总任务",
                count: viewModel.tasks.count
            )
            
            Spacer()
            
            // 清除已完成任务按钮
            if viewModel.tasks.contains(where: { $0.isCompleted }) {
                Button(action: clearCompletedTasks) {
                    Label("清除已完成", systemImage: "trash")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
    }
    
    // MARK: - Task List Section
    private var taskListSection: some View {
        Group {
            if filteredTasks.isEmpty {
                emptyStateView
            } else if searchText.isEmpty {
                // 非搜索模式：使用 List 支持拖拽排序
                List {
                    ForEach(viewModel.tasks) { task in
                        TaskManagementRowView(task: task, viewModel: viewModel)
                            .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                    .onMove(perform: moveTask)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            } else {
                // 搜索模式：使用 ScrollView
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredTasks) { task in
                            TaskManagementRowView(task: task, viewModel: viewModel)
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: searchText.isEmpty ? "tray" : "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(searchText.isEmpty ? "暂无任务" : "未找到匹配的任务")
                .font(.title3)
                .foregroundColor(.secondary)
            
            if searchText.isEmpty {
                Button(action: { showingAddTask = true }) {
                    Label("创建第一个任务", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
    
    // MARK: - Bottom Toolbar
    private var bottomToolbar: some View {
        HStack {
            Text("\(filteredTasks.count) 个任务")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            if searchText.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "hand.draw")
                        .font(.caption2)
                    Text("拖拽任务可重新排序")
                        .font(.caption2)
                }
                .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Actions
    private func moveTask(from source: IndexSet, to destination: Int) {
        viewModel.moveTask(from: source, to: destination)
    }
    
    private func clearCompletedTasks() {
        let alert = NSAlert()
        alert.messageText = "确认清除已完成任务"
        alert.informativeText = "这将删除所有已完成的任务，此操作无法撤销。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "删除")
        alert.addButton(withTitle: "取消")
        
        if alert.runModal() == .alertFirstButtonReturn {
            // 使用 deleteTask 方法删除每个已完成的任务
            let completedTasks = viewModel.tasks.filter { $0.isCompleted }
            for task in completedTasks {
                viewModel.deleteTask(task)
            }
        }
    }
}

// MARK: - Stat View
struct StatView: View {
    let icon: String
    let color: Color
    let title: String
    let count: Int
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(count)")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
        }
    }
}

// MARK: - Task Management Row View
struct TaskManagementRowView: View {
    let task: Task
    @ObservedObject var viewModel: TaskTimerViewModel
    @State private var showingEditTask = false
    @State private var isHovering = false
    @State private var isDragging = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // 拖拽手柄
            Image(systemName: "line.3.horizontal")
                .foregroundColor(.secondary)
                .font(.body)
                .opacity(isHovering ? 1 : 0)
                .frame(width: 20)
            
            // 完成按钮
            Button(action: { viewModel.toggleTaskCompletion(task) }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(task.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)
            
            // 任务信息
            VStack(alignment: .leading, spacing: 8) {
                Text(task.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)
                
                if let description = task.taskDescription, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                // 标签和时长
                HStack(spacing: 8) {
                    if !task.tags.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(task.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(6)
                            }
                        }
                    }
                    
                    if let duration = task.estimatedDuration {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption2)
                            Text("\(duration)分钟")
                                .font(.caption2)
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
            
            Spacer()
            
            // 优先级和操作按钮
            HStack(alignment: .center, spacing: 8) {
                // 优先级标记
                Text(task.priority.rawValue)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(priorityColor(task.priority))
                    .frame(width: 32, height: 24)
                    .background(priorityColor(task.priority).opacity(0.2))
                    .cornerRadius(6)
                
                Button(action: { showingEditTask = true }) {
                    Image(systemName: "pencil")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button(action: { deleteTask() }) {
                    Image(systemName: "trash")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(.red)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isDragging ? Color.blue.opacity(0.1) : (isHovering ? Color(NSColor.controlBackgroundColor) : Color.clear))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isDragging ? Color.blue : Color.secondary.opacity(0.2), lineWidth: isDragging ? 2 : 1)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
        .popover(isPresented: $showingEditTask) {
            EditTaskView(isPresented: $showingEditTask, task: task, viewModel: viewModel)
        }
    }
    
    private func priorityColor(_ priority: TaskPriority) -> Color {
        switch priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }
    
    private func deleteTask() {
        let alert = NSAlert()
        alert.messageText = "确认删除任务"
        alert.informativeText = "确定要删除任务「\(task.title)」吗？此操作无法撤销。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "删除")
        alert.addButton(withTitle: "取消")
        
        if alert.runModal() == .alertFirstButtonReturn {
            viewModel.deleteTask(task)
        }
    }
}
