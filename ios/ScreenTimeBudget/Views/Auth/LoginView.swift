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
                    VStack(spacing: 16) {
                        Image(systemName: "hourglass")
                            .font(.system(size: 64))
                            .foregroundColor(.blue)

                        Text("Screen Budget")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)

                        Text("Take control of your screen time")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.top, 60)

                    // Email/Password form
                    VStack(spacing: 20) {
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
                        }

                        // Password field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))

                            SecureField("", text: $viewModel.password)
                                .textContentType(.password)
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                                .foregroundColor(.white)
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
                                        .font(.system(size: 17, weight: .semibold))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(viewModel.isLoading || !viewModel.isFormValid)
                        .opacity(viewModel.isFormValid ? 1.0 : 0.5)
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
