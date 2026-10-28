-- configs/WindowRules.conf + UserConfigs/WindowRules.conf (converted by hyprlang2lua, hand-fixed)
-- ==================================================
--  KoolDots (2026)
--  Project URL: https://github.com/LinuxBeginnings
--  License: GNU GPLv3
--  SPDX-License-Identifier: GPL-3.0-or-later
-- ==================================================
-- Vendor defaults for window rules and layerrules
-- See https://wiki.hyprland.org/Configuring/Window-Rules/ for more

-- NOTES: This is only for Hyprland >= 0.53

--  Some samples on hwo to start apps on specific workspaces 
-- windowrule = match:tag email*, workspace 1
-- windowrule = match:tag browser*, workspace 2
-- windowrule = match:tag projects*, workspace 3
-- windowrule = match:tag screenshare*, workspace 4 silent
-- windowrule = match:tag gamestore*, workspace 5
-- windowrule = match:class ^(virt-manager)$, workspace 6 silent
-- windowrule = match:class ^(.virt-manager-wrapped)$, workspace 6 silent
-- windowrule = match:tag im*, workspace 7
-- windowrule = match:class obsidian, workspace 8
-- windowrule = match:tag games*, workspace 8
-- windowrule = match:tag multimedia*, workspace 9 silent

-- TAGS - add apps under appropriate tag to use the same settings
-- browser tags

hl.window_rule({
    match = {
        class = "^([Ff]irefox|org.mozilla.firefox|[Ff]irefox-esr|[Ff]irefox-bin)$",
    },
    tag = "+browser",
})

hl.window_rule({
    match = {
        class = "^([Gg]oogle-chrome(-beta|-dev|-unstable)?)$",
    },
    tag = "+browser",
})

hl.window_rule({
    match = {
        class = "^(chrome-.+-Default)$",
    },
    tag = "+browser",
})

hl.window_rule({
    match = {
        class = "^([Cc]hromium)$",
    },
    tag = "+browser",
})

hl.window_rule({
    match = {
        class = "^([Mm]icrosoft-edge(-stable|-beta|-dev|-unstable))$",
    },
    tag = "+browser",
})

hl.window_rule({
    match = {
        class = "^([Bb]rave-browser(-beta|-dev|-unstable)?)$",
    },
    tag = "+browser",
})

hl.window_rule({
    match = {
        class = "^([Tt]horium-browser|[Cc]achy-browser)$",
    },
    tag = "+browser",
})

hl.window_rule({
    match = {
        class = "^(zen-alpha|zen)$",
    },
    tag = "+browser",
})

-- notif tags
hl.window_rule({
    match = {
        class = "^(swaync-control-center|swaync-notification-window|swaync-client|class)$",
    },
    tag = "+notif",
})

-- KooL settings tag
hl.window_rule({
    match = {
        title = "^(KooL Quick Cheat Sheet)$",
    },
    tag = "+KooL_Cheat",
})

hl.window_rule({
    match = {
        title = "^(KooL Hyprland Settings)$",
    },
    tag = "+KooL_Settings",
})

hl.window_rule({
    match = {
        class = "^(nwg-displays|nwg-look)$",
    },
    tag = "+KooL-Settings",
})

-- terminal tags
hl.window_rule({
    match = {
        class = "^(ghostty|wezterm|Alacritty|kitty|kitty-dropterm)$",
    },
    tag = "+terminal",
})

-- email tags
hl.window_rule({
    match = {
        class = "^([Tt]hunderbird|org.mozilla.Thunderbird)$",
    },
    tag = "+email",
})

hl.window_rule({
    match = {
        class = "^(eu.betterbird.Betterbird)$",
    },
    tag = "+email",
})

hl.window_rule({
    match = {
        class = "^(org.gnome.Evolution)$",
    },
    tag = "+email",
})

-- project tags
hl.window_rule({
    match = {
        class = "^(codium|codium-url-handler|VSCodium)$",
    },
    tag = "+projects",
})

