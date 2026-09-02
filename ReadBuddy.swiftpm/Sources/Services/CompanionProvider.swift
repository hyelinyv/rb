import Foundation

enum CompanionTrigger: String {
    case explain = "看不懂"
    case summary = "帮我总结"
    case encouragement = "读太久了"
}

struct CompanionMessage {
    let title: String
    let body: String
}

protocol CompanionProvider {
    func message(for paragraphID: String, trigger: CompanionTrigger) -> CompanionMessage
}

struct LocalCompanionProvider: CompanionProvider {
    private let explanations: [String: String] = [
        "p1": "专注并不是完全不走神，而是发现走神后能够回来。这个能力可以通过练习逐渐增强。",
        "p2": "工作记忆像一张临时便签。干扰越多，留给理解文章的空间就越少。",
        "p3": "把任务缩小到一个段落，可以降低开始行动时的心理阻力。",
        "p4": "RSVP 会一次呈现一个字，减少视线搜索；结束后仍回到原文理解上下文。",
        "p5": "记录回归次数，是为了看见恢复注意力的能力，而不是记录失败。",
        "p6": "小而明确的完成感，更容易帮助人建立稳定习惯。"
    ]

    func message(for paragraphID: String, trigger: CompanionTrigger) -> CompanionMessage {
        switch trigger {
        case .explain:
            return CompanionMessage(
                title: "换一种说法",
                body: explanations[paragraphID] ?? "先把这一段拆成一句一句读，不必急着一次全部理解。"
            )
        case .summary:
            return CompanionMessage(
                title: "这一段的重点",
                body: explanations[paragraphID] ?? "这段强调把阅读目标缩小，并温和地将注意力带回文字。"
            )
        case .encouragement:
            return CompanionMessage(
                title: "小伴在这里",
                body: "你已经坚持了一会儿。休息三十秒也算阅读的一部分，回来后只读下一句话就好。"
            )
        }
    }
}
