#!/usr/bin/env bash
# ----------------------------------------------------------------------------
# Script   : install.sh
# Descrição: Script de pós-instalação do Pop!_OS 22.04
# Versão   : 0.0.1
# Autor    : Stenio Silveira <stenioas@gmail.com>
# Data     : 03/07/2022
# Licença  : GNU/GPL v3.0
# ============================================================================

# ============================================================================
# VARIÁVEIS GLOBAIS
# ----------------------------------------------------------------------------

# cursor
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

# lista de pacotes essenciais
PKGS_LIST="lame libavcodec-extra vlc gimp inkscape simplescreenrecorder \
          transmission-gtk papirus-icon-theme gnome-tweaks dconf-editor \
          htop gparted neofetch gpick code zsh fzf ca-certificates gnupg \
          curl lsb-release wine64 wine32 libasound2-plugins:i386 \
          libsdl2-2.0-0:i386 libdbus-1-3:i386 libsqlite3-0:i386 lutris \
          steam-installer"

# ============================================================================
# FUNÇÕES COMUNS
# ----------------------------------------------------------------------------

# imprime o título do script
_title() {
  clear
  _line
  echo " ${BOLD}${TITLE}${RESET}"
  _line
}

# imprime mensagem da ação atual
_action() {
  tput sc
  echo -n "${CYAN}[ ]${RESET} $1"
}

# imprime linha da largura do console
_line() {
  local t_cols=$(tput cols)
  echo -e "${CYAN}${BOLD}$(seq -s '-' $(( t_cols + 1 )) | tr -d "[:digit:]")${RESET}"
}

# imprime retorno de sucesso
_done() {
  tput rc
  tput cuf 1
  echo "${GREEN}${BOLD}✔${RESET}"
}

# imprime retorno de erro
_error() {
  [[ "$#" -ne 0 ]] && echo -n " ${RED}${BOLD}➜${RESET} ${BOLD}$@${RESET}"
  tput rc
  tput cuf 1
  echo "${RED}${BOLD}✖${RESET}"
}

# imprime retorno de alerta
_warn() {
  echo -n " ${YELLOW}${BOLD}➜${RESET} ${BOLD}$@${RESET}"
  tput rc
  tput cuf 1
  echo "${RED}${BOLD}!${RESET}"
}

# imprime mensagem informativa
_info() {
  echo " ${BLUE}${BOLD}==> info:${RESET} $@"
}