hl.window_rule({
    match = {
        class = "^(VSCode|code|code-url-handler)$",
    },
    tag = "+projects",
})

hl.window_rule({
    match = {
        class = "^(jetbrains-.+)$",
    },
    tag = "+projects",
})

hl.window_rule({
    match = {
        class = "^(dev.zed.Zed|antigravity)$",
    },
    tag = "+projects",
})

-- screenshare tags
hl.window_rule({
    match = {
        class = "^(com.obsproject.Studio)$",
    },
    tag = "+screenshare",
})

-- IM tags
hl.window_rule({
    match = {
        class = "^([Dd]iscord|[Ww]ebCord|[Vv]esktop)$",
    },
    tag = "+im",
})

hl.window_rule({
    match = {
        class = "^([Ff]erdium)$",
    },
    tag = "+im",
})

hl.window_rule({
    match = {
        class = "^([Ww]hatsapp-for-linux|ZapZap|com.rtosta.zapzap)$",
    },
    tag = "+im",
})

hl.window_rule({
    match = {
        class = "^(org.telegram.desktop|io.github.tdesktop_x64.TDesktop)$",
    },
    tag = "+im",
})

hl.window_rule({
    match = {
        class = "^(teams-for-linux)$",
    },
    tag = "+im",
})

hl.window_rule({
    match = {
        class = "^(im.riot.Riot|Element)$",
    },
    tag = "+im",
})

-- game tags
hl.window_rule({
    match = {
        class = "^(gamescope)$",
    },
    tag = "+games",
})

hl.window_rule({
    match = {
        class = "^(steam_app_\\d+)$",
    },
    tag = "+games",
})

hl.window_rule({
    match = {
        xdg_tag = "^(proton-game)$",
    },
    tag = "+games",
})

-- gamestore tags
hl.window_rule({
    match = {
        class = "^([Ss]team)$",
    },
    tag = "+gamestore",
})

hl.window_rule({
    match = {
        title = "^([Ll]utris)$",
    },
    tag = "+gamestore",
})

hl.window_rule({
    match = {
        class = "^(com.heroicgameslauncher.hgl)$",
    },
    tag = "+gamestore",
})

-- file-manager tags
hl.window_rule({
    match = {
        class = "^([Tt]hunar|org.gnome.Nautilus|[Pp]cmanfm-qt|org.kde.dolphin)$",
    },
    tag = "+file-manager",
})

hl.window_rule({
    match = {
        class = "^(app.drey.Warp)$",
    },
    tag = "+file-manager",
})

-- wallpaper tags
hl.window_rule({
    match = {
        class = "^([Ww]aytrogen)$",
    },
    tag = "+wallpaper",
})

-- multimedia tags
hl.window_rule({
    match = {
        class = "^([Aa]udacious)$",
    },
    tag = "+multimedia",
})

-- multimedia-video tags
hl.window_rule({
    match = {
        class = "^([Mm]pv|vlc)$",
    },
    tag = "+multimedia_video",
})

-- settings tags
hl.window_rule({
    match = {
        title = "^(ROG Control)$",
    },
    tag = "+settings",
})

hl.window_rule({
    match = {
        class = "^(wihotspot(-gui)?)$",
    },
    tag = "+settings",
})

hl.window_rule({
    match = {
        class = "^([Bb]aobab|org.gnome.[Bb]aobab)$",
    },
    tag = "+settings",
})

hl.window_rule({
    match = {
        class = "^(gnome-disks|wihotspot(-gui)?)$",
    },
    tag = "+settings",
})

hl.window_rule({
    match = {
        title = "(Kvantum Manager)",
    },
    tag = "+settings",
})

hl.window_rule({
    match = {
        class = "^(file-roller|org.gnome.FileRoller)$",
    },
    tag = "+settings",
})

hl.window_rule({
    match = {
        class = "^(nm-applet|nm-connection-editor|blueman-manager)$",
    },
    tag = "+settings",
})

