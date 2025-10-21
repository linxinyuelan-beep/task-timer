//
//  ContentView.swift
//  TaskTimer
//
//  Created on 2025-10-21.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: TaskTimerViewModel
    @State private var newTaskTitle = ""
    @State private var showingAddTask = false
    @State private var showingSettings = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 时间显示区域
            timeDisplaySection
            
            Divider()
            
            // 计时器区域
            timerSection
            
            Divider()
            
            // 工具栏
            toolbarSection
            
            Divider()
            
            // 任务列表
            taskListSection
        }
        .background(VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow))
    }
    
    // MARK: - Time Display Section
    private var timeDisplaySection: some View {
        VStack(spacing: 4) {
            Text(viewModel.currentTime)
                .font(.system(size: 36, weight: .light, design: .monospaced))
            
            Text(viewModel.currentDate)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Timer Section
    private var timerSection: some View {
        HStack {
            Image(systemName: "timer")
                .foregroundColor(.orange)
            
            Text(viewModel.pomodoroMode ? "🍅 专注模式: \(viewModel.timerDisplay)" : "计时器")
                .font(.system(size: 16, weight: .medium))
            
            Spacer()
            
            Button(action: viewModel.toggleTimer) {
                Image(systemName: viewModel.isTimerRunning ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title2)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Toolbar Section
    private var toolbarSection: some View {
        HStack {
            Button(action: { showingAddTask = true }) {
                Label("添加任务", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showingAddTask) {
                AddTaskView(isPresented: $showingAddTask, viewModel: viewModel)
            }
            
            Spacer()
            
            Button(action: viewModel.toggleCompactMode) {
                Image(systemName: "rectangle.compress.vertical")
            }
            .buttonStyle(.plain)
            .help("轻量化模式")
            
            Button(action: {}) {
                Image(systemName: "magnifyingglass")
            }
            .buttonStyle(.plain)
            
            Button(action: { showingSettings = true }) {
                Image(systemName: "gearshape.fill")
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showingSettings) {
                SettingsView(isPresented: $showingSettings, viewModel: viewModel)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
    
    // MARK: - Task List Section
    private var taskListSection: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(viewModel.tasks) { task in
                    TaskRowView(task: task, viewModel: viewModel)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Task Row View
struct TaskRowView: View {
    let task: Task
    @ObservedObject var viewModel: TaskTimerViewModel
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: { viewModel.toggleTaskCompletion(task) }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(task.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)
                
                if let description = task.taskDescription, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    if !task.tags.isEmpty {
                        ForEach(task.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                    
                    if let duration = task.estimatedDuration {
                        Text("\(duration)分钟")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // 优先级标记
            Text(task.priority.rawValue)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(priorityColor(task.priority))
                .frame(width: 24, height: 24)
                .background(priorityColor(task.priority).opacity(0.2))
                .cornerRadius(4)
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
        .contextMenu {
            Button("编辑") {
                // TODO: 编辑任务
            }
            Button("删除", role: .destructive) {
                viewModel.deleteTask(task)
            }
        }
    }
    
    private func priorityColor(_ priority: TaskPriority) -> Color {
        switch priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }
}

// MARK: - Add Task View
struct AddTaskView: View {
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: TaskTimerViewModel
    
    @State private var title = ""
    @State private var description = ""
    @State private var priority: TaskPriority = .medium
    @State private var estimatedDuration: String = ""
    @State private var tags: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("添加新任务")
                .font(.headline)
            
            TextField("任务标题", text: $title)
                .textFieldStyle(.roundedBorder)
            
            TextField("任务描述（可选）", text: $description)
                .textFieldStyle(.roundedBorder)
            
            Picker("优先级", selection: $priority) {
                Text("高").tag(TaskPriority.high)
                Text("中").tag(TaskPriority.medium)
                Text("低").tag(TaskPriority.low)
            }
            .pickerStyle(.segmented)
            
            TextField("预计时长（分钟）", text: $estimatedDuration)
                .textFieldStyle(.roundedBorder)
            
            TextField("标签（逗号分隔）", text: $tags)
                .textFieldStyle(.roundedBorder)
            
            HStack {
                Button("取消") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("添加") {
                    addTask()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(title.isEmpty)
            }
        }
        .padding()
        .frame(width: 300)
    }
    
    private func addTask() {
        let duration = Int(estimatedDuration)
        let tagArray = tags.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
        
        viewModel.addTask(
            title: title,
            description: description.isEmpty ? nil : description,
            priority: priority,
            estimatedDuration: duration,
            tags: tagArray
        )
        
        isPresented = false
    }
}

// MARK: - Visual Effect Blur
struct VisualEffectBlur: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
