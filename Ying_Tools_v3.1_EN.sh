#!/system/bin/sh
# =============================================================================
# Y i n g   T o o l s   V3.1
# Author: Ying Gong Xiang Zhi (Ying)
# Email: 177286017@qq.com
# Welcome to use this script.
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
active_slot="Unknown"

start_action() { echo "${YELLOW}${BOLD}➤ $1${RESET}"; }
action_ok() { echo "${GREEN}${BOLD}✓ $1${RESET}"; }
action_fail() { echo "${RED}${BOLD}✗ $1${RESET}"; }
action_info() { echo "${CYAN}${BOLD}ℹ $1${RESET}"; }

check_root() {
    if ! $has_root; then
        action_fail "Device is not rooted, this feature requires root access"
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
    echo "${RED}${BOLD}                 ⚠️ Important Risk Notice ⚠️        ${RESET}"
    echo "${RED}${BOLD}════════════════════════════════════════════════════${RESET}"
    echo ""
    echo "${YELLOW}Operations involve the following risks:${RESET}"
    echo "${YELLOW}  • Device brick, unable to boot${RESET}"
    echo "${YELLOW}  • Complete data loss${RESET}"
    echo "${YELLOW}  • Some functions may fail (camera, fingerprint, etc.)${RESET}"
    echo "${YELLOW}  • Security risks (e.g., reduced security after unlocking)${RESET}"
    echo "${YELLOW}  • Warranty void${RESET}"
    echo ""
    echo "${WHITE}Before proceeding, make sure to:${RESET}"
    echo "${WHITE}  1. Back up all important data (contacts, photos, documents, etc.) to PC or cloud${RESET}"
    echo "${WHITE}  2. Ensure sufficient battery level (recommended >50%)${RESET}"
    echo "${WHITE}  3. Familiarize yourself with brick recovery methods (e.g., fastboot flashing)${RESET}"
    echo ""
    echo "${CYAN}This tool is for learning and communication only. Please delete within 24 hours.${RESET}"
    echo "${RED}The author and distributor assume no responsibility for any direct or indirect loss${RESET}"
    echo "${RED} caused by using this resource, including but not limited to brick, data loss, hardware damage.${RESET}"
    echo ""
    echo "${YELLOW}If you cannot bear the above risks or disagree with this statement, please stop immediately.${RESET}"
    echo ""
    echo -n "${BOLD}Do you accept the above risks and continue? (y/n) ${RESET}"
}

boot_animation() {
    clear
    echo "${CYAN}${BOLD}══════════════════════════════════════════════${RESET}"
    echo "${CYAN}${BOLD}         Y i n g   T o o l s   v3.1         ${RESET}"
    echo "${CYAN}${BOLD}══════════════════════════════════════════════${RESET}"
    echo ""
    local spin='|/-\'
    for i in 1 2 3 4 5 6 7 8 9 10; do
        printf "\r${YELLOW}Loading… [%-10s] %d%% ${spin:$((i%4)):1}${RESET}" \
               "$(printf '#%.0s' $(seq 1 $i))" $((i*10))
        sleep 0.1
    done
    printf "\n${GREEN}${BOLD}✓ Load:   Done! ${RESET}\n"
    sleep 0.5
    printf "\n${GREEN}${BOLD}✓ Version: V3.1   ${RESET}\n"
    sleep 1
    printf "\n${GREEN}${BOLD}✓ Check:   OKAY  ${RESET}\n"
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
    echo "${GREEN}${BOLD}Author: Ying Gong Xiang Zhi${RESET}    ${YELLOW}${BOLD}Current time: $(date +"%Y-%m-%d %H:%M:%S")${RESET}"
    echo "────────────────────────────────────────────"
}