hl.window_rule({
    match = {
        class = "^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$",
    },
    tag = "+settings",
})

hl.window_rule({
    match = {
        class = "^(qt5ct|qt6ct)$",
    },
    tag = "+settings",
})

hl.window_rule({
    match = {
        class = "(xdg-desktop-portal-gtk)",
    },
    tag = "+settings",
})

hl.window_rule({
    match = {
        class = "^(org.kde.polkit-kde-authentication-agent-1)$",
    },
    tag = "+settings",
})

hl.window_rule({
    match = {
        class = "^([Rr]ofi)$",
    },
    tag = "+settings",
})

hl.window_rule({
    match = {
        class = "^(btrfs-assistant)$",
    },
    tag = "+settings",
})

hl.window_rule({
    match = {
        class = "^(timeshift-gtk)$",
    },
    tag = "+settings",
})

-- viewer tags
hl.window_rule({
    match = {
        class = "^(gnome-system-monitor|org.gnome.SystemMonitor|io.missioncenter.MissionCenter)$",
    },
    tag = "+viewer",
})

hl.window_rule({
    match = {
        class = "^(evince)$",
    },
    tag = "+viewer",
})

hl.window_rule({
    match = {
        class = "^(eog|org.gnome.Loupe)$",
    },
    tag = "+viewer",
})

hl.window_rule({
    match = {
        class = "^([Dd][Bb]eaver)$",
    },
    tag = "+dbeaver",
})

hl.window_rule({
    match = {
        title = "^([Dd][Bb]eaver)$",
    },
    tag = "+dbeaver",
})

hl.window_rule({
    match = {
        class = "^([Cc]lash[- ][Vv]erge)$",
    },
    tag = "+vpnclient",
})

-- Some special override rules
hl.window_rule({
    match = {
        tag = "multimedia",
    },
    no_blur = true,
    opacity = 1.0,
})

-- FLOAT
hl.window_rule({
    match = {
        class = "([Zz]oom|onedriver|onedriver-launcher)",
    },
    float = true,
})

hl.window_rule({
    match = {
        class = "^(mpv|com.github.rafostar.Clapper)$",
    },
    float = true,
})

hl.window_rule({
    match = {
        class = "^([Qq]alculate-gtk)$",
    },
    float = true,
})

-- float popups and dialogue
hl.window_rule({
    match = {
        title = "^(Authentication Required)$",
    },
    float = true,
    center = true,
})

hl.window_rule({
    match = {
        class = "^(xfce-polkit|mate-polkit|polkit-mate-authentication-agent-1)$",
        title = "^(Authentication required|Authentication Required)$",
    },
    float = true,
    center = true,
    size = "(monitor_w*0.35) (monitor_h*0.35)",
})

hl.window_rule({
    match = {
        class = "(codium|codium-url-handler|VSCodium)",
        title = "negative:(.*codium.*|.*VSCodium.*)",
    },
    float = true,
})

hl.window_rule({
    match = {
        class = "^(com.heroicgameslauncher.hgl)$",
        title = "negative:(Heroic Games Launcher)",
    },
    float = true,
})

hl.window_rule({
    match = {
        class = "^([Ss]team)$",
        title = "negative:^([Ss]team)$",
    },
    float = true,
})

hl.window_rule({
    match = {
        title = "^(Add Folder to Workspace)$",
    },
    float = true,
    size = "(monitor_w*0.7) (monitor_h*0.6)",
    center = true,
})

hl.window_rule({
    match = {
        title = "^(Save As)$",
    },
    float = true,
    size = "(monitor_w*0.7) (monitor_h*0.6)",
    center = true,
})

hl.window_rule({
    match = {
        initial_title = "(Open Files)",
    },
    float = true,
    size = "(monitor_w*0.7) (monitor_h*0.6)",
})

hl.window_rule({
    match = {
        title = "^(SDDM Background)$",
    },
    float = true,
    center = true,
    size = "(monitor_w*0.16) (monitor_h*0.12)",
})

