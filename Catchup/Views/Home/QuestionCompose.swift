// View/Home/QuestionComposeView.swift
import SwiftUI
import FirebaseAuth
import UIKit   // for haptics

struct QuestionComposeView: View {
    @ObservedObject var flow: QuestionFlowController
    @State private var showFriends = false
    @State private var showCelebration = false

    @Environment(\.dismiss) private var dismiss

    // MARK: - CATEGORY COLOR
    private func colorForCategory(_ category: String?) -> Color {
        switch category?.lowercased() {
        case let c? where c.contains("self reflection"):
            return Color("CU.Orange")
        case let c? where c.contains("memories"):
            return Color("CU.indigo")
        case let c? where c.contains("relationships"):
            return Color("CU.Pink")
        case let c? where c.contains("would you rather"):
            return Color("CU.Green")
        case let c? where c.contains("goals"):
            return Color("CU.Red")
        case let c? where c.contains("gratitude"):
            return Color("CU.Yellow")
        default:
            return Color.gray.opacity(0.3)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // MARK: - QUESTION CATEGORY
                if !flow.categoryDisplayName.isEmpty {
                    Text(flow.categoryDisplayName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(colorForCategory(flow.categoryDisplayName))
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)
                }

                // MARK: - QUESTION CARD
                VStack(alignment: .leading, spacing: 10) {
                    Text("Question")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(flow.questionText)
                        .font(.title3.weight(.semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(colorForCategory(flow.categoryDisplayName).opacity(0.75))
                        )
                }
                
                // MARK: - SKIP BUTTON
                Button {
                    Task {
                        // soft haptic
                        let h = UIImpactFeedbackGenerator(style: .light)
                        h.impactOccurred()

                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            flow.isLoading = true
                        }

                        await flow.loadNewPrompt()
                        withAnimation(.easeOut(duration: 0.25)) {
                            flow.isLoading = false
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Skip")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(colorForCategory(flow.selectedCategory?.rawValue))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(colorForCategory(flow.selectedCategory?.rawValue).opacity(0.15))
                    )
                }
                .buttonStyle(.plain)

                // MARK: - ANSWER FIELD
                VStack(alignment: .leading, spacing: 10) {
                    Text("Your Answer")
                        .font(.subheadline.weight(.semibold))

                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.gray.opacity(0.10))

                        TextEditor(text: $flow.answerDraft)
                            .frame(minHeight: 140)
                            .padding(12)
                            .scrollContentBackground(.hidden)

                        if flow.answerDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text("Type your answer here…")
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 20)
                        }
                    }
                }

                // MARK: - FRIENDS PICKER
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Send to Friends")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Button {
                            showFriends = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "person.2.fill")
                                Text("Select")
                            }
                            .font(.subheadline.weight(.semibold))
                        }
                    }

                    if !flow.selectedRecipientUids.isEmpty {
                        Text("\(flow.selectedRecipientUids.count) selected")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // MARK: - SEND BUTTON
                Button {
                    Task {
                        await flow.submitAnswer()
                        // If no error, celebrate + dismiss
                        if flow.error == nil {
                            // haptic
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)

                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                showCelebration = true
                            }

                            // wait a bit so user sees the animation
                            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1s
                            dismiss()
                        }
                    }
                } label: {
                    Text("Send to your friends!")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(.borderedProminent)
                .tint(colorForCategory(flow.selectedCategory?.rawValue))   // match category color
                .controlSize(.large)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .disabled(
                    flow.answerDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                    flow.selectedRecipientUids.isEmpty ||
                    flow.isLoading
                )

                Spacer(minLength: 60) // space above floating tab bar
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 140) // extra so Send button is reachable
        }
        .navigationTitle("Share your thoughts!")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showFriends) {
            FriendMultiPickerSheet(selected: $flow.selectedRecipientUids)
        }
        .overlay {
            ZStack {
                // Existing loading overlay
                if flow.isLoading {
                    Color.black.opacity(0.12).ignoresSafeArea()
                    ProgressView().controlSize(.large)
                }

                // Celebration overlay
                if showCelebration {
                    CelebrationOverlay(color: colorForCategory(flow.selectedCategory?.rawValue))
                }
            }
        }
        .alert("Error", isPresented: .constant(flow.error != nil)) {
            Button("OK") { flow.error = nil }
        } message: {
            Text(flow.error ?? "")
        }
    }
}

// MARK: - Simple Confetti + "Sent!" Overlay

private struct CelebrationOverlay: View {
    let color: Color
    @State private var animate = false

    var body: some View {
        ZStack {
            // Dim background
            Color.black.opacity(0.35)
                .ignoresSafeArea()

            // Confetti dots
            ZStack {
                ForEach(0..<22, id: \.self) { i in
                    Circle()
                        .fill(i % 3 == 0 ? color : .white)
                        .frame(width: 8, height: 8)
                        .offset(
                            x: animate ? CGFloat.random(in: -140...140) : 0,
                            y: animate ? CGFloat.random(in: -260...40) : 0
                        )
                        .opacity(animate ? 0 : 1)
                        .animation(
                            .easeOut(duration: 0.9).delay(Double(i) * 0.02),
                            value: animate
                        )
                }
            }

            // Center "Sent" card
            VStack(spacing: 12) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(.white)

                Text("Sent!")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)

            }
            .padding(.horizontal, 28)
            .padding(.vertical, 22)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(color.opacity(0.95))
            )
            .shadow(radius: 16)
            .scaleEffect(animate ? 1.0 : 0.8)
            .opacity(animate ? 1.0 : 0.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: animate)
        }
        .onAppear {
            animate = true
        }
    }
}
