# 小语 App V1.0 开发文档

> 项目代号：小语（CarTalk）
>
> 产品定位：一款把手机变成"车载情绪显示器"的跨平台
> App。第一版不依赖实体硬件，用户横屏后即可将手机作为车载表情屏；后续通过
> BLE 蓝牙连接独立 LED 硬件显示器。
>
> 开发技术：Flutter + Dart
>
> 发布平台：Android / iOS
>
> 设计基准：以当前提供的「小语」视觉方案为准，核心视觉为深色车载场景、玻璃拟态、圆形宠物陪伴、情绪表情和横屏全屏显示。

------------------------------------------------------------------------

## 1. 产品目标

### 1.1 V1.0 核心目标

第一版只解决一个核心体验：

``` text
打开 App
    ↓
选择陪伴宠物
    ↓
选择一句想表达的话 / 表情
    ↓
横屏
    ↓
宠物做出情绪反馈
    ↓
进入全屏显示
    ↓
手机屏幕作为“小语显示器”
```

第一版暂不依赖实体硬件。

### 1.2 后续产品路线

``` text
V1.0
手机全屏显示
    ↓
V1.1
宠物系统 + 更多表情 + 动画
    ↓
V1.5
AI 自定义小语
    ↓
V2.0
BLE 连接车载 LED 硬件
    ↓
V2.5
硬件商城 / 表情商城 / 宠物皮肤
```

------------------------------------------------------------------------

# 2. 产品核心概念

## 2.1 不是"表情包工具"，而是"小语宠物"

App 的核心 IP 是一组原创陪伴宠物。

用户第一次进入 App 时，可以选择一个自己的"小语伙伴"。

例如：

  宠物       性格       推荐情绪
  ---------- ---------- ------------------
  KK       温柔治愈   谢谢、抱歉、开心
  小熊       憨厚可靠   收到、感谢
  小狗       活泼开朗   打招呼、再见
  小兔       可爱灵动   开心、撒娇
  小恐龙     勇敢有趣   加油、鼓励
  小企鹅     呆萌冷静   搞怪、吐槽
  小机器人   科技感     默认/未来主题

宠物不仅是静态图片，而是一个简单的状态机：

``` text
Idle
 ↓
Happy
 ↓
Excited
 ↓
Display
 ↓
Idle
```

例如用户点击"谢谢"：

``` text
宠物：
普通状态
  ↓
看到用户操作
  ↓
眼睛变亮
  ↓
挥手 / 点头
  ↓
显示“谢谢啦！”
  ↓
恢复待机
```

------------------------------------------------------------------------

# 3. V1.0 功能范围

## 3.1 必须实现

-   [x] 首页
-   [x] 横屏首页
-   [x] 宠物选择
-   [x] 6～7 个默认宠物
-   [x] 表情分类
-   [x] 常用表情
-   [x] 自定义文字
-   [x] 全屏显示
-   [x] 横屏显示
-   [x] 宠物动画
-   [x] 表情动画
-   [x] 收藏
-   [x] 最近使用
-   [x] 屏幕常亮
-   [x] 本地数据持久化
-   [x] Android
-   [x] iOS

## 3.2 V1.0 暂不实现

-   BLE 硬件连接
-   登录注册
-   用户社区
-   社交分享系统
-   在线商城
-   支付
-   AI Agent
-   RAG
-   云端账号同步
-   复杂后台

这些功能保留架构接口，但不进入第一版。

------------------------------------------------------------------------

# 4. 信息架构

``` text
App
│
├── 首页
│   ├── 当前宠物
│   ├── 推荐表达
│   ├── 最近使用
│   ├── 快捷分类
│   └── 更多
│
├── 表情
│   ├── 礼貌沟通
│   ├── 行车表达
│   ├── 搞怪有趣
│   ├── 节日
│   ├── 情侣/朋友
│   └── 自定义
│
├── DIY
│   ├── Emoji
│   ├── 自定义文字
│   ├── 动画
│   └── 全屏预览
│
└── 我的
    ├── 我的宠物
    ├── 收藏
    ├── 最近使用
    ├── 设置
    └── 关于
```

------------------------------------------------------------------------

