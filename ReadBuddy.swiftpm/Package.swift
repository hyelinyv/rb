// swift-tools-version: 5.9

import PackageDescription
import AppleProductTypes

let package = Package(
    name: "ReadBuddy",
    platforms: [
        .iOS("17.0")
    ],
    products: [
        .iOSApplication(
            name: "ReadBuddy",
            targets: ["AppModule"],
            bundleIdentifier: "com.readbuddy.offline",
            displayVersion: "0.1.0",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .book),
            accentColor: .presetColor(.black),
            supportedDeviceFamilies: [
                .pad
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight,
                .landscapeLeft,
                .portraitUpsideDown(.when(deviceFamilies: [.pad]))
            ],
            capabilities: [
                .camera(purposeString: "ReadBuddy 仅在本机估计阅读时的视线趋势，用于提供专注提醒；不会保存或上传相机画面与面部数据。")
            ],
            appCategory: .education
        )
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            path: "Sources"
        )
    ]
)
