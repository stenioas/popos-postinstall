#!/usr/bin/env bash
# ----------------------------------------------------------------------------
# Script   : install.sh
# Descrição: Script de pós-instalação do Pop!_OS 22.04
# Versão   : 0.0.2
# Autor    : Stenio Silveira <stenioas@gmail.com>
# Data     : 03/07/2022
# Licença  : GNU/GPL v3.0
# ============================================================================

# ============================================================================
# VARIÁVEIS GLOBAIS
# ----------------------------------------------------------------------------

# customização do cursor
BOLD="$(tput bold 2>/dev/null || printf '')"
RESET="$(tput sgr0 2>/dev/null || printf '')"
UNDERLINE="$(tput smul 2>/dev/null || printf '')"
GREY="$(tput setaf 0 2>/dev/null || printf '')"
RED="$(tput setaf 1 2>/dev/null || printf '')"
GREEN="$(tput setaf 2 2>/dev/null || printf '')"
YELLOW="$(tput setaf 3 2>/dev/null || printf '')"
BLUE="$(tput setaf 4 2>/dev/null || printf '')"
MAGENTA="$(tput setaf 5 2>/dev/null || printf '')"
CYAN="$(tput setaf 6 2>/dev/null || printf '')"
WHITE="$(tput setaf 7 2>/dev/null || printf '')"

# título do script
TITLE="Pop!_OS 22.04 LTS - Script de pós-instalação"

# diretório temporário
DIR_TEMP="${HOME}/Downloads/temp"

# lista de pacotes essenciais
PKGS_LIST=(
  "lame"
  "libavcodec-extra"
  "vlc"
  "gimp"
  "inkscape"
  "simplescreenrecorder"
  "transmission-gtk"
  "papirus-icon-theme"
  "gnome-tweaks"
  "dconf-editor"
  "htop"
  "gparted"
  "neofetch"
  "gpick"
  "code"
  "devscripts"
  "shellcheck"
  "zsh"
  "wine64"
  "wine32"
  "libasound2-plugins:i386"
  "libsdl2-2.0-0:i386"
  "libdbus-1-3:i386"
  "libsqlite3-0:i386"
  "lutris"
  "steam-installer"
)

# ============================================================================
# CONFIGURAÇÕES
# ----------------------------------------------------------------------------
# 1 = ON

OPTION_EXTRA_PACKAGES=1
OPTION_CHROME=1
OPTION_BRAVE=1
OPTION_SPOTIFY=1
OPTION_DOCKER=1
OPTION_INSOMNIA=1
OPTION_DBEAVER=1
OPTION_TERMINAL=1
OPTION_ASDF=1

# ============================================================================
# FUNÇÕES COMUNS
# ----------------------------------------------------------------------------

# imprime o título do script
_print_title() {
  clear
  _print_dline
  echo -e " ${BOLD}${WHITE}${TITLE}${RESET}"
  _print_dline
}

# imprime subtítulos
_print_subtitle() {
  echo -e "\n${BOLD}:: ${GREEN}${*}${RESET}"
}

# imprime mensagem da ação atual
_print_action() {
  echo -e "[ ] ${1}"
  tput cuu1
  tput sc
}

# imprime linha simples da largura do console
_print_line() {
  local t_cols
  t_cols=$(tput cols)
  echo -e "${CYAN}$(seq -s '-' $(( t_cols + 1 )) | tr -d "[:digit:]")${RESET}"
}

# imprime linha dupla da largura do console
_print_dline() {
  local t_cols
  t_cols=$(tput cols)
  echo -e "${CYAN}$(seq -s '=' $(( t_cols + 1 )) | tr -d "[:digit:]")${RESET}"
}

# imprime retorno de sucesso
_print_ok() {
  tput rc
  tput cuf 1
  echo -e "${BOLD}${GREEN}✔${RESET}"
}

# imprime retorno de erro
_print_error() {
  tput rc
  tput cuf 1
  echo -e "${BOLD}${RED}✘${RESET}"
  [[ "$#" -ne 0 ]] && echo -e "${RED}${BOLD} ➜ Erro:${RESET} ${BOLD}${*}${RESET}"
}

# imprime retorno de alerta
_print_warn() {
  tput rc
  tput cuf 1
  echo -e "${BOLD}${YELLOW}!${RESET}"
  [[ "$#" -ne 0 ]] && echo -e "${BOLD}${YELLOW} ➜ Aviso:${RESET} ${BOLD}${*}${RESET}"
}

# imprime mensagem informativa
_print_info() {
  echo -e "${BLUE}${BOLD} ➜ Info:${RESET} ${BOLD}${*}${RESET}"
}

