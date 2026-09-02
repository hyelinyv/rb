import SwiftUI

struct RSVPView: View {
    let paragraph: ReadingParagraph
    let onFinished: () -> Void
    @Environment(\.dismiss) private var dismiss
    @StateObject private var engine = RSVPEngine()

    var body: some View {
        VStack(spacing: 28) {
            HStack {
                Button("关闭") { close() }
                Spacer()
                Text("RSVP 专注模式").font(.headline)
                Spacer()
                Text("\(engine.wordsPerMinute) 字/分")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(spacing: 14) {
                Rectangle().fill(Color.secondary.opacity(0.2)).frame(width: 1, height: 28)
                Text(engine.currentToken)
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .frame(minWidth: 100, minHeight: 88)
                    .contentTransition(.numericText())
                Rectangle().fill(Color.secondary.opacity(0.2)).frame(width: 1, height: 28)
            }

            ProgressView(value: engine.progress)
                .tint(.black)
                .frame(maxWidth: 560)

            HStack(spacing: 30) {
                Button { engine.step(-1) } label: {
                    Image(systemName: "backward.end.fill")
                }
                Button { engine.togglePlayback() } label: {
                    Image(systemName: engine.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 62))
                }
                Button { engine.step(1) } label: {
                    Image(systemName: "forward.end.fill")
                }
            }
            .font(.title2)
            .foregroundStyle(.black)

            VStack(spacing: 8) {
                Slider(
                    value: Binding(
                        get: { Double(engine.wordsPerMinute) },
                        set: { engine.wordsPerMinute = Int($0) }
                    ),
                    in: 150...500,
                    step: 25
                )
                HStack {
                    Text("慢 150")
                    Spacer()
                    Text("快 500")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: 520)

            Spacer()
            Text("完成后会回到原段落，你可以再次结合上下文阅读。")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(30)
        .background(ReadBuddyTheme.background.ignoresSafeArea())
        .onAppear { engine.load(text: paragraph.text) }
        .onDisappear { engine.pause() }
    }

    private func close() {
        engine.pause()
        onFinished()
        dismiss()
    }
}
