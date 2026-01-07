// Controller/QuestionFlowController.swift
import Foundation
import FirebaseAuth
import Combine

// MARK: - Protocols for DI

protocol AnswersRepositoryType {
    func createAnswer(
        promptText: String,
        category: String?,
        author: User,
        text: String,
        recipients: [String]
    ) async throws -> String
}

protocol NotificationsRepositoryType {
    func notifyAnswerShared(from author: User, to recipientUid: String, answerId: String) async throws
}

protocol FriendsRepositoryType {
    func pairId(_ a: String, _ b: String) -> String
}

@MainActor
final class QuestionFlowController: ObservableObject {
    // UI state
    @Published var isLoading = false
    @Published var error: String?
    @Published var selectedCategory: QuestionCategory?
    @Published var questionText: String = ""
    @Published var answerDraft: String = ""
    @Published var selectedRecipientUids: Set<String> = []

    // Services / repos
    private let promptService: PromptServiceType
    private let usersRepo: UsersRepositoryType
    private let answersRepo: AnswersRepositoryType
    private let notifsRepo: NotificationsRepositoryType
    private let friendsRepo: FriendsRepositoryType
    private let currentUserIdProvider: () -> String

    // Default initializer for app use
    init(
        promptService: PromptServiceType = FirestorePromptService(),
        usersRepo: UsersRepositoryType = UsersRepository(),
        answersRepo: AnswersRepositoryType = AnswersRepository(),
        notifsRepo: NotificationsRepositoryType = NotificationsRepository(),
        friendsRepo: FriendsRepositoryType = FriendsRepository(),
        currentUserIdProvider: @escaping () -> String = { Auth.auth().currentUser?.uid ?? "" }
    ) {
        self.promptService = promptService
        self.usersRepo = usersRepo
        self.answersRepo = answersRepo
        self.notifsRepo = notifsRepo
        self.friendsRepo = friendsRepo
        self.currentUserIdProvider = currentUserIdProvider
    }

    private var uid: String { currentUserIdProvider() }

    // Generate a question for the chosen category
    func loadQuestion(for category: QuestionCategory) async {
        isLoading = true; error = nil
        selectedCategory = category
        do {
            let q = try await promptService.generateQuestion(for: category)
            questionText = q
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
    
    func loadNewPrompt() async {
        guard let category = selectedCategory else { return }
        do {
            let q = try await promptService.generateQuestion(for: category)
            await MainActor.run {
                self.questionText = q
            }
        } catch {
            print("Failed to load new prompt: \(error)")
        }
    }


    // Save the answer, then notify selected friends
    func submitAnswer() async {
        guard !uid.isEmpty else { error = "Not signed in"; return }
        guard !questionText.isEmpty else { error = "No question"; return }

        isLoading = true; defer { isLoading = false }

        do {
            let me = try await usersRepo.get(uid: uid)
            let categoryRaw = selectedCategory?.rawValue

            // 1) Save the answer
            let answerId = try await answersRepo.createAnswer(
                promptText: questionText,
                category: categoryRaw,
                author: me,
                text: answerDraft,
                recipients: Array(selectedRecipientUids)
            )

            // 2) Notify each friend
            for rid in selectedRecipientUids {
                try await notifsRepo.notifyAnswerShared(from: me, to: rid, answerId: answerId)
            }

            // 3) Update APP-WIDE STREAK
            try await StreakService.shared.updateUserStreak(
                uid: uid,
                timezoneId: me.settings.timezone
            )

            // 4) Update FRIEND STREAKS
            try await StreakService.shared.updateFriendStreaksForUser(
                uid: uid,
                recipients: Array(selectedRecipientUids),
                timezoneId: me.settings.timezone
            )

            // 5) Cancel tonight’s streak reminder (already in your code)
            LocalPushCoordinator.shared.cancelTonightsStreakReminder()

            // 6) Clean up UI state
            answerDraft = ""
            selectedRecipientUids.removeAll()

        } catch {
            self.error = error.localizedDescription
        }
    }

    
    var categoryDisplayName: String {
        selectedCategory?.rawValue ?? ""
    }
}

