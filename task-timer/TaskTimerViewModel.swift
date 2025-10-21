//
//  TaskTimerViewModel.swift
//  TaskTimer
//
//  Created on 2025-10-21.
//

import Foundation
import Combine
import SwiftUI

class TaskTimerViewModel: ObservableObject {
        static let timerDidCompleteNotification = Notification.Name("TimerDidCompleteNotification")
    // MARK: - Published Properties
    @Published var tasks: [Task] = []
    @Published var currentTime: String = ""
    @Published var currentDate: String = ""
    @Published var isTimerRunning: Bool = false
    @Published var timerDisplay: String = "00:00"
    @Published var pomodoroMode: Bool = false
    @Published var settings: UserSettings = UserSettings()
    
    // MARK: - Private Properties
    private var timerCancellable: AnyCancellable?
    private var clockCancellable: AnyCancellable?
    private var timerSeconds: Int = 0
    private var timerTargetSeconds: Int = 25 * 60 // 默认 25 分钟
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Storage
    private let tasksKey = "savedTasks"
    private let settingsKey = "userSettings"
    
    // MARK: - Initialization
    init() {
        loadTasks()
        loadSettings()
        setupClock()
        setupCompactModeObserver()
        
        // 添加示例任务（首次运行）
        if tasks.isEmpty {
            addSampleTasks()
        }
    }
    
    // MARK: - Observers
    private func setupCompactModeObserver() {
        // 监听轻量化模式变化，自动调整窗口可拖拽状态
        $settings
            .map { $0.isCompactMode }
            .removeDuplicates()
            .sink { [weak self] isCompact in
                guard let self = self else { return }
                // 非轻量化模式下自动启用窗口可拖拽
                if !isCompact {
                    self.settings.isWindowMovable = true
                    self.saveSettings()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Clock
    private func setupClock() {
        clockCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateTime()
            }
    }
    
    private func updateTime() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        currentTime = formatter.string(from: Date())
        
        formatter.dateFormat = "yyyy年MM月dd日 EEEE"
        formatter.locale = Locale(identifier: "zh_CN")
        currentDate = formatter.string(from: Date())
    }
    
    // MARK: - Timer Functions
    func toggleTimer() {
        if isTimerRunning {
            stopTimer()
        } else {
            startTimer()
        }
    }
    
    func startTimer() {
        isTimerRunning = true
        pomodoroMode = true
        
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateTimer()
            }
    }
    
    func stopTimer() {
        isTimerRunning = false
        timerCancellable?.cancel()
    }
    
    private func updateTimer() {
        if timerSeconds < timerTargetSeconds {
            timerSeconds += 1
            updateTimerDisplay()
        } else {
            // 计时器完成
            stopTimer()
            timerCompleted()
        }
    }
    
