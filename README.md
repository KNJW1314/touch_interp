# Moto Edge X30 触控插值自动恢复

自动将触控插值（interpolation）设置为 4，保持 ~376Hz 高报点率，解决熄屏/重启后掉回 180Hz 的问题。

## 文件说明

| 文件 | 用途 |
|---|---|
| `service.sh` | KernelSU 模块主脚本，开机自动运行，每 2 秒强制重写插值 |
| `module.prop` | KernelSU 模块信息 |
| `v1-v4.sh` | 历史迭代版本（参考用） |

## 安装

### 方法一：KernelSU 模块（推荐）

```bash
adb push touch_interp /data/adb/modules/
adb shell su -c 'chmod 755 /data/adb/modules/touch_interp/service.sh'
adb shell su -c 'reboot'
```

### 方法二：手动部署

```bash
adb push service.sh /data/local/tmp/
adb shell su -c 'setsid sh /data/local/tmp/service.sh &'
```

## 验证

```bash
adb shell su -c 'cat /sys/class/touchscreen/primary/interpolation'
# 期望输出: 0x04
```

## 日志

```bash
adb shell su -c 'cat /data/local/tmp/touch_interp.log'
```

## 技术说明

详见 [REPORT_RATE_ANALYSIS.md](REPORT_RATE_ANALYSIS.md)

## 致谢

基于 ST FTS3639 触控 IC 驱动逆向分析，发现熄屏后 `fts_mmi_post_resume` 会清零插值状态但节点缓存保持 0x04，导致节点值与实际 IC 状态脱节。v4 采用无条件强制重写方案绕过此问题。
