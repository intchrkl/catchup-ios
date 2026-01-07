//
//  NotificationsView.swift
//  Catchup
//
//  Created by Nick Jitjang on 10/29/25.
//

// View/Notifications/NotificationsView.swift
import SwiftUI

struct NotificationsView: View {
    @StateObject private var vm = NotificationsController()
    @State private var showReceivedAnswers = false   // 👈 new

    var body: some View {
        NavigationStack {
            List {
                // Friend requests
                Section("Friend Requests") {
                    let friendRequests = vm.incoming.filter { $0.type == "friendRequest" }

                    if friendRequests.isEmpty {
                        Text("No friend requests")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(friendRequests) { n in
                            FriendRequestRow(notification: n, vm: vm)
                        }
                    }
                }

                // Answers from friends
                Section("Answers from friends") {
                    let answerNotifs = vm.incoming.filter { $0.type == "answerShared" }

                    if answerNotifs.isEmpty {
                        Text("No new answers")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(answerNotifs) { n in
                            AnswerSharedRow(
                                notification: n,
                                vm: vm,
                                onOpen: { showReceivedAnswers = true }   // 👈 push reel view
                            )
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Notifications")
            .onAppear { vm.start() }
            .onDisappear {
                // Optional: mark all answerShared as read when leaving
                Task { await vm.markAllAnswerSharedRead() }
            }
            .navigationDestination(isPresented: $showReceivedAnswers) {
                // This is your Reels-style feed
                ReceivedAnswersView(showsBackButton: true)
            }
        }
    }
}

// MARK: - Friend Request Row

private struct FriendRequestRow: View {
    let notification: AppNotificationLite
    @ObservedObject var vm: NotificationsController

    var body: some View {
        HStack(spacing: 12) {
            let fromUid = (notification.data["fromUid"] as? String) ?? ""
            SenderAvatarThumb(uid: fromUid)

            VStack(alignment: .leading, spacing: 2) {
                let fromName = (notification.data["fromName"] as? String) ?? "Someone"
                let fromUser = (notification.data["fromUsername"] as? String) ?? "unknown"
                Text("\(fromName) sent you a friend request")
                    .font(.subheadline.weight(.semibold))
                Text("@\(fromUser)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 16) {
                Button {
                    Task {
                        await vm.accept(
                            notification,
                            myDisplay: "Me",
                            myUsername: "me_user",
                            otherDisplay: (notification.data["fromName"] as? String) ?? "Someone",
                            otherUsername: (notification.data["fromUsername"] as? String) ?? "unknown"
                        )
                    }
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Color.blue))
                }
                .buttonStyle(.plain)

                Button {
                    Task { await vm.decline(notification) }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.blue)
                        .frame(width: 40, height: 40)
                        .background(Circle().stroke(Color.blue, lineWidth: 2))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Answer Shared Row

private struct AnswerSharedRow: View {
    let notification: AppNotificationLite
    @ObservedObject var vm: NotificationsController
    let onOpen: () -> Void     // 👈 callback to parent

    var body: some View {
        Button {
            Task {
                // mark this notification as read in Firestore + remove from list
                await vm.markRead(notification)
                // then navigate to ReceivedAnswersView
                onOpen()
            }
        } label: {
            HStack(spacing: 12) {
                let fromUid = (notification.data["fromUid"] as? String) ?? ""
                SenderAvatarThumb(uid: fromUid)

                VStack(alignment: .leading, spacing: 2) {
                    let fromName = (notification.data["fromName"] as? String) ?? "Someone"
                    let fromUser = (notification.data["fromUsername"] as? String) ?? "unknown"
                    Text("\(fromName) answered a question!")
                        .font(.subheadline.weight(.semibold))
                    Text("@\(fromUser)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }
}



// For profile photos
private struct SenderAvatarThumb: View {
    let uid: String
    @State private var photoURL: String?
    private let users = UsersRepository()

    var body: some View {
        AvatarView(photoURL: photoURL, avatarKey: nil, size: 36)
            .task(id: uid) {
                if photoURL == nil {
                    if let user = try? await users.get(uid: uid) {
                        photoURL = user.photoURL
                    }
                }
            }
    }
}
