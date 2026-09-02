import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var gaze: GazeTrackingCoordinator
    @State private var showingCalibration = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                BrandHeader()

                Text("今日继续阅读")
                    .font(.title2.bold())

                ReadBuddyCard {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .top, spacing: 18) {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.black.gradient)
                                .frame(width: 116, height: 150)
                                .overlay {
                                    Image(systemName: "text.book.closed.fill")
                                        .font(.system(size: 38))
                                        .foregroundStyle(.white)
                                }
                            VStack(alignment: .leading, spacing: 8) {
                                Text(SampleLibrary.book.title)
                                    .font(.title3.bold())
                                Text(SampleLibrary.book.author)
                                    .foregroundStyle(.secondary)
                                Text("第 1 章 · 6 个阅读片段")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                NavigationLink {
                                    ReadingView()
                                } label: {
                                    Label("继续阅读", systemImage: "arrow.right")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.black)
                            }
                        }
                    }
                }

                Text("专注准备")
                    .font(.title3.bold())

                ReadBuddyCard {
                    HStack(spacing: 16) {
                        Image(systemName: gaze.hardwareSupportsFaceTracking ? "eye.circle.fill" : "eye.slash.circle.fill")
                            .font(.system(size: 42))
                        VStack(alignment: .leading, spacing: 5) {
                            Text(gaze.hardwareSupportsFaceTracking ? "设备支持前摄追踪" : "将使用模拟专注模式")
                                .font(.headline)
                            Text("完成五点校准后，阅读页会提供段落级目光锚点。")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("开始校准") {
                            showingCalibration = true
                        }
                        .buttonStyle(.bordered)
                    }
                }

                Text("所有内容和统计都保存在这台 iPad 上。离线状态下也能完整使用。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
            .frame(maxWidth: 900)
            .frame(maxWidth: .infinity)
        }
        .background(ReadBuddyTheme.background)
        .navigationBarHidden(true)
        .sheet(isPresented: $showingCalibration) {
            CalibrationView()
        }
    }
}
