//
//  ReceivedAnswersView.swift
//  Catchup
//
//  Created by Eric Lin on 11/8/25.
//
// View/Reels/ReceivedAnswersView.swift

import SwiftUI
import UIKit
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

// MARK: - Simple vertical pager with page snap (TikTok/IG Reels style)
struct VerticalPager<Content: View>: View {
    @Binding var index: Int
    let count: Int
    let content: (Int) -> Content

    var body: some View {
        GeometryReader { geo in
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(0..<count, id: \.self) { i in
                            content(i)
                                .frame(width: geo.size.width, height: geo.size.height)
                                .id(i)
                        }
                    }
                }
                .scrollDisabled(true)
                .onChange(of: index) { _, new in
                    withAnimation(.easeInOut(duration: 0.22)) {
                        proxy.scrollTo(new, anchor: .top)
                    }
                }
                .onAppear {
                    proxy.scrollTo(index, anchor: .top)
                }
                .gesture(
                    DragGesture(minimumDistance: 10, coordinateSpace: .local)
                        .onEnded { value in
                            let h = geo.size.height
                            let delta = value.predictedEndTranslation.height
                            let threshold = h * 0.15

                            var next = index
                            if delta < -threshold { next = min(index + 1, count - 1) }
                            if delta >  threshold { next = max(index - 1, 0) }

                            withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                                index = next
                            }
                            withAnimation(.easeInOut(duration: 0.2)) {
                                proxy.scrollTo(index, anchor: .top)
                            }
                        }
                )
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Share helpers

private struct ShareItem: Identifiable {
    let id = UUID()
    let image: UIImage
}

private struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    var onComplete: (() -> Void)? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let vc = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        vc.completionWithItemsHandler = { _, _, _, _ in
            onComplete?()
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Snapshot helper

extension View {
    @MainActor
    func snapshotImageAsync(
        size: CGSize,
        scale: CGFloat = UIScreen.main.scale,
        forceDark: Bool = true
    ) async -> UIImage? {
        await Task.yield()

        if #available(iOS 16.0, *) {
            let renderer = ImageRenderer(
                content: self.environment(\.colorScheme, forceDark ? .dark : .light)
            )
            renderer.proposedSize = .init(size)
            renderer.scale = scale

            await Task.yield()
            return renderer.uiImage
        } else {
            let host = UIHostingController(
                rootView: self.environment(\.colorScheme, forceDark ? .dark : .light)
            )
            host.view.bounds = CGRect(origin: .zero, size: size)
            host.view.backgroundColor = .clear

            host.view.setNeedsLayout()
            host.view.layoutIfNeeded()

            let format = UIGraphicsImageRendererFormat()
            format.scale = scale
            let renderer = UIGraphicsImageRenderer(size: size, format: format)
            return renderer.image { _ in
                host.view.drawHierarchy(in: host.view.bounds, afterScreenUpdates: true)
            }
        }
    }
}

// MARK: - Reel Card

struct AnswerReelCard: View {
    let vm: AnswerReelVM
    let showsBackButton: Bool

    @State private var shareItem: ShareItem?
    @State private var showComments = false
    @Environment(\.dismiss) private var dismiss

    // Reactions controller (Slack-style reactions)
    @StateObject private var reactions: ReactionsController

    // Fixed emoji set (5 basics)
    private let reactionEmojis = ["👍", "❤️", "😂", "😮", "🥹"]

    init(vm: AnswerReelVM, showsBackButton: Bool) {
        self.vm = vm
        self.showsBackButton = showsBackButton

        let uid = Auth.auth().currentUser?.uid ?? ""
        _reactions = StateObject(
            wrappedValue: ReactionsController(answer: vm.answer, currentUid: uid)
        )
    }

