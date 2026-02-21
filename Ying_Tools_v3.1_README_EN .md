# Ying Tools v3.1 - Android Full-Featured Partition Management Script

Welcome to **Ying Tools**! This script is designed for Android devices, running in **Termux** terminal with **root privileges**. It provides safe, interactive partition operations, supports A/B slot selection, and can backup all partitions (excluding data partitions) with a detailed info file.

---

## 📦 Features

| Feature | Description |
|---------|-------------|
| **Flash Partition** | Enter partition name (e.g., `boot`), auto-detect A/B support, choose to flash `a`, `b`, or both. |
| **Backup Single Partition** | Similar to flash, select slot and save as `.img` file. |
| **Full Firmware Backup** | Scan all readable partitions (exclude virtual devices), skip data partitions by default (`userdata`, `sdcard`, etc.). Pre-calculates total size and compares with available space. Generates `Ying-tool backup.txt` with detailed info after completion. |
| **USB Debugging Switch** | Enable/disable ADB debugging with one click. |
| **Reboot to Fastboot** | Quickly reboot to bootloader mode. |

---

## 🚀 Usage

1. Place the script file (e.g., `Ying-Tools_v3.1_EN.sh`) in a directory accessible by Termux (e.g., `/sdcard/`).
2. Open Termux and gain root access by typing `su`.
3. Grant execute permission:  
   `chmod +x /sdcard/Ying-Tools_v3.1_EN.sh`
4. Run the script:  
   `sh /sdcard/Ying-Tools_v3.1_EN.sh`
5. Read the disclaimer and enter `y` to agree.
6. After viewing device info, enter `y` to enter the main menu.
7. Follow the menu prompts to choose an operation.

---

## 📁 Backup Output Example

After running full firmware backup, the following will be generated in `/sdcard/Ying-backup/`:

- `partition_name.img` - Image of each successfully backed up partition
- `partition_name.img.md5` - MD5 checksum (if supported)
- `Ying-tool backup.txt` - Backup time, device info, success/failure lists, etc.

---

## 🧑‍💻 Author Info

- **Name**: Ying Gong Xiang Zhi (Ying)
- **Country**: China
- **Age**: 17 (high school student)
- **Hobby**: Anime & ACG
- **Belief**: Everything comes from passion
- **A special girl in my heart**: named Wang Menghan
- **Favorite quote**:  
  *“I will carry roses and fervor, looking forward to our next rendezvous.”*

- **Development Time**: 2026-02-20 23:23

--
## 📜 License

This script is a personal project for learning and communication purposes only. The author assumes no responsibility for any damage or loss caused by using this script. Please delete it within 24 hours.

---

**Thank you for using Ying Tools ❤️**