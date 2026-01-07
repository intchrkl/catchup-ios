//
//  QuestionFlowControllerTests.swift
//  Catchup
//
//  Created by Eric Lin on 12/3/25.
//

import XCTest
@testable import Catchup

final class QuestionFlowControllerTests: XCTestCase {

    struct ThrowingPromptService: PromptServiceType {
        struct DummyError: Error {}
        func generateQuestion(for category: QuestionCategory) async throws -> String {
            throw DummyError()
        }
    }

    final class SequencedPromptService: PromptServiceType {
        var outputs: [String]
        init(outputs: [String]) { self.outputs = outputs }
        func generateQuestion(for category: QuestionCategory) async throws -> String {
            if outputs.isEmpty { return "default" }
            return outputs.removeFirst()
        }
    }

    actor MockUsersRepo: UsersRepositoryType {
        var user: User = .init(
            uid: "u1",
            displayName: "Nick",
            username: "nick",
            password_hash: nil,
            photoURL: nil,
            createdAt: Date(),
            updatedAt: Date(),
            stats: .init(answersCount: 0, friendsCount: 0, streakDays: 0),
            settings: .init(inAppNotification: true, pushEnabled: true, timezone: TimeZone.current.identifier)
        )

        func get(uid: String) async throws -> User { user }
        func createUserDoc(_ user: User) async throws {}
        func usernameExists(_ username: String) async throws -> Bool { false }
    }

    struct NoopAnswersRepo: AnswersRepositoryType {
        func createAnswer(
            promptText: String,
            category: String?,
            author: User,
            text: String,
            recipients: [String]
        ) async throws -> String { "aid" }
    }

    struct NoopNotificationsRepo: NotificationsRepositoryType {
        func notifyAnswerShared(from author: User, to recipientUid: String, answerId: String) async throws {}
    }

    struct NoopFriendsRepo: FriendsRepositoryType {
        func pairId(_ a: String, _ b: String) -> String { [a, b].sorted().joined(separator: "__") }
    }

    @MainActor
    func testLoadQuestion_success_setsTextAndCategory() async throws {
        let prompt = SequencedPromptService(outputs: ["What is your goal?"])
        let sut = QuestionFlowController(
            promptService: prompt,
            usersRepo: MockUsersRepo(),
            answersRepo: NoopAnswersRepo(),
            notifsRepo: NoopNotificationsRepo(),
            friendsRepo: NoopFriendsRepo(),
            currentUserIdProvider: { "u1" }
        )

        await sut.loadQuestion(for: .goals)

        XCTAssertEqual(sut.selectedCategory, .goals)
        XCTAssertEqual(sut.questionText, "What is your goal?")
        XCTAssertFalse(sut.isLoading)
    }

    @MainActor
    func testLoadQuestion_failure_setsError() async {
        let sut = QuestionFlowController(
            promptService: ThrowingPromptService(),
            usersRepo: MockUsersRepo(),
            answersRepo: NoopAnswersRepo(),
            notifsRepo: NoopNotificationsRepo(),
            friendsRepo: NoopFriendsRepo(),
            currentUserIdProvider: { "u1" }
        )

        await sut.loadQuestion(for: .gratitude)
        XCTAssertNotNil(sut.error)
        XCTAssertFalse(sut.isLoading)
    }

    @MainActor
    func testLoadNewPrompt_replacesQuestionText() async throws {
        let prompt = SequencedPromptService(outputs: ["Q1", "Q2"])
        let sut = QuestionFlowController(
            promptService: prompt,
            usersRepo: MockUsersRepo(),
            answersRepo: NoopAnswersRepo(),
            notifsRepo: NoopNotificationsRepo(),
            friendsRepo: NoopFriendsRepo(),
            currentUserIdProvider: { "u1" }
        )

        await sut.loadQuestion(for: .memories)
        let first = sut.questionText
        await sut.loadNewPrompt()
        let second = sut.questionText

        XCTAssertEqual(first, "Q1")
        XCTAssertEqual(second, "Q2")
    }

    // New tests

    struct CapturingAnswersRepo: AnswersRepositoryType {
        var onCreate: ((String, String?, User, String, [String]) -> Void)?
        func createAnswer(promptText: String, category: String?, author: User, text: String, recipients: [String]) async throws -> String {
            onCreate?(promptText, category, author, text, recipients)
            return "aid-123"
        }
    }

    final class CapturingNotifsRepo: NotificationsRepositoryType {
        var calls: [(from: String, to: String, answerId: String)] = []
        func notifyAnswerShared(from author: User, to recipientUid: String, answerId: String) async throws {
            calls.append((from: author.uid, to: recipientUid, answerId: answerId))
        }
    }

    @MainActor
    func testSubmitAnswer_success_flow() async throws {
        var captured: (String, String?, User, String, [String])?
        let answers = CapturingAnswersRepo(onCreate: { p, c, a, t, r in
            captured = (p, c, a, t, r)
        })
        let notifs = CapturingNotifsRepo()

        let users = MockUsersRepo()
        let me = try await users.get(uid: "u1")

        let sut = QuestionFlowController(
            promptService: MockPromptService(),
            usersRepo: users,
            answersRepo: answers,
            notifsRepo: notifs,
            friendsRepo: NoopFriendsRepo(),
            currentUserIdProvider: { "u1" }
        )

        sut.selectedCategory = .goals
        sut.questionText = "Q?"
        sut.answerDraft = "My answer"
        sut.selectedRecipientUids = ["f1", "f2"]

        await sut.submitAnswer()

        XCTAssertEqual(captured?.0, "Q?")
        XCTAssertEqual(captured?.1, QuestionCategory.goals.rawValue)
        XCTAssertEqual(captured?.2.uid, me.uid)
        XCTAssertEqual(captured?.3, "My answer")
        XCTAssertEqual(Set(captured?.4 ?? []), Set(["f1", "f2"]))

        XCTAssertEqual(notifs.calls.count, 2)
        XCTAssertTrue(notifs.calls.contains(where: { $0.to == "f1" }))
        XCTAssertTrue(notifs.calls.contains(where: { $0.to == "f2" }))

        XCTAssertFalse(sut.isLoading)
    }

    @MainActor
    func testSubmitAnswer_earlyExit_notSignedIn() async {
        let sut = QuestionFlowController(
            promptService: MockPromptService(),
            usersRepo: MockUsersRepo(),
            answersRepo: NoopAnswersRepo(),
            notifsRepo: NoopNotificationsRepo(),
            friendsRepo: NoopFriendsRepo(),
            currentUserIdProvider: { "" } // not signed in
        )
        sut.questionText = "Q?"
        await sut.submitAnswer()
        XCTAssertEqual(sut.error, "Not signed in")
    }

    @MainActor
    func testSubmitAnswer_earlyExit_noQuestion() async {
        let sut = QuestionFlowController(
            promptService: MockPromptService(),
            usersRepo: MockUsersRepo(),
            answersRepo: NoopAnswersRepo(),
            notifsRepo: NoopNotificationsRepo(),
            friendsRepo: NoopFriendsRepo(),
            currentUserIdProvider: { "u1" }
        )
        sut.questionText = ""
        await sut.submitAnswer()
        XCTAssertEqual(sut.error, "No question")
    }
}

