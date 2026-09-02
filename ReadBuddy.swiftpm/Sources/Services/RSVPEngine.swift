import Foundation

@MainActor
final class RSVPEngine: ObservableObject {
    @Published private(set) var tokens: [String] = []
    @Published private(set) var currentIndex = 0
    @Published private(set) var isPlaying = false
    @Published var wordsPerMinute = 250

    private var playbackTask: Task<Void, Never>?

    var currentToken: String {
        guard tokens.indices.contains(currentIndex) else { return "准备" }
        return tokens[currentIndex]
    }

    var progress: Double {
        guard !tokens.isEmpty else { return 0 }
        return Double(currentIndex + 1) / Double(tokens.count)
    }

    func load(text: String) {
        stop()
        tokens = tokenize(text)
        currentIndex = 0
    }

    func togglePlayback() {
        isPlaying ? pause() : play()
    }

    func play() {
        guard !tokens.isEmpty, currentIndex < tokens.count else { return }
        isPlaying = true
        playbackTask?.cancel()
        playbackTask = Task { [weak self] in
            while let self, !Task.isCancelled, self.isPlaying {
                let delay = UInt64((60.0 / Double(max(self.wordsPerMinute, 1))) * 1_000_000_000)
                try? await Task.sleep(nanoseconds: delay)
                guard !Task.isCancelled else { return }
                if self.currentIndex < self.tokens.count - 1 {
                    self.currentIndex += 1
                } else {
                    self.isPlaying = false
                    return
                }
            }
        }
    }

    func pause() {
        isPlaying = false
        playbackTask?.cancel()
        playbackTask = nil
    }

    func stop() {
        pause()
        currentIndex = 0
    }

    func step(_ amount: Int) {
        pause()
        guard !tokens.isEmpty else { return }
        currentIndex = min(max(currentIndex + amount, 0), tokens.count - 1)
    }

    private func tokenize(_ text: String) -> [String] {
        text
            .filter { !$0.isWhitespace }
            .map(String.init)
    }
}