# 5. 页面设计

## 5.1 竖屏首页

竖屏首页用于日常浏览和选择。

设计参考当前提供的第一张设计稿。

### 页面结构

``` text
┌─────────────────────────┐
│ 🚗 小语              ⚙  │
│                         │
│ 让你的情绪，             │
│ 显示给后车               │
│                         │
│ ┌─────────────────────┐ │
│ │                     │ │
│ │       当前宠物       │ │
│ │        🐱           │ │
│ │                     │ │
│ │    “你好呀～”        │ │
│ └─────────────────────┘ │
│                         │
│ 最近使用                │
│                         │
│ 🙏      👍      👋      │
│ 谢谢     收到     再见   │
│                         │
│ 礼貌沟通                │
│                         │
│ 🙏      ❤️      😊      │
│                         │
│ 行车表达                │
│                         │
│ ➡️      ⚠️      🐢      │
│                         │
│ 首页      DIY       我的 │
└─────────────────────────┘
```

------------------------------------------------------------------------

# 6. 横屏首页------V1.0 核心页面

横屏首页是整个 App 最重要的页面。

设计目标：

> 接近"车载陪伴角色"的体验，但形成自己的原创视觉。

## 6.1 横屏布局

``` text
┌────────────────────────────────────────────────────────────┐
│                                                            │
│ 🚗 小语                                      ● 已准备好     │
│                                                            │
│                         🐱                                 │
│                    ╭─────────╮                             │
│                    │  ◡  ◡  │                             │
│                    │   ︶    │                             │
│                    ╰─────────╯                             │
│                                                            │
│                     “今天也要开心哦～”                      │
│                                                            │
│  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐   │
│  │  🙏  │ │  👍  │ │  👋  │ │  ❤️  │ │  😂  │ │  ⋯   │   │
│  │ 谢谢 │ │ 收到 │ │ 再见 │ │ 爱你 │ │ 哈哈 │ │ 更多 │   │
│  └──────┘ └──────┘ └──────┘ └──────┘ └──────┘ └──────┘   │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

## 6.2 横屏交互原则

### 原则一：大按钮

车内使用场景下，按钮必须明显大于普通 App。

建议：

-   快捷按钮最小点击区域：56～72 logical pixels
-   重要按钮：72～96 logical pixels
-   避免小文字按钮

### 原则二：少层级

用户最好：

``` text
点击表情
    ↓
直接显示
```

不要：

``` text
点击
 ↓
确认
 ↓
预览
 ↓
确定
 ↓
显示
```

### 原则三：强视觉反馈

点击：

``` text
🙏
```

立即出现：

``` text
🐱 → 开心 → 挥手
```

随后进入全屏。

------------------------------------------------------------------------

# 7. 宠物系统

## 7.1 第一版宠物

建议首发 7 个：

``` text
🐱 KK
🐻 小熊
🐶 小狗
🐰 小兔
🦖 小恐龙
🐧 小企鹅
🤖 小机器人
```

实际生产版本不要直接使用系统 Emoji 作为最终视觉素材。

应该使用原创 SVG / Rive / Lottie / Spine / PNG 资产。

------------------------------------------------------------------------

# 8. 宠物状态系统

定义：

``` dart
enum PetState {
  idle,
  happy,
  excited,
  shy,
  sorry,
  greeting,
  love,
  laughing,
  sleepy,
}
```

定义事件：

``` dart
enum PetAction {
  thank,
  receive,
  goodbye,
  love,
  sorry,
  warning,
  encourage,
  custom,
}
```

映射：

``` text
谢谢 → happy
收到 → receive
再见 → greeting
爱你 → love
抱歉 → sorry
注意 → warning
加油 → excited
哈哈 → laughing
```

------------------------------------------------------------------------

# 9. 表情系统

## 9.1 第一批表情分类

### 礼貌沟通

``` text
🙏 谢谢
👍 收到
❤️ 感谢
😊 谢啦
🙇 抱歉
😅 不好意思
👋 再见
```

### 行车表达

``` text
➡️ 我要并线
🙏 可以让我一下吗
👍 谢谢让行
⚠️ 注意
🐢 新手上路
🚗 马上走
⏳ 等一下
```

### 搞怪

``` text
😂 哈哈哈
😎 酷
🤡 6
🗿 淡定
❓ 什么情况
😏 懂的都懂
```

### 情侣/朋友

``` text
❤️ 爱你
😘 想你
🥰 开心
👋 等你
```

### 节日

``` text
🎉 节日快乐
🎂 生日快乐
🎄 圣诞快乐
🧧 新年快乐
```

------------------------------------------------------------------------

# 10. Expression 数据模型

``` dart
class Expression {
  final String id;
  final String categoryId;
  final String emoji;
  final String title;
  final String? subtitle;