hl.window_rule({
    match = {
        class = "^(yad)$",
    },
    float = true,
    center = true,
    size = "(monitor_w*0.2) (monitor_h*0.2)",
})

hl.window_rule({
    match = {
        class = "^(hyprland-donate-screen)$",
    },
    float = true,
    center = true,
})

-- SIZE

-- POSITION
hl.window_rule({
    match = {
        title = "^(ROG Control)$",
    },
    center = true,
})

hl.window_rule({
    match = {
        title = "^(Keybindings)$",
    },
    center = true,
})

hl.window_rule({
    match = {
        class = "^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$",
    },
    center = true,
})

hl.window_rule({
    match = {
        class = "^([Ww]hatsapp-for-linux|ZapZap|com.rtosta.zapzap)$",
    },
    center = true,
})

hl.window_rule({
    match = {
        class = "^(nm-connection-editor)$",
    },
    center = true,
})

hl.window_rule({
    match = {
        class = "^(nm-applet)$",
        title = "^(Wi-Fi Network Authentication Required)$",
    },
    center = true,
})

-- windowrule to avoid idle for fullscreen apps
hl.window_rule({
    match = {
        fullscreen = true,
    },
    idle_inhibit = "fullscreen",
})

hl.window_rule({
    match = {
        fullscreen = true,
    },
    idle_inhibit = "fullscreen",
})

hl.window_rule({
    match = {
        class = ".*",
    },
    idle_inhibit = "fullscreen",
})

hl.window_rule({
    match = {
        title = ".*",
    },
    idle_inhibit = "fullscreen",
})

-- OPACITY
hl.window_rule({
    match = {
        tag = "browser",
    },
    opacity = "0.99 0.8",
})

hl.window_rule({
    match = {
        tag = "projects",
    },
    opacity = "0.9 0.8",
})

hl.window_rule({
    match = {
        tag = "im",
    },
    opacity = "0.94 0.86",
})

hl.window_rule({
    match = {
        tag = "multimedia",
    },
    opacity = "0.94 0.86",
})

hl.window_rule({
    match = {
        tag = "file-manager",
    },
    opacity = "0.9 0.8",
})

hl.window_rule({
    match = {
        tag = "terminal",
    },
    opacity = "0.9 0.7",
})

hl.window_rule({
    match = {
        class = "^(gedit|org.gnome.TextEditor|mousepad)$",
    },
    opacity = "0.8 0.7",
})

hl.window_rule({
    match = {
        class = "^(deluge)$",
    },
    opacity = "0.9 0.8",
})

hl.window_rule({
    match = {
        class = "^(seahorse)$",
    },
    opacity = "0.9 0.8",
})

-- BLUR & FULLSCREEN

-- This not gonna take the focus to the window that appears 
-- when hovering over some of the parts of the IntelliJ Products
hl.window_rule({
    match = {
        class = "^(jetbrains-.*)$",
    },
    no_initial_focus = true,
})

hl.window_rule({
    match = {
        title = "^(wind.*)$",
    },
    no_initial_focus = true,
})

hl.window_rule({
    name = "vpnclient-float",
    match = {
        tag = "vpnclient",
    },
    float = true,
    center = true,
    opacity = "0.95 0.6",
    keep_aspect_ratio = true,
    size = "(monitor_w*0.5) (monitor_h*0.5)",
})

hl.window_rule({
    name = "mpv-float",
    match = {
        class = "mpv",
    },
    float = true,
    move = "monitor_w*0.49 monitor_h*0.07",
    opacity = "0.95 0.75",
    pin = true,
    keep_aspect_ratio = true,
    size = "(monitor_w*0.5) (monitor_h*0.5)",
})

hl.window_rule({
    name = "Picture-in-Picture",
    match = {
        title = "^[Pp]icture-in-[Pp]icture$",
    },
    float = true,
    move = "monitor_w*0.69 monitor_h*0.07",
    opacity = "0.95 0.75",
    pin = true,
    keep_aspect_ratio = true,
    size = "(monitor_w*0.3) (monitor_h*0.3)",
})

