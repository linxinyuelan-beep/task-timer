//
//  Models.swift
//  TaskTimer
//
//  Created on 2025-10-21.
//

import Foundation

// MARK: - Task Priority
enum TaskPriority: String, Codable, CaseIterable {
    case high = "H"
    case medium = "M"
    case low = "L"
}

// MARK: - Task Status
enum TaskStatus: String, Codable {
    case todo = "待办"
    case inProgress = "进行中"
    case completed = "已完成"
    case archived = "已归档"
}

// MARK: - Task Model
struct Task: Identifiable, Codable {
    var id: UUID
    var title: String
    var taskDescription: String?
    var priority: TaskPriority
    var status: TaskStatus
    var isCompleted: Bool
    var tags: [String]
    var estimatedDuration: Int? // 分钟
    var actualDuration: Int? // 实际花费时间
    var createdAt: Date
    var completedAt: Date?
    var sortOrder: Int // 排序顺序
    
    init(
        id: UUID = UUID(),
        title: String,
        taskDescription: String? = nil,
        priority: TaskPriority = .medium,
        status: TaskStatus = .todo,
        isCompleted: Bool = false,
        tags: [String] = [],
        estimatedDuration: Int? = nil,
        actualDuration: Int? = nil,
        createdAt: Date = Date(),
        completedAt: Date? = nil,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.title = title
        self.taskDescription = taskDescription
        self.priority = priority
        self.status = status
        self.isCompleted = isCompleted
        self.tags = tags
        self.estimatedDuration = estimatedDuration
        self.actualDuration = actualDuration
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.sortOrder = sortOrder
    }
}

// MARK: - Timer Mode
enum TimerMode {
    case normal
    case pomodoro(workDuration: Int, breakDuration: Int, longBreakDuration: Int)
    case countdown(duration: Int)
}

// MARK: - User Settings
struct UserSettings: Codable {
    var theme: Theme
    var opacity: Double
    var autoStart: Bool
    var defaultWindowPosition: WindowPosition?
    var pomodoroWorkDuration: Int // 分钟
    var pomodoroShortBreak: Int
    var pomodoroLongBreak: Int
    var notificationSound: Bool
    var isCompactMode: Bool // 轻量化模式
    var isWindowMovable: Bool // 窗口是否可移动
    
    // 轻量化模式字体设置
    var compactTimeFontSize: Double // 时间字体大小
    var compactTaskFontSize: Double // 任务字体大小
    var compactColorHex: String // 主题颜色（十六进制）
    
    init(
        theme: Theme = .system,
        opacity: Double = 0.95,
        autoStart: Bool = false,
        defaultWindowPosition: WindowPosition? = nil,
        pomodoroWorkDuration: Int = 25,
        pomodoroShortBreak: Int = 5,
        pomodoroLongBreak: Int = 15,
        notificationSound: Bool = true,
        isCompactMode: Bool = false,
        isWindowMovable: Bool = true,
        compactTimeFontSize: Double = 48,
        compactTaskFontSize: Double = 16,
        compactColorHex: String = "086FB2"
    ) {
        self.theme = theme
        self.opacity = opacity
        self.autoStart = autoStart
        self.defaultWindowPosition = defaultWindowPosition
        self.pomodoroWorkDuration = pomodoroWorkDuration
        self.pomodoroShortBreak = pomodoroShortBreak
        self.pomodoroLongBreak = pomodoroLongBreak
        self.notificationSound = notificationSound
        self.isCompactMode = isCompactMode
        self.isWindowMovable = isWindowMovable
        self.compactTimeFontSize = compactTimeFontSize
        self.compactTaskFontSize = compactTaskFontSize
        self.compactColorHex = compactColorHex
    }
}

// MARK: - Theme
enum Theme: String, Codable {
    case light = "亮色"
    case dark = "暗色"
    case system = "跟随系统"
}

// MARK: - Window Position
struct WindowPosition: Codable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double
}