# spinner de progresso de ação
_progress() {
  tput civis
  _spinny() {
    local spin="/-\|"
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
        _done
      else
        _error
      fi
      break
    fi
  done
  tput cnorm
}

# pausa a ação e aguarda pressionar qualquer tecla
_pause() {
  read -e -sn 1 -p " Pressione qualquer tecla para continuar..."
}

# verifica conexão com a internet
_check_connection() {
  _connection_test() {
    ping -q -w 1 -c 1 "$(ip r | grep default | awk 'NR==1 {print $3}')" &> /dev/null && return 1 || return 0
  }
  _action "Verificando conexão com a internet"
  if ! _connection_test; then
    _done
  else
    _error "Você está desconectado!"
    _line
    echo -e "    ${BOLD}Script encerrado!${RESET}"
    exit 1
  fi
}

# ============================================================================
# FUNÇÕES DA DISTRO
# ----------------------------------------------------------------------------

# executa apt update
_update() {
  _action "Atualizando informações de pacotes"
  sudo apt update &> /dev/null & PID=$!; _progress $PID
}

# executa apt upgrade -y
_upgrade() {
  _action "Atualizando sistema"
  sudo apt upgrade -y &> /dev/null & PID=$!; _progress $PID
}

# instala pacote com apt install
_package_install() {
  #local c_testing="--dry-run" # descomente essa linha para utilizar o modo dry-run do apt
  for PKG in $1; do
    _action "Instalando ${PKG}"
    if ! _is_package_installed "${PKG}"; then
      sudo apt install "${c_testing}" "${PKG}" -y &> /dev/null & PID=$!; _progress $PID
    else
      _done
    fi
  done
}

# verifica se o pacote já existe no sistema
_is_package_installed() {
  dpkg -s "$1" &> /dev/null && return 0;
  return 1
}

_clean() {
  _action "Limpando cache de pacotes"
  sudo apt autoclean -y &> /dev/null & PID=$!; _progress $PID

  _action "Limpando pacotes desnecessários"
  sudo apt autoremove -y &> /dev/null & PID=$!; _progress $PID
}

# ============================================================================
# FUNÇÕES MICRO
# ----------------------------------------------------------------------------
_set_chrome() {
  _action "Adicionando chave pública do Google Chrome"
  [[ -f /usr/share/keyrings/google-chrome.gpg ]] && sudo rm /usr/share/keyrings/google-chrome.gpg
  curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg &> /dev/null & PID=$!; _progress $PID

  _action "Adicionando repositório do Google Chrome à lista de fontes"
  [[ -f /etc/apt/sources.list.d/google-chrome.list ]] && sudo rm /etc/apt/sources.list.d/google-chrome.list
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list &> /dev/null & PID=$!; _progress $PID
}

_set_brave() {
  _action "Adicionando chave pública do Brave Browser"
  [[ -f /usr/share/keyrings/brave-browser-archive-keyring.gpg ]] && sudo rm /usr/share/keyrings/brave-browser-archive-keyring.gpg
  curl -fsSL https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg | sudo gpg --dearmor -o /usr/share/keyrings/brave-browser-archive-keyring.gpg &> /dev/null & PID=$!; _progress $PID
  
  _action "Adicionando repositório do Brave Browser à lista de fontes"
  [[ -f /etc/apt/sources.list.d/brave-browser-release.list ]] && sudo rm /etc/apt/sources.list.d/brave-browser-release.list
  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list &> /dev/null & PID=$!; _progress $PID
}

_set_spotify() {
  _action "Adicionando chave pública do Spotify"
  [[ -f /usr/share/keyrings/spotify.gpg ]] && sudo rm /usr/share/keyrings/spotify.gpg
  curl -fsSL https://download.spotify.com/debian/pubkey_5E3C45D7B312C643.gpg | sudo gpg --dearmor -o /usr/share/keyrings/spotify.gpg &> /dev/null & PID=$!; _progress $PID

  _action "Adicionando repositório do Spotify à lista de fontes"
  [[ -f /etc/apt/sources.list.d/spotify.list ]] && sudo rm /etc/apt/sources.list.d/spotify.list
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/spotify.gpg] http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list &> /dev/null & PID=$!; _progress $PID
}

_set_docker() {
  _action "Adicionando chave pública do Docker"
  [[ -f /usr/share/keyrings/docker.gpg ]] && sudo rm /usr/share/keyrings/docker.gpg
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker.gpg &> /dev/null & PID=$!; _progress $PID
  
  _action "Adicionando repositório do Docker à lista de fontes"
  [[ -f /etc/apt/sources.list.d/docker.list ]] && sudo rm /etc/apt/sources.list.d/docker.list
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list &> /dev/null & PID=$!; _progress $PID
}

_set_insomnia() {
  _action "Adicionando repositório do Insomnia à lista de fontes"
  [[ -f /etc/apt/sources.list.d/insomnia.list ]] && sudo rm /etc/apt/sources.list.d/insomnia.list
  echo "deb [trusted=yes arch=amd64] https://download.konghq.com/insomnia-ubuntu/ default all" | sudo tee -a /etc/apt/sources.list.d/insomnia.list &> /dev/null & PID=$!; _progress $PID
}

_install_dbeaver() {
  local file_path=~/Downloads/dbeaver-ce_latest_amd64.deb
  _action "Baixando Dbeaver"
  wget -c -O $file_path "https://dbeaver.io/files/dbeaver-ce_latest_amd64.deb" &> /dev/null & PID=$!; _progress $PID
  _action "Instalando Dbeaver"
  if ! _is_package_installed "dbeaver-ce"; then
    sudo dpkg -i "$file_path" &> /dev/null & PID=$!; _progress $PID
  else
    _done
  fi
  _action "Removendo pacote baixado"
  rm $file_path &> /dev/null & PID=$!; _progress $PID
}