hl.window_rule({
    name = "Picture-in-Picture2",
    match = {
        title = "^([Кк]артинка в [Кк]артинке)$",
    },
    float = true,
    move = "monitor_w*0.59 monitor_h*0.07",
    opacity = "1.0 override 1.0 override",
    pin = true,
    keep_aspect_ratio = true,
    size = "(monitor_w*0.4) (monitor_h*0.4)",
})

hl.window_rule({
    match = {
        title = "^([Кк]артинка в [Кк]артинке)$",
    },
    opacity = "1.0 override 1.0 override",
})

-- Named rule for CachyOS Kernel Manager
hl.window_rule({
    name = "CachyOS Kernel Manager",
    match = {
        class = "^(org.cachyos.KernelManager)$",
        title = "^(CachyOS Kernel Manager)$",
        initial_class = "^(org.cachyos.KernelManager)$",
        initial_title = "^(CachyOS Kernel Manager)$",
    },
    float = true,
    center = true,
    size = "(monitor_w*0.6) (monitor_h*0.6)",
})

-- Named rule for Mainline Kernels
hl.window_rule({
    name = "Mainline Kernels",
    match = {
        class = "^(mainline-gtk)$",
        title = "^(Mainline Kernels)$",
        initial_class = "^(mainline-gtk)$",
        initial_title = "^(Mainline Kernels)$",
    },
    float = true,
    center = true,
    size = "(monitor_w*0.45) (monitor_h*0.55)",
})

-- Named rule for Kwallet 
hl.window_rule({
    name = "Kwallet",
    match = {
        class = "^(org.kde.kwalletmanager)$",
        title = "^(Wallet Manager)$",
        initial_class = "^(org.kde.kwalletmanager)$",
        initial_title = "^(Wallet Manager)$",
    },
    float = true,
    center = true,
    size = "(monitor_w*0.6) (monitor_h*0.6)",
})

-- Named rule for NVIDIA Settings
hl.window_rule({
    name = "NVIDIA Settings",
    match = {
        class = "^(nvidia-settings)$",
        title = "^(NVIDIA Settings)$",
        initial_class = "^(nvidia-settings)$",
        initial_title = "^(NVIDIA Settings)$",
    },
    float = true,
    center = true,
    size = "(monitor_w*0.6) (monitor_h*0.6)",
})

-- Named rule for CachyOS Package Installer
hl.window_rule({
    name = "CachyOS Package Installer",
    match = {
        class = "^(org.cachyos.cachyos-pi)$",
        title = "^(CachyOS Package Installer)$",
        initial_class = "^(org.cachyos.cachyos-pi)$",
        initial_title = "^(CachyOS Package Installer)$",
    },
    float = true,
    center = true,
    size = "(monitor_w*0.6) (monitor_h*0.6)",
})

-- Named rule for Shelly
hl.window_rule({
    name = "Shelly",
    match = {
        class = "^(com.shellyorg.shelly)$",
        title = "^(Shelly)$",
        initial_class = "^(com.shellyorg.shelly)$",
        initial_title = "^(Shelly)$",
    },
    float = true,
    center = true,
    size = "(monitor_w*0.6) (monitor_h*0.6)",
})

-- Named rule for CachyOS Hello
hl.window_rule({
    name = "CachyOS Hello",
    match = {
        class = "^(CachyOSHello)$",
        title = "^(CachyOS Hello)$",
        initial_class = "^(CachyOSHello)$",
        initial_title = "^(CachyOS Hello)$",
    },
    float = true,
    center = true,
    size = "(monitor_w*0.6) (monitor_h*0.6)",
})

