//
//  FriendMultiPickerSheet.swift
//  Catchup
//
//  Created by Intat Tochirakul on 8/11/2568 BE.
//

// View/Friends/FriendMultiPickerSheet.swift
import SwiftUI
import FirebaseAuth

struct FriendMultiPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selected: Set<String>

    @State private var isLoading = true
    @State private var rows: [FriendRowVM] = []   // <- view models w/ names from users

    private let friendsRepo = FriendsRepository()
    private let usersRepo = UsersRepository()
    private var myUid: String { Auth.auth().currentUser?.uid ?? "" }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView().controlSize(.large)
                } else if rows.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "person.2").font(.largeTitle)
                        Text("You have no friends yet").foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(rows, id: \.id) { r in
                        HStack(spacing: 12) {
                            // (You) marker if ever present (usually shouldn’t be)
                            if r.uid == myUid {
                                Text("(You)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(r.displayName.isEmpty ? "Friend" : r.displayName)
                                Text("@\(r.username.isEmpty ? "unknown" : r.username)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()

                            let isOn = selected.contains(r.uid)
                            Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(isOn ? Color.accentColor : Color.secondary)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                if selected.contains(r.uid) { selected.remove(r.uid) }
                                else { selected.insert(r.uid) }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Friends")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.bold()
                }
            }
            .task {
                await loadFriends()
            }
        }
    }

    // MARK: - Data load: edges → batch profiles → row VMs
    private func loadFriends() async {
        guard !myUid.isEmpty else { isLoading = false; rows = []; return }
        isLoading = true
        defer { isLoading = false }

        do {
            // 1) edges from subcollection (friend UIDs)
            let edges = try await friendsRepo.friendsOnce(for: myUid)
            let ids = edges.map { $0.friendUid }

            // 2) batch fetch user profiles for these UIDs
            let profiles = try await usersRepo.getMany(uids: ids)

            // 3) map to row VMs; fall back to edge cache if profile missing
            self.rows = edges.map { e in
                if let u = profiles[e.friendUid] {
                    return FriendRowVM(
                        uid: u.uid,
                        displayName: u.displayName,
                        username: u.username,
                        photoURL: u.photoURL,
                        since: e.since,
                        streaks: e.streaks
                    )
                } else {
                    return FriendRowVM(
                        uid: e.friendUid,
                        displayName: e.friendName.isEmpty ? "Friend" : e.friendName,
                        username: e.friendUsername.isEmpty ? "unknown" : e.friendUsername,
                        photoURL: nil,
                        since: e.since,
                        streaks: e.streaks
                    )
                }
            }
            .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }

        } catch {
            // On any failure, show empty gracefully
            self.rows = []
        }
    }
}
