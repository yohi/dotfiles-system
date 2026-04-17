#!/bin/bash
set -e

echo "=== Arto Setup Script for Ubuntu (nix-portable + nixGL) ==="

# 1. nix-portable の準備
if [ ! -f "./nix-portable" ]; then
    echo "Downloading nix-portable..."
    curl -L https://github.com/DavHau/nix-portable/releases/latest/download/nix-portable-$(uname -m) > ./nix-portable
    chmod +x ./nix-portable
fi

# 2. Nix設定の最適化
echo "Configuring Nix..."
mkdir -p ~/.config/nix
if ! grep -q "experimental-features" ~/.config/nix/nix.conf 2>/dev/null; then
    echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
fi

# 3. Arto と nixGL のプリフェッチ（アイコン取得のため）
echo "Pre-fetching Arto and nixGL (This may take a moment)..."
./nix-portable nix run --impure github:guibou/nixGL#nixGLIntel -- echo "Graphics driver bridge ready."
./nix-portable nix run github:arto-app/Arto -- --help > /dev/null 2>&1 || true

# 4. アイコンの動的検索
echo "Searching for Arto icon..."
ICON_PATH=$(find ~/.nix-portable/nix/store -maxdepth 3 -name "*arto*" -type d 2>/dev/null | xargs -I{} find {} -name "arto-app-*.png" 2>/dev/null | head -n 1)

if [ -z "$ICON_PATH" ]; then
    echo "Warning: Icon not found. Using default system icon."
    ICON_PATH="system-run"
fi

# 5. .desktop ファイルの生成
echo "Generating desktop entry..."
DESKTOP_FILE="$HOME/.local/share/applications/arto.desktop"
NP_PATH=$(readlink -f ./nix-portable)

cat <<EOF > "$DESKTOP_FILE"
[Desktop Entry]
Name=Arto
GenericName=Code Editor
Comment=Lambda-ready Code Editor
Exec=$NP_PATH nix run --impure github:guibou/nixGL#nixGLIntel -- $NP_PATH nix run github:arto-app/Arto
Icon=$ICON_PATH
Type=Application
Terminal=false
Categories=Development;TextEditor;
StartupWMClass=arto
EOF

chmod +x "$DESKTOP_FILE"

echo "=== Setup Complete! ==="
echo "1. Open your Applications menu (Super key)."
echo "2. Search for 'Arto' and launch it."
echo "3. Right-click the icon in the Dock and select 'Add to Favorites'."
