import SwiftUI

struct ProfileView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                BrandHeader()
                Image(systemName: "pawprint.circle.fill")
                    .font(.system(size: 92))
                Text("小伴")
                    .font(.largeTitle.bold())
                Text("你的离线阅读伙伴")
                    .foregroundStyle(.secondary)

                ReadBuddyCard {
                    VStack(spacing: 0) {
                        profileRow("阅读偏好", icon: "slider.horizontal.3")
                        Divider()
                        profileRow("眼动与专注", icon: "eye")
                        Divider()
                        profileRow("隐私说明", icon: "lock.shield")
                    }
                }

                ReadBuddyCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("离线与隐私", systemImage: "checkmark.shield.fill")
                            .font(.headline)
                        Text("ReadBuddy 不保存相机画面、人脸网格或原始视线数据。当前版本不会向网络发送任何内容。")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(24)
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
        }
        .background(ReadBuddyTheme.background)
        .navigationBarHidden(true)
    }

    private func profileRow(_ title: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon).frame(width: 28)
            Text(title)
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.secondary)
        }
        .padding(.vertical, 15)
    }
}
