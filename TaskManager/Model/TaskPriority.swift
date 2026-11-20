import Foundation

enum TaskPriority: String, CaseIterable, Codable {
    case low
    case medium
    case high

    static let defaultPriority: Self = .medium
}

extension TaskPriority {
    var displayTitle: String {
        switch self {
        case .low: return "Низкий"
        case .medium: return "Средний"
        case .high: return "Высокий"
        }
    }
}
