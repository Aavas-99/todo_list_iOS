import SwiftUI

private enum AuthMode: String, CaseIterable, Identifiable {
    case login = "Log In"
    case signup = "Sign Up"
    var id: String { rawValue }
}

private extension View {
    func inputBox() -> some View {
        self
            .padding(14)
            .background(Color(.secondarySystemBackground),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct AuthView: View {
    @EnvironmentObject var auth: AuthManager

    @State private var mode: AuthMode = .login
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var message: String?
    @State private var busy = false
    @FocusState private var focused: Field?

    private enum Field { case email, password }

    private var cleanEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSubmit: Bool {
        cleanEmail.contains("@") && password.count >= 6 && !busy
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.indigo, .purple.opacity(0.85), .blue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    header
                    card
                }
                .padding(24)
                .padding(.top, 40)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "checklist.checked")
                .font(.system(size: 54, weight: .semibold))
                .foregroundStyle(.white)
            Text("TaskNest")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("Plan your day, one task at a time")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
        }
    }

    private var card: some View {
        VStack(spacing: 16) {
            Picker("Mode", selection: $mode) {
                ForEach(AuthMode.allCases) { item in
                    Text(item.rawValue).tag(item)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: mode) { message = nil }

            HStack(spacing: 10) {
                Image(systemName: "envelope")
                    .foregroundStyle(.secondary)
                    .frame(width: 22)
                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .focused($focused, equals: .email)
                    .submitLabel(.next)
                    .onSubmit { focused = .password }
            }
            .inputBox()

            HStack(spacing: 10) {
                Image(systemName: "lock")
                    .foregroundStyle(.secondary)
                    .frame(width: 22)
                Group {
                    if showPassword {
                        TextField("Password", text: $password)
                    } else {
                        SecureField("Password", text: $password)
                    }
                }
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textContentType(mode == .signup ? .newPassword : .password)
                .focused($focused, equals: .password)
                .submitLabel(.go)
                .onSubmit { if canSubmit { submit() } }

                Button {
                    showPassword.toggle()
                } label: {
                    Image(systemName: showPassword ? "eye.slash" : "eye")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .inputBox()

            if mode == .signup {
                Text("Use at least 6 characters for your password.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let message {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button(action: submit) {
                HStack(spacing: 8) {
                    if busy { ProgressView().tint(.white) }
                    Text(mode == .login ? "Log In" : "Create Account")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!canSubmit)
        }
        .padding(20)
        .background(.regularMaterial,
                    in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func submit() {
        focused = nil
        busy = true
        message = nil

        let finish: (String?) -> Void = { error in
            busy = false
            message = error
        }

        switch mode {
        case .login:
            auth.signIn(email: cleanEmail, password: password, completion: finish)
        case .signup:
            auth.signUp(email: cleanEmail, password: password, completion: finish)
        }
    }
}
