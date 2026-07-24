tap "code-hex/tap"
tap "hashicorp/tap"
# tap "homebrew/cask-fonts" # macOSブロック内に移動
tap "knqyf263/utern"
# tap "linuxbrew/fonts" # 未使用のため削除
# tap "linuxbrew/xorg" # Linux専用ブロックに移動
tap "oven-sh/bun"
tap "rcmdnk/file"
tap "romkatv/powerlevel10k"
tap "waltarix/customs"
tap "wezterm/wezterm-linuxbrew"
tap "withgraphite/tap"
# Text-based UI library
brew "ncurses"
# BSD-style licensed readline alternative
brew "libedit"
# Cryptography and SSL/TLS Toolkit
brew "openssl@3"
# Extraction utility for .zip compressed archives
brew "unzip"
brew "asdf"
# brew "at-spi2-core" # Linux専用ブロックに移動
brew "awscli"
brew "bitwarden-cli"
brew "cairo"
brew "clang-format"
brew "cmake"
brew "code-hex/tap/neo-cowsay"
brew "composer"
brew "ctop"
brew "cython"
brew "dagger"
brew "deno"
brew "direnv"
brew "dlib"
brew "docker"
brew "docker-buildx"
brew "docker-compose"
brew "fd"
brew "flake8"
brew "flux"
# フォントはcaskで管理
brew "fontforge"
# brew "freeglut" # Linux専用ブロックに移動
brew "fzf"
brew "gcc"
# brew "gemini-cli"
brew "gh"
brew "ghc"
brew "git-lfs"
brew "glib"
brew "go"
brew "gobject-introspection"
brew "graphviz"
brew "withgraphite/tap/graphite"
# brew "gtk+" # GTK2は旧式、GTK3のみで十分
brew "gtk+3"
brew "hadolint"
brew "terraform"
brew "inih"
brew "jmeter"
brew "jq"
brew "just"
brew "utern"
brew "lazydocker"
brew "lazygit"
brew "libconfig"
brew "librsvg"
# brew "linuxbrew/xorg/libevdev" # Linux専用ブロックに移動
brew "lpeg"
brew "lsd"
brew "lua"
brew "luajit"
brew "luarocks"
brew "maven"
brew "mercurial"
# brew "mesa" # Linux専用ブロックに移動
brew "mmctl"
brew "mypy", link: false
# MySQL Server (統一バージョン)
brew "mysql@8.0"
brew "neovim"
brew "netpbm"
brew "newrelic-cli"
brew "nghttp2"
# Node.js version manager (nodenv-first approach)
brew "node", link: false  # Homebrewのnodeはリンクしない（nodenv shimsを優先）
brew "node-build"
brew "nodenv"
brew "numpy", link: false
brew "openjdk"
brew "oven-sh/bun/bun"
brew "p7zip"
brew "pango"
brew "peco"
brew "perl"
brew "pgpdump"
brew "php"
brew "pipenv"
brew "pipx"
brew "pkgconf"
brew "postgresql@14"
brew "powerlevel10k"
brew "pv"
brew "py3cairo"
brew "pygobject3"
brew "python-gdbm@3.12"
brew "python-tk@3.12"
# brew "python-tk@3.9" # python@3.12に統一
# brew "python-yq" # Go版のyqと競合するため削除
brew "python@3.12"
# brew "python@3.9" # python@3.12に統一
brew "ripgrep"
brew "ruby"
brew "rust"
brew "srt"
brew "starship"
brew "taglib"
brew "tmux"
brew "tree"
# brew "tree-sitter"
# brew "uv", link: false
# brew "vte3" # Linux専用ブロックに移動
brew "watchman"
# Package manager for Node.js (nodenv経由のnodeを使用)
# NOTE: yarnをHomebrewでインストールするより、corepackで管理することを推奨
# corepack enable後にyarn使用可能。この行は必要に応じて削除を検討
brew "yarn"
brew "yq"
brew "zsh"
brew "zsh-autosuggestions"

# フォント (macOS のみ)
if OS.mac?
  tap "homebrew/cask-fonts"
  cask "font-cica"
  cask "font-noto-sans-cjk-jp"
end

# Linux専用パッケージ
if OS.linux? && ENV["SKIP_GUI"] != "1"
  tap "linuxbrew/xorg"
  brew "at-spi2-core"
  brew "freeglut"
  brew "linuxbrew/xorg/libevdev"
  brew "mesa"
  brew "terminator", link: false
  brew "vte3"
  brew "xclip"
  brew "xsel"
end