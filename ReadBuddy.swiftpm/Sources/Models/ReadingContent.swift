import Foundation

struct Book: Identifiable, Hashable {
    let id: String
    let title: String
    let author: String
    let chapters: [Chapter]
}

struct Chapter: Identifiable, Hashable {
    let id: String
    let title: String
    let paragraphs: [ReadingParagraph]
}

struct ReadingParagraph: Identifiable, Hashable {
    let id: String
    let text: String
}

enum SampleLibrary {
    static let book = Book(
        id: "deep-work",
        title: "深度工作：在嘈杂世界中保持专注",
        author: "ReadBuddy 离线示例",
        chapters: [
            Chapter(
                id: "chapter-1",
                title: "把注意力带回当下",
                paragraphs: [
                    ReadingParagraph(
                        id: "p1",
                        text: "在我们的媒体体系中，深度工作是一项越来越稀缺、却越来越有价值的能力。真正的专注并不意味着从不走神，而是能够觉察注意力去了哪里，并温和地把它带回来。"
                    ),
                    ReadingParagraph(
                        id: "p2",
                        text: "阅读长文本时，大脑需要暂时保存前文，同时理解眼前的信息。环境里的声音、弹出的通知，甚至对自己的责备，都可能占用这份有限的工作记忆。"
                    ),
                    ReadingParagraph(
                        id: "p3",
                        text: "与其要求自己一次坚持很久，不如把目标缩小到一个段落。完成一个清晰的小目标，会让下一步变得更容易，也让注意力重新拥有方向。"
                    ),
                    ReadingParagraph(
                        id: "p4",
                        text: "当一句话反复读不进去时，可以暂时改变信息呈现方式。逐词阅读减少了眼球在页面上的搜索负担，完成后再回到原文，就能重新获得上下文。"
                    ),
                    ReadingParagraph(
                        id: "p5",
                        text: "专注不是一条永不偏离的直线。每一次意识到走神并重新回到文字，都是一次有效的练习。记录这些回归，不是为了评判，而是为了看见真实的进步。"
                    ),
                    ReadingParagraph(
                        id: "p6",
                        text: "今天不必读完整本书。读完这一页，理解一个观点，或者安静地坐上五分钟，都可以成为值得确认的成果。稳定来自许多次微小而友善的重新开始。"
                    )
                ]
            )
        ]
    )
}
