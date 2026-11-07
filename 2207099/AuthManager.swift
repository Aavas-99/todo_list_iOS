import SwiftUI
import Combine
import FirebaseAuth

final class AuthManager: ObservableObject {
    @Published private(set) var user: User?
    private var listenerHandle: AuthStateDidChangeListenerHandle?

    var isSignedIn: Bool { user != nil }
    var userId: String? { user?.uid }

    var friendlyName: String {
        if let name = user?.displayName, !name.isEmpty { return name }
        if let mail = user?.email, let local = mail.split(separator: "@").first {
            return String(local)
        }
        return "there"
    }

    init() {
        user = Auth.auth().currentUser
        listenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, newUser in
            self?.user = newUser
        }
    }

    deinit {
        if let listenerHandle {
            Auth.auth().removeStateDidChangeListener(listenerHandle)
        }
    }

    func signUp(email: String, password: String, completion: @escaping (String?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { _, error in
            DispatchQueue.main.async { completion(error?.localizedDescription) }
        }
    }

    func signIn(email: String, password: String, completion: @escaping (String?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { _, error in
            DispatchQueue.main.async { completion(error?.localizedDescription) }
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Sign out failed:", error)
        }
    }
}
