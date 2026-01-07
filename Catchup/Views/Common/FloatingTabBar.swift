//
//  FloatingTabBar.swift
//  Catchup
//
//  Created by Nick Jitjang on 10/29/25.
//

import SwiftUI

struct FloatingTabBar: View {
    @EnvironmentObject var router: TabRouter
    let onInboxTap: (() -> Void)?

    init(onInboxTap: (() -> Void)? = nil) {
        self.onInboxTap = onInboxTap
    }

    var body: some View {
        HStack(spacing: 28) {
            TabIcon(systemName: "greetingcard.fill", tab: .home, onInboxTap: nil)
            TabIcon(systemName: "paperplane.fill", tab: .outbox, onInboxTap: nil)
            TabIcon(systemName: "text.bubble.fill", tab: .inbox, onInboxTap: onInboxTap)
            TabIcon(systemName: "person.fill", tab: .profile, onInboxTap: nil)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(
            Capsule().fill(.ultraThickMaterial)
                .shadow(color: .black.opacity(0.08), radius: 10, y: 6)
        )
        .padding(.horizontal, 24)
    }
}

private struct TabIcon: View {
    @EnvironmentObject var router: TabRouter
    let systemName: String
    let tab: AppTab
    let onInboxTap: (() -> Void)?   // only used for .inbox

    var body: some View {
        Button {
            if tab == .inbox, let onInboxTap {
                // Push ReceivedAnswersView via the HomeView’s NavigationStack
                onInboxTap()
            } else {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                    router.selected = tab
                }
            }
        } label: {
            Image(systemName: systemName)
                .imageScale(.large)
                .foregroundStyle(router.selected == tab ? Color.accentColor : Color.secondary)
                .padding(10)
                .background(
                    Circle().fill(router.selected == tab ? Color.accentColor.opacity(0.12) : .clear)
                )
        }
        .buttonStyle(.plain)
    }
}
