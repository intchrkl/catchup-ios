//
//  AccountSettingsView.swift
//  Catchup
//
//  Created by Nick Jitjang on 11/9/25.
//

import SwiftUI
import PhotosUI

struct AccountSettingsView: View {
    @StateObject private var vm = AccountSettingsController()
    @EnvironmentObject var session: SessionController

    var body: some View {
        Form {
            Section("Profile Picture") {
                HStack(spacing: 16) {
                    avatarPreview
                        .frame(width: 64, height: 64)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.secondary.opacity(0.2), lineWidth: 1))

                    PhotosPicker(selection: $vm.pickedItem, matching: .images) {
                        Label("Choose Photo", systemImage: "photo.on.rectangle")
                    }
                    .onChange(of: vm.pickedItem) { _ in vm.handlePickChange() }

                    if vm.pickedImageData != nil {
                        Text("New image selected").font(.footnote).foregroundColor(.secondary)
                    }
                }
            }

            Section("Name") {
                TextField("Display Name", text: $vm.displayName)
                    .textInputAutocapitalization(.words)
            }

            Section("Username") {
                TextField("username", text: $vm.username)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .keyboardType(.asciiCapable)
            }

            if let err = vm.errorMessage {
                Section {
                    Text(err).foregroundColor(.red)
                }
            }

            Section {
                Button {
                    Task {
                        await vm.save()
                        await session.refreshNow()
                    }
                } label: {
                    if vm.isSaving {
                        ProgressView()
                    } else {
                        Text("Save Changes")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .disabled(vm.isSaving || vm.displayName.isEmpty || vm.username.isEmpty)
            }
        }
        .navigationTitle("Account Settings")
        .task { await vm.loadCurrent() }
    }

    @ViewBuilder
    private var avatarPreview: some View {
        if let data = vm.pickedImageData, let img = UIImage(data: data) {
            Image(uiImage: img).resizable().scaledToFill()
        } else if let s = vm.currentPhotoURL, let url = URL(string: s) {
            AsyncImage(url: url) { ph in
                switch ph {
                case .empty: ProgressView()
                case .success(let img): img.resizable().scaledToFill()
                case .failure: placeholder
                @unknown default: placeholder
                }
            }
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        ZStack {
            Circle().fill(Color.gray.opacity(0.2))
            Image(systemName: "person.fill")
                .font(.title2)
                .foregroundStyle(.secondary)
        }
    }
}
