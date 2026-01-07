//
//  LoginView.swift
//  ScreenTimeBudget
//
//  User login screen
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        ZStack {
            // Dark background
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    // Logo and title
                    VStack(spacing: 20) {
                        Image(systemName: "hourglass")
                            .font(.system(size: 72))
                            .foregroundColor(.blue)
                            .shadow(color: .blue.opacity(0.3), radius: 20, x: 0, y: 10)

                        Text("Screen Time Copilot")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)

                        Text("Take control of your screen time")
                            .font(.system(size: 17))
                            .foregroundColor(.white.opacity(0.7))
                            .tracking(0.5)
                    }
                    .padding(.top, 80)

                    // Email/Password form
                    VStack(spacing: 20) {
                        // Email field
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Email")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white.opacity(0.9))
                                .tracking(0.3)

                            TextField("your@email.com", text: $viewModel.email)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .keyboardType(.emailAddress)
                                .textContentType(.emailAddress)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.white.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                )
                                .foregroundColor(.white)
                                .font(.system(size: 17))
                        }

                        // Password field
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Password")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white.opacity(0.9))
                                .tracking(0.3)

                            SecureField("Enter your password", text: $viewModel.password)
                                .textContentType(.password)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.white.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                )
                                .foregroundColor(.white)
                                .font(.system(size: 17))
                        }

                        // Error message
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        }

                        // Login button
                        Button(action: {
                            Task {
                                await viewModel.login()
                            }
                        }) {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Log In")
                                        .font(.system(size: 18, weight: .bold))
                                        .tracking(0.5)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 58)
                            .background(
                                LinearGradient(
                                    colors: viewModel.isFormValid ?
                                        [Color.blue, Color.blue.opacity(0.8)] :
                                        [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(14)
                            .shadow(color: viewModel.isFormValid ? Color.blue.opacity(0.3) : Color.clear, radius: 12, x: 0, y: 6)
                        }
                        .disabled(viewModel.isLoading || !viewModel.isFormValid)
                        .animation(.easeInOut(duration: 0.2), value: viewModel.isFormValid)
                    }
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
                    SignInWithAppleButton(.signIn) { request in
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

                    // Sign up link
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .foregroundColor(.white.opacity(0.6))
                        Button("Sign Up") {
                            viewModel.showSignup = true
                        }
                        .foregroundColor(.blue)
                        .fontWeight(.semibold)
                    }
                    .font(.system(size: 15))
                    .padding(.bottom, 40)
                }
            }
        }
        .sheet(isPresented: $viewModel.showSignup) {
            SignupView()
                .environmentObject(authManager)
        }
        .onChange(of: viewModel.loginSuccess) { success in
            if success {
                authManager.isAuthenticated = true
            }
        }
    }
}

// MARK: - ViewModel

@MainActor
class LoginViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showSignup = false
    @Published var loginSuccess = false

    var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && password.count >= 8
    }

    func login() async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await AuthManager.shared.login(email: email, password: password)
            loginSuccess = true
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
    LoginView()
        .environmentObject(AuthManager.shared)
}