# spinner de progresso de ação
# &> /dev/null & PID=$!; _progress $PID
_progress() {
  tput civis
  _spinny() {
    local spin
    spin="/-\|"
    tput cuf 1
    echo -ne "\b${YELLOW}${BOLD}${spin:i++%${#spin}:1}${RESET}"
  }
  while true; do
    if kill -0 "$PID" &> /dev/null; then
      tput rc
      tput cuf 1
      _spinny
      sleep 0.2
    else
      wait "$PID"
      retcode=$?
      if [ $retcode == 0 ] || [ $retcode == 255 ]; then
        _print_ok
      else
        _print_error
      fi
      break
    fi
  done
  tput cnorm
}

_reboot() {
  read -p -r " Deseja reiniciar a máquina? [s/N]: " OPTION
  [[ ${OPTION,,} == "s" ]] && sudo reboot now
}

# pausa a ação e aguarda pressionar qualquer tecla
_pause() {
  printf '\n'
  read -e -sn 1 -p " Pressione qualquer tecla para continuar..."
}

# verifica conexão com a internet
_check_connection() {
  _connection_test() {
    ping -q -w 1 -c 1 "$(ip r | grep default | awk 'NR==1 {print $3}')" &> /dev/null && return 1 || return 0
  }
  _print_action "Verificando conexão com a internet..."
  if ! _connection_test; then
    _print_ok
  else
    _print_error "Você está desconectado!"
    _print_line
    echo -e "${BOLD}Script encerrado!${RESET}"
    exit 1
  fi
}

# ============================================================================
# FUNÇÕES DA DISTRO
# ----------------------------------------------------------------------------

# executa apt update
_update() {
  _print_subtitle "Atualizando informações dos pacotes"
  sudo apt update
}

# executa apt upgrade -y
_upgrade() {
  _print_subtitle "Atualizando sistema"
  sudo apt upgrade -y
}

# instala uma lista de pacotes
_package_install_list() {
  _print_subtitle "Instalando pacotes"
  for PKG in "$@"; do
    _print_action "Instalando ${PKG}"
    sudo apt install -y "$PKG" &> /dev/null & PID=$!; _progress $PID
  done
}

# instala um pacote com apt install
_package_install() {
  sudo apt install -y "$1" &> /dev/null & PID=$!; _progress $PID
}

# verifica se o pacote já existe no sistema
_is_package_installed() {
  dpkg -s "$1" &> /dev/null && return 0;
  return 1
}

_apt_autoclean() {
  _print_action "Limpando cache de pacotes..."
  sudo apt autoclean -y &> /dev/null & PID=$!; _progress $PID
}

_apt_autoremove() {
  _print_action "Removendo pacotes desnecessários..."
  sudo apt autoremove -y &> /dev/null & PID=$!; _progress $PID
}

# ============================================================================
# FUNÇÕES MICRO
# ----------------------------------------------------------------------------
_set_chrome() {
  _print_action "Adicionando chave pública Google Chrome..."
  [[ -f /usr/share/keyrings/google-chrome.gpg ]] && sudo rm /usr/share/keyrings/google-chrome.gpg
  curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg &> /dev/null & PID=$!; _progress $PID

  _print_action "Adicionando repositório Google Chrome..."
  [[ -f /etc/apt/sources.list.d/google-chrome.list ]] && sudo rm /etc/apt/sources.list.d/google-chrome.list
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list &> /dev/null & PID=$!; _progress $PID

  PKGS_LIST+=("google-chrome-stable")
}

_set_brave() {
  _print_action "Adicionando chave pública Brave Browser..."
  [[ -f /usr/share/keyrings/brave-browser-archive-keyring.gpg ]] && sudo rm /usr/share/keyrings/brave-browser-archive-keyring.gpg
  curl -fsSL https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg | sudo gpg --dearmor -o /usr/share/keyrings/brave-browser-archive-keyring.gpg &> /dev/null & PID=$!; _progress $PID
  
  _print_action "Adicionando repositório Brave Browser..."
  [[ -f /etc/apt/sources.list.d/brave-browser-release.list ]] && sudo rm /etc/apt/sources.list.d/brave-browser-release.list
  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list &> /dev/null & PID=$!; _progress $PID

  PKGS_LIST+=("brave-browser")
}

_set_spotify() {
  _print_action "Adicionando chave pública Spotify..."
  [[ -f /usr/share/keyrings/spotify.gpg ]] && sudo rm /usr/share/keyrings/spotify.gpg
  curl -fsSL https://download.spotify.com/debian/pubkey_5E3C45D7B312C643.gpg | sudo gpg --dearmor -o /usr/share/keyrings/spotify.gpg &> /dev/null & PID=$!; _progress $PID

  _print_action "Adicionando repositório Spotify..."
  [[ -f /etc/apt/sources.list.d/spotify.list ]] && sudo rm /etc/apt/sources.list.d/spotify.list
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/spotify.gpg] http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list &> /dev/null & PID=$!; _progress $PID

  PKGS_LIST+=("spotify-client")
}

