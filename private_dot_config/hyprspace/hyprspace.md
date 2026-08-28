# Hyprspace Cheatsheet — Starter Defaults

## Workspaces

| Shortcut            | Action                       |
|---------------------|------------------------------|
| `Alt + 0…7`         | Switch to workspace 0…7      |
| `Alt + Shift + 0…7` | Move window to workspace 0…7 |
| `Alt + Tab`         | Focus the previous window    |

Workspaces 1–6 stay on the configured primary monitor. Persistent workspace 7
stays on the configured secondary monitor; persistent workspace 0 is unpinned.

## Focus and Move

| Shortcut                | Action                         |
|-------------------------|--------------------------------|
| `Alt + H/J/K/L`         | Focus left/down/up/right       |
| `Alt + Shift + H/J/K/L` | Move window left/down/up/right |

## Layout

| Shortcut              | Action                               |
|-----------------------|--------------------------------------|
| `Alt + Shift + Space` | Toggle floating/tiling               |
| `Alt + Shift + /`     | Toggle horizontal/vertical tiles     |
| `Alt + Shift + ,`     | Toggle horizontal/vertical accordion |
| `Alt + -`             | Shrink focused window                |
| `Alt + =`             | Grow focused window                  |
| `Alt + F`             | Toggle fullscreen                    |
| `Alt + Cmd + F`       | Toggle macOS native fullscreen       |

## Service Mode (`Alt + Shift + ;`)

| Shortcut          | Action                              |
|-------------------|-------------------------------------|
| `Esc`             | Reload config and exit service mode |
| `R`               | Flatten workspace tree and exit     |
| `F`               | Toggle floating/tiling and exit     |
| `Alt + Shift + ;` | Exit service mode                   |

## App Routing

| App                                                        | Workspace | Layout    |
|------------------------------------------------------------|-----------|-----------|
| Finder, Path Finder, Tailscale                             | 0         | floating  |
| Ghostty, Cmux, T3 Code, GitButler                          | 1         | tiled     |
| IntelliJ, Sublime Text                                     | 2         | accordion |
| Chrome, Zen Browser, Vivaldi, Arc                          | 3         | floating  |
| Spark, Fantastical, Outlook                                | 4         | tiled     |
| WhatsApp, Threema, Infomaniak Chat, Messages, Slack, Teams | 5         | tiled     |

Spark is resized to 1400 points wide. Routing runs both for new windows and for
windows already open when Hyprspace starts.

## Other Floating Applications

- Screen Sharing
- iPhone Simulator
- CleanMyMac and CleanMyMac X
- Bitwarden
- QuickTime Player
