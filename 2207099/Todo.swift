import SwiftUI
import FirebaseFirestore

enum Priority: String, Codable, CaseIterable, Identifiable {
    case low, medium, high

    var id: String { rawValue }
    var title: String { rawValue.capitalized }

    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}

struct Todo: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var title: String
    var isDone: Bool
    var createdAt: Date
    var priority: Priority?

    var level: Priority { priority ?? .medium }
}
