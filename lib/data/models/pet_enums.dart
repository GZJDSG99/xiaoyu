/// 宠物状态机
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

/// 用户触发的宠物动作事件
enum PetAction {
  thank,
  receive,
  goodbye,
  love,
  sorry,
  warning,
  encourage,
  laugh,
  sleep,
  custom,
}

/// 全屏文字/表情动画类型
enum DisplayAnimation {
  fade,
  scale,
  slide,
  bounce,
  typewriter,
  pulse,
  breath,
}
