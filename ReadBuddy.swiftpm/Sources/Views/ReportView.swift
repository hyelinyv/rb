import SwiftUI
import SwiftData

struct ReportView: View {
    @Query private var progressRecords: [ReadingProgressRecord]
    @Query(sort: \ReadingSessionRecord.startedAt, order: .reverse) private var sessions: [ReadingSessionRecord]

    private var progress: ReadingProgressRecord? {
        progressRecords.first(where: { $0.bookID == SampleLibrary.book.id })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                BrandHeader()
                Text("专注报告")
                    .font(.largeTitle.bold())
                Text("这里只和过去的自己比较。每次回来，都算一次进步。")
                    .foregroundStyle(.secondary)

                HStack(spacing: 16) {
                    metricCard(value: readingMinutes, label: "阅读分钟", icon: "clock.fill")
                    metricCard(value: "\(progress?.completedParagraphCount ?? 0)", label: "完成片段", icon: "checkmark.circle.fill")
                    metricCard(value: "\(progress?.returnCount ?? 0)", label: "注意回归", icon: "arrow.uturn.backward.circle.fill")
                }

                ReadBuddyCard {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("阅读进度").font(.headline)
                            Spacer()
                            Text("\(completionPercent)%").font(.title2.bold())
                        }
                        ProgressView(value: Double(completionPercent), total: 100)
                            .tint(.black)
                        Text("完成 \(progress?.completedParagraphCount ?? 0) / \(SampleLibrary.book.chapters[0].paragraphs.count) 个片段")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Text("最近阅读")
                    .font(.title3.bold())

                if sessions.isEmpty {
                    ContentUnavailableView(
                        "还没有阅读记录",
                        systemImage: "book.closed",
                        description: Text("完成一次阅读后，小伴会在这里记录你的努力。")
                    )
                } else {
                    ForEach(sessions.prefix(6)) { session in
                        ReadBuddyCard {
                            HStack {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(session.startedAt, format: .dateTime.month().day().hour().minute())
                                        .font(.headline)
                                    Text("专注 \(Int(session.focusedSeconds / 60)) 分钟 · 回归 \(session.returnCount) 次")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "pawprint.fill")
                                    .font(.title2)
                            }
                        }
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: 900)
            .frame(maxWidth: .infinity)
        }
        .background(ReadBuddyTheme.background)
        .navigationBarHidden(true)
    }

    private var readingMinutes: String {
        String(Int((progress?.totalReadingSeconds ?? 0) / 60))
    }

    private var completionPercent: Int {
        let count = SampleLibrary.book.chapters[0].paragraphs.count
        guard count > 0 else { return 0 }
        return Int((Double(progress?.completedParagraphCount ?? 0) / Double(count)) * 100)
    }

    private func metricCard(value: String, label: String, icon: String) -> some View {
        ReadBuddyCard {
            VStack(spacing: 9) {
                Image(systemName: icon).font(.title2)
                Text(value).font(.system(size: 32, weight: .bold, design: .rounded))
                Text(label).font(.caption).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
