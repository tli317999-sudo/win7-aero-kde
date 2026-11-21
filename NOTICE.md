# 版权与素材声明

本仓库包含**两类完全不同授权状态**的内容，请务必区分。

---

## 1. 配置与脚本（可自由使用）

以下内容由本仓库作者编写，以 **MIT 许可证** 发布（见 `LICENSE`）：

- `install.sh`
- `configs/`（KDE 各配置文件）
- `color-schemes/Aero.colors`
- 仓库内的说明文档

---

## 2. 第三方素材（不属于本仓库，也未获得再分发授权）

`assets/` 目录下的内容**全部来自第三方**，本仓库作者不拥有其任何权利：

| 目录 | 来源 | 权利状态 |
|---|---|---|
| `assets/icons/Windows 7 Aero/` | Microsoft Windows 7 图标资源 | 微软版权与商标 |
| `assets/icons/aero-drop/` | Windows 7 Aero 光标 | 微软版权 |
| `assets/sounds/Windows 7/` | Microsoft Windows 7 系统音效 | 微软版权 |
| `assets/wallpapers/` | Microsoft Windows 7 自带壁纸 | 微软版权 |

这些素材存放于此仅用于**个人桌面美化的可复现存档**。

**明确声明：**

- 本项目与 Microsoft Corporation 无任何关联、合作或背书关系
- Windows、Windows 7、Windows Aero 是 Microsoft Corporation 的商标
- 这些素材**不适用**本仓库的 MIT 许可证
- 这些素材的合法使用范围由你所在司法辖区的法律决定；在多数地区，以这种方式再分发它们**可能构成侵权**
- 若你是权利持有人并要求移除，请开 issue，我会立即删除对应文件

---

## 3. 上游主题

本仓库的配置与安装脚本是对以下项目的**使用与调优**，而非其衍生分发：

- [AeroThemePlasma](https://github.com/aeroshell-desktop/aerothemeplasma) — **AGPL-3.0**
  包含 Plasma 全局主题、SMOD 窗口装饰、SevenStart / SevenTasks、SDDM 登录主题、
  Aero 玻璃模糊 KWin 特效等。
- `aeroshell-libplasma` / `aeroshell-workspace` / `aeroshell-smod` /
  `aeroshell-kwin-components` — 同为 AeroThemePlasma 项目的组件，AGPL-3.0
- 图标主题与音效主题通过 AUR 包 `aerothemeplasma-icons-git` /
  `aerothemeplasma-sounds-git` 获取

`install.sh` 通过 AUR 安装这些组件，不包含、也不重新打包其源代码。

---

## 4. 第三方组件许可

若你分发基于本仓库配置的系统镜像，除上述微软素材问题外，还需遵守：

- AeroThemePlasma 及其组件：AGPL-3.0
- KDE Plasma / Qt：LGPL / GPL 系列
- SMOD 窗口装饰引擎：AGPL-3.0-or-later（见 AUR 包 `aeroshell-smod-git`）
