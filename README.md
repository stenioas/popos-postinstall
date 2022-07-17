# popos-postinstall

<p>
  <img src="https://img.shields.io/badge/version-0.0.2-AAF683?style=flat">&nbsp;<img src="https://img.shields.io/badge/maintained%3F-Yes-339933?style=flat">&nbsp;<img src="https://img.shields.io/github/license/stenioas/popos-postinstall?style=flat">&nbsp;<img src="https://img.shields.io/github/issues/stenioas/popos-postinstall?color=violet&style=flat">&nbsp;<img src="https://img.shields.io/github/stars/stenioas/popos-postinstall?style=flat">
</p>

Script de pós-instalação do **Pop!\_OS 22.04 LTS**, que utilizo em minhas máquinas pessoais, fique a vontade para modificar e utilizar da forma que achar melhor! Se preferir você pode seguir meu [guia de instalação](https://github.com/stenioas/popos-postinstall/blob/main/postinstall_guide.md).

### Antes de começar

#### Atualize o sistema

Instale todas as atualizações disponíveis, se optar por não seguir este passo o script poderá não funcionar corretamente!

💡 **info:** Se você acabou de instalar o sistema, prepara o café e relaxa porque pode demorar um pouco!

Primeiro, altere a região dos espelhos para o Brasil.

```bash
sudo sed -i 's|http://us.|http://br.|' /etc/apt/sources.list.d/system.sources
```

Atualize o sistema.

```bash
sudo apt update && sudo apt upgrade -y
```

Atualize a partição de recuperação.

```bash
sudo pop-upgrade recovery upgrade from-release
```

Reinicie a máquina após concluir as atualizações!

```bash
sudo reboot now
```

### O que o script faz

Instala os seguintes pacotes do repositório oficial:

`lame` `libavcodec-extra` `vlc` `gimp` `inkscape` `simplescreenrecorder` `transmission-gtk` `papirus-icon-theme` `gnome-tweaks` `dconf-editor` `htop` `gparted` `neofetch` `gpick` `code` `zsh` `fzf` `wine64` `wine32` `libasound2-plugins:i386` `libsdl2-2.0-0:i386` `libdbus-1-3:i386` `libsqlite3-0:i386` `lutris` `steam-installer`

Instala os seguintes apps externos:

`Google Chrome` `Brave Browser` `Spotify` `Docker-cli` `Insomnia` `Dbeaver` `Oh-my-zsh` `Oh-my-zsh plugins` `Starship prompt` `Asdf-vm`

### Como usar

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/stenioas/popos-postinstall/main/postinstall.sh)"
```

### Contribuindo

Sinta-se a vontade para:

- :bug: Reportar bugs.
- :inbox_tray: Enviar PRs para ajudar a resolver bugs ou sugerir alterações.
- :star: Todas as contribuições são bem-vindas!

---
