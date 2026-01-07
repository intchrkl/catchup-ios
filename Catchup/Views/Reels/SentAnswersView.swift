//
//  SentAnswersView.swift
//  Catchup
//
//  Created by Intat Tochirakul on 28/11/2568 BE.
//

import SwiftUI
import FirebaseAuth

private func colorForCategory(_ category: String?) -> Color {
    let base: Color

    switch category?.lowercased() {
    case let c? where c.contains("self reflection"):
        base = Color("CU.Orange")
    case let c? where c.contains("memories"):
        base = Color("CU.indigo")
    case let c? where c.contains("relationships"):
        base = Color("CU.Pink")
    case let c? where c.contains("would you rather"):
        base = Color("CU.Green")
    case let c? where c.contains("goals"):
        base = Color("CU.Red")
    case let c? where c.contains("gratitude"):
        base = Color("CU.Yellow")
    default:
        base = Color.black   // fallback
    }

    return base
}

struct SentAnswersView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm: SentAnswersController
    let showsBackButton: Bool

    init(showsBackButton: Bool = false) {
        _vm = StateObject(wrappedValue: SentAnswersController())
        self.showsBackButton = showsBackButton
    }

    var body: some View {
        ZStack {
            if vm.items.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "paperplane.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No sent responses yet")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white)
            } else {
                VerticalPager(index: $vm.currentIndex, count: vm.items.count) { i in
                    SentAnswerCard(vm: vm.items[i])
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Group {
                if vm.items.isEmpty {
                    Color.white
                } else {
                    colorForCategory(vm.items[vm.currentIndex].answer.category)
                }
            }
            .ignoresSafeArea()
        )
        .animation(.easeInOut(duration: 0.25), value: vm.currentIndex)
        .overlay(alignment: .topLeading) {
            if showsBackButton {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(
                            Circle().fill(Color.black.opacity(0.35))
                        )
                }
                .padding(.leading, 16)
                .padding(.top, 12)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
        .onAppear { vm.start() }
        .onDisappear { vm.stop() }
    }
}

private struct SentAnswerCard: View {
    let vm: AnswerReelVM

    // recipients display
    @State private var recipientNames: [String] = []
    private let usersRepo = UsersRepository()

    // reactions + comments
    @StateObject private var reactions: ReactionsController
    @StateObject private var comments: CommentsController
    @State private var showComments = false

    // same emojis as inbox
    private let reactionEmojis = ["👍", "❤️", "😂", "😮", "🥹"]

    init(vm: AnswerReelVM) {
        self.vm = vm

        let uid = Auth.auth().currentUser?.uid ?? ""
        _reactions = StateObject(
            wrappedValue: ReactionsController(answer: vm.answer, currentUid: uid)
        )
        _comments = StateObject(
            wrappedValue: CommentsController(answer: vm.answer)
        )
    }

    private var recipientsSummary: String {
        if recipientNames.isEmpty {
            return "to: loading..."
        }
        return "to: " + recipientNames.joined(separator: ", ")
    }

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    colorForCategory(vm.answer.category),
                    colorForCategory(vm.answer.category).opacity(0.9)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {

                // ----- HEADER -----
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sent by you")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)

                    Text(recipientsSummary)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))

                    Text(vm.answer.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.75))
                }

                // QUESTION
                VStack(alignment: .leading, spacing: 8) {
                    Text("Question")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white.opacity(0.9))

                    Text(vm.answer.promptText)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(.white.opacity(0.08))
                        )
                }

                // ANSWER
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your answer")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white.opacity(0.9))

                    Text(vm.answer.text)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(.white.opacity(0.06))
                        )
                }

                // REACTIONS + COMMENTS
                HStack(spacing: 8) {
                    // Emoji reactions (same behavior as inbox)
                    ForEach(reactionEmojis, id: \.self) { emoji in
                        Button {
                            Task { await reactions.toggle(emoji: emoji) }
                        } label: {
                            HStack(spacing: 4) {
                                Text(emoji)

                                if let count = reactions.counts[emoji], count > 0 {
                                    Text("\(count)")
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(.white)
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(
                                Capsule().fill(
                                    reactions.userReactions.contains(emoji)
                                    ? Color.white.opacity(0.28)
                                    : Color.white.opacity(0.16)
                                )
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()

                    // Comments button with count
                    Button {
                        showComments = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "text.bubble")
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(.white.opacity(0.16))
                        )
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .padding(.bottom, 26)
        }
        .sheet(isPresented: $showComments) {
            CommentsView(controller: comments)
        }
        .onAppear {
            Task { await loadRecipientNames() }
            reactions.start()
            comments.start()
        }
        .onDisappear {
            reactions.stop()
            comments.stop()
        }
    }

    private func loadRecipientNames() async {
        var names: [String] = []

        for uid in vm.answer.recipients {
            if let user = try? await usersRepo.get(uid: uid) {
                let name = user.displayName.isEmpty ? user.username : user.displayName
                names.append(name)
            }
        }

        await MainActor.run {
            self.recipientNames = names
        }
    }
}