  /// 宠物动作
  final PetAction petAction;

  /// 显示动画
  final DisplayAnimation animation;

  /// 显示时长
  final Duration duration;

  /// 是否收藏
  final bool favorite;

  const Expression({
    required this.id,
    required this.categoryId,
    required this.emoji,
    required this.title,
    this.subtitle,
    required this.petAction,
    required this.animation,
    required this.duration,
    this.favorite = false,
  });
}
```

------------------------------------------------------------------------

# 11. Display Device 抽象

这是未来接入硬件最重要的架构设计。

第一版不要把业务逻辑直接写成：

``` dart
showOnPhone();
```

而应该抽象：

``` dart
abstract class DisplayDevice {
  Future<void> connect();

  Future<void> disconnect();

  Future<void> show(Expression expression);

  Future<void> showCustom(CustomExpression expression);

  Future<void> clear();

  bool get isConnected;
}
```

V1：

``` dart
class PhoneDisplayDevice implements DisplayDevice {
  // 手机屏幕显示
}
```

未来：

``` dart
class BluetoothDisplayDevice implements DisplayDevice {
  // BLE LED 硬件
}
```

业务层：

``` text
ExpressionService
       │
       ↓
DisplayDevice
       │
 ┌─────┴───────────────┐
 ↓                     ↓
PhoneDisplay       BluetoothDisplay
 ↓                     ↓
手机屏幕              LED硬件
```

这样以后增加硬件不会重写业务层。

------------------------------------------------------------------------

# 12. 全屏显示模式

## 12.1 进入条件

用户点击：

``` text
🙏 谢谢
```

执行：

``` text
横屏
 ↓
隐藏系统 UI
 ↓
屏幕常亮
 ↓
宠物动画
 ↓
文字动画
 ↓
持续显示
```

## 12.2 全屏界面

``` text
┌───────────────────────────────────────────┐
│                                           │
│                                           │
│                  🐱                       │
│                                           │
│                谢谢啦！                    │
│                                           │
│                                           │
│                              点击退出      │
└───────────────────────────────────────────┘
```

### 默认规则

-   黑色/深色背景
-   最大化内容
-   隐藏 App Bar
-   隐藏 Bottom Navigation
-   隐藏状态栏
-   隐藏导航栏
-   防止自动息屏
-   点击屏幕退出
-   支持左右滑动切换表情

------------------------------------------------------------------------

# 13. 自定义 DIY

## 13.1 V1.0 功能

用户可以：

``` text
选择 Emoji
+
输入文字
+
选择动画
=
生成小语
```

例如：

``` text
Emoji：🙏

文字：
谢谢你让路啦

动画：
● 呼吸
○ 左右滑入
○ 弹跳
○ 打字机

[全屏显示]
```

## 13.2 数据模型

``` dart
class CustomExpression {
  final String id;
  final String emoji;
  final String text;
  final DisplayAnimation animation;
  final int durationSeconds;
}
```

------------------------------------------------------------------------

# 14. 动画系统

建议 V1.0 使用 Flutter 自身动画 + Lottie/Rive。

## 推荐动画

### 宠物

-   Idle 呼吸
-   眨眼
-   挥手
-   点头
-   跳跃
-   开心
-   害羞
-   生气
-   爱心

### 文字

-   Fade
-   Scale
-   Slide
-   Bounce
-   Typewriter
-   Pulse

------------------------------------------------------------------------

# 15. 推荐 Flutter 技术栈

## 核心

``` text
Flutter
Dart
```

## 状态管理

推荐：

``` text
Riverpod
```

原因：

-   类型安全
-   依赖注入方便
-   易测试
-   后期扩展 BLE / API 比较自然

## 路由

推荐：

``` text
go_router
```

## 本地存储

V1 推荐：

``` text
Hive / Isar
```

如果数据非常简单，也可以：

``` text
shared_preferences
```

建议：

``` text
shared_preferences
→ 设置、当前宠物、简单配置

