import SwiftUI

struct LibraryView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                BrandHeader()
                Text("我的书库")
                    .font(.largeTitle.bold())

                NavigationLink {
                    ReadingView()
                } label: {
                    ReadBuddyCard {
                        HStack(spacing: 18) {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(.black.gradient)
                                .frame(width: 92, height: 122)
                                .overlay {
                                    Image(systemName: "book.pages.fill")
                                        .font(.largeTitle)
                                        .foregroundStyle(.white)
                                }
                            VStack(alignment: .leading, spacing: 8) {
                                Text(SampleLibrary.book.title)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text(SampleLibrary.book.author)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text("离线可用")
                                    .font(.caption.bold())
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.green.opacity(0.12))
                                    .clipShape(Capsule())
                                    .foregroundStyle(.green)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .buttonStyle(.plain)

                ContentUnavailableView(
                    "暂不支持导入",
                    systemImage: "tray",
                    description: Text("TXT、PDF 与 EPUB 导入将在离线阅读闭环验证后加入。")
                )
                .frame(maxWidth: .infinity)
                .padding(.top, 36)
            }
            .padding(24)
            .frame(maxWidth: 900)
            .frame(maxWidth: .infinity)
        }
        .background(ReadBuddyTheme.background)
        .navigationBarHidden(true)
    }
}
