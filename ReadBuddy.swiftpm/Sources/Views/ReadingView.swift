import SwiftUI
import SwiftData

private struct ParagraphFramePreferenceKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

struct ReadingView: View {
    @EnvironmentObject private var gaze: GazeTrackingCoordinator
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Query private var progressRecords: [ReadingProgressRecord]

    @StateObject private var focusMonitor = FocusMonitor()
    @State private var paragraphFrames: [String: CGRect] = [:]
    @State private var viewportSize: CGSize = .zero
    @State private var selectedParagraph: ReadingParagraph?
    @State private var companionMessage: CompanionMessage?
    @State private var showDebugGaze = true
    @State private var sessionStartedAt = Date.now
    @State private var sessionDrifts = 0
    @State private var sessionReturns = 0
    @State private var automaticRSVPParagraph: ReadingParagraph?

    private let book = SampleLibrary.book
    private let companion = LocalCompanionProvider()

    private var chapter: Chapter { book.chapters[0] }
    private var progress: ReadingProgressRecord? {
        progressRecords.first(where: { $0.bookID == book.id })
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                ReadBuddyTheme.background.ignoresSafeArea()
                readingLayout
                    .coordinateSpace(name: "readingViewport")
                    .onPreferenceChange(ParagraphFramePreferenceKey.self) { frames in
                        paragraphFrames = frames
                    }

                if showDebugGaze, gaze.sample.isReliable {
                    Circle()
                        .fill(gaze.isUsingSimulation ? Color.orange : ReadBuddyTheme.glow)
                        .frame(width: 18, height: 18)
                        .overlay(Circle().stroke(.black, lineWidth: 1))
                        .position(
                            x: gaze.sample.normalizedPoint.x * geometry.size.width,
                            y: gaze.sample.normalizedPoint.y * geometry.size.height
                        )
                        .allowsHitTesting(false)
                }
            }
            .onAppear { viewportSize = geometry.size }
            .onChange(of: geometry.size) { _, newSize in viewportSize = newSize }
            .onReceive(gaze.$sample) { sample in
                focusMonitor.update(
                    sample: sample,
                    paragraphFrames: paragraphFrames,
                    viewportSize: viewportSize
                )
                updateProgressFromFocus()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text(chapter.title).font(.headline)
                    Text(gaze.status.label).font(.caption2).foregroundStyle(.secondary)
                }
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    showDebugGaze.toggle()
                } label: {
                    Image(systemName: showDebugGaze ? "eye.fill" : "eye.slash")
                }
                if gaze.isUsingSimulation {
                    Button {
                        gaze.toggleSimulatedDrift()
                    } label: {
                        Image(systemName: "waveform.path.ecg")
                    }
                    .accessibilityLabel("切换模拟走神")
                }
            }
        }
        .onAppear {
            ensureProgress()
            sessionStartedAt = .now
            configureFocusCallbacks()
            gaze.start()
        }
        .onDisappear {
            saveSession()
            gaze.stop()
        }
        .sheet(item: $selectedParagraph) { paragraph in
            RSVPView(paragraph: paragraph) {
                progress?.rsvpCount += 1
                progress?.lastReadAt = .now
                try? modelContext.save()
            }
        }
        .sheet(item: $companionMessage) { message in
            CompanionSheet(message: message)
        }
        .alert(
            "试试逐字阅读？",
            isPresented: Binding(
                get: { automaticRSVPParagraph != nil },
                set: { if !$0 { automaticRSVPParagraph = nil } }
            ),
            presenting: automaticRSVPParagraph
        ) { paragraph in
            Button("开始 RSVP") {
                automaticRSVPParagraph = nil
                selectedParagraph = paragraph
            }
            Button("继续原文", role: .cancel) {
                automaticRSVPParagraph = nil
            }
        } message: { _ in
            Text("刚才的注意偏离可能意味着阅读卡顿。小伴可以把当前段落逐字呈现，结束后自动回到这里。")
        }
    }

    @ViewBuilder
    private var readingLayout: some View {
        if horizontalSizeClass == .regular {
            HStack(spacing: 0) {
                articlePane.frame(maxWidth: .infinity)
                Divider()
                companionPane.frame(width: 300)
            }
        } else {
            articlePane
        }
    }

    private var articlePane: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text(chapter.title)
                        .font(.system(size: 34, weight: .bold, design: .serif))
                    Text("长按任一段落进入 RSVP 逐字阅读")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    ForEach(chapter.paragraphs) { paragraph in
                        ParagraphView(
                            paragraph: paragraph,
                            isFocused: focusMonitor.focusedParagraphID == paragraph.id,
                            onRSVP: { selectedParagraph = paragraph },
                            onExplain: {
                                companionMessage = companion.message(for: paragraph.id, trigger: .explain)
                            }
                        )
                        .id(paragraph.id)
                        .background {
                            GeometryReader { geometry in
                                Color.clear.preference(
                                    key: ParagraphFramePreferenceKey.self,
                                    value: [paragraph.id: geometry.frame(in: .named("readingViewport"))]
                                )
                            }
                        }
                    }
                }
                .padding(28)
                .frame(maxWidth: 760, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .onAppear {
                if let progress,
                   chapter.paragraphs.indices.contains(progress.currentParagraphIndex) {
                    proxy.scrollTo(chapter.paragraphs[progress.currentParagraphIndex].id, anchor: .center)
                }
            }
            .overlay(alignment: .top) {
                focusWarning
            }
        }
    }

    private var companionPane: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label("小伴", systemImage: "pawprint.fill")
                .font(.title2.bold())
            Text("卡住时，我会帮你把内容拆小一点。")
                .foregroundStyle(.secondary)
            Divider()
            Button("总结当前段落") {
                let id = focusMonitor.focusedParagraphID ?? chapter.paragraphs[0].id
                companionMessage = companion.message(for: id, trigger: .summary)
            }
            .buttonStyle(.borderedProminent)
            .tint(.black)
            Button("我读得有点久了") {
                let id = focusMonitor.focusedParagraphID ?? chapter.paragraphs[0].id
                companionMessage = companion.message(for: id, trigger: .encouragement)
            }
            .buttonStyle(.bordered)
            Spacer()
            Text("离线伴读 · 不上传阅读内容")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .background(.white.opacity(0.7))
    }

    @ViewBuilder
    private var focusWarning: some View {
        switch focusMonitor.warningLevel {
        case .none:
            EmptyView()
        case .gentle:
            warningBanner(text: "注意力好像离开了一会儿，慢慢看回文字就好。", strong: false)
        case .strong:
            warningBanner(text: "小伴在这里。先找回刚才发光的段落。", strong: true)
        }
    }

    private func warningBanner(text: String, strong: Bool) -> some View {
        Label(text, systemImage: "pawprint.fill")
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(strong ? Color.orange.opacity(0.94) : Color.white.opacity(0.96))
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
            .padding(.top, 10)
    }

    private func ensureProgress() {
        guard progress == nil else { return }
        modelContext.insert(ReadingProgressRecord(bookID: book.id))
        try? modelContext.save()
    }

    private func configureFocusCallbacks() {
        focusMonitor.onDrift = {
            sessionDrifts += 1
            progress?.driftCount += 1
        }
        focusMonitor.onReturn = {
            sessionReturns += 1
            progress?.returnCount += 1
            if sessionReturns == 1,
               let id = focusMonitor.focusedParagraphID,
               let paragraph = chapter.paragraphs.first(where: { $0.id == id }) {
                automaticRSVPParagraph = paragraph
            }
        }
    }

    private func updateProgressFromFocus() {
        guard let id = focusMonitor.focusedParagraphID,
              let index = chapter.paragraphs.firstIndex(where: { $0.id == id }),
              let progress else { return }
        progress.currentParagraphIndex = index
        progress.completedParagraphCount = max(progress.completedParagraphCount, index + 1)
        progress.lastReadAt = .now
    }

    private func saveSession() {
        let endedAt = Date.now
        let duration = max(0, endedAt.timeIntervalSince(sessionStartedAt))
        progress?.totalReadingSeconds += duration
        progress?.lastReadAt = endedAt
        modelContext.insert(
            ReadingSessionRecord(
                bookID: book.id,
                startedAt: sessionStartedAt,
                endedAt: endedAt,
                focusedSeconds: duration,
                driftCount: sessionDrifts,
                returnCount: sessionReturns
            )
        )
        try? modelContext.save()
    }
}