Isar/Hive
→ 收藏、最近使用、自定义表情
```

## 动画

``` text
Lottie
Rive
Flutter Animation
```

## 图片资源

``` text
PNG
WebP
SVG
```

------------------------------------------------------------------------

# 16. Flutter 项目目录

``` text
lib/
│
├── main.dart
│
├── app/
│   ├── app.dart
│   ├── router.dart
│   └── theme/
│       ├── app_theme.dart
│       ├── app_colors.dart
│       └── app_text_styles.dart
│
├── core/
│   ├── constants/
│   ├── utils/
│   ├── extensions/
│   └── services/
│
├── data/
│   ├── models/
│   │   ├── pet.dart
│   │   ├── expression.dart
│   │   ├── category.dart
│   │   └── custom_expression.dart
│   │
│   ├── repositories/
│   │   ├── pet_repository.dart
│   │   └── expression_repository.dart
│   │
│   └── local/
│       └── local_storage.dart
│
├── domain/
│   ├── display/
│   │   ├── display_device.dart
│   │   └── phone_display_device.dart
│   │
│   └── services/
│       ├── expression_service.dart
│       └── pet_service.dart
│
├── features/
│   ├── home/
│   │   ├── pages/
│   │   │   ├── home_page.dart
│   │   │   └── landscape_home_page.dart
│   │   ├── widgets/
│   │   │   ├── pet_stage.dart
│   │   │   ├── expression_bar.dart
│   │   │   └── quick_expression.dart
│   │   └── providers/
│   │
│   ├── expression/
│   │   ├── pages/
│   │   │   ├── expression_category_page.dart
│   │   │   └── expression_detail_page.dart
│   │   └── widgets/
│   │
│   ├── pet/
│   │   ├── pages/
│   │   │   └── pet_select_page.dart
│   │   └── widgets/
│   │
│   ├── diy/
│   │   ├── pages/
│   │   │   └── diy_page.dart
│   │   └── widgets/
│   │
│   ├── display/
│   │   └── pages/
│   │       └── fullscreen_display_page.dart
│   │
│   └── settings/
│
└── assets/
    ├── pets/
    │   ├── cat/
    │   ├── bear/
    │   ├── dog/
    │   ├── rabbit/
    │   ├── dinosaur/
    │   ├── penguin/
    │   └── robot/
    │
    ├── expressions/
    ├── animations/
    ├── icons/
    └── backgrounds/
```

------------------------------------------------------------------------

# 17. UI 设计系统

## 17.1 视觉关键词

``` text
深色
车载
科技
温暖
陪伴
玻璃拟态
柔和发光
圆角
轻量
```

## 17.2 推荐颜色

``` text
Background:
#07101C

Surface:
#101C2B

Surface Secondary:
#16263A

Primary:
#75B9FF

Text:
#FFFFFF

Text Secondary:
#91A2B7

Border:
rgba(255,255,255,0.08)
```

注意：颜色应该集中定义在 `AppColors`，不要散落在 Widget 中。

------------------------------------------------------------------------

# 18. 响应式与横竖屏

Flutter 需要同时处理：

``` text
Portrait
Landscape
```

不要简单地通过大量 `if (orientation == ...)` 拼页面。

建议：

``` dart
OrientationBuilder(
  builder: (context, orientation) {
    if (orientation == Orientation.landscape) {
      return const LandscapeHomePage();
    }

    return const PortraitHomePage();
  },
);
```

同时结合：

``` dart
MediaQuery.sizeOf(context)
```

根据屏幕宽高比例调整布局。

------------------------------------------------------------------------

# 19. 横屏设计比例

目标设备：

``` text
手机横屏
19.5:9
20:9
16:9
```

核心区域：

``` text
左上：
Logo + 产品 Slogan

