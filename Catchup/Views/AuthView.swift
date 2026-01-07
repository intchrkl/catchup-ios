//
//  AuthView.swift
//  Catchup
//
//  Created by Nick Jitjang on 10/29/25.
//

import SwiftUI

struct AuthView: View {
    enum Mode { case signIn, signUp }
    @EnvironmentObject var auth: AuthController
    @State private var mode: Mode = .signUp

    // shared fields
    @State private var email = ""
    @State private var password = ""

    // sign up only
    @State private var displayName = ""
    @State private var username = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Picker("", selection: $mode) {
                    Text("Create Account").tag(Mode.signUp)
                    Text("Sign In").tag(Mode.signIn)
                }
                .pickerStyle(.segmented)

                if mode == .signUp {
                    TextField("Display name", text: $displayName)
                        .textContentType(.name)
                        .autocapitalization(.words)
                        .textFieldStyle(.roundedBorder)
                    TextField("Username (no spaces)", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textFieldStyle(.roundedBorder)
                }

                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)

                SecureField("Password (min 6 chars)", text: $password)
                    .textContentType(.password)
                    .textFieldStyle(.roundedBorder)

                if let error = auth.errorMessage {
                    Text(error).foregroundStyle(.red).font(.footnote)
                }

                Button(action: primaryAction) {
                    if auth.isBusy { ProgressView() }
                    else { Text(mode == .signUp ? "Create Account" : "Sign In").frame(maxWidth: .infinity) }
                }
                .buttonStyle(.borderedProminent)
                .disabled(auth.isBusy || !formValid)
                .padding(.top, 8)

                Spacer()
            }
            .padding()
            .navigationTitle(mode == .signUp ? "Welcome" : "Welcome Back")
        }
    }

    private var formValid: Bool {
        switch mode {
        case .signUp: return !displayName.isEmpty && !username.isEmpty && !email.isEmpty && password.count >= 6
        case .signIn: return !email.isEmpty && password.count >= 6
        }
    }

    private func primaryAction() {
        Task {
            switch mode {
            case .signUp:
                await auth.signUp(displayName: displayName.trimmingCharacters(in: .whitespaces),
                                  username: username.lowercased().trimmingCharacters(in: .whitespaces),
                                  email: email.lowercased().trimmingCharacters(in: .whitespaces),
                                  password: password)
            case .signIn:
                await auth.signIn(email: email.lowercased().trimmingCharacters(in: .whitespaces),
                                  password: password)
            }
        }
    }
}
