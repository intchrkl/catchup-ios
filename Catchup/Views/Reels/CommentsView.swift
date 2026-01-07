//
//  CommentsView.swift
//  Catchup
//
//  Created by Eric Lin on 11/19/25.
//

import SwiftUI

struct CommentsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm: CommentsController

    // Creates its own controller from an AnswerDoc
    init(answer: AnswerDoc) {
        _vm = StateObject(wrappedValue: CommentsController(answer: answer))
    }

    // Reuse an existing controller (for live count, etc.)
    init(controller: CommentsController) {
        _vm = StateObject(wrappedValue: controller)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 18, weight: .semibold))
                        .padding(8)
                }

                Text("Comments")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 8)

            Divider()

            // Comments list
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(vm.comments) { comment in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(comment.authorName)
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                Text(comment.createdAt, style: .time)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Text(comment.text)
                                .font(.body)
                        }
                        .padding(.horizontal)
                        .padding(.top, 6)
                    }
                }
                .padding(.top, 4)
            }

            // Input bar
            Divider()

            HStack(alignment: .center, spacing: 8) {
                TextField("Add a comment…", text: $vm.newText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...3)

                Button {
                    Task { await vm.sendComment() }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 24))
                }
                .disabled(vm.newText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
        }
        .onAppear { vm.start() }
        .onDisappear { vm.stop() }
    }
}