get_device_info() {
    start_action "Collecting device info..."
    brand=$(getprop ro.product.brand 2>/dev/null || getprop ro.product.manufacturer 2>/dev/null)
    model=$(getprop ro.product.model 2>/dev/null)
    device_model="${brand} ${model}"; [ -z "$brand" ] && device_model="$model"; [ -z "$model" ] && device_model="Unknown"
    kernel=$(uname -r 2>/dev/null || echo "Unknown")
    android=$(getprop ro.build.version.release 2>/dev/null || echo "Unknown")
    if [ -r /proc/meminfo ]; then
        mem_kb=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
        mem_gb=$(awk "BEGIN {printf \"%.1f\", $mem_kb/1024/1024}")
    else
        mem_gb="Unknown"
    fi
    if df -k /data >/dev/null 2>&1; then
        set -- $(df -k /data | tail -1 | awk '{print $2,$3,$4}')
        total_kb=$1; used_kb=$2; avail_kb=$3
        total_gb=$(( (total_kb + 512*1024) / 1024 / 1024 ))
        used_gb=$(( (used_kb + 512*1024) / 1024 / 1024 ))
        avail_gb=$(( (avail_kb + 512*1024) / 1024 / 1024 ))
        storage="${total_gb}G (Used ${used_gb}G, Available ${avail_gb}G)"
    else
        storage="Unknown"
    fi
    if command -v bootctl >/dev/null 2>&1 && $has_root; then
        slot_num=$(bootctl get-current-slot 2>/dev/null)
        [ -n "$slot_num" ] && active_slot=$(bootctl get-suffix "$slot_num" 2>/dev/null)
    fi
    [ -z "$active_slot" ] || [ "$active_slot" = "Unknown" ] && active_slot=$(getprop ro.boot.slot_suffix 2>/dev/null)
    if [ -z "$active_slot" ] || [ "$active_slot" = "Unknown" ] && [ -r /proc/cmdline ]; then
        active_slot=$(cat /proc/cmdline | tr ' ' '\n' | grep -i 'androidboot.slot_suffix' | cut -d= -f2)
    fi
    [ -z "$active_slot" ] || [ "$active_slot" = "Unknown" ] && active_slot="A/B not supported"
    root_status=$($has_root && echo "${GREEN}Rooted${RESET}" || echo "${RED}Not rooted${RESET}")
    bb1=$(getprop gsm.version.baseband 2>/dev/null); bb2=$(getprop gsm.version.baseband2 2>/dev/null); bb3=$(getprop ro.baseband 2>/dev/null)
    baseband_list=""; for bb in "$bb1" "$bb2" "$bb3"; do
        if [ -n "$bb" ] && [ "$bb" != "unknown" ] && [ "$bb" != "Unknown" ]; then
            case "$baseband_list" in *"$bb"*) ;; *) [ -z "$baseband_list" ] && baseband_list="$bb" || baseband_list="${baseband_list},${bb}";; esac
        fi
    done; [ -z "$baseband_list" ] && baseband_list="Unknown"
    action_ok "Info collection complete"
}

show_info() {
    echo "${CYAN}${BOLD}═══════════════ Device Info ═══════════════${RESET}"
    echo "${BLUE}${BOLD}Model${RESET} : ${YELLOW}$device_model${RESET}"
    echo "${BLUE}${BOLD}RAM${RESET} : ${YELLOW}$mem_gb GB${RESET}"
    echo "${BLUE}${BOLD}Storage${RESET} : ${YELLOW}$storage${RESET}"
    echo "${BLUE}${BOLD}Android version${RESET} : ${YELLOW}$android${RESET}"
    echo "${BLUE}${BOLD}Kernel version${RESET} : ${YELLOW}$kernel${RESET}"
    echo "${BLUE}${BOLD}Current slot${RESET} : ${YELLOW}$active_slot${RESET}"
    echo -n "${BLUE}${BOLD}Root status${RESET} : "; echo "$root_status"
    echo "${BLUE}${BOLD}Baseband version${RESET} : ${YELLOW}$baseband_list${RESET}"
    echo "${CYAN}${BOLD}══════════════════════════════════════════${RESET}"
}