中间：
宠物舞台

中下：
宠物情绪文案

底部：
快捷表达

右上：
连接状态 / 设置
```

不要把重要信息贴近屏幕边缘。

------------------------------------------------------------------------

# 20. 首页交互流程

``` text
启动 App
 ↓
读取当前宠物
 ↓
加载首页
 ↓
用户选择：
 ├── 谢谢
 ├── 收到
 ├── 再见
 ├── 爱你
 ├── 行车
 ├── 搞怪
 └── 更多
        ↓
    Expression
        ↓
 PetState Animation
        ↓
 FullscreenDisplay
        ↓
   显示完成
        ↓
     返回首页
```

------------------------------------------------------------------------

# 21. 宠物选择流程

``` text
我的
 ↓
我的宠物
 ↓
宠物列表
 ↓
选择KK
 ↓
预览动画
 ↓
设为我的宠物
 ↓
保存本地
```

首次启动：

``` text
欢迎来到小语
       ↓
选择你的陪伴伙伴
       ↓
🐱 🐻 🐶 🐰 🦖 🐧 🤖
       ↓
开始使用
```

------------------------------------------------------------------------

# 22. 本地数据

V1.0 不要求登录。

数据全部本地保存：

``` text
currentPetId
favoriteExpressions
recentExpressions
customExpressions
firstLaunch
settings
```

示例：

``` json
{
  "currentPetId": "cat",
  "favoriteExpressions": [
    "thank_you",
    "receive",
    "goodbye"
  ],
  "recentExpressions": [
    "thank_you",
    "sorry"
  ]
}
```

------------------------------------------------------------------------

# 23. 屏幕常亮

全屏显示页面必须防止系统自动息屏。

抽象成：

``` dart
class ScreenService {
  Future<void> keepAwake();

  Future<void> allowSleep();
}
```

进入全屏：

``` text
keepAwake()
```

退出：

``` text
allowSleep()
```

同时处理：

-   iOS
-   Android

平台差异通过 Flutter Plugin 或平台 Channel 隔离。

------------------------------------------------------------------------

# 24. 系统 UI

全屏显示：

``` text
Status Bar → 隐藏
Navigation Bar → 隐藏
App Bar → 隐藏
```

退出全屏后恢复。

注意不要让全局 App 状态永久保持沉浸式，否则会影响普通页面。

------------------------------------------------------------------------

# 25. 后续 BLE 架构

V2 接入硬件后：

``` text
Flutter
   │
   ↓
BluetoothService
   │
   ↓
BLE GATT
   │
   ↓
ESP32
   │
   ↓
LED Matrix
```

建议 BLE 协议从第一版就预留。

例如：

``` text
Service UUID

Characteristic:
WRITE
NOTIFY
```

数据：

``` json
{
  "type": "expression",
  "id": "thank_you",
  "animation": "fade",
  "duration": 5000
}
```

未来不要让 Flutter UI 直接处理 BLE 数据。

------------------------------------------------------------------------

# 26. 硬件显示协议建议

最终可以设计成：

``` text
[Header]
0xAA

[Version]
0x01

[Command]
0x01

[Expression ID]
0x0012

[Animation]
0x02

[Duration]
5000

[Checksum]
XXXX
```

这样未来可以支持：

``` text
表达式
文字
动画
亮度
设备配置
固件升级
```

------------------------------------------------------------------------

# 27. AI 功能预留

V1.0 不实现 AI，但接口提前预留：

``` dart
abstract class ExpressionGenerator {
  Future<CustomExpression> generate(String prompt);
}
```

未来：

``` text
用户：
“有人让我先走，帮我做一个可爱的谢谢”

        ↓

AI

        ↓

🙏
谢谢你呀！
❤️
```

然后直接：

``` text
Preview
 ↓
Fullscreen
```

------------------------------------------------------------------------

# 28. 素材规范

宠物素材不要直接依赖 Emoji。

建议每个宠物拥有：

``` text
pet/
├── idle
├── happy
├── excited
├── sorry
├── greeting
├── love
├── laughing
└── sleepy
```

例如：

``` text
assets/pets/cat/
├── cat_idle.riv
├── cat_happy.riv
├── cat_excited.riv
├── cat_sorry.riv
└── cat_greeting.riv
```

如果使用 Lottie：

``` text
cat_idle.json
cat_happy.json
...
```

------------------------------------------------------------------------

# 29. 性能要求

目标：

``` text
页面启动：
< 2 秒

