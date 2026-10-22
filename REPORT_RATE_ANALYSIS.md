# Moto Edge X30 (XT2201-2) 触控采样率分析报告

## 设备信息

- 机型: Motorola Edge X30 (hiphic_cn)
- 触控 IC: STMicroelectronics FTS3639
- 面板: CSOT
- 固件: `stmicro-csot-fts3639-22010628-ab151028-hiphic.ftb`

## 采样率体系

### 原生档位
- 基础扫描率: ~180Hz
- 实测插值关闭: **175Hz** (间隔 5.7ms)

### 插值档位
- 设备树 `st,interpolation_cmd = c0 05 00 01 50 0c 04 0e 01 10`
- 插值开 (interpolation=4): **~354-376Hz** (间隔 2.8ms)
- 576Hz 为营销等效值（144Hz 屏 × 4），实际驱动上限 ~360Hz

## 配置节点

```
/sys/class/touchscreen/primary/interpolation   ← 插值开关/档位 (0-4)
/sys/class/touchscreen/primary/refresh_rate     ← 报告率 (只写)
/sys/class/touchscreen/primary/sensitivity      ← 灵敏度
/sys/class/touchscreen/primary/edge             ← 边缘抑制
```

## 驱动模块

```
/vendor/lib/modules/stmicro_mmi.ko       (631KB, 带符号)
/vendor/lib/modules/touchscreen_mmi.ko   (131KB)
```

关键函数:
- `fts_mmi_interpolation_store` - 写入插值
- `fts_mmi_post_resume` - 熄屏唤醒恢复（会清零插值）
- `fts_mmi_set_report_rate` - 设置报告率

## 问题根因

熄屏后 `fts_mmi_post_resume` 将 IC 插值状态清零，但 sysfs 节点缓存保持原值（0x04），
导致 `cat` 节点显示 0x04 但 IC 实际工作在 175Hz。

**节点缓存 ≠ IC 实际状态**

## 解决方案

v4: 每 2 秒无条件强制重写 `echo 0 > ...; echo 4 > ...`，绕过节点缓存判断。

内核日志确认写入成功:
```
fts_mmi_set_report_rate: Successfully to set inpolation = 0
fts_mmi_set_report_rate: Successfully to set inpolation = 4
fts_status_event_handler Echo event of command = C0 05 04 01 00 00
```
