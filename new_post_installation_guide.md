# ALTERAR PREFERECNIAS

## FILTRO LUZ AZUL

```bash
# verificar status
gsettings get org.gnome.settings-daemon.plugins.color night-light-enabled
# habilitar
gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true
# desabilitar
gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled false
# ajustar temperatura
gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 3500
```

## Ativar hot corner

```bash
gsettings set org.gnome.desktop.interface enable-hot-corners true
```

## Dock

```bash
# dock sumir automaticamente
gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed false
# multiplos monitores
gsettings set org.gnome.shell.extensions.dash-to-dock multi-monitor true
```

## Gedit

```bash
# usar font padrão
gsettings set org.gnome.gedit.preferences.editor use-default-font false
# alterar font
gsettings set org.gnome.gedit.preferences.editor editor-font 'Monospace 16'
# alterar schema de cores
gsettings set org.gnome.gedit.preferences.editor scheme 'oblivion'
# Tab-size
gsettings set org.gnome.gedit.preferences.editor tabs-size 2
```

## Monitor

```bash
# alterar monitor primário
xrandr --output DP-2 --primary
```