    var body: some View {
        ZStack {
            Color.clear
            LinearGradient(
                gradient: Gradient(colors: [
                    colorForCategory(vm.answer.category).opacity(0.95)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 16) {
                // Header (avatar + meta + share)
                HStack(alignment: .center, spacing: 12) {
                    AvatarView(photoURL: vm.answer.photoURL, avatarKey: nil, size: 36)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(vm.answer.name.isEmpty ? "Friend" : vm.answer.name)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)

                        VStack(alignment: .leading, spacing: 4) {
                            if let c = vm.answer.category, !c.isEmpty {
                                Text(c)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.9))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(.white.opacity(0.18)))
                            }

                            Text(vm.answer.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.75))
                        }
                    }

                    Spacer()

                    Button {
                        captureAndShare()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(Circle().fill(.white.opacity(0.15)))
                    }
                    .accessibilityLabel("Share")
                }

                // Question
                VStack(alignment: .leading, spacing: 8) {
                    Text("Question")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white.opacity(0.9))
                    Text(vm.answer.promptText)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(.white.opacity(0.08))
                        )
                }

                // Answer
                VStack(alignment: .leading, spacing: 8) {
                    Text("Answer")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white.opacity(0.9))

                    VStack {
                        Text(vm.answer.text)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .padding(12)

                        Spacer()
                    }
                    .frame(maxHeight: 280, alignment: .top)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(.white.opacity(0.06))
                    )
                }

                // MARK: - Reactions row + Comments button
                HStack(spacing: 8) {
                    // Emoji reactions to the LEFT
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

                    // Existing Comments button on the RIGHT
                    Button {
                        showComments = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "text.bubble")
//                            Text("Comments")
                        }
                        .font(.subheadline.weight(.semibold))
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
            .padding(.horizontal, 32)
            .padding(.top, 32)
            .padding(.bottom, 26)
        }
        .sheet(item: $shareItem) { item in
            ShareSheet(activityItems: [item.image]) {
                shareItem = nil
            }
        }
        .sheet(isPresented: $showComments) {
            CommentsView(answer: vm.answer)
        }
        .onAppear { reactions.start() }
        .onDisappear { reactions.stop() }
    }

    private func captureAndShare() {
        Task { @MainActor in
            let screen = UIScreen.main.bounds.size
            let card = AnswerShareCard(vm: vm)
            if let image = await card.snapshotImageAsync(size: screen, forceDark: false) {
                shareItem = ShareItem(image: image)
            }
        }
    }
}


private struct AnswerShareCard: View {
    let vm: AnswerReelVM

    var body: some View {
        ZStack {
            // Full-bleed category background
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
                // HEADER (static avatar, no network)
                HStack(alignment: .center, spacing: 12) {
                    ZStack {
                        Circle().fill(.white.opacity(0.18))

                        // Use first letter of name as a nice, deterministic avatar
                        Text(String((vm.answer.name.first ?? "F")))
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 36, height: 36)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(vm.answer.name.isEmpty ? "Friend" : vm.answer.name)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)

                        VStack(alignment: .leading, spacing: 4) {
                            if let c = vm.answer.category, !c.isEmpty {
                                Text(c)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.9))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(.white.opacity(0.18))
                                    )
                            }

                            Text(vm.answer.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.75))
                        }
                    }

                    Spacer()
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
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(.white.opacity(0.08))
                        )
                }

                // ANSWER
                VStack(alignment: .leading, spacing: 8) {
                    Text("Answer")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white.opacity(0.9))

                    Text(vm.answer.text)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(.white.opacity(0.06))
                        )
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 26)
        }
    }
}



// MARK: - ReceivedAnswersView root

struct ReceivedAnswersView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm: ReceivedAnswersController
    let showsBackButton: Bool

    init(showsBackButton: Bool = false) {
        _vm = StateObject(wrappedValue: ReceivedAnswersController())
        self.showsBackButton = showsBackButton
    }

    var body: some View {
        ZStack {
            if vm.items.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "text.bubble.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No shared answers yet")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white)
            } else {
                VerticalPager(index: $vm.currentIndex, count: vm.items.count) { i in
                    AnswerReelCard(vm: vm.items[i], showsBackButton: showsBackButton)
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