    private func updateTimerDisplay() {
        let remainingSeconds = timerTargetSeconds - timerSeconds
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        timerDisplay = String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func timerCompleted() {
        // 发送倒计时完成通知
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: TaskTimerViewModel.timerDidCompleteNotification, object: nil)
        }
        timerSeconds = 0
        updateTimerDisplay()
    }
    
    func resetTimer() {
        stopTimer()
        timerSeconds = 0
        updateTimerDisplay()
    }
    
    func restartTimer() {
        stopTimer()
        timerSeconds = 0
        updateTimerDisplay()
        startTimer()
    }
    
    func setTimerDuration(minutes: Int) {
        let wasRunning = isTimerRunning
        stopTimer()
        timerTargetSeconds = minutes * 60
        timerSeconds = 0
        updateTimerDisplay()
        if wasRunning {
            startTimer()
        }
    }
    
    func stopPomodoroMode() {
        stopTimer()
        pomodoroMode = false
        timerSeconds = 0
        timerTargetSeconds = 25 * 60
        updateTimerDisplay()
    }
    
    // MARK: - Task Management
    func addTask(
        title: String,
        description: String? = nil,
        priority: TaskPriority = .medium,
        estimatedDuration: Int? = nil,
        tags: [String] = []
    ) {
        // 计算新任务的排序顺序：未完成任务的最大顺序 + 1
        let maxIncompleteSortOrder = tasks.filter { !$0.isCompleted }.map { $0.sortOrder }.max() ?? -1
        
        let task = Task(
            title: title,
            taskDescription: description,
            priority: priority,
            tags: tags,
            estimatedDuration: estimatedDuration,
            sortOrder: maxIncompleteSortOrder + 1
        )
        tasks.insert(task, at: 0)
        reorderTasks()
        saveTasks()
    }
    
    func toggleTaskCompletion(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
            tasks[index].status = tasks[index].isCompleted ? .completed : .todo
            tasks[index].completedAt = tasks[index].isCompleted ? Date() : nil
            
            // 如果任务完成，将其移到已完成任务的末尾
            if tasks[index].isCompleted {
                let maxCompletedSortOrder = tasks.filter { $0.isCompleted }.map { $0.sortOrder }.max() ?? tasks.filter { !$0.isCompleted }.map { $0.sortOrder }.max() ?? 0
                tasks[index].sortOrder = maxCompletedSortOrder + 1
            } else {
                // 如果取消完成，将其移到未完成任务的末尾
                let maxIncompleteSortOrder = tasks.filter { !$0.isCompleted && $0.id != task.id }.map { $0.sortOrder }.max() ?? -1
                tasks[index].sortOrder = maxIncompleteSortOrder + 1
            }
            
            reorderTasks()
            saveTasks()
        }
    }
    
    func deleteTask(_ task: Task) {
        tasks.removeAll { $0.id == task.id }
        saveTasks()
    }
    
    func updateTask(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
            saveTasks()
        }
    }
    
    // MARK: - Task Reordering
    func moveTask(from source: IndexSet, to destination: Int) {
        // 创建临时数组用于移动
        var reorderedTasks = tasks
        reorderedTasks.move(fromOffsets: source, toOffset: destination)
        
        // 检查移动后的任务是否跨越了完成/未完成的边界
        guard let sourceIndex = source.first else { return }
        let movedTask = tasks[sourceIndex]
        
        // 确定目标位置的任务状态
        let destinationIndex = destination > sourceIndex ? destination - 1 : destination
        
        // 如果目标位置有任务，检查是否跨越边界
        if destinationIndex < reorderedTasks.count {
            let destinationTask = reorderedTasks[destinationIndex]
            
            // 不允许将未完成的任务拖到已完成任务之后
            // 也不允许将已完成的任务拖到未完成任务之前
            if movedTask.isCompleted != destinationTask.isCompleted {
                return
            }
        }
        
        // 更新任务数组
        tasks = reorderedTasks
        
        // 重新分配 sortOrder
        for (index, _) in tasks.enumerated() {
            tasks[index].sortOrder = index
        }
        
        saveTasks()
    }
    
    // 重新排序任务：未完成在前，已完成在后，各自按 sortOrder 排序
    private func reorderTasks() {
        let incompleteTasks = tasks.filter { !$0.isCompleted }.sorted { $0.sortOrder < $1.sortOrder }
        let completedTasks = tasks.filter { $0.isCompleted }.sorted { $0.sortOrder < $1.sortOrder }
        tasks = incompleteTasks + completedTasks
    }
    
    // MARK: - Data Persistence
    private func saveTasks() {
        if let encoded = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(encoded, forKey: tasksKey)
        }
    }
    
    private func loadTasks() {
        if let data = UserDefaults.standard.data(forKey: tasksKey),
           let decoded = try? JSONDecoder().decode([Task].self, from: data) {
            tasks = decoded
            reorderTasks()
        }
    }
    
    private func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(UserSettings.self, from: data) {
            settings = decoded
        }
    }
    
    // MARK: - Compact Mode
    func toggleCompactMode() {
        settings.isCompactMode.toggle()
        saveSettings()
    }
    
    // MARK: - Window Movable
    func toggleWindowMovable() {
        settings.isWindowMovable.toggle()
        saveSettings()
    }
    
    // MARK: - Theme
    func setTheme(_ theme: Theme) {
        settings.theme = theme
        saveSettings()
    }
    
    // 公开 saveSettings 方法
    func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: settingsKey)
        }
    }
    
    // 获取第一个未完成的任务
    var firstIncompleteTask: Task? {
        tasks.first { !$0.isCompleted }
    }
    
    // MARK: - Sample Data
    private func addSampleTasks() {
        let sampleTasks = [
            Task(
                title: "完成需求文档编写",
                taskDescription: "整理 Task Timer 的详细需求",
                priority: .high,
                tags: ["工作", "文档"],
                estimatedDuration: 120,
                sortOrder: 0
            ),
            Task(
                title: "回复邮件",
                taskDescription: "处理今天收到的重要邮件",
                priority: .medium,
                tags: ["沟通"],
                estimatedDuration: 30,
                sortOrder: 1
            ),
            Task(
                title: "学习 SwiftUI",
                taskDescription: "深入学习 SwiftUI 窗口管理",
                priority: .low,
                tags: ["学习", "技术"],
                estimatedDuration: 60,
                sortOrder: 2
            )
        ]
        
        tasks = sampleTasks
        saveTasks()
    }
}
