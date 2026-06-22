#!/bin/bash
set -euo pipefail

echo "========================================"
echo "  NI Multisim 14.0 Installer for macOS"
echo "========================================"
echo

# ──────────────────────────────────────────────
# CHECK ARCHITECTURE
# ──────────────────────────────────────────────
ARCH=$(uname -m)
if [[ "$ARCH" == "arm64" ]]; then
    echo "⚠️  Apple Silicon (M1/M2/M3/M4) detected."
    echo "   Wine verrà eseguito tramite emulazione Rosetta 2."
    echo "   Verifica Rosetta 2..."
    if ! pkgutil --pkg-info com.apple.pkg.RosettaUpdateAuto &>/dev/null; then
        echo "Installazione di Rosetta 2..."
        softwareupdate --install-rosetta --agree-to-license
    else
        echo "✅ Rosetta 2 già installata."
    fi
    echo
fi

# ──────────────────────────────────────────────
# CHECK HOMEBREW
# ──────────────────────────────────────────────
if ! command -v brew &>/dev/null; then
    echo "❌ Homebrew non trovato. Installazione in corso..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    if [[ "$ARCH" == "arm64" ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
fi

echo "✅ Homebrew trovato."

# ──────────────────────────────────────────────
# INSTALL WINE
# ──────────────────────────────────────────────
echo "Installazione di Wine tramite Homebrew..."

brew uninstall --cask --ignore-dependencies wine-stable 2>/dev/null || true
brew uninstall --ignore-dependencies wine 2>/dev/null || true

brew install --cask wine-stable
brew install cabextract

# ──────────────────────────────────────────────
# INSTALL WINETRICKS
# ──────────────────────────────────────────────
if ! command -v winetricks &>/dev/null; then
    echo "Installazione di winetricks..."
    brew install winetricks
fi

echo "✅ Wine e winetricks installati."

# ──────────────────────────────────────────────
# CREA PREFISSO WINE (64-bit su Apple Silicon, 32-bit su Intel)
# ──────────────────────────────────────────────
export WINEPREFIX="$HOME/.multisim"

if [[ "$ARCH" == "arm64" ]]; then
    export WINEARCH=win64
    echo "ℹ️  Prefisso Wine a 64 bit (richiesto su Apple Silicon con Wine 8+)."
else
    export WINEARCH=win32
    echo "ℹ️  Prefisso Wine a 32 bit (Intel)."
fi

echo "Creazione del prefisso Wine in $WINEPREFIX..."

if [ -d "$WINEPREFIX" ]; then
    echo "Rimozione del prefisso Wine esistente..."
    rm -rf "$WINEPREFIX"
fi

wineboot -u 2>/dev/null || true
winecfg -v winxp 2>/dev/null || true

# ──────────────────────────────────────────────
# DIPENDENZE WINE
# ──────────────────────────────────────────────
echo "Installazione delle dipendenze Wine (corefonts, mdac27, jet40)..."
wineserver -k 2>/dev/null || true
sleep 2

winetricks -q corefonts 2>/dev/null || true
winetricks -q mdac27    2>/dev/null || true
winetricks -q jet40     2>/dev/null || true

# ──────────────────────────────────────────────
# DOWNLOAD MULTISIM
# ──────────────────────────────────────────────
INSTALLER_ZIP="NI_Circuit_Design_Suite_14_0.zip"
INSTALLER_DIR="multisim_installer"
DOWNLOAD_URL="https://download.ni.com/support/softlib/Core/Circuit_Design_Suite/14.0/14.0/NI_Circuit_Design_Suite_14_0.zip"

echo "Download di Multisim 14.0..."
if [ -f "$INSTALLER_ZIP" ]; then
    echo "File già presente. Salto il download."
else
    if ! curl -L --fail --progress-bar -o "$INSTALLER_ZIP" "$DOWNLOAD_URL"; then
        echo "❌ Download fallito."
        echo "   Scarica manualmente il file da:"
        echo "   https://www.ni.com/it-it/support/downloads/software-products/download.multisim.html"
        echo "   e rinominalo: $INSTALLER_ZIP"
        exit 1
    fi
