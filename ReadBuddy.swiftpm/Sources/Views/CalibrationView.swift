import SwiftUI

struct CalibrationView: View {
    @EnvironmentObject private var gaze: GazeTrackingCoordinator
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex = 0
    @State private var capturedSamples: [CGPoint] = []
    @State private var completed = false

    private let points = [
        CGPoint(x: 0.5, y: 0.5),
        CGPoint(x: 0.16, y: 0.18),
        CGPoint(x: 0.84, y: 0.18),
        CGPoint(x: 0.16, y: 0.82),
        CGPoint(x: 0.84, y: 0.82)
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ReadBuddyTheme.background.ignoresSafeArea()

                if completed {
                    VStack(spacing: 22) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 72))
                        Text("校准完成")
                            .font(.largeTitle.bold())
                        Text("现在可以开始阅读。校准参数只保留在本次运行中。")
                            .foregroundStyle(.secondary)
                        Button("进入阅读") { dismiss() }
                            .buttonStyle(.borderedProminent)
                            .tint(.black)
                    }
                } else {
                    let target = points[currentIndex]
                    Circle()
                        .fill(ReadBuddyTheme.glow)
                        .frame(width: 42, height: 42)
                        .overlay(Circle().fill(.black).frame(width: 10, height: 10))
                        .position(
                            x: target.x * geometry.size.width,
                            y: target.y * geometry.size.height
                        )

                    VStack {
                        HStack {
                            Button("关闭") { dismiss() }
                            Spacer()
                            Text("眼动校准 · \(currentIndex + 1)/\(points.count)")
                                .font(.headline)
                            Spacer()
                            Button("模拟") { gaze.useSimulation() }
                        }
                        .padding()
                        Spacer()
                        VStack(spacing: 10) {
                            Text("保持头部稳定，看向圆点")
                                .font(.headline)
                            Text(gaze.status.label)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Button("记录这个点") { capture() }
                                .buttonStyle(.borderedProminent)
                                .tint(.black)
                                .disabled(!gaze.sample.isReliable)
                        }
                        .padding(.bottom, 28)
                    }
                }
            }
        }
        .onAppear {
            gaze.resetCalibration()
            gaze.start()
        }
        .onDisappear { gaze.stop() }
    }

    private func capture() {
        let newSamples = capturedSamples + [gaze.sample.normalizedPoint]
        capturedSamples = newSamples
        if currentIndex == points.count - 1 {
            gaze.applyCalibration(expectedPoints: points, samples: newSamples)
            completed = true
        } else {
            currentIndex += 1
        }
    }
}
