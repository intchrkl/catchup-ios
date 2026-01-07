import XCTest
import FirebaseFirestore
@testable import Catchup

final class UserMapperTests: XCTestCase {

    func testDictFromUser_mapsAllFields() {
        let now = Date()
        let user = User(
            uid: "u1",
            displayName: "Nick",
            username: "nick",
            password_hash: nil,
            photoURL: "http://example.com/p.png",
            createdAt: now,
            updatedAt: now,
            stats: .init(answersCount: 1, friendsCount: 2, streakDays: 3),
            settings: .init(inAppNotification: true, pushEnabled: false, timezone: "UTC")
        )

        let dict = UserMapper.dict(from: user)
        XCTAssertEqual(dict["uid"] as? String, "u1")
        XCTAssertEqual(dict["displayName"] as? String, "Nick")
        XCTAssertEqual(dict["username"] as? String, "nick")
        XCTAssertNil(dict["password_hash"] as? String)
        XCTAssertEqual(dict["photoURL"] as? String, "http://example.com/p.png")

        let stats = dict["stats"] as? [String: Any]
        XCTAssertEqual(stats?["answersCount"] as? Int, 1)
        XCTAssertEqual(stats?["friendsCount"] as? Int, 2)
        XCTAssertEqual(stats?["streakDays"] as? Int, 3)

        let settings = dict["settings"] as? [String: Any]
        XCTAssertEqual(settings?["inAppNotification"] as? Bool, true)
        XCTAssertEqual(settings?["pushEnabled"] as? Bool, false)
        XCTAssertEqual(settings?["timezone"] as? String, "UTC")

        XCTAssertNotNil(dict["createdAt"])
        XCTAssertNotNil(dict["updatedAt"])
    }

    func testUserFromDict_defaultsMissingFields() throws {
        let now = Timestamp(date: Date())
        let data: [String: Any] = [
            "displayName": "A",
            "username": "a",
            "createdAt": now,
            "updatedAt": now,
            "stats": ["answersCount": 0, "friendsCount": 0, "streakDays": 0],
            "settings": ["inAppNotification": true, "pushEnabled": true, "timezone": "UTC"]
        ]

        let u = try UserMapper.user(from: data, uid: "uid123")
        XCTAssertEqual(u.uid, "uid123")
        XCTAssertEqual(u.displayName, "A")
        XCTAssertEqual(u.username, "a")
        XCTAssertNil(u.password_hash)
        XCTAssertNil(u.photoURL)
        XCTAssertEqual(u.stats.answersCount, 0)
        XCTAssertEqual(u.settings.timezone, "UTC")
    }
}