fi

echo "Estrazione del pacchetto di installazione..."
rm -rf "$INSTALLER_DIR"
unzip -q "$INSTALLER_ZIP" -d "$INSTALLER_DIR"

# ──────────────────────────────────────────────
# INSTALLAZIONE
# ──────────────────────────────────────────────
SETUP_PATH="$INSTALLER_DIR/setup.exe"
if [ ! -f "$SETUP_PATH" ]; then
    SETUP_PATH=$(find "$INSTALLER_DIR" -maxdepth 2 -iname "setup.exe" | head -n 1)
    if [ -z "$SETUP_PATH" ]; then
        echo "❌ setup.exe non trovato nell'archivio estratto."
        exit 1
    fi
fi

echo "Avvio del programma di installazione Multisim tramite Wine..."
echo "Potrebbero volerci 10–20 minuti. Attendere..."

wineserver -k 2>/dev/null || true
sleep 2

WINE_LOG="/tmp/multisim-install.log"
(
    export WINEPREFIX WINEARCH
    export WINEDEBUG=-all
    wine "$SETUP_PATH" /quiet /norestart 2>/dev/null \
    || wine "$SETUP_PATH" /silent /norestart 2>/dev/null \
    || wine "$SETUP_PATH"
) >"$WINE_LOG" 2>&1

echo "Installazione terminata. Log: $WINE_LOG"
sleep 3

# ──────────────────────────────────────────────
# ATTIVATORE LICENZA
# ──────────────────────────────────────────────
echo
echo "================================================================"
echo "  NI LICENSE ACTIVATOR"
echo "================================================================"

ACTIVATOR_URL="https://github.com/AndreaLestingi/NI-Multisim-Crack-1.14/releases/download/activator/NI.License.Activator.exe"
ACTIVATOR_PATH="$WINEPREFIX/drive_c/NI.License.Activator.exe"

if [ -f "$ACTIVATOR_PATH" ]; then
    echo "✅ Activator already present: $ACTIVATOR_PATH"
else
    echo "Downloading NI License Activator..."
    curl -L --fail --progress-bar -o "$ACTIVATOR_PATH" "$ACTIVATOR_URL"
fi

if [ -f "$ACTIVATOR_PATH" ]; then
    echo "Stopping Wine processes before activator..."
    wineserver -k 2>/dev/null || true
    sleep 2

    echo
    echo "============================================================="
    echo "  Avvio NI License Activator"
    echo "============================================================="
    echo "When the activator window opens:"
    echo "  1. You will see a list of NI products"
    echo "  2. Right-click (or Ctrl+click) on each product"
    echo "  3. Select 'Activate' from the context menu"
    echo "  4. Close the activator when done"
    echo "============================================================="
    echo
    read -p "Press Enter to open the activator..."

    export WINEPREFIX
    export WINEARCH
    wine "$ACTIVATOR_PATH"

    echo "Activator closed."
else
    echo "⚠️  WARNING: Failed to download activator."
    echo "   You can manually download it from:"
    echo "   $ACTIVATOR_URL"
    echo "   Then run: wine \"$ACTIVATOR_PATH\""
fi

# ──────────────────────────────────────────────
# CREA BUNDLE MACOS
# ──────────────────────────────────────────────
echo "Creazione del bundle applicazione macOS..."

APP_DIR="$HOME/Applications/Multisim.app"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

ICONSET_TMP=$(mktemp -d)
for size in 16 32 64 128 256 512; do
    sips -z "$size" "$size" \
        /System/Applications/Utilities/Terminal.app/Contents/Resources/Terminal.icns \
        --out "$ICONSET_TMP/icon_${size}x${size}.png" 2>/dev/null || true
