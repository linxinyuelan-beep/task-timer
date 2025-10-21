//
//  TaskTimerViewModel.swift
//  TaskTimer
//
//  Created on 2025-10-21.
//

import Foundation
import Combine

class TaskTimerViewModel: ObservableObject {
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
    
    // MARK: - Storage
    private let tasksKey = "savedTasks"
    private let settingsKey = "userSettings"
    
    // MARK: - Initialization
    init() {
        loadTasks()
        loadSettings()
        setupClock()
        
        // 添加示例任务（首次运行）
        if tasks.isEmpty {
            addSampleTasks()
        }
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
    
    private func startTimer() {
        isTimerRunning = true
        pomodoroMode = true
        
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateTimer()
            }
    }
    
    private func stopTimer() {
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
        // TODO: 发送通知
        print("计时器完成！")
        timerSeconds = 0
        updateTimerDisplay()
    }
    
    func resetTimer() {
        stopTimer()
        timerSeconds = 0
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
        let task = Task(
            title: title,
            taskDescription: description,
            priority: priority,
            tags: tags,
            estimatedDuration: estimatedDuration
        )
        tasks.insert(task, at: 0)
        saveTasks()
    }
    
    func toggleTaskCompletion(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
            tasks[index].status = tasks[index].isCompleted ? .completed : .todo
            tasks[index].completedAt = tasks[index].isCompleted ? Date() : nil
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
        }
    }
    
    private func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: settingsKey)
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
                estimatedDuration: 120
            ),
            Task(
                title: "回复邮件",
                taskDescription: "处理今天收到的重要邮件",
                priority: .medium,
                tags: ["沟通"],
                estimatedDuration: 30
            ),
            Task(
                title: "学习 SwiftUI",
                taskDescription: "深入学习 SwiftUI 窗口管理",
                priority: .low,
                tags: ["学习", "技术"],
                estimatedDuration: 60
            )
        ]
        
        tasks = sampleTasks
        saveTasks()
    }
}
