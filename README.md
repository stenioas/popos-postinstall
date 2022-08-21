# popos-postinstall

<p>
  <img src="https://img.shields.io/badge/version-0.0.2-AAF683?style=flat">&nbsp;<img src="https://img.shields.io/badge/maintained%3F-Yes-339933?style=flat">&nbsp;<img src="https://img.shields.io/github/license/stenioas/popos-postinstall?style=flat">&nbsp;<img src="https://img.shields.io/github/issues/stenioas/popos-postinstall?color=violet&style=flat">&nbsp;<img src="https://img.shields.io/github/stars/stenioas/popos-postinstall?style=flat">
</p>

Script de pós-instalação do **Pop!\_OS 22.04 LTS**, que utilizo em minhas máquinas pessoais, fique a vontade para modificar e utilizar da forma que achar melhor! Se preferir você pode seguir meu [guia de instalação](./postinstall_guide.md).

### Antes de começar

#### Atualize o sistema

Instale todas as atualizações disponíveis, se optar por não seguir este passo o script poderá não funcionar corretamente!

💡 **info:** Se você acabou de instalar o sistema, prepara o café e relaxa porque pode demorar um pouco!

💡 **dica:** Caso ocorra algum erro ao atualizar pelo terminal você pode utilizar a Pop!\_Shop para instalar as atualizações.

```bash
sudo apt update && sudo apt upgrade -y
```

Atualize a partição de recuperação caso ela exista.

💡 **dica:** Se você utilizou o modo "Clean Install" essa partição foi criada automaticamente.

```bash
sudo pop-upgrade recovery upgrade from-release
```

Reinicie a máquina após concluir as atualizações!

```bash
sudo reboot now
```

### O que o script faz

Instala os seguintes pacotes do repositório oficial:

`lame` `libavcodec-extra` `vlc` `gimp` `inkscape` `simplescreenrecorder` `transmission-gtk` `papirus-icon-theme` `gnome-tweaks` `dconf-editor` `htop` `gparted` `neofetch` `gpick` `code` `devscripts` `shellcheck` `zsh` `wine64` `wine32` `libasound2-plugins:i386` `libsdl2-2.0-0:i386` `libdbus-1-3:i386` `libsqlite3-0:i386` `lutris` `steam-installer`

Instala os seguintes apps externos:

`Google Chrome` `Brave Browser` `Spotify` `Docker-cli` `Insomnia` `Dbeaver`

Extras:

`oh-my-zsh` `fzf` `powerlevel10k` `asdf-vm` `papirus-folders` `McMojave-cursors`

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