_set_docker() {
  _print_action "Adicionando chave pública Docker..."
  [[ -f /usr/share/keyrings/docker.gpg ]] && sudo rm /usr/share/keyrings/docker.gpg
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker.gpg &> /dev/null & PID=$!; _progress $PID
  
  _print_action "Adicionando repositório Docker..."
  [[ -f /etc/apt/sources.list.d/docker.list ]] && sudo rm /etc/apt/sources.list.d/docker.list
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list &> /dev/null & PID=$!; _progress $PID

  PKGS_LIST+=("docker-ce")
  PKGS_LIST+=("docker-compose-plugin")
}

_set_insomnia() {
  _print_action "Adicionando repositório Insomnia..."
  [[ -f /etc/apt/sources.list.d/insomnia.list ]] && sudo rm /etc/apt/sources.list.d/insomnia.list
  echo "deb [trusted=yes arch=amd64] https://download.konghq.com/insomnia-ubuntu/ default all" | sudo tee -a /etc/apt/sources.list.d/insomnia.list &> /dev/null & PID=$!; _progress $PID

  PKGS_LIST+=("insomnia")
}

_set_extra_packages() {
  _print_subtitle "Configurando respositórios extras"
  [[ $OPTION_CHROME -eq 1 ]] && _set_chrome
  [[ $OPTION_BRAVE -eq 1 ]] && _set_brave
  [[ $OPTION_SPOTIFY -eq 1 ]] && _set_spotify
  [[ $OPTION_DOCKER -eq 1 ]] && _set_docker
  [[ $OPTION_INSOMNIA -eq 1 ]] && _set_insomnia
}

_install_dbeaver() {
  local filepath
  filepath="$DIR_TEMP/dbeaver-ce_latest_amd64.deb"
  _print_action "Baixando Dbeaver..."
  wget -c -O "$filepath" "https://dbeaver.io/files/dbeaver-ce_latest_amd64.deb" &> /dev/null & PID=$!; _progress $PID
  _print_action "Instalando Dbeaver..."
  sudo dpkg -i "$filepath" &> /dev/null & PID=$!; _progress $PID
}

_set_terminal() {
  _print_subtitle "Customizando o terminal"
  _print_action "Alterando o shell padrão para o zsh..."
  if [[ $SHELL != $(which zsh) ]]; then
    sudo usermod --shell "$(which zsh)" "$USER" &> /dev/null & PID=$!; _progress $PID
  else
    _print_warn "o zsh já é o shell padrão!"
  fi

  _print_action "Instalando oh-my-zsh..."
  if [[ ! -d $HOME/.oh-my-zsh ]]; then
    curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | sh &> /dev/null & PID=$!; _progress $PID
  else
    _print_warn "já existe!"
  fi

  _print_action "Baixando plugin zsh-syntax-highlighting..."
  if [[ ! -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting ]]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}"/plugins/zsh-syntax-highlighting &> /dev/null & PID=$!; _progress $PID
  else
    _print_warn "já existe!"
  fi

  _print_action "Baixando zsh-autosuggestions..."
  if [[ ! -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions ]]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}"/plugins/zsh-autosuggestions &> /dev/null & PID=$!; _progress $PID
  else
    _print_warn "já existe!"
  fi

  _print_action "Adicionando plugins ao arquivo ~/.zshrc..."
  if [[ -f "$HOME/.zshrc" ]]; then
    if [[ -n $(grep -n 'plugins=(git)' ~/.zshrc) ]]; then
      if [[ $OPTION_ASDF -eq 1 ]]; then
        sed -i -e "$(grep -n 'plugins=(git)' ~/.zshrc | cut -f1 -d:)s/plugins=(git)/plugins=(git zsh-syntax-highlighting zsh-autosuggestions asdf)/" ~/.zshrc & PID=$!; _progress $PID
      else
        sed -i -e "$(grep -n 'plugins=(git)' ~/.zshrc | cut -f1 -d:)s/plugins=(git)/plugins=(git zsh-syntax-highlighting zsh-autosuggestions)/" ~/.zshrc & PID=$!; _progress $PID
      fi
    else
      _print_warn "o arquivo não está como esperado!"
    fi
  else
    _print_error "arquivo inexistente: .zshrc!"
  fi

  _print_action "Baixando fzf..."
  if [[ ! -d "$HOME/.fzf" ]]; then
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf &> /dev/null & PID=$!; _progress $PID
    _print_action "Instalando fzf..."
    bash ~/.fzf/install --all &> /dev/null & PID=$!; _progress $PID
  else
    _print_warn "já existe!"
  fi

  _print_action "Baixando powerlevel10k..."
  if [[ ! -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k ]]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"/themes/powerlevel10k &> /dev/null & PID=$!; _progress $PID
  else
    _print_warn "já existe!"
  fi

  _print_action "Adicionando powerlevel10k ao arquivo ~/.zshrc..."
  if [[ -f "$HOME/.zshrc" ]]; then
    if [[ -n $(grep -n 'ZSH_THEME="robbyrussell"' ~/.zshrc) ]]; then
      sed -i -e "$(grep -n 'ZSH_THEME="robbyrussell"' ~/.zshrc | cut -f1 -d:)s/ZSH_THEME=\"robbyrussell\"/ZSH_THEME=\"powerlevel10k\/powerlevel10k\"/" ~/.zshrc & PID=$!; _progress $PID
    else
      _print_warn "o arquivo não está como esperado!"
    fi
  else
    _print_error "arquivo inexistente: .zshrc!"
  fi
}

