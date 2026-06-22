#!/bin/bash
# Automated Multisim 14.3 installer (Wine)
# Authors: Giovanni De Rosa, Lorenzo Pappalardo
# Description: Downloads NI's official online installer for Multisim 14.3
#              (Educational or Professional) and sets it up under Wine.
#
# NOTE ON THIS VERSION:
#   - No patched installer folder needed anymore - this pulls the real
#     installer straight from NI's servers.
#   - Single unified method, no distro detection/branching.
#   - Wine, winetricks, cabextract, wget and git must already be installed.

set -e # Exit on errors

echo "============================================================================================"
echo "   'NI Multisim 14.3 for Linux'  Copyright (C)  2026  Giovanni De Rosa, Lorenzo Pappalardo"
echo "   This program comes with ABSOLUTELY NO WARRANTY; for details type 'show w'."
echo "   This is free software, and you are welcome to redistribute it"
echo "   under certain conditions; type 'show c' for details."
echo "============================================================================================"
echo

while true; do
  read -p "Do you wish to see the warranty or the license details [w/c; press Enter to skip]: " GPL_choice

  if [[ -z "$GPL_choice" ]]; then
    break

  elif [[ "$GPL_choice" =~ ^[Ww]$ ]]; then
    echo "THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY"
    echo "APPLICABLE LAW.  EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT"
    echo "HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM 'AS IS' WITHOUT WARRANTY"
    echo "OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO,"
    echo "THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR"
    echo "PURPOSE.  THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM"
    echo "IS WITH YOU.  SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF"
    echo "ALL NECESSARY SERVICING, REPAIR OR CORRECTION."
    echo
    echo

  elif [[ "$GPL_choice" =~ ^[Cc]$ ]]; then
    echo "This program is free software: you can redistribute it and/or modify"
    echo "it under the terms of the GNU General Public License as published by"
    echo "the Free Software Foundation, either version 3 of the License, or"
    echo "(at your option) any later version."
    echo
    echo
    echo "You must provide source code and preserve this license when conveying"
    echo "modified or unmodified versions."
    echo
    echo

  else
    echo "Invalid input. Press Enter with no input to skip."
    echo
    echo
  fi
done

echo "=============================="
echo "  Multisim 14.3 Installer"
echo "=============================="
echo

# ──────────────────────────────────────────────
# CONFIG
# ──────────────────────────────────────────────
export WINEPREFIX="${WINEPREFIX:-$HOME/.multisim143}"
# No WINEARCH override: standard 64-bit prefix with WoW64 support.
# Dedicated prefix (not the default ~/.wine) so this never touches/depends
# on other Wine apps, and every run starts from known state.

# All the noisy/verbose command output goes here instead of the terminal.
# The user only sees short step titles; full output is available for debugging.
LOGFILE="/tmp/multisim143-install-full.log"
: >"$LOGFILE"

step() {
  echo "==> $*"
}