flash_partition() {
    check_root || return 1
    echo ""; echo "${MAGENTA}${BOLD}══════ Flash Partition ══════${RESET}"
    printf "${YELLOW}${BOLD}Enter partition name (e.g., boot, system, vendor): ${RESET}"; read part_name
    [ -z "$part_name" ] && { action_fail "Partition name cannot be empty"; return 1; }

    local ab_supported=false
    if [ "$active_slot" != "A/B not supported" ]; then
        ab_supported=true
    fi

    local target_parts=""
    if $ab_supported; then
        if echo "$part_name" | grep -qE '_(a|b)$'; then
            target_parts="$part_name"
        else
            echo "${CYAN}Device supports A/B partitions${RESET}"
            printf "${YELLOW}${BOLD}Choose slot to flash [a/b/ab]: ${RESET}"; read slot_choice
            case $slot_choice in
                a) target_parts="${part_name}_a" ;;
                b) target_parts="${part_name}_b" ;;
                ab) target_parts="${part_name}_a ${part_name}_b" ;;
                *) action_fail "Invalid choice"; return 1 ;;
            esac
        fi
    else
        target_parts="$part_name"
    fi

    for current_part in $target_parts; do
        echo ""
        start_action "Processing partition: $current_part"
        part_node=$(find_partition_node "$current_part")
        if [ -z "$part_node" ]; then
            action_fail "Partition $current_part not found"
            continue
        fi
        action_ok "Found partition node: $part_node"
        printf "${YELLOW}${BOLD}Enter image file path (for $current_part): ${RESET}"; read img_path
        [ ! -f "$img_path" ] && { action_fail "File not found"; continue; }
        printf "${RED}${BOLD}Confirm flash $current_part? (yes/no): ${RESET}"; read confirm
        [ "$confirm" != "yes" ] && { action_info "Cancelled $current_part"; continue; }
        start_action "Flashing $current_part ..."
        dd if="$img_path" of="$part_node" bs=4M 2>&1 && { sync; action_ok "Flash successful!"; } || action_fail "Flash failed!"
    done
}

backup_partition() {
    check_root || return 1
    echo ""; echo "${MAGENTA}${BOLD}══════ Backup Partition ══════${RESET}"
    printf "${YELLOW}${BOLD}Enter partition name: ${RESET}"; read part_name
    [ -z "$part_name" ] && { action_fail "Partition name cannot be empty"; return 1; }

    local ab_supported=false
    if [ "$active_slot" != "A/B not supported" ]; then
        ab_supported=true
    fi

    local target_parts=""
    if $ab_supported; then
        if echo "$part_name" | grep -qE '_(a|b)$'; then
            target_parts="$part_name"
        else
            echo "${CYAN}Device supports A/B partitions${RESET}"
            printf "${YELLOW}${BOLD}Choose slot to backup [a/b/ab]: ${RESET}"; read slot_choice
            case $slot_choice in
                a) target_parts="${part_name}_a" ;;
                b) target_parts="${part_name}_b" ;;
                ab) target_parts="${part_name}_a ${part_name}_b" ;;
                *) action_fail "Invalid choice"; return 1 ;;
            esac
        fi
    else
        target_parts="$part_name"
    fi

    for current_part in $target_parts; do
        echo ""
        start_action "Processing partition: $current_part"
        part_node=$(find_partition_node "$current_part")
        if [ -z "$part_node" ]; then
            action_fail "Partition $current_part not found"
            continue
        fi
        action_ok "Found partition node: $part_node"
        local default_path="/sdcard/${current_part}_$(date +%Y%m%d_%H%M%S).img"
        printf "${YELLOW}${BOLD}Save path [Enter for default: $default_path]: ${RESET}"; read save_path
        [ -z "$save_path" ] && save_path="$default_path"
        [ -f "$save_path" ] && { action_fail "File already exists"; continue; }
        printf "${YELLOW}${BOLD}Confirm backup $current_part? (y/n): ${RESET}"; read confirm
        [ "$confirm" != "y" ] && [ "$confirm" != "Y" ] && { action_info "Cancelled $current_part"; continue; }
        start_action "Backing up $current_part ..."
        dd if="$part_node" of="$save_path" bs=4M 2>&1 && { sync; action_ok "Backup successful!"; } || action_fail "Backup failed!"
    done
}

