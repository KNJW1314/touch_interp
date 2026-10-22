#!/system/bin/sh
# 触控插值自动恢复 v4 - 强制周期性重写（不信任节点值）
INTERP=/sys/class/touchscreen/primary/interpolation
LOG=/data/local/tmp/touch_interp.log

log() { echo "$(date '+%m-%d %H:%M:%S') $*" >> $LOG; }

# 强制重写：先写0清缓存，再写4真正下发IC
force_rewrite() {
    [ -e "$INTERP" ] || return 1
    echo 0 > $INTERP 2>/dev/null
    echo 4 > $INTERP 2>/dev/null
    return 0
}

log "=== v4 启动（强制重写模式）==="

# 等待节点出现
n=0
while [ $n -lt 180 ]; do
    if [ -e "$INTERP" ]; then
        force_rewrite
        log "节点就绪，首次写入完成 (等待 ${n}秒)"
        break
    fi
    n=$((n+1))
    sleep 1
done

if [ $n -ge 180 ]; then
    log "!!! 180秒未就绪，退出 !!!"
    exit 1
fi

# 核心：每 2 秒无条件强制重写（不管节点值是什么）
cnt=0
while true; do
    force_rewrite
    cnt=$((cnt+1))
    # 每 30 次（60秒）记一次日志，避免刷屏
    if [ $((cnt % 30)) -eq 0 ]; then
        log "强制重写运行中 (已执行 ${cnt} 次, 当前=$(cat $INTERP 2>/dev/null))"
    fi
    sleep 2
done