#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# win7-aero-kde — 一键部署 Windows 7 Aero 风格的 KDE Plasma 6 桌面
#
# 目标系统：Arch Linux（或基于 Arch 的发行版）+ KDE Plasma 6.8 + Wayland
# 上游主题：[AeroThemePlasma](https://github.com/aeroshell-desktop/aerothemeplasma) (AGPL-3.0)
#
# 用法：
#   ./install.sh              完整安装
#   ./install.sh --no-pkgs    跳过 AUR 打包（已装过 ATP 时用）
#   ./install.sh --unsafe-no-backup  不备份现有配置（不推荐）
# ---------------------------------------------------------------------------
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$HOME/.local/state/win7-aero-kde-backup-$STAMP"
SKIP_PKGS=0
DO_BACKUP=1

for arg in "$@"; do
    case $arg in
        --no-pkgs) SKIP_PKGS=1 ;;
        --unsafe-no-backup) DO_BACKUP=0 ;;
        -h|--help) sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "未知参数: $arg" >&2; exit 2 ;;
    esac
done

c_ok()   { printf '\033[32m  ✓ %s\033[0m\n' "$*"; }
c_warn() { printf '\033[33m  ! %s\033[0m\n' "$*"; }
c_info() { printf '\033[36m→ %s\033[0m\n' "$*"; }
die()    { printf '\033[31m✗ %s\033[0m\n' "$*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# 0. 环境检查
# ---------------------------------------------------------------------------
c_info "检查环境"
[[ -f /etc/arch-release ]] || c_warn "不是 Arch Linux，下面的 pacman/yay 步骤需要你自行换算"
[[ ${XDG_CURRENT_DESKTOP:-} == *KDE* ]] || c_warn "当前不在 KDE 会话里，配置会写入但需要重新登录才生效"

PLASMA_VER=$(kreadconfig6 --file /usr/share/plasma/plasmarc --group General --key Version 2>/dev/null || true)
c_ok "KDE 会话: ${XDG_CURRENT_DESKTOP:-未知} / ${XDG_SESSION_TYPE:-未知}"

# ---------------------------------------------------------------------------
# 1. 安装 AeroThemePlasma（AUR）
# ---------------------------------------------------------------------------
if (( ! SKIP_PKGS )); then
    c_info "安装 AeroThemePlasma（需要 sudo 密码，编译需要几分钟）"
    command -v yay >/dev/null || die "需要 yay 或 paru 来装 AUR 包；也可加 --no-pkgs 手动装"

    yay -S --needed --noconfirm \
        aerothemeplasma-desktop-git \
        aeroshell-libplasma-git \
        aeroshell-workspace-git \
        aeroshell-kwin-components-git \
        aeroshell-smod-git || c_warn "AUR 安装未完成，请检查上面的报错"
    c_ok "ATP 组件已安装"
else
    c_info "跳过 AUR 安装（--no-pkgs）"
fi

# ---------------------------------------------------------------------------
# 2. 备份现有配置
# ---------------------------------------------------------------------------
if (( DO_BACKUP )); then
    c_info "备份现有配置到 $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    for f in kdeglobals dolphinrc kwinrc plasmarc kscreenlockerrc konsolerc; do
        [[ -f $HOME/.config/$f ]] && cp -a "$HOME/.config/$f" "$BACKUP_DIR/"
    done
    [[ -d $HOME/.config/kdedefaults ]] && cp -a "$HOME/.config/kdedefaults" "$BACKUP_DIR/"
    [[ -d /etc/sddm.conf.d ]] && cp -a /etc/sddm.conf.d "$BACKUP_DIR/" 2>/dev/null || true
    c_ok "已备份"
fi

# ---------------------------------------------------------------------------
# 3. 部署素材（图标 / 光标 / 音效）
# ---------------------------------------------------------------------------
c_info "部署图标、光标与音效到 /usr/share（需要 sudo）"
sudo cp -a "$REPO_DIR/assets/icons/Windows 7 Aero" /usr/share/icons/
sudo cp -a "$REPO_DIR/assets/icons/aero-drop"       /usr/share/icons/
sudo cp -a "$REPO_DIR/assets/sounds/Windows 7"      /usr/share/sounds/
sudo cp -a "$REPO_DIR/color-schemes/Aero.colors"    /usr/share/color-schemes/
c_ok "素材已就位"

# 壁纸放到用户目录
mkdir -p "$HOME/Pictures/wallpapers/windows7"
cp -a "$REPO_DIR"/assets/wallpapers/*.jpg "$HOME/Pictures/wallpapers/windows7/"
c_ok "壁纸已放到 ~/Pictures/wallpapers/windows7"

# ---------------------------------------------------------------------------
# 4. 部署配置（把 __HOME__ 替换成真实家目录）
# ---------------------------------------------------------------------------
c_info "写入 KDE 配置"
mkdir -p "$HOME/.config/kdedefaults"
deploy() {  # $1=源  $2=目标
    sed "s|__HOME__|$HOME|g" "$1" > "$2"
}
deploy "$REPO_DIR/configs/kdeglobals"             "$HOME/.config/kdeglobals"
deploy "$REPO_DIR/configs/dolphinrc"              "$HOME/.config/dolphinrc"
deploy "$REPO_DIR/configs/kwinrc"                 "$HOME/.config/kwinrc"
deploy "$REPO_DIR/configs/plasmarc"               "$HOME/.config/plasmarc"
deploy "$REPO_DIR/configs/kscreenlockerrc"        "$HOME/.config/kscreenlockerrc"
deploy "$REPO_DIR/configs/konsolerc"              "$HOME/.config/konsolerc"
deploy "$REPO_DIR/configs/kdedefaults-kdeglobals" "$HOME/.config/kdedefaults/kdeglobals"

# 图标 / 光标 / 音效主题键
kwriteconfig6 --file kdeglobals --group Icons    --key Theme       "Windows 7 Aero"
kwriteconfig6 --file kdeglobals --group General  --key SoundTheme  "Windows 7"
kwriteconfig6 --file kcminputrc --group Mouse    --key cursorTheme "aero-drop"
c_ok "配置已写入"

# ---------------------------------------------------------------------------
# 5. 修复 smodglow 找不到库的问题
#    上游 PKGBUILD 把 org.smod.smod.so 装在装饰插件目录里，不在库搜索路径上，
#    导致 KWin 效果 smodglow 加载失败。
# ---------------------------------------------------------------------------
SMOD_SO=/usr/lib/qt6/plugins/org.kde.kdecoration3/org.smod.smod.so
if [[ -f $SMOD_SO && ! -e /usr/lib/org.smod.smod.so ]]; then
    c_info "修复 smodglow 库路径（需要 sudo）"
    sudo ln -s "$SMOD_SO" /usr/lib/org.smod.smod.so
    c_ok "已建立软链 /usr/lib/org.smod.smod.so"
elif [[ -e /usr/lib/org.smod.smod.so ]]; then
    c_ok "smodglow 库路径已存在"
else
    c_warn "没找到 $SMOD_SO，跳过 smodglow 修复"
fi

# ---------------------------------------------------------------------------
# 6. 窗口装饰切到 SMOD
# ---------------------------------------------------------------------------
kwriteconfig6 --file kwinrc --group org.kde.kdecoration3 --key theme "org.smod.smod"
c_ok "窗口装饰 = org.smod.smod"

# ---------------------------------------------------------------------------
# 7. SDDM 登录主题
#    注意：sddm.conf.d 会读取目录里【所有文件】，不只有 *.conf，
#    所以必须把别的主题配置挪出该目录，而不是改扩展名。
# ---------------------------------------------------------------------------
if [[ -d /etc/sddm.conf.d ]]; then
    c_info "配置 SDDM 登录主题（需要 sudo）"
    sudo install -m644 "$REPO_DIR/configs/sddm/zzz-aerothemeplasma.conf" \
        /etc/sddm.conf.d/zzz-aerothemeplasma.conf
    stale=$(sudo find /etc/sddm.conf.d -maxdepth 1 -type f ! -name 'zzz-aerothemeplasma.conf' \
            -exec grep -l 'Current=cyberkde' {} + 2>/dev/null || true)
    if [[ -n $stale ]]; then
        for f in $stale; do
            c_warn "停用旧主题配置: $f"
            sudo mv "$f" "$BACKUP_DIR/$(basename "$f")"
        done
    fi
    c_ok "SDDM 主题 = sddm-theme-mod"
fi

# ---------------------------------------------------------------------------
# 8. 刷新缓存 + 应用壁纸
# ---------------------------------------------------------------------------
c_info "刷新图标缓存"
rm -f "$HOME/.cache/icon-cache.kcache" 2>/dev/null || true
kbuildsycoca6 --noincremental >/dev/null 2>&1 || true

if command -v qdbus6 >/dev/null && pgrep -x plasmashell >/dev/null; then
    c_info "应用壁纸"
    WP="$HOME/Pictures/wallpapers/windows7/w7-lighthouse.jpg"
    qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript \
        "var d=desktops();for(var i=0;i<d.length;i++){d[i].wallpaperPlugin='org.kde.image';d[i].currentConfigGroup=['Wallpaper','org.kde.image','General'];d[i].writeConfig('Image','file://$WP');d[i].writeConfig('FillMode',2);}" \
        >/dev/null 2>&1 && c_ok "壁纸已设置"
fi

# ---------------------------------------------------------------------------
echo
c_ok "安装完成"
cat <<'EOF'

下一步：
  1. 注销，在 SDDM 会话列表里选 **AeroThemePlasma (Wayland)** 登录
  2. 首次进入会弹设置向导，配置外观与默认值
  3. 光标主题需要重新登录后才完全生效

已知上游缺陷（不影响主体效果）：
  · smodglow 效果会报 `SMOD RCC "smodgloweffecttextures" not found`
    —— 上游 aeroshell-kwin-components 没有打包该纹理资源
  · 若曾装过其它主题（如 CyberKDE），它们的应用级配置（dolphinrc 里的
    [Icons] Theme=）会覆盖全局设置，需要手动删除

回滚：备份在 ~/.local/state/win7-aero-kde-backup-*
EOF