backup_full_firmware() {
    check_root || return 1
    echo ""
    echo "${MAGENTA}${BOLD}══════════════════ Full Firmware Backup (Beta) ══════════════════${RESET}"

    DEFAULT_EXCLUDE="userdata sdc sdcard cache metadata"
    echo ""
    echo "${CYAN}Default excluded data partitions:${RESET} $DEFAULT_EXCLUDE"
    printf "${YELLOW}${BOLD}Customize exclude list? (y/n): ${RESET}"; read custom_exclude
    local exclude_list="$DEFAULT_EXCLUDE"
    if [ "$custom_exclude" = "y" ] || [ "$custom_exclude" = "Y" ]; then
        printf "${YELLOW}${BOLD}Enter partition names to exclude (space separated): ${RESET}"; read exclude_list
    fi

    start_action "Scanning partitions..."
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
        action_fail "No partitions to backup (all excluded or unreadable)"
        return 1
    fi
    action_ok "Found $total backup-eligible partitions"

    local backup_base="/sdcard/Ying-backup"
    mkdir -p "$backup_base"

    local avail_kb=$(df -P "$backup_base" 2>/dev/null | tail -1 | awk '{print $4}')
    if [ -z "$avail_kb" ] || [ "$avail_kb" = "Available" ]; then
        avail_kb=$(df -k "$backup_base" 2>/dev/null | tail -1 | awk '{print $4}')
    fi
    if [ -z "$avail_kb" ] || ! [ "$avail_kb" -gt 0 ] 2>/dev/null; then
        action_fail "Cannot get available space on target directory"
        return 1
    fi
    local avail_bytes=$((avail_kb * 1024))

    action_info "Calculating total size of all partitions..."
    local total_bytes=0
    local unknown_parts=""
    for part in $filtered_list; do
        node=$(find_partition_node "$part")
        if [ -z "$node" ]; then
            action_info "Partition $part has no node, skipping"
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
        action_fail "Unknown size for partitions: $unknown_parts"
        printf "${YELLOW}${BOLD}Continue? (space estimation may be inaccurate) (y/n): ${RESET}"; read force
        if [ "$force" != "y" ] && [ "$force" != "Y" ]; then
            action_info "Backup cancelled"
            return 1
        fi
    fi

    action_info "Total backup size: $(format_size $total_bytes)"
    action_info "Available space: $(format_size $avail_bytes)"
    if [ $total_bytes -gt $avail_bytes ]; then
        action_fail "Insufficient space, missing $(format_size $((total_bytes - avail_bytes)))"
        printf "${YELLOW}${BOLD}Continue anyway? (may fail midway) (y/n): ${RESET}"; read force
        if [ "$force" != "y" ] && [ "$force" != "Y" ]; then
            action_info "Backup cancelled"
            return 1
        fi
    else
        action_ok "Space sufficient, continuing backup"
    fi

    local count=0
    local success_list=""
    local fail_list=""
    local out_of_space=0

    for part in $filtered_list; do
        if [ $out_of_space -eq 1 ]; then
            action_fail "Stopping further backups due to insufficient space"
            break
        fi

        node=$(find_partition_node "$part")
        [ -z "$node" ] && { action_info "Partition $part has no node, skipping"; continue; }

        if ! dd if="$node" of=/dev/null bs=4M count=1 2>/dev/null; then
            action_info "Partition $part is not readable, skipping"
            continue
        fi

        count=$((count + 1))
        size=$(get_partition_size_bytes "$node")
        size_str=$(format_size "$size")

        echo ""; action_info "[$count/$total] Backing up: $part ($size_str)"
        local img_file="$backup_base/${part}.img"

        dd if="$node" of="$img_file" bs=4M 2>&1
        local dd_exit=$?
        sync

        if [ $dd_exit -eq 0 ]; then
            action_ok "✓ $part backup successful"
            success_list="$success_list $part"
            if command -v md5sum >/dev/null 2>&1; then
                md5sum "$img_file" | awk '{print $1}' > "${img_file}.md5"
            fi
        else
            if [ $dd_exit -eq 1 ] && [ -f "$img_file" ] && tail -1 "$img_file" 2>/dev/null | grep -q "No space left"; then
                action_fail "Out of space, terminating backup"
                out_of_space=1
                fail_list="$fail_list $part"
                rm -f "$img_file"
                break
            else
                action_fail "✗ $part backup failed"
                fail_list="$fail_list $part"
            fi
        fi
    done

    local info_file="$backup_base/Ying-tool backup.txt"
    {
        echo "=============================================="
        echo "          Ying-tool Backup Info"
        echo "=============================================="
        echo "Backup time: $(date)"
        echo "Device model: $device_model"
        echo "Current slot: $active_slot"
        echo "Total partitions scanned: $total"
        echo "Successfully backed up: $(echo $success_list | wc -w)"
        echo "Failed partitions: $(echo $fail_list | wc -w)"
        if [ -n "$fail_list" ]; then
            echo "Failed partitions list:"
            for f in $fail_list; do echo "  - $f"; done
        fi
        echo ""
        echo "Successfully backed up partitions:"
        for s in $success_list; do echo "  - $s"; done
        echo "=============================================="
    } > "$info_file" 2>/dev/null
    if [ $? -eq 0 ]; then
        action_ok "Backup info file generated: $info_file"
    else
        action_fail "Unable to write backup info file (maybe out of space)"
    fi

    echo ""
    echo "${GREEN}${BOLD}══════════════════ Backup Complete ══════════════════${RESET}"
    action_ok "Successfully backed up: $(echo $success_list | wc -w) partitions"
    if [ -n "$fail_list" ]; then
        action_fail "Failed partitions: $fail_list"
    fi
    action_info "Backup directory: $backup_base"
    action_info "Generated files:"
    action_info "  - Ying-tool backup.txt"
    echo "${YELLOW}Please copy the entire Ying-backup folder to your PC promptly!${RESET}"
}

