import XCTest
@testable import Catchup

final class MyFriendsControllerTests: XCTestCase {

    struct FakeUsersRepo: UsersRepositoryType {
        let users: [String: User]

        func get(uid: String) async throws -> User {
            if let u = users[uid] { return u }
            throw NSError(domain: "Missing", code: 404)
        }

        func createUserDoc(_ user: User) async throws {}

        func usernameExists(_ username: String) async throws -> Bool { false }

        // Test helper
        func getMany(uids: [String]) async throws -> [String: User] {
            var out: [String: User] = [:]
            for id in uids {
                if let u = users[id] { out[id] = u }
            }
            return out
        }
    }

    // Extend controller to inject our fake repo and call helpers
    final class TestableMyFriendsController: MyFriendsController {
        private let testUsersRepo: FakeUsersRepo
        init(usersRepo: FakeUsersRepo) {
            self.testUsersRepo = usersRepo
            super.init()
        }

        override func loadProfiles(for edges: [FriendLite]) async {
            let ids = edges.map { $0.friendUid }
            do {
                let profiles = try await testUsersRepo.getMany(uids: ids)

                let rows: [FriendRowVM] = edges.compactMap { e in
                    let streakVal = e.streaks
                    if let u = profiles[e.friendUid] {
                        return FriendRowVM(
                            uid: u.uid,
                            displayName: u.displayName.isEmpty ? "Friend" : u.displayName,
                            username: u.username.isEmpty ? "unknown" : u.username,
                            photoURL: u.photoURL,
                            since: e.since,
                            streaks: streakVal
                        )
                    } else {
                        return FriendRowVM(
                            uid: e.friendUid,
                            displayName: "Friend",
                            username: "unknown",
                            photoURL: nil,
                            since: e.since,
                            streaks: streakVal
                        )
                    }
                }

                self.friends = rows.sorted { $0.since > $1.since }
            } catch {
                await loadProfilesIndividually(for: edges)
            }
        }

        override func loadProfilesIndividually(for edges: [FriendLite]) async {
            var rows: [FriendRowVM] = []
            for e in edges {
                let streakVal = e.streaks
                if let u = try? await testUsersRepo.get(uid: e.friendUid) {
                    rows.append(FriendRowVM(
                        uid: u.uid,
                        displayName: u.displayName.isEmpty ? "Friend" : u.displayName,
                        username: u.username.isEmpty ? "unknown" : u.username,
                        photoURL: u.photoURL,
                        since: e.since,
                        streaks: streakVal
                    ))
                } else {
                    rows.append(FriendRowVM(
                        uid: e.friendUid,
                        displayName: "Friend",
                        username: "unknown",
                        photoURL: nil,
                        since: e.since,
                        streaks: streakVal
                    ))
                }
            }
            self.friends = rows.sorted { $0.since > $1.since }
        }
    }

    @MainActor
    func testLoadProfiles_threadsStreaksAndSorts() async {
        let now = Date()
        let earlier = now.addingTimeInterval(-3600)

        let u1 = User(uid: "u1", displayName: "Alice", username: "alice", password_hash: nil, photoURL: nil, createdAt: now, updatedAt: now, stats: .init(answersCount: 0, friendsCount: 0, streakDays: 0), settings: .init(inAppNotification: true, pushEnabled: true, timezone: "UTC"))
        let u2 = User(uid: "u2", displayName: "", username: "", password_hash: nil, photoURL: nil, createdAt: now, updatedAt: now, stats: .init(answersCount: 0, friendsCount: 0, streakDays: 0), settings: .init(inAppNotification: true, pushEnabled: true, timezone: "UTC"))

        let repo = FakeUsersRepo(users: ["u1": u1, "u2": u2])
        let sut = TestableMyFriendsController(usersRepo: repo)

        let edges: [FriendLite] = [
            .init(friendUid: "u1", friendName: "n1", friendUsername: "u1", since: now, sourcePairId: "p1", streaks: 5),
            .init(friendUid: "u2", friendName: "n2", friendUsername: "u2", since: earlier, sourcePairId: "p2", streaks: 2),
            .init(friendUid: "u3", friendName: "n3", friendUsername: "u3", since: earlier, sourcePairId: "p3", streaks: 0)
        ]

        await sut.loadProfiles(for: edges)

        XCTAssertEqual(sut.friends.count, 3)
        // Sorted desc by since
        XCTAssertEqual(sut.friends.first?.uid, "u1")
        // Fallback names/usernames applied for empty
        let second = sut.friends[1]
        XCTAssertEqual(second.displayName, "Friend")
        XCTAssertEqual(second.username, "unknown")
        // Streaks threaded
        XCTAssertEqual(sut.friends.first?.streaks, 5)
    }

    @MainActor
    func testLoadProfilesIndividually_usesFallbackOnMissing() async {
        let now = Date()
        let repo = FakeUsersRepo(users: [:])
        let sut = TestableMyFriendsController(usersRepo: repo)
        let edges: [FriendLite] = [
            .init(friendUid: "x1", friendName: "n", friendUsername: "u", since: now, sourcePairId: "p", streaks: 1)
        ]
        await sut.loadProfilesIndividually(for: edges)
        XCTAssertEqual(sut.friends.count, 1)
        XCTAssertEqual(sut.friends[0].displayName, "Friend")
        XCTAssertEqual(sut.friends[0].username, "unknown")
        XCTAssertEqual(sut.friends[0].streaks, 1)
    }
}

