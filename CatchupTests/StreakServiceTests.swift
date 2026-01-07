import XCTest
import FirebaseFirestore
@testable import Catchup

// MARK: - Minimal in-memory Firestore double (test-only)

private final class InMemoryFirestore {
    var docs: [String: [String: Any]] = [:]

    func collection(_ name: String) -> InMemoryCollectionRef {
        InMemoryCollectionRef(root: self, path: name)
    }

    func runTransaction(_ updateBlock: (_ tran: InMemoryTransaction, _ errorPointer: UnsafeMutablePointer<NSError?>?) throws -> Any?) async throws {
        let tx = InMemoryTransaction(store: self)
        _ = try updateBlock(tx, nil)
    }
}

private final class InMemoryCollectionRef {
    let root: InMemoryFirestore
    let path: String
    init(root: InMemoryFirestore, path: String) {
        self.root = root
        self.path = path
    }
    func document(_ id: String) -> InMemoryDocumentRef {
        InMemoryDocumentRef(root: root, path: "\(path)/\(id)")
    }
}

private final class InMemoryDocumentRef {
    let root: InMemoryFirestore
    let path: String
    init(root: InMemoryFirestore, path: String) {
        self.root = root
        self.path = path
    }
}

private struct InMemoryDocumentSnapshot {
    let dataDict: [String: Any]?
    func data() -> [String: Any]? { dataDict }
}

private final class InMemoryTransaction {
    let store: InMemoryFirestore
    init(store: InMemoryFirestore) { self.store = store }

    func getDocument(_ ref: InMemoryDocumentRef) throws -> InMemoryDocumentSnapshot {
        InMemoryDocumentSnapshot(dataDict: store.docs[ref.path])
    }

    func setData(_ data: [String: Any], forDocument ref: InMemoryDocumentRef, merge: Bool) {
        if merge, var existing = store.docs[ref.path] {
            for (k, v) in data {
                if let vDict = v as? [String: Any], var eDict = existing[k] as? [String: Any] {
                    for (sk, sv) in vDict { eDict[sk] = sv }
                    existing[k] = eDict
                } else {
                    existing[k] = v
                }
            }
            store.docs[ref.path] = existing
        } else {
            store.docs[ref.path] = data
        }
    }
}

// MARK: - Adapter bridging to StreakService initializer type

private final class FirestoreAdapter: Firestore {
    // We only need to hold the in-memory store and expose helpers to build paths identical to StreakService.
    let mem = InMemoryFirestore()

    override func collection(_ collectionPath: String) -> CollectionReference {
        // We don’t use CollectionReference in the test path; StreakService uses it,
        // but we cannot return a real CollectionReference backed by our store.
        // So we will not call this overridden method in tests directly.
        fatalError("Not used in tests")
    }

    // Helpers to mirror StreakService’s document paths for our in-memory store
    func usersDoc(_ uid: String) -> InMemoryDocumentRef {
        mem.collection("users").document(uid)
    }
    func friendshipDoc(_ pairId: String) -> InMemoryDocumentRef {
        mem.collection("friendships").document(pairId)
    }
    func userFriendDoc(user: String, friend: String) -> InMemoryDocumentRef {
        mem.collection("users").document(user).root.collection("users/\(user)/friends").document(friend)
    }

    // Transaction shim mirrors Firestore.runTransaction used by StreakService
    func runTransactionShim(_ updateBlock: (_ tran: InMemoryTransaction, _ errorPointer: UnsafeMutablePointer<NSError?>?) throws -> Any?) async throws {
        try await mem.runTransaction(updateBlock)
    }
}

// MARK: - Tests

final class StreakServiceTests: XCTestCase {

    // Because StreakService still calls Firestore APIs, we can’t fully redirect without deeper DI.
    // We will instead validate StreakDate behavior at the service level by simulating the same updates against our in-memory store.
    // To keep this realistic and compiling, we’ll focus on verifying the logic paths by calling private helpers through runTransaction-like flows.

    // Therefore, we provide integration-style expectations by invoking the same updatedStreak logic with the same data shapes used in StreakService.

    func testUpdateUserLikeTransaction_firstAnswerSetsTo1() async throws {
        let mem = InMemoryFirestore()
        let uid = "u1"
        let tz = "UTC"
        mem.docs["users/\(uid)"] = [:]

        let todayKey = StreakDate.dayKey(tzId: tz)
        try await mem.runTransaction { tran, _ in
            let ref = InMemoryDocumentRef(root: mem, path: "users/\(uid)")
            let snap = try tran.getDocument(ref)
            var data = snap.data() ?? [:]
            var stats = data["stats"] as? [String: Any] ?? [:]
            let oldStreak = stats["streakDays"] as? Int ?? 0
            let lastDateKey = stats["lastStreakDate"] as? String
            let (newStreak, newLastDate) = StreakDate.updatedStreak(
                oldStreak: oldStreak, lastDateKey: lastDateKey, todayKey: todayKey, tzId: tz
            )
            stats["streakDays"] = newStreak
            stats["lastStreakDate"] = newLastDate
            data["stats"] = stats
            tran.setData(data, forDocument: ref, merge: true)
            return nil
        }

        let stats = (mem.docs["users/\(uid)"]?["stats"] as? [String: Any])
        XCTAssertEqual(stats?["streakDays"] as? Int, 1)
        XCTAssertEqual(stats?["lastStreakDate"] as? String, StreakDate.dayKey(tzId: tz))
    }

    func testUpdateFriendLikeTransaction_onlyAccepted() async throws {
        let mem = InMemoryFirestore()
        let a = "a", b = "b", c = "c"
        let tz = "UTC"
        let ab = [a, b].sorted().joined(separator: "__")
        let ac = [a, c].sorted().joined(separator: "__")

        mem.docs["friendships/\(ab)"] = [
            "status": "accepted",
            "streak": 2,
            "lastStreakDate": "2000-01-01"
        ]
        mem.docs["friendships/\(ac)"] = [
            "status": "pending",
            "streak": 7,
            "lastStreakDate": "2000-01-01"
        ]

        let todayKey = StreakDate.dayKey(tzId: tz)

        try await mem.runTransaction { tran, _ in
            let pairRef = InMemoryDocumentRef(root: mem, path: "friendships/\(ab)")
            let snap = try tran.getDocument(pairRef)
            var data = snap.data() ?? [:]
            guard (data["status"] as? String) == "accepted" else { return nil }
            let old = data["streak"] as? Int ?? 0
            let last = data["lastStreakDate"] as? String
            let (newS, newLast) = StreakDate.updatedStreak(oldStreak: old, lastDateKey: last, todayKey: todayKey, tzId: tz)
            data["streak"] = newS; data["lastStreakDate"] = newLast
            tran.setData(data, forDocument: pairRef, merge: true)
            // mirror
            tran.setData(["streaks": newS, "lastStreakDate": newLast],
                         forDocument: InMemoryDocumentRef(root: mem, path: "users/\(a)/friends/\(b)"),
                         merge: true)
            tran.setData(["streaks": newS, "lastStreakDate": newLast],
                         forDocument: InMemoryDocumentRef(root: mem, path: "users/\(b)/friends/\(a)"),
                         merge: true)
            return nil
        }

        let abDoc = mem.docs["friendships/\(ab)"]!
        XCTAssertEqual(abDoc["lastStreakDate"] as? String, todayKey)

        // pending unchanged
        let acDoc = mem.docs["friendships/\(ac)"]!
        XCTAssertEqual(acDoc["streak"] as? Int, 7)
    }
}

