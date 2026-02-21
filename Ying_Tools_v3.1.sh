#!/system/bin/sh
# =============================================================================
# Y i n g   T o o l s   V3.1
# Author: 映宫香织 (Ying)
# Emali: 177286017@qq.com
# 欢迎使用此脚本
# =============================================================================
if [ -t 1 ] && command -v tput >/dev/null 2>&1 && [ "$(tput colors)" -ge 8 ]; then
    BOLD=$(tput bold); RED=$(tput setaf 1); GREEN=$(tput setaf 2); YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4); MAGENTA=$(tput setaf 5); CYAN=$(tput setaf 6); WHITE=$(tput setaf 7)
    RESET=$(tput sgr0)
else
    BOLD='\033[1m'; RED='\033[31m'; GREEN='\033[32m'; YELLOW='\033[33m'
    BLUE='\033[34m'; MAGENTA='\033[35m'; CYAN='\033[36m'; WHITE='\033[37m'
    RESET='\033[0m'
fi

has_root=false; [ -d "/data/adb" ] && has_root=true
active_slot="未知"

start_action() { echo "${YELLOW}${BOLD}➤ $1${RESET}"; }
action_ok() { echo "${GREEN}${BOLD}✓ $1${RESET}"; }
action_fail() { echo "${RED}${BOLD}✗ $1${RESET}"; }
action_info() { echo "${CYAN}${BOLD}ℹ $1${RESET}"; }

check_root() {
    if ! $has_root; then
        action_fail "设备未Root，此功能需要Root权限"
        return 1
    fi
    return 0
}