_set_asdf() {
  _print_action "Baixando asdf-vm..."
  if [[ ! -d "$HOME/.asdf" ]]; then
    git clone https://github.com/asdf-vm/asdf.git ~/.asdf &> /dev/null & PID=$!; _progress $PID
  else
    _print_warn "já existe!"
  fi

  _print_action "Configurando asdf..."
  if [[ -f "$HOME/.zshrc" ]]; then
    if [[ -z $(grep -n '. $HOME/.asdf/asdf.sh' ~/.zshrc) ]]; then
      echo -e '\n# asdf-vm\n. $HOME/.asdf/asdf.sh' >> "${HOME}/.zshrc" & PID=$!; _progress $PID
    else
      _print_warn "a linha já existe!"
    fi
  else
    _print_error "arquivo inexistente: .zshrc!"
  fi
}

_set_themes() {
  _print_subtitle "Aplicando temas"

  _print_action "Definindo tema de ícones Papirus-Dark..."
  gsettings set org.gnome.desktop.interface icon-theme Papirus-Dark &> /dev/null & PID=$!; _progress $PID
  
  _print_action "Baixando papirus-folders..."
  git clone https://github.com/PapirusDevelopmentTeam/papirus-folders.git "$DIR_TEMP"/papirus-folders &> /dev/null & PID=$!; _progress $PID

  _print_action "Instalando papirus-folders..."
  cd "$DIR_TEMP"/papirus-folders && ./install.sh &> /dev/null & PID=$!; _progress $PID
  
  _print_action "Alterando cor das pastas para Adwaita..."
  papirus-folders -C paleorange --theme Papirus-Dark &> /dev/null & PID=$!; _progress $PID

  _print_action "Baixando McMojave-cursors..."
  git clone https://github.com/vinceliuice/McMojave-cursors "$DIR_TEMP"/McMojave-cursors &> /dev/null & PID=$!; _progress $PID
  
  _print_action "Instalando McMojave-cursors..."
  cd "$DIR_TEMP"/McMojave-cursors && sudo ./install.sh &> /dev/null & PID=$!; _progress $PID

  _print_action "Definindo tema do cursor McMojave-cursors..."
  gsettings set org.gnome.desktop.interface cursor-theme McMojave-cursors &> /dev/null & PID=$!; _progress $PID
}

_clean() {
  _print_subtitle "Limpando o sistema"
  _apt_autoclean
  _apt_autoremove

  _print_action "Removendo pasta temporária..."
  sudo rm -rf "$DIR_TEMP" &> /dev/null & PID=$!; _progress $PID
  
}

# ============================================================================
# FUNÇÕES MACRO
# ----------------------------------------------------------------------------
_init() {
  # apenas para autenticar como sudo antes do script iniciar realmente
  sudo ls > /dev/null
  _print_title
  _pause
  _print_title
  _check_connection
  _print_action "Criando pasta temporária..."
  mkdir -p "$HOME"/Downloads/temp &> /dev/null & PID=$!; _progress $PID
}

_setup() {
  [[ $OPTION_EXTRA_PACKAGES -eq 1 ]] && _set_extra_packages

  _update
  
  _package_install_list "${PKGS_LIST[@]}"

  [[ $OPTION_EXTRA_PACKAGES -eq 1 && $OPTION_DBEAVER -eq 1 ]] && _install_dbeaver
  [[ $OPTION_TERMINAL -eq 1 ]] && _set_terminal
  [[ $OPTION_ASDF -eq 1 ]] && _set_asdf

  _set_themes

  _update
  _upgrade
}

_finish() {
  _clean
  _print_dline
  echo -e "\n${BOLD} Concluído!${RESET}\n"
  _reboot
}

# ============================================================================
# EXECUTANDO
# ----------------------------------------------------------------------------
_init
_setup
_finish