done
iconutil -c icns "$ICONSET_TMP" \
    -o "$APP_DIR/Contents/Resources/icon.icns" 2>/dev/null || true
rm -rf "$ICONSET_TMP"

cat > "$APP_DIR/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Multisim</string>
    <key>CFBundleIdentifier</key>
    <string>com.nationalinstruments.multisim</string>
    <key>CFBundleName</key>
    <string>Multisim 14</string>
    <key>CFBundleDisplayName</key>
    <string>NI Multisim 14.0</string>
    <key>CFBundleVersion</key>
    <string>14.0</string>
    <key>CFBundleShortVersionString</key>
    <string>14.0</string>
    <key>CFBundleIconFile</key>
    <string>icon</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

WINEPREFIX_VAL="$WINEPREFIX"
WINEARCH_VAL="$WINEARCH"

if [[ "$WINEARCH_VAL" == "win64" ]]; then
    MULTISIM_REL="Program Files/National Instruments/Circuit Design Suite 14.0/multisim.exe"
else
    MULTISIM_REL="Program Files/National Instruments/Circuit Design Suite 14.0/multisim.exe"
fi

cat > "$APP_DIR/Contents/MacOS/Multisim" << LAUNCHER
#!/bin/bash
export WINEPREFIX="$WINEPREFIX_VAL"
export WINEARCH="$WINEARCH_VAL"
export WINEDEBUG=-all

MULTISIM_EXE="\$WINEPREFIX/drive_c/$MULTISIM_REL"

if [ ! -f "\$MULTISIM_EXE" ]; then
    osascript -e "display dialog \"Multisim non trovato in:\\n\$MULTISIM_EXE\\n\\nRiesegui il programma di installazione.\" buttons {\"OK\"} default button 1 with icon stop"
    exit 1
fi

wine "\$MULTISIM_EXE" 2>/dev/null
LAUNCHER

chmod +x "$APP_DIR/Contents/MacOS/Multisim"
echo "✅ Bundle creato in ~/Applications/Multisim.app"

# ──────────────────────────────────────────────
# LAUNCHER DA TERMINALE
# ──────────────────────────────────────────────
echo "Creazione del launcher da riga di comando..."

LAUNCHER_CONTENT="#!/bin/bash
export WINEPREFIX=\"$WINEPREFIX_VAL\"
export WINEARCH=\"$WINEARCH_VAL\"
export WINEDEBUG=-all
wine \"\$WINEPREFIX/drive_c/$MULTISIM_REL\" 2>/dev/null
"

echo "$LAUNCHER_CONTENT" | sudo tee /usr/local/bin/multisim > /dev/null
sudo chmod +x /usr/local/bin/multisim || {
    echo "⚠️  Impossibile creare /usr/local/bin/multisim (permessi negati)."
    echo "   Esegui manualmente:"
    echo "   echo '$LAUNCHER_CONTENT' | sudo tee /usr/local/bin/multisim && sudo chmod +x /usr/local/bin/multisim"
}

# ──────────────────────────────────────────────
# PULIZIA
# ──────────────────────────────────────────────
echo "Pulizia dei file di installazione..."
rm -rf "$INSTALLER_DIR" "$INSTALLER_ZIP"

echo
echo "======================================="
echo "✅ Multisim 14.0 installato e attivato!"
echo "======================================="
echo
echo "Avvio da:"
echo "  📱 ~/Applications/Multisim.app (trascinabile nel Dock)"
echo "  💻 Terminale: multisim"
echo "  ⌨️  Spotlight: Cmd+Spazio → 'Multisim'"
echo
echo "Il primo avvio può richiedere 10–20 secondi."
echo
echo "Se Multisim non si avvia, esegui:"
echo "  WINEPREFIX=\"$WINEPREFIX_VAL\" winecfg"
echo "  → Imposta versione Windows: Windows XP"
echo "  → Applica e riprova"
echo
echo "Per problemi su Apple Silicon:"
echo "  arch -x86_64 wine \"...multisim.exe\""
echo
