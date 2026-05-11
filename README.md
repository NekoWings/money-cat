# MoneyCat（多人活动快速记账 iOS App）

MoneyCat 是一个可直接落地的 SwiftUI iOS 项目，针对“多人出行/聚餐，一个人先垫付，后续快速结算”的场景。

## 功能总览

### 1) OCR 扫描小票（中文 / 日文 / 英文）
- 使用 Apple `Vision` 进行 OCR。
- 语言配置：`zh-Hans`、`ja-JP`、`en-US`。
- 支持两种导入方式：
  - 文档相机拍照扫描（`VNDocumentCameraViewController`）
  - 相册图片导入
- 对小票行进行规则解析：提取商品名 + 金额，并过滤合计/税费/支付方式等非商品行。

### 2) 人员与活动管理
- 创建、编辑、删除成员。
- 创建活动并勾选参与人。
- 活动列表展示参与人数、订单数量。

### 3) 订单与消费项分配
- 活动内可新增/编辑/删除订单。
- 每笔订单支持折扣（0%~100%）。
- OCR 导入后可继续手动补充条目。
- 每个消费项支持：
  - 选择付款人
  - 选择参与人
  - 分摊方式：均分 / 按权重

### 4) 结算结果
- 自动按“条目金额 × 订单折扣”计算。
- 输出活动内每笔转账（谁给谁多少钱）。
- 输出每个参与人的净额（应收/应付）。

### 5) 数据持久化
- 使用 JSON 文件持久化，自动保存人员和活动数据。

## 项目结构

- `MoneyCat/Models`: 领域模型（Person、Activity、Order、ReceiptItem 等）
- `MoneyCat/Services`: OCR、结算计算、数据存储
- `MoneyCat/ViewModels`: 全局状态与业务入口
- `MoneyCat/Views`: 页面（人员、活动、订单、扫描、结算）
- `MoneyCat/Utilities`: 通用扩展（金额格式化）

## 运行

### 方式一：XcodeGen（推荐）
1. 安装 [XcodeGen](https://github.com/yonaskolb/XcodeGen)
2. 执行：
   ```bash
   xcodegen generate
   ```
3. 打开 `MoneyCat.xcodeproj` 运行。

### 方式二：手动工程
- 新建 iOS SwiftUI App，将 `MoneyCat/` 源码加入 target。

## 权限
- `NSCameraUsageDescription`
- `NSPhotoLibraryUsageDescription`
