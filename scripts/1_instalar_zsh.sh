#!/bin/bash

# Atualiza os pacotes do sistema
echo "Atualizando pacotes do sistema..."
sudo apt update && sudo apt upgrade -y

# Instala dependências básicas
echo "Instalando dependências..."
sudo apt install -y zsh git curl wget fzf bat pipx

# Instala o Zsh como shell padrão
echo "Definindo o Zsh como shell padrão..."
chsh -s $(which zsh)

# Instala o Oh My Zsh
echo "Instalando Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Instala o tema Powerlevel10k
echo "Instalando tema Powerlevel10k..."
if [ ! -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $HOME/.oh-my-zsh/custom/themes/powerlevel10k
fi

# Instala os plugins
echo "Instalando plugins do Zsh..."
ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}
PLUGINS=(
    "git"
    "emoji-clock"
    "history"
    "you-should-use"
    "command-not-found"
    "gitignore"
    "web-search"
    "fzf"
    "zsh-interactive-cd"
    "zsh-autosuggestions"
    "zsh-syntax-highlighting"
    "zsh-bat"
)

# Baixa e instala os plugins necessários
git clone https://github.com/laggardkernel/gitignore $ZSH_CUSTOM/plugins/gitignore
git clone https://github.com/jomo/emoji-clock $ZSH_CUSTOM/plugins/emoji-clock
git clone https://github.com/MichaelAquilina/zsh-you-should-use $ZSH_CUSTOM/plugins/you-should-use
git clone https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/command-not-found $ZSH_CUSTOM/plugins/command-not-found
git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-interactive-cd.git $ZSH_CUSTOM/plugins/zsh-interactive-cd
git clone https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/fzf $ZSH_CUSTOM/plugins/fzf
git clone https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/web-search $ZSH_CUSTOM/plugins/web-search
git clone https://github.com/Aloxaf/fzf-tab $ZSH_CUSTOM/plugins/fzf-tab
git clone https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/history $ZSH_CUSTOM/plugins/history
git clone https://github.com/clarketm/zsh-completions $ZSH_CUSTOM/plugins/zsh-bat

# Configura o arquivo .zshrc
echo "Configurando .zshrc..."
cat <<EOF > $HOME/.zshrc
export ZSH="$HOME/.oh-my-zsh"

# Tema do Zsh
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins do Zsh
plugins=(${PLUGINS[*]})

source \$ZSH/oh-my-zsh.sh

# Mudar a cor das sugestões (por padrão é cinza)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=245'

# Configurar web search
ZSH_WEB_SEARCH_ENGINES=(claude "https://claude.ai/new?q=")

# Configurar zsh-interactive-cd para usar Ctrl+T ao invés de Tab
bindkey '^T' fzf-cd-widget

# Carregar agente SSH se existir
# Carrega o script do ssh-agent
source ~/.ssh/ssh-agent-init.sh

# Executa a inicialização silenciosamente
ssh_agent_init

export GPG_TTY=\$(tty)
EOF

# Instala o pipx
echo "Instalando pipx e garantindo path..."

sudo apt install pipx  # Instalar o pipx (se ainda não tiver)

# garante que o path está configurado
echo "Configurando o pipx e garantindo path..."
pipx ensurepath

# Instala o Seshat para realizar commits
echo "Instala o Seshat para automatizar commits"
pipx install git+https://github.com/juniormartinxo/seshat.git

# Finaliza
echo "Instalação concluída! Reinicie o terminal ou execute 'exec zsh' para aplicar as mudanças."