enable_adb() {
    start_action "Enabling USB debugging..."
    command -v settings >/dev/null 2>&1 && settings put global adb_enabled 1 && action_ok "USB debugging enabled" || action_fail "Enable failed"
}
disable_adb() {
    start_action "Disabling USB debugging..."
    command -v settings >/dev/null 2>&1 && settings put global adb_enabled 0 && action_ok "USB debugging disabled" || action_fail "Disable failed"
}
reboot_fastboot() {
    echo ""; action_info "About to reboot to bootloader mode"
    printf "${YELLOW}${BOLD}Confirm reboot? (y/n): ${RESET}"; read confirm
    [ "$confirm" = "y" ] || [ "$confirm" = "Y" ] && { start_action "Rebooting..."; reboot bootloader; } || action_info "Cancelled"
}

show_menu() {
    echo ""
    echo "${MAGENTA}${BOLD}══════════════════ Main Menu ══════════════════${RESET}"
    echo "${GREEN}${BOLD} 1.${RESET} Flash Partition"
    echo "${GREEN}${BOLD} 2.${RESET} Backup Partition"
    echo "${GREEN}${BOLD} 3.${RESET} Full Firmware Backup"
    echo "${GREEN}${BOLD} 4.${RESET} Enable USB Debugging"
    echo "${GREEN}${BOLD} 5.${RESET} Disable USB Debugging"
    echo "${GREEN}${BOLD} 6.${RESET} Reboot to Bootloader"
    echo "${GREEN}${BOLD} 7.${RESET} Exit"
    echo "${MAGENTA}${BOLD}══════════════════════════════════════════════${RESET}"
    echo -n "${BOLD}Please select [1-7]: ${RESET}"
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
            7) action_ok "Thank you for using, goodbye!"; exit 0 ;;
            *) action_fail "Invalid option, please try again"; sleep 1 ;;
        esac
        echo ""; printf "${YELLOW}Press Enter to continue...${RESET}"; read dummy
    done
}

main() {
    show_disclaimer; read ans
    case $ans in n|N) echo "${GREEN}Exited.${RESET}"; exit 0 ;; y|Y) ;; *) echo "${RED}Invalid input, exiting.${RESET}"; exit 1 ;; esac
    boot_animation
    show_logo
    get_device_info
    show_info
    echo ""; printf "${BOLD}Enter main menu? (y/n): ${RESET}"; read ans
    case $ans in y|Y) menu_loop ;; *) action_ok "Exiting directly." ; exit 0 ;; esac
}

main