# 小语（xiaoyu / CarTalk）

把手机变成「车载情绪显示器」的 Flutter App。

## 技术栈

- Flutter + Dart
- 状态管理：Riverpod
- 路由：go_router
- 本地存储：shared_preferences + Hive
- 屏幕常亮：wakelock_plus

## 目录结构

```text
lib/
├── app/          # App 入口、路由、主题
├── core/         # 常量、工具、屏幕服务
├── data/         # Model / Repository / LocalStorage
├── domain/       # DisplayDevice 抽象与业务 Service
└── features/     # 首页 / 表情 / 宠物 / DIY / 全屏 / 我的
```

## 运行

需已安装 Flutter SDK，并将 `flutter` 加入 PATH。

```bash
flutter pub get
flutter run
```

本机若尚未配置 PATH，可临时使用：

```powershell
$env:Path = "C:\flutter\bin;" + $env:Path
flutter run
```

## V1.0 框架说明

当前为可编译的领域骨架：

- 首次启动 → 宠物选择
- 底部导航：首页 / 表情 / DIY / 我的
- 竖屏/横屏首页切换
- 全屏显示占位（常亮 + 沉浸式）
- DisplayDevice 抽象（Phone / 预留 BLE）

业务动画与原创素材尚未接入，详见 `小语_App_V1.0_Flutter开发文档.md`。