find_partition_node() {
    local part_name="$1"
    local node=""
    for base in /dev/block/by-name /dev/block/bootdevice/by-name /dev/block/platform/*/by-name; do
        [ -e "$base/$part_name" ] && node="$base/$part_name" && break
    done
    [ -z "$node" ] && node=$(find /dev/block -name "$part_name" -o -name "*$part_name*" 2>/dev/null | head -1)
    echo "$node"
}

get_partition_size_bytes() {
    local node="$1"
    local size=""

    if command -v blockdev >/dev/null 2>&1; then
        size=$(blockdev --getsize64 "$node" 2>/dev/null)
        [ -n "$size" ] && { echo "$size"; return; }
    fi

    local major_minor=$(stat -L -c '%t:%T' "$node" 2>/dev/null)
    if [ -n "$major_minor" ]; then
        local major_hex=${major_minor%:*}
        local minor_hex=${major_minor#*:}
        local major_dec=$((16#$major_hex))
        local minor_dec=$((16#$minor_hex))
        size=$(awk -v maj=$major_dec -v min=$minor_dec '$1==maj && $2==min {print $3}' /proc/partitions)
        if [ -n "$size" ]; then
            echo $((size * 512))
            return
        fi
    fi

    local real_path=$(readlink -f "$node")
    local dev_name=$(basename "$real_path")
    if [ -e "/sys/block/$dev_name/size" ]; then
        local blocks=$(cat "/sys/block/$dev_name/size" 2>/dev/null)
        if [ -n "$blocks" ]; then
            echo $((blocks * 512))
            return
        fi
    fi

    echo ""
}

format_size() {
    local bytes=$1
    if [ -z "$bytes" ] || [ "$bytes" -le 0 ]; then
        echo "??"
        return
    fi
    if command -v numfmt >/dev/null 2>&1; then
        numfmt --to=iec "$bytes" 2>/dev/null || echo "??"
    else
        if [ $bytes -ge 1073741824 ]; then
            echo "$((bytes / 1073741824))G"
        elif [ $bytes -ge 1048576 ]; then
            echo "$((bytes / 1048576))M"
        elif [ $bytes -ge 1024 ]; then
            echo "$((bytes / 1024))K"
        else
            echo "${bytes}B"
        fi
    fi
}

show_disclaimer() {
    clear
    echo "${RED}${BOLD}════════════════════════════════════════════════════${RESET}"
    echo "${RED}${BOLD}                 ⚠️ 重要风险提示 ⚠️                           ${RESET}"
    echo "${RED}${BOLD}════════════════════════════════════════════════════${RESET}"
    echo ""
    echo "${YELLOW}操作存在以下风险：${RESET}"
    echo "${YELLOW}  • 设备变砖、无法启动${RESET}"
    echo "${YELLOW}  • 数据完全丢失${RESET}"
    echo "${YELLOW}  • 部分功能失效（如相机、指纹等）${RESET}"
    echo "${YELLOW}  • 安全风险（如解锁后安全性降低）${RESET}"
    echo "${YELLOW}  • 保修失效${RESET}"
    echo ""
    echo "${WHITE}操作前请务必：${RESET}"
    echo "${WHITE}  1. 将所有重要数据（联系人、照片、文档等）完整备份至电脑或云端${RESET}"
    echo "${WHITE}  2. 确保设备电量充足（建议 >50%）${RESET}"
    echo "${WHITE}  3. 熟悉救砖方法（如 fastboot 刷机）${RESET}"
    echo ""
    echo "${CYAN}本工具仅供学习交流，请于24小时内删除。${RESET}"
    echo "${RED}作者及发布者不承担任何因使用本资源导致的直接或间接损失，${RESET}"
    echo "${RED}包括但不限于变砖、数据丢失、硬件损坏等。${RESET}"
    echo ""
    echo "${YELLOW}如你无法承担上述风险或不同意本声明，请立即停止操作。${RESET}"
    echo ""
    echo -n "${BOLD}是否接受上述风险并继续？ (y/n) ${RESET}"
}

boot_animation() {
    clear
    echo "${CYAN}${BOLD}══════════════════════════════════════════════${RESET}"
    echo "${CYAN}${BOLD}         Y i n g   T o o l s   v3.1         ${RESET}"
    echo "${CYAN}${BOLD}══════════════════════════════════════════════${RESET}"
    echo ""
    local spin='|/-\'
    for i in 1 2 3 4 5 6 7 8 9 10; do
        printf "\r${YELLOW}正在加载中… [%-10s] %d%% ${spin:$((i%4)):1}${RESET}" \
               "$(printf '#%.0s' $(seq 1 $i))" $((i*10))
        sleep 0.1
    done
    printf "\n${GREEN}${BOLD}✓ 加载:   完成！ ${RESET}\n"
    sleep 0.5
    printf "\n${GREEN}${BOLD}✓ 版本:   V3.1   ${RESET}\n"
    sleep 1
    printf "\n${GREEN}${BOLD}✓ 校验:   OKAY  ${RESET}\n"
    sleep 1
    clear
}

show_logo() {
    echo "${MAGENTA}${BOLD}"
    echo "██╗   ██╗██╗███╗   ██╗ ██████╗ "
    echo "╚██╗ ██╔╝██║████╗  ██║██╔════╝ "
    echo " ╚████╔╝ ██║██╔██╗ ██║██║  ███╗"
    echo "  ╚██╔╝  ██║██║╚██╗██║██║   ██║"
    echo "   ██║   ██║██║ ╚████║╚██████╔╝"
    echo "   ╚═╝   ╚═╝╚═╝  ╚═══╝ ╚═════╝ "
    echo "${RESET}"
    echo "${GREEN}${BOLD}作者：映宫香织${RESET}    ${YELLOW}${BOLD}当前时间：$(date +"%Y-%m-%d %H:%M:%S")${RESET}"
    echo "────────────────────────────────────────────"
}

get_device_info() {
    start_action "正在采集设备信息..."
    brand=$(getprop ro.product.brand 2>/dev/null || getprop ro.product.manufacturer 2>/dev/null)
    model=$(getprop ro.product.model 2>/dev/null)
    device_model="${brand} ${model}"; [ -z "$brand" ] && device_model="$model"; [ -z "$model" ] && device_model="未知"
    kernel=$(uname -r 2>/dev/null || echo "未知")
    android=$(getprop ro.build.version.release 2>/dev/null || echo "未知")
    if [ -r /proc/meminfo ]; then
        mem_kb=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
        mem_gb=$(awk "BEGIN {printf \"%.1f\", $mem_kb/1024/1024}")
    else
        mem_gb="未知"
    fi
    if df -k /data >/dev/null 2>&1; then
        set -- $(df -k /data | tail -1 | awk '{print $2,$3,$4}')
        total_kb=$1; used_kb=$2; avail_kb=$3
        total_gb=$(( (total_kb + 512*1024) / 1024 / 1024 ))
        used_gb=$(( (used_kb + 512*1024) / 1024 / 1024 ))
        avail_gb=$(( (avail_kb + 512*1024) / 1024 / 1024 ))
        storage="${total_gb}G（已用 ${used_gb}G，可用 ${avail_gb}G）"
    else
        storage="未知"
    fi
    if command -v bootctl >/dev/null 2>&1 && $has_root; then
        slot_num=$(bootctl get-current-slot 2>/dev/null)
        [ -n "$slot_num" ] && active_slot=$(bootctl get-suffix "$slot_num" 2>/dev/null)
    fi
    [ -z "$active_slot" ] || [ "$active_slot" = "未知" ] && active_slot=$(getprop ro.boot.slot_suffix 2>/dev/null)
    if [ -z "$active_slot" ] || [ "$active_slot" = "未知" ] && [ -r /proc/cmdline ]; then
        active_slot=$(cat /proc/cmdline | tr ' ' '\n' | grep -i 'androidboot.slot_suffix' | cut -d= -f2)
    fi
    [ -z "$active_slot" ] || [ "$active_slot" = "未知" ] && active_slot="不支持 A/B"
    root_status=$($has_root && echo "${GREEN}已 Root${RESET}" || echo "${RED}未 Root${RESET}")
    bb1=$(getprop gsm.version.baseband 2>/dev/null); bb2=$(getprop gsm.version.baseband2 2>/dev/null); bb3=$(getprop ro.baseband 2>/dev/null)
    baseband_list=""; for bb in "$bb1" "$bb2" "$bb3"; do
        if [ -n "$bb" ] && [ "$bb" != "unknown" ] && [ "$bb" != "Unknown" ]; then
            case "$baseband_list" in *"$bb"*) ;; *) [ -z "$baseband_list" ] && baseband_list="$bb" || baseband_list="${baseband_list},${bb}";; esac
        fi
    done; [ -z "$baseband_list" ] && baseband_list="未知"
    action_ok "信息采集完成"
}

show_info() {
    echo "${CYAN}${BOLD}═══════════════ 设备信息 ═══════════════${RESET}"
    echo "${BLUE}${BOLD}手机型号${RESET} : ${YELLOW}$device_model${RESET}"
    echo "${BLUE}${BOLD}内存总量${RESET} : ${YELLOW}$mem_gb GB${RESET}"
    echo "${BLUE}${BOLD}内部存储${RESET} : ${YELLOW}$storage${RESET}"
    echo "${BLUE}${BOLD}安卓版本${RESET} : ${YELLOW}$android${RESET}"
    echo "${BLUE}${BOLD}内核版本${RESET} : ${YELLOW}$kernel${RESET}"
    echo "${BLUE}${BOLD}当前槽位${RESET} : ${YELLOW}$active_slot${RESET}"
    echo -n "${BLUE}${BOLD}Root状态${RESET} : "; echo "$root_status"
    echo "${BLUE}${BOLD}基带版本${RESET} : ${YELLOW}$baseband_list${RESET}"
    echo "${CYAN}${BOLD}══════════════════════════════════════════${RESET}"
}

flash_partition() {
    check_root || return 1
    echo ""; echo "${MAGENTA}${BOLD}══════ 刷写分区 ══════${RESET}"
    printf "${YELLOW}${BOLD}请输入分区名 (例如 boot, system, vendor): ${RESET}"; read part_name
    [ -z "$part_name" ] && { action_fail "分区名不能为空"; return 1; }

    local ab_supported=false
    if [ "$active_slot" != "不支持 A/B" ]; then
        ab_supported=true
    fi

    local target_parts=""
    if $ab_supported; then
        if echo "$part_name" | grep -qE '_(a|b)$'; then
            target_parts="$part_name"
        else
            echo "${CYAN}检测到设备支持 A/B 分区${RESET}"
            printf "${YELLOW}${BOLD}请选择要刷写的槽位 [a/b/ab]: ${RESET}"; read slot_choice
            case $slot_choice in
                a) target_parts="${part_name}_a" ;;
                b) target_parts="${part_name}_b" ;;
                ab) target_parts="${part_name}_a ${part_name}_b" ;;
                *) action_fail "无效选择"; return 1 ;;
            esac
        fi
    else
        target_parts="$part_name"
    fi

    for current_part in $target_parts; do
        echo ""
        start_action "处理分区: $current_part"
        part_node=$(find_partition_node "$current_part")
        if [ -z "$part_node" ]; then
            action_fail "未找到分区: $current_part"
            continue
        fi
        action_ok "找到分区节点: $part_node"
        printf "${YELLOW}${BOLD}请输入镜像文件路径 (用于 $current_part): ${RESET}"; read img_path
        [ ! -f "$img_path" ] && { action_fail "文件不存在"; continue; }
        printf "${RED}${BOLD}确认刷写 $current_part？(yes/no): ${RESET}"; read confirm
        [ "$confirm" != "yes" ] && { action_info "已取消 $current_part"; continue; }
        start_action "正在刷写 $current_part ..."
        dd if="$img_path" of="$part_node" bs=4M 2>&1 && { sync; action_ok "刷写成功！"; } || action_fail "刷写失败！"
    done
}

backup_partition() {
    check_root || return 1
    echo ""; echo "${MAGENTA}${BOLD}══════ 备份分区 ══════${RESET}"
    printf "${YELLOW}${BOLD}请输入分区名: ${RESET}"; read part_name
    [ -z "$part_name" ] && { action_fail "分区名不能为空"; return 1; }

    local ab_supported=false
    if [ "$active_slot" != "不支持 A/B" ]; then
        ab_supported=true
    fi

    local target_parts=""
    if $ab_supported; then
        if echo "$part_name" | grep -qE '_(a|b)$'; then
            target_parts="$part_name"
        else
            echo "${CYAN}检测到设备支持 A/B 分区${RESET}"
            printf "${YELLOW}${BOLD}请选择要备份的槽位 [a/b/ab]: ${RESET}"; read slot_choice
            case $slot_choice in
                a) target_parts="${part_name}_a" ;;
                b) target_parts="${part_name}_b" ;;
                ab) target_parts="${part_name}_a ${part_name}_b" ;;
                *) action_fail "无效选择"; return 1 ;;
            esac
        fi
    else
        target_parts="$part_name"
    fi

    for current_part in $target_parts; do
        echo ""
        start_action "处理分区: $current_part"
        part_node=$(find_partition_node "$current_part")
        if [ -z "$part_node" ]; then
            action_fail "未找到分区: $current_part"
            continue
        fi
        action_ok "找到分区节点: $part_node"
        local default_path="/sdcard/${current_part}_$(date +%Y%m%d_%H%M%S).img"
        printf "${YELLOW}${BOLD}保存路径 [回车默认: $default_path]: ${RESET}"; read save_path
        [ -z "$save_path" ] && save_path="$default_path"
        [ -f "$save_path" ] && { action_fail "文件已存在"; continue; }
        printf "${YELLOW}${BOLD}确认备份 $current_part？(y/n): ${RESET}"; read confirm
        [ "$confirm" != "y" ] && [ "$confirm" != "Y" ] && { action_info "已取消 $current_part"; continue; }
        start_action "正在备份 $current_part ..."
        dd if="$part_node" of="$save_path" bs=4M 2>&1 && { sync; action_ok "备份成功！"; } || action_fail "备份失败！"
    done
}

backup_full_firmware() {
    check_root || return 1
    echo ""
    echo "${MAGENTA}${BOLD}══════════════════ 字库备份(测试版) ══════════════════${RESET}"

    DEFAULT_EXCLUDE="userdata sdc sdcard cache metadata"
    echo ""
    echo "${CYAN}默认排除的数据分区:${RESET} $DEFAULT_EXCLUDE"
    printf "${YELLOW}${BOLD}是否要自定义排除列表？(y/n): ${RESET}"; read custom_exclude
    local exclude_list="$DEFAULT_EXCLUDE"
    if [ "$custom_exclude" = "y" ] || [ "$custom_exclude" = "Y" ]; then
        printf "${YELLOW}${BOLD}请输入要排除的分区名（空格分隔）: ${RESET}"; read exclude_list
    fi

    start_action "正在读取分区..."
    local partition_list=""
    if [ -d /dev/block/by-name ]; then
        partition_list=$(ls /dev/block/by-name/ 2>/dev/null)
    elif [ -d /dev/block/bootdevice/by-name ]; then
        partition_list=$(ls /dev/block/bootdevice/by-name/ 2>/dev/null)
    else
        partition_list=$(cat /proc/partitions 2>/dev/null | awk '{print $4}' | grep -E '^[a-zA-Z]' | grep -v -E 'loop|ram|sda')
    fi

    local filtered_list=""
    for part in $partition_list; do
        case "$part" in sda*|loop*|ram*|zram*|dm-*) continue ;; esac
        local excluded=0
        for e in $exclude_list; do
            if [ "$part" = "$e" ]; then
                excluded=1
                break
            fi
        done
        [ $excluded -eq 1 ] && continue
        filtered_list="$filtered_list $part"
    done

    local total=$(echo $filtered_list | wc -w)
    if [ $total -eq 0 ]; then
        action_fail "没有可备份的分区（全部被排除或不可读）"
        return 1
    fi
    action_ok "共找到 $total 个可备份分区"

    local backup_base="/sdcard/Ying-backup"
    mkdir -p "$backup_base"

    local avail_kb=$(df -P "$backup_base" 2>/dev/null | tail -1 | awk '{print $4}')
    if [ -z "$avail_kb" ] || [ "$avail_kb" = "可用" ] || [ "$avail_kb" = "Available" ]; then
        avail_kb=$(df -k "$backup_base" 2>/dev/null | tail -1 | awk '{print $4}')
    fi
    if [ -z "$avail_kb" ] || ! [ "$avail_kb" -gt 0 ] 2>/dev/null; then
        action_fail "无法获取目标目录可用空间"
        return 1
    fi
    local avail_bytes=$((avail_kb * 1024))

    action_info "正在计算所有分区总大小..."
    local total_bytes=0
    local unknown_parts=""
    for part in $filtered_list; do
        node=$(find_partition_node "$part")
        if [ -z "$node" ]; then
            action_info "分区 $part 无对应节点，跳过"
            continue
        fi
        size=$(get_partition_size_bytes "$node")
        if [ -n "$size" ] && [ "$size" -gt 0 ]; then
            total_bytes=$((total_bytes + size))
        else
            unknown_parts="$unknown_parts $part"
        fi
    done

    if [ -n "$unknown_parts" ]; then
        action_fail "以下分区大小未知：$unknown_parts"
        printf "${YELLOW}${BOLD}是否继续？（空间估算可能不准）(y/n): ${RESET}"; read force
        if [ "$force" != "y" ] && [ "$force" != "Y" ]; then
            action_info "已取消备份"
            return 1
        fi
    fi

    action_info "待备份分区总大小: $(format_size $total_bytes)"
    action_info "目标目录可用空间: $(format_size $avail_bytes)"
    if [ $total_bytes -gt $avail_bytes ]; then
        action_fail "可用空间不足，缺少 $(format_size $((total_bytes - avail_bytes)))"
        printf "${YELLOW}${BOLD}是否继续？（可能会中途失败）(y/n): ${RESET}"; read force
        if [ "$force" != "y" ] && [ "$force" != "Y" ]; then
            action_info "已取消备份"
            return 1
        fi
    else
        action_ok "空间足够，继续备份"
    fi

    local count=0
    local success_list=""
    local fail_list=""
    local out_of_space=0

    for part in $filtered_list; do
        if [ $out_of_space -eq 1 ]; then
            action_fail "因空间不足终止后续备份"
            break
        fi

        node=$(find_partition_node "$part")
        [ -z "$node" ] && { action_info "分区 $part 无对应节点，跳过"; continue; }

        if ! dd if="$node" of=/dev/null bs=4M count=1 2>/dev/null; then
            action_info "分区 $part 不可读，跳过"
            continue
        fi

        count=$((count + 1))
        size=$(get_partition_size_bytes "$node")
        size_str=$(format_size "$size")

        echo ""; action_info "[$count/$total] 正在备份: $part ($size_str)"
        local img_file="$backup_base/${part}.img"

        dd if="$node" of="$img_file" bs=4M 2>&1
        local dd_exit=$?
        sync

        if [ $dd_exit -eq 0 ]; then
            action_ok "✓ $part 备份成功"
            success_list="$success_list $part"
            if command -v md5sum >/dev/null 2>&1; then
                md5sum "$img_file" | awk '{print $1}' > "${img_file}.md5"
            fi
        else
            if [ $dd_exit -eq 1 ] && [ -f "$img_file" ] && tail -1 "$img_file" 2>/dev/null | grep -q "No space left"; then
                action_fail "磁盘空间不足，终止备份"
                out_of_space=1
                fail_list="$fail_list $part"
                rm -f "$img_file"
                break
            else
                action_fail "✗ $part 备份失败"
                fail_list="$fail_list $part"
            fi
        fi
    done

    local info_file="$backup_base/Ying-tool备份.txt"
    {
        echo "=============================================="
        echo "          Ying-tool 备份信息"
        echo "=============================================="
        echo "备份时间: $(date)"
        echo "设备型号: $device_model"
        echo "当前槽位: $active_slot"
        echo "读取到的分区总数: $total"
        echo "备份成功的分区数: $(echo $success_list | wc -w)"
        echo "备份失败的分区数: $(echo $fail_list | wc -w)"
        if [ -n "$fail_list" ]; then
            echo "备份失败分区列表:"
            for f in $fail_list; do echo "  - $f"; done
        fi
        echo ""
        echo "备份成功的分区:"
        for s in $success_list; do echo "  - $s"; done
        echo "=============================================="
    } > "$info_file" 2>/dev/null
    if [ $? -eq 0 ]; then
        action_ok "已生成备份信息: $info_file"
    else
        action_fail "无法写入备份信息文件（可能空间不足）"
    fi

    echo ""
    echo "${GREEN}${BOLD}══════════════════ 备份完成 ══════════════════${RESET}"
    action_ok "成功备份: $(echo $success_list | wc -w) 个分区"
    if [ -n "$fail_list" ]; then
        action_fail "失败分区: $fail_list"
    fi
    action_info "备份目录: $backup_base"
    action_info "生成的文件:"
    action_info "  - Ying-tool备份.txt"
    echo "${YELLOW}请及时将整个Ying-backup文件夹复制到电脑！${RESET}"
}

enable_adb() {
    start_action "正在开启 USB 调试..."
    command -v settings >/dev/null 2>&1 && settings put global adb_enabled 1 && action_ok "USB调试已开启" || action_fail "开启失败"
}
disable_adb() {
    start_action "正在关闭 USB 调试..."
    command -v settings >/dev/null 2>&1 && settings put global adb_enabled 0 && action_ok "USB调试已关闭" || action_fail "关闭失败"
}
reboot_fastboot() {
    echo ""; action_info "即将重启到引导模式"
    printf "${YELLOW}${BOLD}确认重启？(y/n): ${RESET}"; read confirm
    [ "$confirm" = "y" ] || [ "$confirm" = "Y" ] && { start_action "正在重启..."; reboot bootloader; } || action_info "已取消"
}

show_menu() {
    echo ""
    echo "${MAGENTA}${BOLD}══════════════════ 功能菜单 ══════════════════${RESET}"
    echo "${GREEN}${BOLD} 1.${RESET} 刷写分区"
    echo "${GREEN}${BOLD} 2.${RESET} 备份分区"
    echo "${GREEN}${BOLD} 3.${RESET} 字库备份"
    echo "${GREEN}${BOLD} 4.${RESET} 开启调试"
    echo "${GREEN}${BOLD} 5.${RESET} 关闭调试"
    echo "${GREEN}${BOLD} 6.${RESET} 引导模式"
    echo "${GREEN}${BOLD} 7.${RESET} 退出脚本"
    echo "${MAGENTA}${BOLD}══════════════════════════════════════════════${RESET}"
    echo -n "${BOLD}请选择操作 [1-7]: ${RESET}"
}

menu_loop() {
    while true; do
        show_menu; read choice
        case $choice in
            1) flash_partition ;;
            2) backup_partition ;;
            3) backup_full_firmware ;;
            4) enable_adb ;;
            5) disable_adb ;;
            6) reboot_fastboot ;;
            7) action_ok "感谢使用，再见！"; exit 0 ;;
            *) action_fail "无效选项，请重新输入"; sleep 1 ;;
        esac
        echo ""; printf "${YELLOW}按回车键继续...${RESET}"; read dummy
    done
}

main() {
    show_disclaimer; read ans
    case $ans in n|N) echo "${GREEN}已退出。${RESET}"; exit 0 ;; y|Y) ;; *) echo "${RED}无效输入，已退出。${RESET}"; exit 1 ;; esac
    boot_animation
    show_logo
    get_device_info
    show_info
    echo ""; printf "${BOLD}是否进入功能菜单？(y/n): ${RESET}"; read ans
    case $ans in y|Y) menu_loop ;; *) action_ok "直接退出。" ; exit 0 ;; esac
}

main