# ──────────────────────────────────────────────
# PREREQUISITES
# (installing these is out of scope for this script)
# ──────────────────────────────────────────────
check_prerequisites() {
  local missing=()
  for cmd in wget git wine winetricks cabextract curl unzip; do
    command -v "$cmd" &>/dev/null || missing+=("$cmd")
  done

  if [ ${#missing[@]} -gt 0 ]; then
    echo "❌ Missing required tools: ${missing[*]}"
    echo "   Install them with your distro's package manager, then re-run this script."
    exit 1
  fi

  # On Ubuntu, make sure the distro's own wine/wine32/wine64 packages are
  # present. If only winehq-stable (from the WineHQ repo) is installed,
  # the "wine" on PATH may not behave correctly unless
  # PATH="/opt/wine-stable/bin:$PATH" is exported first.
  if [ -f /etc/os-release ] && grep -qi '^ID=ubuntu' /etc/os-release; then
    local missing_deb=()
    for pkg in wine wine32 wine64; do
      dpkg -s "$pkg" &>/dev/null || missing_deb+=("$pkg")
    done

    if [ ${#missing_deb[@]} -gt 0 ]; then
      echo "❌ Ubuntu detected, but these packages are missing: ${missing_deb[*]}"
      echo "   Install them with: sudo apt install ${missing_deb[*]}"
      if dpkg -s winehq-stable &>/dev/null; then
        echo "   Note: winehq-stable is installed, but that alone isn't enough -"
        echo "   you still need the packages above, and you must run:"
        echo "     export PATH=\"/opt/wine-stable/bin:\$PATH\""
        echo "   before re-running this script."
      fi
      exit 1
    fi

    if dpkg -s winehq-stable &>/dev/null; then
      echo "⚠️  winehq-stable is installed. Make sure you've run:"
      echo "     export PATH=\"/opt/wine-stable/bin:\$PATH\""
      echo "   in this shell, otherwise the wrong 'wine' binary may be used."
      echo
    fi
  fi

  echo "✅ wget, git, wine, winetricks, cabextract, curl and unzip are all available."
  echo
}

check_prerequisites

# ──────────────────────────────────────────────
# CREATE THE DEDICATED PREFIX
# ──────────────────────────────────────────────
step "Creating Wine prefix for Multisim at $WINEPREFIX"
wineboot >>"$LOGFILE" 2>&1
echo

# ──────────────────────────────────────────────
# WORKING DIRECTORY
# ──────────────────────────────────────────────
WORKDIR="$(mktemp -d /tmp/multisim143_install.XXXXXX)"
cd "$WORKDIR" || exit 1
echo "Working directory: $WORKDIR"
echo

# ──────────────────────────────────────────────
# CHOOSE EDITION & DOWNLOAD THE OFFICIAL ONLINE INSTALLER
# ──────────────────────────────────────────────
choose_edition() {
  echo "Which Multisim 14.3 edition would you like to install?"
  echo "  1) Educational"
  echo "  2) Professional"
  read -rp "Enter choice [1/2]: " edition_choice

  case "$edition_choice" in
  1)
    INSTALLER_URL="https://download.ni.com/support/nipkg/products/ni-c/ni-cds-educational/14.3/online/ni-cds-educational_14.3_online.exe"
    INSTALLER_FILE="ni-cds-educational_14.3_online.exe"
    ;;
  2)
    INSTALLER_URL="https://download.ni.com/support/nipkg/products/ni-c/ni-cds-professional/14.3/online/ni-cds-professional_14.3_online.exe"
    INSTALLER_FILE="ni-cds-professional_14.3_online.exe"
    ;;
  *)
    echo "❌ Invalid choice."
    exit 1
    ;;
  esac

  step "Downloading $INSTALLER_FILE from NI"
  wget -q -O "$INSTALLER_FILE" "$INSTALLER_URL" >>"$LOGFILE" 2>&1
  echo
}

choose_edition

# ──────────────────────────────────────────────
# WINE PREFIX SETUP
# ──────────────────────────────────────────────
step "Running winetricks (corefonts, dotnet48)"
winetricks -q corefonts dotnet48 >>"$LOGFILE" 2>&1
echo

set_winver_win10() {
  step "Setting Wine Windows version to 10"
  wine winecfg -v win10 >>"$LOGFILE" 2>&1
  echo
}

set_winver_win10

# ──────────────────────────────────────────────
# RUN THE NI ONLINE INSTALLER
# ──────────────────────────────────────────────
# Run through cmd's "start /wait" rather than invoking the exe directly:
# the installer's own "please reboot" prompt at the end otherwise leaves a
# Wine process sitting around forever and the script never gets control back.
step "Running the Multisim 14.3 online installer"
(
  WINEDEBUG=-all \
    wine cmd /c "start /wait \"\" $INSTALLER_FILE"
) >/tmp/multisim143-install.log 2>&1 || true

echo "Installer finished."
sleep 5

step "Stopping Wine"
wineserver -k || true
echo "Multisim installation stage complete."
echo

# ──────────────────────────────────────────────
# DATABASE ENGINE: MDAC 2.7 + JET 4.0
# (archived copies - Microsoft's original download links are dead)
# ──────────────────────────────────────────────
install_database_engine() {
  step "Downloading MDAC 2.7 and Jet 4.0 redistributables"
  wget -q -O MDAC_TYP.EXE \
    "https://web.archive.org/web/20060718123742/http://ftp.gunadarma.ac.id/pub/driver/itegno/USB%20Software/MDAC/MDAC_TYP.EXE" >>"$LOGFILE" 2>&1
  wget -q -O Jet40SP8_9xNT.exe \
    "https://web.archive.org/web/20210225171713/http://download.microsoft.com/download/4/3/9/4393c9ac-e69e-458d-9f6d-2fe191c51469/Jet40SP8_9xNT.exe" >>"$LOGFILE" 2>&1

  step "Installing MDAC 2.7"
  wine MDAC_TYP.EXE >>"$LOGFILE" 2>&1

  step "Installing Jet 4.0"
  wine Jet40SP8_9xNT.exe >>"$LOGFILE" 2>&1
  echo

  step "Extracting Jet 4.0 DLLs"
  mkdir -p /tmp/jet40
  pushd /tmp/jet40 >/dev/null

  cabextract "$WORKDIR/Jet40SP8_9xNT.exe" >>"$LOGFILE" 2>&1
  cabextract jetsetup.exe >>"$LOGFILE" 2>&1
  cabextract jetsetup.cab >>"$LOGFILE" 2>&1

  mkdir -p "$WINEPREFIX/drive_c/windows/syswow64"
  mkdir -p "$WINEPREFIX/drive_c/Program Files/Common Files/Microsoft Shared/DAO"

  cp dao360.dll "$WINEPREFIX/drive_c/windows/syswow64/"
  cp msjet40.dll "$WINEPREFIX/drive_c/windows/syswow64/"
  cp msrd3x40.dll "$WINEPREFIX/drive_c/windows/syswow64/"

  step "Registering DLLs"
  wine regsvr32 'C:\windows\syswow64\dao360.dll' >>"$LOGFILE" 2>&1
  wine regsvr32 'C:\windows\syswow64\msjet40.dll' >>"$LOGFILE" 2>&1

  popd >/dev/null
  rm -rf /tmp/jet40
  echo "✅ Database engine setup complete."
  echo
}

install_database_engine

# ──────────────────────────────────────────────
# CLEANUP
# ──────────────────────────────────────────────
step "Cleaning up downloaded installer files"
cd "$HOME" || exit 1
rm -rf "$WORKDIR"

# ──────────────────────────────────────────────
# macOS: INSTALL THE MULTISIM.APP SHORTCUT
# ──────────────────────────────────────────────
# TODO: confirm/replace this with the actual raw download URL for
# multisim.app.zip from the repo's assets/multisim14-3/macOS folder.
MACOS_APP_ZIP_URL="https://raw.githubusercontent.com/<owner>/NI-Multisim-14-for-Linux-and-MacOS/main/assets/multisim14-3/macOS/multisim.app.zip"

install_macos_app() {
  step "Installing Multisim.app into /Applications"

  local tmpzip
  tmpzip="$(mktemp /tmp/multisim_app.XXXXXX.zip)"

  if ! curl -fsSL -o "$tmpzip" "$MACOS_APP_ZIP_URL" >>"$LOGFILE" 2>&1; then
    echo "⚠️  Could not download multisim.app.zip - skipping shortcut install."
    echo "    You can manually unzip it into /Applications/ later."
    rm -f "$tmpzip"
    return
  fi

  local tmpdir
  tmpdir="$(mktemp -d /tmp/multisim_app_extract.XXXXXX)"
  unzip -q -o "$tmpzip" -d "$tmpdir" >>"$LOGFILE" 2>&1

  local app_path
  app_path="$(find "$tmpdir" -maxdepth 2 -name '*.app' -print -quit)"

  if [ -z "$app_path" ]; then
    echo "⚠️  Could not find a .app bundle inside multisim.app.zip - skipping."
  else
    rm -rf "/Applications/$(basename "$app_path")"
    cp -R "$app_path" /Applications/
    echo "✅ Multisim shortcut installed to /Applications/$(basename "$app_path")."
  fi

  rm -f "$tmpzip"
  rm -rf "$tmpdir"
  echo
}

if [[ "$(uname -s)" == "Darwin" ]]; then
  install_macos_app
fi

echo
echo "======================================="
echo "✅ Multisim 14.3 installation complete!"
echo "   WINEPREFIX: $WINEPREFIX"
echo "A reboot of your machine is recommended"
echo "======================================="

read -rp "Do you want to restart the machine now? [y/N]: " answer

case "$answer" in
[Yy] | [Yy][Ee][Ss])
  echo "Restarting system..."
  sudo reboot
  ;;
*)
  echo "Restart skipped. You can reboot later manually."
  ;;
esac
