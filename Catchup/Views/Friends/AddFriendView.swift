//
//  AddFriendView.swift
//  Catchup
//
//  Created by Nick Jitjang on 10/29/25.
//

import SwiftUI

struct AddFriendView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = AddFriendController()
    @State private var hasSearched = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text("Enter friend username")
                    .font(.headline)
                    .padding(.horizontal, 20)

                HStack(spacing: 10) {
                    TextField("Type here", text: $vm.query)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.gray.opacity(0.25))
                        )

                    Button("Search") {
                        hasSearched = true
                        Task { await vm.search() }
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal, 20)

                // Status text: either "results for" or "no users found"
                if !vm.results.isEmpty {
                    Text("Showing results for “\(vm.query)”")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 20)
                } else if hasSearched && !vm.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("No users found")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 20)
                }

                List {
                    ForEach(vm.results) { user in
                        HStack(spacing: 12) {
                            AvatarView(photoURL: user.photoURL, avatarKey: nil, size: 40)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(user.displayName)
                                    .font(.headline)
                                Text("@\(user.username)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                            
                            if vm.existingFriends.contains(user.uid) {
                                Text("Friends")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.gray)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule().fill(Color.gray.opacity(0.3))
                                    )
                                
                            } else if vm.sentTo.contains(user.uid) {
                                Text("Sent")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.gray)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(Color.gray.opacity(0.3))
                                    )
                            } else {
                                Button {
                                    Task { await vm.sendRequest(to: user) }
                                } label: {
                                    if vm.sending.contains(user.uid) {
                                        ProgressView()
                                    } else {
                                        Text("Add")
                                            .font(.subheadline.weight(.semibold))
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(Color.indigo))
                                .foregroundStyle(.white)
                                .buttonStyle(.plain)
                            }
                        }
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Add Friend")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                    }
                }
            }
        }
    }
}
