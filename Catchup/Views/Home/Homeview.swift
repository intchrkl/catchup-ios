//
//  HomeView.swift
//  Catchup
//
//  Created by Nick Jitjang on 10/29/25.
//

import SwiftUI
import FirebaseAuth

struct HomeView: View {
    // Existing feed controller
    @StateObject private var controller = HomeController()

    // New question flow controller
    @StateObject private var flow = QuestionFlowController()
    @State private var goCompose = false

    // Sheets
    @State private var showNotifications = false
    @State private var showAddFriend = false

    @State private var showReceived = false

    // Unread notifications
    @State private var hasUnreadNotifications = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // MARK: Feed section
                    Text("Feed")
                        .font(.title3.weight(.semibold))
                        .padding(.horizontal, 20)

                    HeroPager(answers: controller.heroAnswers, onOpenInbox: {
                        showReceived = true
                    })
                    .padding(.horizontal, 20)

                    // MARK: Send Questions to Friends
                    Text("Send Questions to Friends!")
                        .font(.title3.weight(.semibold))
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    // Category grid entry point -> generate question -> navigate to compose
                    CategoryGrid { category in
                        Task {
                            await flow.loadQuestion(for: category)
                            if !flow.questionText.isEmpty {
                                goCompose = true
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 16)
            }
            .navigationTitle("Catch Up")
            .navigationBarTitleDisplayMode(.inline)

            // Destinations (keep exactly one for each binding)
            .navigationDestination(isPresented: $goCompose) {
                QuestionComposeView(flow: flow)
            }
            .navigationDestination(isPresented: $showReceived) {
                ReceivedAnswersView(showsBackButton: true)
            }


            // Toolbar
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { showNotifications = true } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell")
                            if hasUnreadNotifications {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 6, y: -4)
                            }
                        }
                    }
                    Button { showAddFriend = true } label: {
                        Image(systemName: "person.badge.plus")
                    }
                }
            }

            // Sheets
            .sheet(isPresented: $showNotifications) {
                NotificationsView()
                    .onAppear { hasUnreadNotifications = false }
                    .presentationDetents([.medium, .large])
                    .background(
                        .ultraThinMaterial
                            .opacity(0.95)
                    )
            }
            .sheet(isPresented: $showAddFriend) {
                AddFriendView()
                    .presentationDetents([.large])
            }

            // Floating tab
            .safeAreaInset(edge: .bottom) {
                FloatingTabBar()
                    .padding(.bottom, 16)
            }

            // Loading overlay for the GPT question call
            .overlay {
                if flow.isLoading {
                    ProgressView().controlSize(.large)
                }
            }

            // Error surfaced from question flow
            .alert("Error", isPresented: .constant(flow.error != nil)) {
                Button("OK") { flow.error = nil }
            } message: {
                Text(flow.error ?? "")
            }

            // Start the unread stream
            .task {
                guard let uid = Auth.auth().currentUser?.uid else { return }
                let repo = NotificationsRepository()
                do {
                    for try await list in repo.unreadInbox(for: uid) {
                        hasUnreadNotifications = !list.isEmpty
                    }
                } catch {
                    print("unread notifications stream error: \(error.localizedDescription)")
                }
            }
        }
    }
}
