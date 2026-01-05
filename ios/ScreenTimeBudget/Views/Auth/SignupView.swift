//
//  SignupView.swift
//  ScreenTimeBudget
//
//  User signup screen
//

import SwiftUI
import AuthenticationServices

struct SignupView: View {
    @StateObject private var viewModel = SignupViewModel()
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                // Dark background
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        // Header
                        VStack(spacing: 16) {
                            Text("Create Account")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)

                            HStack(spacing: 6) {
                                Image(systemName: "gift.fill")
                                    .foregroundColor(.green)
                                Text("Start your 7-day free trial")
                                    .font(.system(size: 17))
                                    .foregroundColor(.white.opacity(0.7))
                                    .tracking(0.5)
                            }
                        }
                        .padding(.top, 50)

                        // Form fields
                        VStack(spacing: 20) {
                            // Name field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Name (Optional)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))

                                TextField("", text: $viewModel.name)
                                    .textContentType(.name)
                                    .padding()
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(12)
                                    .foregroundColor(.white)
                            }

                            // Email field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))

                                TextField("", text: $viewModel.email)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .keyboardType(.emailAddress)
                                    .textContentType(.emailAddress)
                                    .padding()
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(12)
                                    .foregroundColor(.white)

                                if !viewModel.email.isEmpty && !viewModel.isEmailValid {
                                    Text("Please enter a valid email")
                                        .font(.system(size: 12))
                                        .foregroundColor(.red.opacity(0.8))
                                }
                            }

                            // Password field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))

                                SecureField("", text: $viewModel.password)
                                    .textContentType(.newPassword)
                                    .padding()
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(12)
                                    .foregroundColor(.white)

                                if !viewModel.password.isEmpty && !viewModel.isPasswordValid {
                                    Text("Password must be at least 8 characters with a number and letter")
                                        .font(.system(size: 12))
                                        .foregroundColor(.red.opacity(0.8))
                                }
                            }

                            // Confirm password field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Confirm Password")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))

                                SecureField("", text: $viewModel.confirmPassword)
                                    .textContentType(.newPassword)
                                    .padding()
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(12)
                                    .foregroundColor(.white)

                                if !viewModel.confirmPassword.isEmpty && !viewModel.passwordsMatch {
                                    Text("Passwords do not match")
                                        .font(.system(size: 12))
                                        .foregroundColor(.red.opacity(0.8))
                                }
                            }
                        }
                        .padding(.horizontal, 32)

                        // Trial info
                        VStack(spacing: 12) {
                            HStack(spacing: 10) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 18))
                                Text("7 days free trial")
                                    .font(.system(size: 16, weight: .medium))
                                Spacer()
                            }
                            HStack(spacing: 10) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 18))
                                Text("$0.99/month after trial")
                                    .font(.system(size: 16, weight: .medium))
                                Spacer()
                            }
                            HStack(spacing: 10) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 18))
                                Text("Cancel anytime")
                                    .font(.system(size: 16, weight: .medium))
                                Spacer()
                            }
                        }
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.vertical, 20)
                        .padding(.horizontal, 24)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.green.opacity(0.15), Color.green.opacity(0.05)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 32)

                        // Error message
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }

                        // Sign up button
                        Button(action: {
                            Task {
                                await viewModel.signup()
                            }
                        }) {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "gift.fill")
                                        .font(.system(size: 16))
                                    Text("Start Free Trial")
                                        .font(.system(size: 18, weight: .bold))
                                        .tracking(0.5)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 58)
                            .background(
                                LinearGradient(
                                    colors: viewModel.isFormValid ?
                                        [Color.green, Color.green.opacity(0.8)] :
                                        [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(14)
                            .shadow(color: viewModel.isFormValid ? Color.green.opacity(0.3) : Color.clear, radius: 12, x: 0, y: 6)
                        }
                        .disabled(viewModel.isLoading || !viewModel.isFormValid)
                        .animation(.easeInOut(duration: 0.2), value: viewModel.isFormValid)
                        .padding(.horizontal, 32)

                        // Divider
                        HStack {
                            Rectangle()
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 1)
                            Text("OR")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                                .padding(.horizontal, 12)
                            Rectangle()
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 1)
                        }
                        .padding(.horizontal, 32)

                        // Apple Sign In
                        SignInWithAppleButton(.signUp) { request in
                            request.requestedScopes = [.email, .fullName]
                        } onCompletion: { result in
                            Task {
                                await viewModel.handleAppleSignIn(result)
                            }
                        }
                        .signInWithAppleButtonStyle(.white)
                        .frame(height: 56)
                        .cornerRadius(12)
                        .padding(.horizontal, 32)

                        // Terms
                        Text("By signing up, you agree to our Terms of Service and Privacy Policy")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .onChange(of: viewModel.signupSuccess) { success in
            if success {
                authManager.isAuthenticated = true
                dismiss()
            }
        }
    }
}

// MARK: - ViewModel

@MainActor
class SignupViewModel: ObservableObject {
    @Published var name = ""
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var signupSuccess = false

    var isEmailValid: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }

    var isPasswordValid: Bool {
        password.count >= 8 && password.contains(where: \.isNumber) && password.contains(where: \.isLetter)
    }

    var passwordsMatch: Bool {
        password == confirmPassword
    }

    var isFormValid: Bool {
        isEmailValid && isPasswordValid && passwordsMatch
    }

    func signup() async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await AuthManager.shared.signup(
                email: email,
                password: password,
                name: name.isEmpty ? nil : name
            )
            signupSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                isLoading = true
                errorMessage = nil

                // TODO: Send identity token to backend
                // For now, this is a placeholder
                print("Apple Sign In successful: \(appleIDCredential.user)")

                isLoading = false
            }
        case .failure(let error):
            errorMessage = "Apple Sign In failed: \(error.localizedDescription)"
        }
    }
}

#Preview {
    SignupView()
        .environmentObject(AuthManager.shared)
}