-- Named rule for Cache Cleaner - Octopi
hl.window_rule({
    name = "Cache Cleaner - Octopi",
    match = {
        class = "^(octopi-cachecleaner)$",
        title = "^(Cache Cleaner - Octopi)$",
        initial_class = "^(octopi-cachecleaner)$",
        initial_title = "^(Cache Cleaner - Octopi)$",
    },
    float = true,
    center = true,
    size = "(monitor_w*0.6) (monitor_h*0.6)",
})

-- Named rule for Octopi Package Manager
hl.window_rule({
    name = "Octopi Package Manager",
    match = {
        class = "^(octopi)$",
        title = "^(Octopi)$",
        initial_class = "^(octopi)$",
        initial_title = "^(Octopi)$",
    },
    float = true,
    center = true,
    size = "(monitor_w*0.6) (monitor_h*0.6)",
})

-- Named rule for Repository Editor - Octopi
hl.window_rule({
    name = "Repository Editor - Octopi",
    match = {
        class = "^(octopi-repoeditor)$",
        title = "^(Repository Editor - Octopi)$",
        initial_class = "^(octopi-repoeditor)$",
        initial_title = "^(Repository Editor - Octop)$",
    },
    float = true,
    center = true,
    size = "(monitor_w*0.6) (monitor_h*0.6)",
})

-- Named rule for KooL Cheat (tag)
hl.window_rule({
    name = "KooL Cheat (tag)",
    match = {
        tag = "KooL_Cheat",
    },
    float = true,
    center = true,
    size = "(monitor_w*0.65) (monitor_h*0.9)",
})

-- Named rule for Wallpaper (tag)
hl.window_rule({
    name = "Wallpaper (tag)",
    match = {
        tag = "wallpaper",
    },
    float = true,
    center = true,
    size = "(monitor_w*0.7) (monitor_h*0.7)",
    opacity = "0.9 0.7",
})

-- Named rule for Settings (tag)
hl.window_rule({
    name = "Settings (tag)",
    match = {
        tag = "settings",
    },
    float = true,
    center = true,
    size = "(monitor_w*0.7) (monitor_h*0.7)",
    opacity = "0.8 0.7",
})

-- Named rule for Viewer (tag)
hl.window_rule({
    name = "Viewer (tag)",
    match = {
        tag = "viewer",
    },
    float = true,
    center = true,
    opacity = "0.82 0.75",
})

-- Named rule for KooL Settings (tag)
hl.window_rule({
    name = "KooL Settings (tag)",
    match = {
        tag = "KooL-Settings",
    },
    float = true,
    center = true,
})

-- Named rule for Multimedia Video (tag)
hl.window_rule({
    name = "Multimedia Video (tag)",
    match = {
        tag = "multimedia_video",
    },
    no_blur = true,
    opacity = 1.0,
    move = "monitor_w*0.49 monitor_h*0.07",
    pin = true,
    keep_aspect_ratio = true,
    size = "(monitor_w*0.5) (monitor_h*0.5)",
})

hl.window_rule({
    name = "dbeaver",
    match = {
        tag = "dbeaver",
    },
    no_blur = true,
    float = true,
    opacity = 1.0,
    center = true,
    keep_aspect_ratio = true,
    size = "(monitor_w*0.5) (monitor_h*0.5)",
})

-- Named rule for Games (tag)
hl.window_rule({
    name = "Games (tag)",
    match = {
        tag = "games",
    },
    no_blur = true,
    immediate = true,
    fullscreen = false,
})

-- Named rule for Ferdium
hl.window_rule({
    name = "Ferdium",
    match = {
        class = "^([Ff]erdium)$",
    },
    float = true,
    center = true,
    size = "(monitor_w*0.6) (monitor_h*0.7)",
})

-- Named rule for Calculators
hl.window_rule({
    name = "Calculators",
    match = {
        class = "(org.gnome.Calculator|qalculate-gtk)",
    },
    float = true,
    center = true,
    size = "(monitor_w*0.55) (monitor_h*0.45)",
})