_set_default_shell() {
  _action "Alterando o shell padrão para o zsh"
  if [[ $SHELL != $(which zsh) ]]; then
    sudo usermod --shell $(which zsh) $USER &> /dev/null & PID=$!; _progress $PID
  else
    _warn "o zsh já é o shell padrão!"
  fi
}

_set_ohmyzsh() {
  _action "Instalando oh-my-zsh"
  if [[ ! -d $HOME/.oh-my-zsh ]]; then
    curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | sh &> /dev/null & PID=$!; _progress $PID
  else
    _warn "já existe!"
  fi

  _action "Baixando plugin zsh-syntax-highlighting"
  if [[ ! -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting ]]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting &> /dev/null & PID=$!; _progress $PID
  else
    _warn "já existe!"
  fi

  _action "Baixando zsh-autosuggestions"
  if [[ ! -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions ]]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions &> /dev/null & PID=$!; _progress $PID
  else
    _warn "já existe!"
  fi
}

_set_starship() {
  _action "Instalando Starship prompt"
  if ! _is_package_installed "starship"; then
    sh <( curl -fsSL "https://starship.rs/install.sh" ) -y &> /dev/null & PID=$!; _progress $PID
  else
    _done
  fi

  _action "Adicionando starship ao arquivo ~/.zshrc"
  if [[ -f "$HOME/.zshrc" ]]; then
    if [[ -z $(grep -n 'eval "$(starship init zsh)"' ~/.zshrc) ]]; then
      echo -e '\n# Starship prompt\neval "$(starship init zsh)"' >> ~/.zshrc & PID=$!; _progress $PID
    else
      _warn "a linha já existe!"
    fi
  else
    _error "arquivo inexistente: .zshrc!"
  fi
}

_set_asdf() {
  _action "Baixando asdf-vm"
  if [[ ! -d "$HOME/.asdf" ]]; then
    git clone https://github.com/asdf-vm/asdf.git ~/.asdf &> /dev/null & PID=$!; _progress $PID
  else
    _warn "já existe!"
  fi

  _action "Configurando asdf"
  if [[ -f "$HOME/.zshrc" ]]; then
    if [[ -z $(grep -n '. $HOME/.asdf/asdf.sh' ~/.zshrc) ]]; then
      echo -e '\n# asdf-vm\n. $HOME/.asdf/asdf.sh' >> "${HOME}/.zshrc" & PID=$!; _progress $PID
    else
      _warn "a linha já existe!"
    fi
  else
    _error "arquivo inexistente: .zshrc!"
  fi
}

_set_ohmyzsh_plugins() {
  _action "Adicionando plugins ao arquivo ~/.zshrc"
  if [[ -f "$HOME/.zshrc" ]]; then
    if [[ -n $(grep -n 'plugins=(git)' ~/.zshrc) ]]; then
      sed -i -e "$(grep -n 'plugins=(git)' ~/.zshrc | cut -f1 -d:)s/plugins=(git)/plugins=(git zsh-syntax-highlighting zsh-autosuggestions asdf)/" ~/.zshrc & PID=$!; _progress $PID
    else
      _warn "o arquivo não está como esperado!"
    fi
  else
    _error "arquivo inexistente: .zshrc!"
  fi
}

# ============================================================================
# FUNÇÕES MACRO
# ----------------------------------------------------------------------------
_init() {
  # apenas para autenticar como sudo antes do script iniciar realmente
  sudo ls > /dev/null
  _title
  read -e -sn 1 -p " Pressione qualquer tecla para iniciar!"
  _title
  _check_connection
}

_setup() {
  _package_install "$PKGS_LIST"
  _set_chrome
  _set_brave
  _set_spotify
  _set_docker
  _set_insomnia
  _update
  _package_install "google-chrome-stable"
  _package_install "brave-browser"
  _package_install "spotify-client"
  _package_install "docker-ce docker-ce-cli containerd.io docker-compose-plugin"
  _package_install "insomnia"
  _install_dbeaver
  _set_default_shell
  _set_ohmyzsh
  _set_starship
  _set_asdf
  _set_ohmyzsh_plugins
}

_finish() {
  _clean
  _line
  echo "    ${BOLD}Concluído!${RESET}"
}

# ============================================================================
# EXECUTANDO
# ----------------------------------------------------------------------------
_init
_setup
_finish
