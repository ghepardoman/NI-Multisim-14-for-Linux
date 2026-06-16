<img src="assets/images/banner.png" alt="MULTISIM" />

![Supported OS: Linux](https://img.shields.io/badge/Supported_OS-Linux%20and%20MacOS-orange.svg)
![Bash](https://img.shields.io/badge/Language-Bash-blue.svg)
> Automated installer for **NI Multisim 14.0** on Linux and MacOS via [Wine](https://www.winehq.org/).

Built for the redpilled breed of engineers and students who rely on [NI Multisim](https://www.ni.com/en/support/downloads/software-products/download.multisim.html) every day but run Linux/MacOS as their primary OS. This repository provides the tools, tweaks, and compatibility setup needed to make Multisim usable on a daily-driver environment without the usual headaches.

**Authors:** Giovanni De Rosa, Lorenzo Pappalardo, Andrea Lestingi

---

## 📋 Table of Contents

- [Overview](#overview)
- [Linux Support](#-linux-support)
- [MacOS Support](#-macos-support)
- [Usage](#-usage)
- [Uninstall](#-uninstall)
- [How it works](#%EF%B8%8F-how-it-works-on-linux)
- [Notes & Known Issues](#%EF%B8%8F-notes--known-issues)

---

## Overview

This bash script automates the full process of installing **NI Circuit Design Suite 14.0 (Multisim)** on Linux or MacOS. It handles Wine installation, a dedicated 32-bit Wine prefix, dependency setup, and the Multisim installer execution — all in a single run across all supported distros.

### Why version 14.0?
Why this version? Multisim 14.0 is the newest version that works reliably on Linux and MacOS with minimal issues while still including most of the features available in Multisim 14.3.
If you want to know more about the latest version check out [this blog post](https://lina.moe/MultiSIM.md)

---

## 🐧 Linux Support

### Supported Distributions

| Distribution Family | Tested Distros |
|---|---|
| 🔵 Arch | [Arch Linux](https://archlinux.org/) |
| 🟠 Debian / Ubuntu | [Ubuntu](https://ubuntu.com/) |
| 🔴 Fedora / RHEL | [Fedora](https://fedoraproject.org/) |
| 🟢 openSUSE | [openSUSE](https://www.opensuse.org/) Tumbleweed |


### Prerequisites
 `wget`, `unzip` available on your system


---

## 🍎 MacOS Support

### Requirements
- macOS 10.14 (Mojave) or later
- Intel or Apple Silicon (M1/M2/M3)

> **Apple Silicon note:** Wine runs via Rosetta 2. First launch may take longer.



---

## 💻 Usage

### 1. Clone the repository

```bash
git clone --depth 1 https://github.com/ghepardoman/NI-Multisim-14-for-Linux.git
cd NI-Multisim-14-for-Linux
```

### 2. Make the script executable

```bash
#For linux:
chmod +x install.sh
#For MacOS:
chmod +x install-macos.sh
```

### 3. Run the installer

```bash
./install.sh
```

> ⚠️ **Do not run as root.** The script uses `sudo` internally where needed.

---

## 🧹 Uninstall

```bash
chmod +x uninstall.sh
./uninstall.sh
```

---

## ⚙️ How it works on Linux

### Distro Detection
Reads `/etc/os-release` to identify your distribution family and selects the correct install path.

### Remove Conflicting Packages
Checks for and removes any existing Wine installations that may conflict with the version required by Multisim.

### Install Wine

| Distro | Method |
|---|---|
| **Arch** | [Chaotic AUR](https://aur.chaotic.cx/) (`wine-stable`, recommended) or AUR via `yay` |
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

## ⚙️ How it works on MacOS

### Architecture Detection
Detects Apple Silicon vs Intel. On Apple Silicon, checks for **Rosetta 2** and installs it if missing, as it's required to run Wine.

### Homebrew Check
Verifies [Homebrew](https://brew.sh/) is installed, bootstrapping it automatically if not. On Apple Silicon, also adds it to your shell path via `~/.zprofile`.

### Install Wine
Installs `wine-stable`, `cabextract`, and `winetricks` via Homebrew, removing any conflicting Wine versions first.

### Wine Prefix Setup
Creates a dedicated prefix at `~/.multisim`, isolated from your default Wine environment. Architecture is chosen automatically:

| CPU | Prefix | Reason |
|---|---|---|
| **Apple Silicon** | `win64` | Wine 8+ on ARM drops 32-bit support |
| **Intel** | `win32` | Standard, matches the Multisim installer |

> Windows XP compatibility mode is essential to make Multisim work.

### Wine Dependencies
Installs required components via `winetricks`: `corefonts`, `mdac27`, `jet40`.

### Download & Install Multisim
Downloads the official NI Circuit Design Suite 14.0 ZIP from National Instruments' servers, extracts it, and runs `setup.exe` through Wine.

### License Activation
Downloads and runs the **NI License Activator** inside the Wine prefix. Right-click each listed product and select **Activate**, then close when done.

### macOS App Bundle
Creates `~/Applications/Multisim.app` so Multisim appears in **Spotlight**, can be pinned to the **Dock**, and launches like any native app.

### Terminal Launcher
Installs a `multisim` command to `/usr/local/bin` for quick terminal access.

### Cleanup
Removes the downloaded ZIP and extracted installer files.

---

## 🗒️ Notes & Known Issues

### Linux-Specific
- **Arch Linux users** are prompted whether to use [Chaotic AUR](https://aur.chaotic.cx/) (fast, pre-built) or compile from AUR (slow). Chaotic AUR is strongly recommended.
- **Arch Linux users** may encounter a problem where a package that starts with "wine" (e.g. wine-stable) gets wrongly queried as "wine" when checking for conflicting packages, if that's the case then pacman will most likely fail and you'll need to remove that package manually before re-executing the script
- **OpenSUSE users** will have their Wine continuosely try to open winedbg (which halts every wine/winetricks operation). The script `forceClosewinedbg.sh` has been included to automatically kill a winedbg instance every time it opens, so that the users doesn't have to do it themselves. After rebooting, the script will stop running and thus when trying to open Multisim a winedbg will appear; just close the window and you will have no issues running the program.
- The Wine prefix is stored at `~/.multisim32` and is completely separate from any existing Wine setup you may have.
- A **system reboot** is recommended after installation.
- If Multisim does not appear in your application launcher after install, try running:
  ```bash
  update-desktop-database ~/.local/share/applications
  ```
- Only the subsequent distros were tested: Arch Linux, Ubuntu, Fedora, openSUSE Tumbleweed.

### MacOS-Specific
- First launch may take 10–20 seconds as Wine initializes
- XQuartz may be required for some Wine components
- The app bundle contains a launcher script with correct environment variables
- On Apple Silicon, Rosetta 2 installs automatically on first Wine launch
- If the terminal prompts you this error: "Bad CPU type in executable", run `softwareupdate --install-rosetta`
---

## License

This project is released for educational and personal use. NI Multisim is proprietary software owned by National Instruments — ensure you have a valid license before use.