-- Named rule for Thunar Dialogs
hl.window_rule({
    name = "Thunar Dialogs",
    match = {
        class = "([Tt]hunar)",
        title = "negative:(.*[Tt]hunar.*)",
    },
    float = true,
    center = true,
})

-- Named rule for Bitwarden
hl.window_rule({
    name = "Bitwarden",
    match = {
        class = "^(Bitwarden)$",
        title = "^(Bitwarden)$",
        initial_class = "^(Bitwarden)$",
        initial_title = "^(Bitwarden)$",
    },
    float = true,
    center = true,
    size = "(monitor_w*0.6) (monitor_h*0.6)",
})

-- Named rule for hyprpwcenter audio control panel
hl.window_rule({
    name = "hyprland audio panel",
    match = {
        class = "^(hyprpwcenter)$",
        initial_class = "^(hyprpwcenter)$",
    },
    float = true,
    center = true,
    size = "(monitor_w*0.6) (monitor_h*0.6)",
})

-- Named rule for Garida Assistant 
hl.window_rule({
    name = "Garuda Assistant",
    match = {
        class = "^(garuda-assistant)$",
        title = "^(Garuda Assistant)$",
        initial_class = "^(garuda-assistant)$",
        initial_title = "^(Garuda Assistant)$",
    },
    float = true,
    center = true,
    size = "(monitor_w*0.6) (monitor_h*0.6)",
})

-- Named rule for HyprMod HL config GUI 
hl.window_rule({
    name = "HyprMod GUI",
    match = {
        class = "^(com.github.hyprmod)$",
        title = "^(HyprMod)$",
        initial_class = "^(com.github.hyprmod)$",
        initial_title = "^(HyprMod)$",
    },
    float = true,
    center = true,
    size = "(monitor_w*0.7) (monitor_h*0.75)",
})

-- Named rule for easy effects  
hl.window_rule({
    name = "EasyEffects",
    match = {
        class = "^(com.github.wwmm.easyeffects)$",
        title = "^(Easy Effects)$",
        initial_class = "^(com.github.wwmm.easyeffects)$",
        initial_title = "^(Easy Effects)$",
    },
    float = true,
    center = true,
    size = "(monitor_w*0.6) (monitor_h*0.65)",
})

-- Named rule for Mousam weather GUI 
hl.window_rule({
    name = "Mousam Weather",
    match = {
        class = "^(io.github.amit9838.mousam)$",
        title = "^(Mousam)$",
        initial_class = "^(io.github.amit9838.mousam)$",
        initial_title = "^(Mousam)$",
    },
    float = true,
    center = true,
    size = "(monitor_w*0.7) (monitor_h*0.75)",
})

--windowrule {
--    name = Picture-in-Picture No Blur
--    match:title = ^(Картинка в картинке)$
--    no_blur = on
--    opacity=1.0
--}
--windowrule {
--    name = PiP Opaque
--    match:title = ^(Картинка в картинке)$
--    opacity = 1.0 override 1.0 override
--    no_blur = on
--    opaque = on
--    
--}
--


-- UserConfigs/WindowRules.conf
hl.window_rule({ match = { class = "^(virt-manager)$" }, no_shortcuts_inhibit = true })

-- LAYER RULES (rofi/swaync/quickshell-overview rules replaced by caelestia's)
hl.layer_rule({ match = { namespace = "quickshell:overview(-blur)?" }, blur = true, ignore_alpha = 0.5 })
hl.layer_rule({ match = { namespace = "launcher" }, blur = true, animation = "popin 80%" }) -- fuzzel (caelestia clipboard/emoji)
hl.layer_rule({ match = { namespace = "hyprpicker" }, animation = "fade" })
hl.layer_rule({ match = { namespace = "selection" },  animation = "fade" }) -- slurp
hl.layer_rule({ match = { namespace = "caelestia-(border-exclusion|area-picker)" }, no_anim = true })
hl.layer_rule({ match = { namespace = "caelestia-(drawers|background)" }, animation = "fade" })