普通页面：
60 FPS

动画：
优先保持 60 FPS

表情点击：
< 100ms UI反馈

进入全屏：
< 300ms

本地表情读取：
< 100ms
```

避免：

-   大量超高清 PNG
-   每次页面进入重新加载动画
-   ListView 中重复创建复杂动画
-   首页同时播放大量 Lottie
-   不必要的网络请求

------------------------------------------------------------------------

# 30. 离线能力

V1.0 核心功能应该完全离线：

``` text
✓ 首页
✓ 宠物
✓ 表情
✓ DIY
✓ 全屏
✓ 收藏
✓ 最近使用
```

没有网络也可以正常使用。

这样对于车内使用场景非常重要。

------------------------------------------------------------------------

# 31. App 权限

V1.0：

### Android

暂时不需要：

``` text
相机
定位
通讯录
麦克风
```

V2 BLE 时再增加蓝牙相关权限。

### iOS

V1.0 同样尽量减少权限。

V2 BLE 时配置 Bluetooth Usage Description。

原则：

> 能不用权限就不用权限。

------------------------------------------------------------------------

# 32. Android 发布

准备：

``` text
applicationId
版本号
App Icon
Splash Screen
签名 Keystore
Release APK
Release AAB
隐私政策
用户协议
应用截图
应用介绍
```

正式发布使用：

``` text
AAB
```

不要把 Debug APK 当正式发布包。

------------------------------------------------------------------------

# 33. iOS 发布

准备：

``` text
Bundle Identifier
App Icon
Launch Screen
Signing
Provisioning Profile
App Store Connect
Privacy Policy
App Privacy
Screenshots
Description
Age Rating
```

测试：

``` text
Flutter Debug
 ↓
iOS Simulator
 ↓
真实 iPhone
 ↓
TestFlight
 ↓
App Store
```

------------------------------------------------------------------------

# 34. App Store 产品定位

建议一句话：

> **小语，让你的情绪显示给后车。**

副标题：

> 可爱的车载陪伴宠物与情绪显示工具。

核心卖点：

``` text
🐱 可爱的陪伴宠物
💬 一句话表达心情
📱 手机横屏即可显示
✨ 丰富动态表情
🎨 自定义你的小语
🔵 未来支持车载蓝牙屏
```

------------------------------------------------------------------------

# 35. V1.0 开发阶段

## Phase 1：项目初始化

``` text
Flutter 项目
 ↓
主题
 ↓
路由
 ↓
Riverpod
 ↓
基础目录
```

## Phase 2：首页

``` text
竖屏首页
 ↓
横屏首页
 ↓
宠物舞台
 ↓
快捷表达
```

## Phase 3：宠物

``` text
宠物列表
 ↓
宠物选择
 ↓
宠物动画
 ↓
本地保存
```

## Phase 4：表情

``` text
表情分类
 ↓
表情详情
 ↓
收藏
 ↓
最近使用
```

## Phase 5：全屏

``` text
横屏
 ↓
沉浸式
 ↓
宠物动画
 ↓
表情动画
 ↓
屏幕常亮
```

## Phase 6：DIY

``` text
Emoji
 +
文字
 +
动画
 ↓
全屏
```

## Phase 7：发布

``` text
Android
 ↓
Google Play

iOS
 ↓
TestFlight
 ↓
App Store
```

------------------------------------------------------------------------

# 36. 推荐开发顺序

不要一开始就做所有页面。

第一阶段只实现：

``` text
Flutter
 ↓
横屏首页
 ↓
KK
 ↓
3 个表情
 ↓
全屏
```

必须首先实现：

``` text
点击“谢谢”
       ↓
KK开心动画
       ↓
“谢谢啦！”
       ↓