private struct ParagraphView: View {
    let paragraph: ReadingParagraph
    let isFocused: Bool
    let onRSVP: () -> Void
    let onExplain: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(paragraph.text)
                .font(.system(size: 21, weight: .regular, design: .serif))
                .lineSpacing(10)
                .foregroundStyle(ReadBuddyTheme.ink)
                .textSelection(.enabled)
            HStack {
                Button("逐字阅读", systemImage: "play.rectangle") { onRSVP() }
                Button("看不懂", systemImage: "questionmark.bubble") { onExplain() }
            }
            .font(.caption)
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
        }
        .padding(18)
        .background(isFocused ? ReadBuddyTheme.glow.opacity(0.20) : Color.clear)
        .overlay(alignment: .leading) {
            if isFocused {
                Capsule().fill(ReadBuddyTheme.glow).frame(width: 4).padding(.vertical, 10)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contentShape(Rectangle())
        .onLongPressGesture(perform: onRSVP)
    }
}

extension CompanionMessage: Identifiable {
    var id: String { title + body }
}

private struct CompanionSheet: View {
    let message: CompanionMessage
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 22) {
            Image(systemName: "pawprint.circle.fill")
                .font(.system(size: 66))
            Text(message.title).font(.title.bold())
            Text(message.body)
                .font(.title3)
                .lineSpacing(8)
                .multilineTextAlignment(.center)
            Button("明白了") { dismiss() }
                .buttonStyle(.borderedProminent)
                .tint(.black)
        }
        .padding(36)
        .presentationDetents([.medium])
    }
}
