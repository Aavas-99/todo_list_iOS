import SwiftUI
import SwiftUI
import FirebaseAuth

private enum TaskFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case active = "Active"
    case done = "Done"
    var id: String { rawValue }
}

struct ContentView: View {
    @EnvironmentObject var auth: AuthManager
    @StateObject private var store = TodoStore()

    @State private var draft = ""
    @State private var draftPriority: Priority = .medium
    @State private var filter: TaskFilter = .all
    @FocusState private var typing: Bool

    private var cleanDraft: String {
        draft.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var visibleTodos: [Todo] {
        switch filter {
        case .all: return store.todos
        case .active: return store.todos.filter { !$0.isDone }
        case .done: return store.todos.filter { $0.isDone }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                summaryHeader
                filterPicker
                taskList
            }
            .background(Color.gray.opacity(0.1))
            .navigationTitle("My Tasks")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    accountMenu
                }
            }
            .safeAreaInset(edge: .bottom) { composer }
            .task(id: auth.userId) {
                store.stopListening()
                if let uid = auth.userId {
                    store.listen(userId: uid)
                }
            }
            .onDisappear { store.stopListening() }
        }
    }

    private var summaryHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Hello, \(auth.friendlyName)")
                .font(.title2.bold())

            Text(store.todos.isEmpty
                 ? "Nothing planned yet"
                 : "\(store.remaining) of \(store.todos.count) tasks left")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ProgressView(value: Double(store.completed),
                         total: Double(max(store.todos.count, 1)))
                .tint(.indigo)

            if let error = store.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    private var filterPicker: some View {
        Picker("Filter", selection: $filter) {
            ForEach(TaskFilter.allCases) { item in
                Text(item.rawValue).tag(item)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    private var taskList: some View {
        List {
            ForEach(visibleTodos) { todo in
                row(for: todo)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            store.delete(todo)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            store.toggle(todo)
                        } label: {
                            Label(todo.isDone ? "Undo" : "Done",
                                  systemImage: todo.isDone ? "arrow.uturn.backward" : "checkmark")
                        }
                        .tint(.green)
                    }
            }
        }
        .listStyle(.inset)
        .scrollContentBackground(.hidden)
        .animation(.default, value: visibleTodos.count)
        .overlay {
            if store.isLoading {
                ProgressView()
            } else if visibleTodos.isEmpty {
                ContentUnavailableView(
                    filter == .done ? "Nothing finished yet" : "No tasks here",
                    systemImage: filter == .done ? "checkmark.seal" : "tray",
                    description: Text("Add a task using the bar below.")
                )
            }
        }
    }

    private func row(for todo: Todo) -> some View {
        HStack(spacing: 12) {
            Button {
                store.toggle(todo)
            } label: {
                Image(systemName: todo.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(todo.isDone ? Color.green : todo.level.color)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                Text(todo.title)
                    .strikethrough(todo.isDone)
                    .foregroundStyle(todo.isDone ? .secondary : .primary)
                Text(todo.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(todo.level.title)
                .font(.caption2.bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(todo.level.color.opacity(0.15), in: Capsule())
                .foregroundStyle(todo.level.color)
        }
        .padding(.vertical, 4)
    }

    private var composer: some View {
        HStack(spacing: 10) {
            Menu {
                Picker("Priority", selection: $draftPriority) {
                    ForEach(Priority.allCases) { level in
                        Text(level.title).tag(level)
                    }
                }
            } label: {
                Image(systemName: "flag.fill")
                    .foregroundStyle(draftPriority.color)
                    .frame(width: 38, height: 38)
                    .background(.thinMaterial, in: Circle())
            }

            TextField("Add a task", text: $draft)
                .focused($typing)
                .submitLabel(.done)
                .onSubmit(addTask)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.thinMaterial, in: Capsule())

            Button(action: addTask) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 36))
            }
            .disabled(cleanDraft.isEmpty)
            .accessibilityLabel("Add task")
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private var accountMenu: some View {
        Menu {
            if let mail = auth.user?.email {
                Text(mail)
            }
            Button(role: .destructive) {
                auth.signOut()
            } label: {
                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
            }
        } label: {
            Image(systemName: "person.crop.circle")
        }
    }

    private func addTask() {
        guard !cleanDraft.isEmpty, let uid = auth.userId else { return }
        store.add(title: cleanDraft, priority: draftPriority, userId: uid)
        draft = ""
        typing = true
    }
}
