import Foundation
import SwiftData

@Model
final class ReadingProgressRecord {
    @Attribute(.unique) var bookID: String
    var currentParagraphIndex: Int
    var completedParagraphCount: Int
    var totalReadingSeconds: Double
    var driftCount: Int
    var returnCount: Int
    var rsvpCount: Int
    var lastReadAt: Date

    init(bookID: String) {
        self.bookID = bookID
        self.currentParagraphIndex = 0
        self.completedParagraphCount = 0
        self.totalReadingSeconds = 0
        self.driftCount = 0
        self.returnCount = 0
        self.rsvpCount = 0
        self.lastReadAt = .now
    }
}

@Model
final class ReadingSessionRecord {
    var id: UUID
    var bookID: String
    var startedAt: Date
    var endedAt: Date
    var focusedSeconds: Double
    var driftCount: Int
    var returnCount: Int

    init(
        bookID: String,
        startedAt: Date,
        endedAt: Date,
        focusedSeconds: Double,
        driftCount: Int,
        returnCount: Int
    ) {
        self.id = UUID()
        self.bookID = bookID
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.focusedSeconds = focusedSeconds
        self.driftCount = driftCount
        self.returnCount = returnCount
    }
}
