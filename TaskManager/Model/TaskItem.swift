import Foundation

struct TaskItem: Codable {
    let id: UUID
    let title: String
    let details: String
    let createdAt: Date
    let priority: TaskPriority
    var isCompleted: Bool
}
