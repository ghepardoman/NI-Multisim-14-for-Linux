<img src="assets/images/banner.png" alt="MULTISIM" />

![Supported OS: Linux](https://img.shields.io/badge/Supported_OS-Linux-orange.svg)
![Bash](https://img.shields.io/badge/Language-Bash-blue.svg)
> Automated installer for **NI Multisim 14.0** on Linux via Wine.

Built for the redpilled breed of engineers and students who rely on NI Multisim every day but run Linux as their primary OS. This repository provides the tools, tweaks, and compatibility setup needed to make Multisim usable on a Linux daily-driver environment without the usual headaches.

**Authors:** Giovanni De Rosa, Lorenzo Pappalardo

---

## 📋 Table of Contents

- [Overview](#overview)
- [Supported Distributions](#supported-distributions)
- [Prerequisites](#prerequisites)
- [Usage](#usage)
- [How it works (What the Script Does)](#how-it-works-what-the-script-does)
- [Notes & Known Issues](#notes--known-issues)

---

## Overview

This bash script automates the full process of installing **NI Circuit Design Suite 14.0 (Multisim)** on Linux. It handles Wine installation, a dedicated 32-bit Wine prefix, dependency setup, and the Multisim installer execution — all in a single run across all supported distros.

### Why version 14.0?
Why this version? Multisim 14.0 is the newest version that works reliably on Linux with minimal issues while still including most of the features available in Multisim 14.3.
If you want to know more about the latest version check out [this blog post](https://lina.moe/MultiSIM.md)

---



## Supported Distributions

| Distribution Family | Tested Distros |
|---|---|
| 🔵 Arch Linux | Arch |
| 🟠 Debian / Ubuntu | Ubuntu |
| 🔴 Fedora / RHEL | Fedora |
| 🟢 openSUSE | openSUSE Tumbleweed |

---

## Prerequisites
 `wget`, `unzip` available on your system


---

## Usage

### 1. Clone the repository

```bash
git clone https://github.com/ghepardoman/NI-Multisim-14-for-Linux.git
cd NI-Multisim-14-for-Linux
```

### 2. Make the script executable

```bash
chmod +x install.sh
```

### 3. Run the installer

```bash
./install.sh
```

> ⚠️ **Do not run as root.** The script uses `sudo` internally where needed.

---

## How it works (What the Script Does)

### Distro Detection
Reads `/etc/os-release` to identify your distribution family and selects the correct install path.

### Remove Conflicting Packages
Checks for and removes any existing Wine installations that may conflict with the version required by Multisim.

### Install Wine

| Distro | Method |
|---|---|
| **Arch** | Chaotic AUR (`wine-stable`, recommended) or AUR via `yay` |
| **Debian/Ubuntu/Mint** | `apt` — installs `wine`, `wine32`, `wine64`, `libwine` |
| **Fedora** | `dnf` — installs `wine`, `wine-core.i686`  |
| **openSUSE** | `zypper` — installs `wine` |

### Wine Prefix Setup
Creates a dedicated **32-bit Wine prefix** at `~/.multisim32`, isolated from your default Wine environment, configured with Windows XP compatibility mode.
> Windows XP compatibility mode is essential to make multisim work

```bash
WINEARCH=win32 WINEPREFIX="$HOME/.multisim32" winecfg -v winxp
```

### Wine Dependencies
Installs required components via `winetricks`:

- `corefonts` — Microsoft core fonts
- `mdac27` — Microsoft Data Access Components 2.7
- `jet40` — Microsoft Jet 4.0 database engine

### Download & Install Multisim
Downloads the official NI Circuit Design Suite 14.0 installer from National Instruments' servers through wget, extracts it, and runs it through Wine.

### Desktop Launcher Fix *(Debian/Fedora)*
Automatically patches the `.desktop` file created by the installer to ensure it uses the correct Wine prefix and `wine32` binary when launched from your application menu.

### Cleanup
Removes the downloaded ZIP and extracted installer directory.

### Reboot
Asks for system reboot, essential for the later functioning of the application.

---

## Notes & Known Issues

- **Arch Linux users** are prompted whether to use Chaotic AUR (fast, pre-built) or compile from AUR (slow). Chaotic AUR is strongly recommended.
- **Arch Linux users** may encounter a problem where a package that starts with "wine" (e.g. wine-stable) gets wrongly queried as "wine" when checking for conflicting packages, if that's the case then pacman will most likely fail and you'll need to remove that package manually before re-executing the script
- **OpenSUSE users** will have their Wine continuosely try to open winedbg (which halts every wine/winetricks operation). The script `forceClosewinedbg.sh` has been included to automatically kill a winedbg instance every time it opens, so that the users doesn't have to do it themselves. After rebooting, the script will stop running and thus when trying to open Multisim a winedbg will appear; just close the window and you will have no issues running the program.
- The Wine prefix is stored at `~/.multisim32` and is completely separate from any existing Wine setup you may have.
- A **system reboot** is recommended after installation.
- If Multisim does not appear in your application launcher after install, try running:
  ```bash
  update-desktop-database ~/.local/share/applications
  ```
- Only the subsequent distros were tested: Arch Linux, Ubuntu, Fedora, openSUSE Tumbleweed.
---

## License

This project is released for educational and personal use. NI Multisim is proprietary software owned by National Instruments — ensure you have a valid license before use.

## 📌 Nota di presentazione
Capolavoro presentato da Giovanni De Rosa e Lorenzo Pappalardo sulla Piattaforma Unica – DD MM 2026.