全屏显示
```

这个 Demo 跑通之后，再扩展其他功能。

------------------------------------------------------------------------

# 37. 第一版验收标准

## 首页

-   [ ] Android 正常
-   [ ] iOS 正常
-   [ ] 横屏正常
-   [ ] 竖屏正常
-   [ ] 宠物显示正常
-   [ ] 快捷表情正常

## 宠物

-   [ ] 7 个宠物
-   [ ] 可以切换
-   [ ] 当前宠物本地保存
-   [ ] 动画正常

## 表情

-   [ ] 至少 30 个
-   [ ] 分类正常
-   [ ] 收藏正常
-   [ ] 最近使用正常

## 全屏

-   [ ] 自动横屏
-   [ ] 隐藏系统 UI
-   [ ] 屏幕常亮
-   [ ] 动画流畅
-   [ ] 点击退出
-   [ ] Android/iOS 都正常

## DIY

-   [ ] Emoji
-   [ ] 自定义文字
-   [ ] 4 种动画
-   [ ] 全屏预览

------------------------------------------------------------------------

# 38. V1.0 最终用户体验

理想体验：

``` text
用户打开 App

        ↓

      🐱

“今天想说什么？”

        ↓

     🙏 谢谢

        ↓

KK开心地挥挥手

        ↓

屏幕进入横屏

        ↓

┌─────────────────────────┐
│                         │
│                         │
│          🐱             │
│                         │
│       谢谢啦！           │
│                         │
│                         │
└─────────────────────────┘

        ↓

后车看到

        ↓

点击屏幕退出
```

------------------------------------------------------------------------

# 39. V1.0 与 V2.0 的架构关系

``` text
                    小语 App
                       │
             ┌─────────┴─────────┐
             ↓                   ↓
        Phone Display        BLE Display
             │                   │
             ↓                   ↓
         手机屏幕              ESP32
                                 │
                                 ↓
                              LED Matrix
```

核心业务：

``` text
Pet
Expression
Animation
Display
```

全部独立于具体显示设备。

因此未来增加：

``` text
车载 LED
桌面小屏
背包屏
自行车屏
电动车屏
```

都可以复用同一套 App。

------------------------------------------------------------------------

# 40. 产品长期方向

最终产品不是：

> "一个显示表情的 App"。

而是：

> **一个拥有原创宠物 IP、情绪表达内容和实体显示硬件的轻量化产品。**

产品生态：

``` text
                 小语
                  │
       ┌──────────┼──────────┐
       ↓          ↓          ↓
     宠物        表情        硬件
       │          │          │
       ↓          ↓          ↓
    宠物皮肤    表情包      LED屏
       │          │          │
       └──────────┼──────────┘
                  ↓
                 AI
                  ↓
             个性化小语
```

------------------------------------------------------------------------

# 41. AI Coding 开发建议

这个项目非常适合使用 Cursor / Claude Code 等 AI Coding 工具。

不要一次把整个项目交给 AI。

推荐拆成：

``` text
Prompt 01
初始化 Flutter 项目

Prompt 02
建立 App Theme

Prompt 03
实现竖屏首页

Prompt 04
实现横屏首页

Prompt 05
实现宠物系统

Prompt 06
实现 Expression 数据模型

Prompt 07
实现全屏 Display

Prompt 08
实现 DIY

Prompt 09
实现本地存储

Prompt 10
实现 Android/iOS 横屏和屏幕常亮

Prompt 11
重构 DisplayDevice，为 BLE 做接口预留

Prompt 12
测试 + 性能优化
```

每完成一个模块就运行：

``` text
flutter analyze
flutter test
flutter build
```

不要让 AI 一次性生成几十个页面，否则后期很容易出现状态管理混乱和 UI
难以维护。

------------------------------------------------------------------------

# 42. 开发优先级

最终按照这个优先级执行：

``` text
P0
横屏首页
宠物
表情
全屏
屏幕常亮

P1
宠物切换
分类
收藏
最近使用
DIY

P2
动画丰富
更多宠物
更多表情
AI生成

P3
BLE
实体硬件
商城
账号
云同步
```

**第一版最重要的不是功能多，而是把"宠物陪伴 → 点击表达 →
手机瞬间变成小语屏"这个体验做到足够顺滑。**
