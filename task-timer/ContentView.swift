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
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "timer")
                    .foregroundColor(.orange)
                
                Text(viewModel.pomodoroMode ? "🍅 专注模式: \(viewModel.timerDisplay)" : "计时器")
                    .font(.system(size: 16, weight: .medium))
                
                Spacer()
                
                // 终止按钮
                Button(action: viewModel.stopPomodoroMode) {
                    Image(systemName: "stop.circle.fill")
                        .font(.title3)
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .help("终止专注模式")
                .disabled(!viewModel.pomodoroMode)
                
                // 重新开始按钮
                Button(action: viewModel.restartTimer) {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                .help("重新开始")
                .disabled(!viewModel.pomodoroMode)
                
                // 开始/暂停按钮
                Button(action: viewModel.toggleTimer) {
                    Image(systemName: viewModel.isTimerRunning ? "pause.circle.fill" : "play.circle.fill")
                        .font(.title2)
                }
                .buttonStyle(.plain)
            }
            
            // 快速时长选择按钮
            if viewModel.pomodoroMode {
                HStack(spacing: 8) {
                    Text("快速设置:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach([5, 10, 25, 30], id: \.self) { duration in
                        Button(action: {
                            viewModel.setTimerDuration(minutes: duration)
                        }) {
                            Text("\(duration)分")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(4)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Spacer()
                }
            }
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
        List {
            ForEach(viewModel.tasks) { task in
                TaskRowView(task: task, viewModel: viewModel)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
            }
            .onMove(perform: viewModel.moveTask)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

// MARK: - Task Row View
struct TaskRowView: View {
    let task: Task
    @ObservedObject var viewModel: TaskTimerViewModel
    @State private var showingEditTask = false
    
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
                showingEditTask = true
            }
            Button("删除", role: .destructive) {
                viewModel.deleteTask(task)
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

// MARK: - Edit Task View
struct EditTaskView: View {
    @Binding var isPresented: Bool
    let task: Task
    @ObservedObject var viewModel: TaskTimerViewModel
    
    @State private var title: String
    @State private var description: String
    @State private var priority: TaskPriority
    @State private var estimatedDuration: String
    @State private var tags: String
    
    init(isPresented: Binding<Bool>, task: Task, viewModel: TaskTimerViewModel) {
        self._isPresented = isPresented
        self.task = task
        self.viewModel = viewModel
        
        // 初始化状态值
        self._title = State(initialValue: task.title)
        self._description = State(initialValue: task.taskDescription ?? "")
        self._priority = State(initialValue: task.priority)
        self._estimatedDuration = State(initialValue: task.estimatedDuration.map { String($0) } ?? "")
        self._tags = State(initialValue: task.tags.joined(separator: ", "))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("编辑任务")
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
                
                Button("保存") {
                    saveTask()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(title.isEmpty)
            }
        }
        .padding()
        .frame(width: 300)
    }
    
    private func saveTask() {
        // 找到要更新的任务
        guard let index = viewModel.tasks.firstIndex(where: { $0.id == task.id }) else {
            return
        }
        
        let duration = Int(estimatedDuration)
        let tagArray = tags.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }.filter { !$0.isEmpty }
        
        // 创建更新后的任务
        var updatedTask = viewModel.tasks[index]
        updatedTask.title = title
        updatedTask.taskDescription = description.isEmpty ? nil : description
        updatedTask.priority = priority
        updatedTask.estimatedDuration = duration
        updatedTask.tags = tagArray
        
        viewModel.updateTask(updatedTask)
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
