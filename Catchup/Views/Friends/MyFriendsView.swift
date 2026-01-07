//
//  MyFriendsView.swift
//  Catchup
//
//  Created by Nick Jitjang on 10/29/25.
//
// View/Friends/MyFriendsView.swift
import SwiftUI

struct MyFriendsView: View {
    @StateObject private var vm = MyFriendsController()

    var body: some View {
        List {
            if vm.friends.isEmpty {
                Section {
                    VStack(spacing: 8) {
                        Image(systemName: "person.2")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("No friends yet").foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            } else {
                ForEach(vm.friends) { row in
                    FriendRow(
                        row: row,
                        onRemove: {
                            Task { await vm.remove(friend: row) }
                        },
                        onOpen: {
                            // TODO: navigate to friend's profile if you add one
                        }
                    )
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("My Friends")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { vm.start() }
        .refreshable { await vm.refresh() }
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 96)
        }
    }
}

private struct FriendRow: View {
    let row: FriendRowVM
    var onRemove: () -> Void
    var onOpen: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            avatar(size: 48)

            VStack(alignment: .leading, spacing: 2) {
                Text(row.displayName.isEmpty ? "Friend" : row.displayName)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)

                Text("@\(row.username.isEmpty ? "unknown" : row.username)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("Friends since \(sinceString(row.since))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Streak: \(row.streaks) days🔥")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

            }

            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture { onOpen() }
        .contextMenu {
            Button(role: .destructive) {
                onRemove()
            } label: {
                Label("Remove Friend", systemImage: "trash")
            }

            // Optional quick actions:
            Button {
                UIPasteboard.general.string = "@\(row.username)"
            } label: {
                Label("Copy Username", systemImage: "doc.on.doc")
            }

            Button {
                onOpen()
            } label: {
                Label("View Profile", systemImage: "person")
            }
        }
    }

    @ViewBuilder
    private func avatar(size: CGFloat) -> some View {
        ZStack {
            Circle().fill(Color.gray.opacity(0.2))
            if let s = row.photoURL, let url = URL(string: s) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty: ProgressView().scaleEffect(0.8)
                    case .success(let img): img.resizable().scaledToFill()
                    case .failure: Image(systemName: "person.fill")
                            .font(.system(size: size * 0.55))
                            .foregroundStyle(.secondary)
                    @unknown default: EmptyView()
                    }
                }
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.55))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private func sinceString(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "MMM yyyy"; return f.string(from: d)
    }
}
