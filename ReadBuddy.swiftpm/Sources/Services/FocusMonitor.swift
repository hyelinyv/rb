import Foundation
import CoreGraphics
import UIKit

@MainActor
final class FocusMonitor: ObservableObject {
    enum WarningLevel {
        case none
        case gentle
        case strong
    }

    @Published private(set) var focusedParagraphID: String?
    @Published private(set) var warningLevel: WarningLevel = .none
    @Published private(set) var driftSeconds: Double = 0

    var onDrift: (() -> Void)?
    var onReturn: (() -> Void)?

    private var driftStartedAt: TimeInterval?
    private var driftWasRecorded = false
    private var strongFeedbackSent = false

    func update(
        sample: GazeSample,
        paragraphFrames: [String: CGRect],
        viewportSize: CGSize
    ) {
        guard sample.isReliable, viewportSize.width > 0, viewportSize.height > 0 else { return }
        let point = CGPoint(
            x: sample.normalizedPoint.x * viewportSize.width,
            y: sample.normalizedPoint.y * viewportSize.height
        )
        let hit = paragraphFrames.first(where: { $0.value.insetBy(dx: -12, dy: -10).contains(point) })?.key

        if let hit {
            focusedParagraphID = hit
            if driftWasRecorded {
                onReturn?()
            }
            resetDrift()
            return
        }

        focusedParagraphID = nil
        if driftStartedAt == nil {
            driftStartedAt = sample.timestamp
        }
        driftSeconds = max(0, sample.timestamp - (driftStartedAt ?? sample.timestamp))

        if driftSeconds >= 8, !driftWasRecorded {
            driftWasRecorded = true
            warningLevel = .gentle
            onDrift?()
        }
        if driftSeconds >= 10 {
            warningLevel = .strong
            if !strongFeedbackSent {
                strongFeedbackSent = true
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
            }
        }
    }

    func reset() {
        focusedParagraphID = nil
        resetDrift()
    }

    private func resetDrift() {
        driftStartedAt = nil
        driftSeconds = 0
        warningLevel = .none
        driftWasRecorded = false
        strongFeedbackSent = false
    }
}
