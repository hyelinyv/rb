# ReadBuddy Offline MVP

ReadBuddy 是面向 ADHD 与注意力易分散读者的离线 iPad 阅读原型。本项目为 Swift Playgrounds App Project（`.swiftpm`），目标系统为 iPadOS 17+。

## 已实现

- SwiftUI 首页、书库、沉浸阅读、报告和个人页
- ARKit 前摄人脸追踪支持性检测与相机授权
- 基于 `ARFaceAnchor.lookAtPoint` 的段落级视线趋势估计
- 五点校准、视线调试点、8/10 秒注意偏离提醒
- 不支持或拒绝相机权限时自动进入模拟模式
- 手动按需 RSVP，支持 150–500 字/分钟、暂停和前后步进
- 首次明显走神并回归后，自动建议从当前段落启动 RSVP
- 离线预置解释、摘要与正向反馈
- SwiftData 阅读进度、会话和成长统计

## 在 iPad 上运行

1. 安装 Swift Playgrounds 和 Working Copy。
2. 在 Working Copy 中克隆保存此项目的 GitHub 仓库。
3. 在“文件”App 中找到 `ReadBuddy.swiftpm`，点按后选择 Swift Playgrounds 打开。
4. 首次运行进入“开始校准”，允许相机访问。
5. 若设备不支持前摄 ARKit，项目会自动进入模拟模式；阅读页右上角心电图按钮可切换模拟走神。

如果 Swift Playgrounds 打开时创建了副本，请先做一次小改动，确认 Working Copy 能看到该改动；不能看到时，测试后将完整 `.swiftpm` 包复制回 Working Copy 再提交。

## GitHub 工作方式

- `main` 始终保持能在 iPad Swift Playgrounds 打开的版本。
- Windows/Codex 修改前先 `git pull`，修改后提交并 `git push`。
- iPad 测试前在 Working Copy 中拉取，测试修改后先提交再切换设备。
- 不要同时在 Windows 和 iPad 编辑同一文件。

## 眼动追踪说明

当前实现是技术原型，只做段落级趋势判断，不是医疗设备，也不承诺精确到字符。相机帧、人脸网格和原始视线点均不持久化。持久化内容仅包括阅读时长、完成片段、偏离次数和回归次数。

## 建议的真机验证顺序

1. 确认项目能编译并进入首页。
2. 完成五点校准，观察阅读页调试圆点是否随视线大致移动。
3. 遮挡相机、转头或看向屏幕外，验证 8 秒柔和提醒和 10 秒震动。
4. 在模拟模式切换走神，验证不支持 ARKit 时的完整流程。
5. 启动 RSVP，调整速度后关闭，确认回到原段落。
6. 退出阅读页并重启 App，确认报告和进度保留。
