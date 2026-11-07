import SwiftUI
import Combine
import FirebaseFirestore

final class TodoStore: ObservableObject {
    @Published private(set) var todos: [Todo] = []
    @Published private(set) var isLoading = true
    @Published private(set) var errorMessage: String?

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    var remaining: Int { todos.filter { !$0.isDone }.count }
    var completed: Int { todos.count - remaining }

    func listen(userId: String) {
        listener?.remove()
        isLoading = true
        errorMessage = nil
        listener = db.collection("todos")
            .whereField("userId", isEqualTo: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error {
                    print("Firestore error:", error)
                    self.errorMessage = "Couldn't load your tasks. Check your connection."
                    self.isLoading = false
                    return
                }

                let items: [Todo] = (snapshot?.documents ?? []).compactMap { doc in
                    do {
                        return try doc.data(as: Todo.self)
                    } catch {
                        print("Decode failed for \(doc.documentID):", error)
                        return nil
                    }
                }

                self.todos = items.sorted { $0.createdAt > $1.createdAt }
                self.errorMessage = nil
                self.isLoading = false
            }
    }

    func add(title: String, priority: Priority, userId: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !userId.isEmpty else { return }

        let todo = Todo(userId: userId,
                        title: trimmed,
                        isDone: false,
                        createdAt: Date(),
                        priority: priority)
        do {
            try db.collection("todos").addDocument(from: todo)
        } catch {
            print("Failed to add todo:", error)
            errorMessage = "Couldn't save that task."
        }
    }

    func toggle(_ todo: Todo) {
        guard let id = todo.id else { return }
        db.collection("todos").document(id).updateData(["isDone": !todo.isDone]) { error in
            if let error { print("Toggle failed:", error) }
        }
    }

    func delete(_ todo: Todo) {
        guard let id = todo.id else { return }
        db.collection("todos").document(id).delete { error in
            if let error { print("Delete failed:", error) }
        }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
        todos = []
        isLoading = true
    }
}
