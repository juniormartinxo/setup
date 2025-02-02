#!/bin/bash

# Cores para mensagens
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Adicionar no início do script
umask 077  # Restringe permissões de arquivos criados

# Adicionar no início do script
trap 'rm -f gpg_key.txt' EXIT INT TERM

# Adicionar antes de começar a criar arquivos
if [ ! -w "$(pwd)" ]; then
    print_warning "Sem permissão de escrita no diretório atual"
    exit 1
fi

# Função para verificar a conexão com a internet
check_internet() {
    if ! ping -c 1 8.8.8.8 &> /dev/null; then
        print_warning "Sem conexão com a internet"
        exit 1
    fi
}

# Função para limpar arquivos e sair
cleanup_and_exit() {
    print_status "Limpando arquivos temporários..."
    # Remove o backup do gitconfig se existir
    if [ -f ~/.gitconfig.backup ]; then
        rm -f ~/.gitconfig.backup
        print_status "Backup da configuração do Git removido"
    fi
    # Remove o arquivo da chave GPG se existir
    if [ -f gpg_key.txt ]; then
        rm -f gpg_key.txt
        print_status "Arquivo de chave GPG removido"
    fi
    print_status "Operação cancelada pelo usuário"
    exit 0
}

# Função para exibir mensagens de status
print_status() {
    echo -e "${GREEN}[*]${NC} $1"
}

# Função para exibir avisos
print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Função para instalar o GPG baseado no sistema operacional
install_gpg() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Detecta o gerenciador de pacotes
        if command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y gnupg
        elif command -v yum &> /dev/null; then
            sudo yum install -y gnupg
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y gnupg
        elif command -v pacman &> /dev/null; then
            sudo pacman -Sy gnupg --noconfirm
        else
            print_warning "Não foi possível detectar o gerenciador de pacotes. Por favor, instale o GPG manualmente."
            exit 1
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            brew install gnupg
        else
            print_warning "Homebrew não encontrado. Por favor, instale o Homebrew primeiro."
            exit 1
        fi
    else
        print_warning "Sistema operacional não suportado para instalação automática."
        exit 1
    fi
}

check_internet

# Adicionar logo após as funções iniciais
if ! command -v git &> /dev/null; then
    print_warning "Git não está instalado. Por favor, instale o Git primeiro."
    exit 1
fi

# Antes de fazer alterações nas configurações
if [ -f ~/.gitconfig ]; then
    cp ~/.gitconfig ~/.gitconfig.backup
    print_status "Backup das configurações do Git criado em ~/.gitconfig.backup"
fi

# Array com as configurações disponíveis do Git
declare -A git_configs=(
    ["user.name"]="Configura o nome do usuário"
    ["user.email"]="Configura o email do usuário"
    ["init.defaultbranch"]="Define a branch padrão como 'main'"
    ["core.editor"]="Define o editor padrão como 'nano'"
    ["core.autocrlf"]="Controla a conversão de quebras de linha"
    ["core.safecrlf"]="Verifica consistência das quebras de linha"
    ["core.ignorecase"]="Controla sensibilidade a maiúsculas/minúsculas"
    ["gpg.program"]="Define o programa GPG"
    ["user.signingkey"]="Define a chave GPG para assinatura"
    ["commit.gpgsign"]="Habilita assinatura de commits"
    ["tag.gpgsign"]="Habilita assinatura de tags"
)

# Array para armazenar as configurações selecionadas
declare -A selected_configs

# Função para mostrar menu de seleção
show_git_config_menu() {
    echo "Selecione as configurações do Git que deseja aplicar:"
    echo "Pressione o número correspondente para selecionar/desselecionar uma opção"
    echo "Pressione 'A' para selecionar todas"
    echo "Pressione 'N' para desselecionar todas"
    echo "Pressione 'C' para confirmar a seleção"
    echo "Pressione 'Q' para cancelar a operação"
    echo ""
    
    local i=1
    for key in "${!git_configs[@]}"; do
        if [[ ${selected_configs[$key]} == "true" ]]; then
            echo -e "$i) [X] ${key} - ${git_configs[$key]}"
        else
            echo -e "$i) [ ] ${key} - ${git_configs[$key]}"
        fi
        ((i++))
    done
}

# Função para aplicar as configurações selecionadas
apply_git_configs() {
    for key in "${!selected_configs[@]}"; do
        if [[ ${selected_configs[$key]} == "true" ]]; then
            case $key in
                "user.name")
                    read -p "Digite seu nome no GitHub: " GITHUB_NAME
                    while [ -z "$GITHUB_NAME" ]; do
                        print_warning "O nome não pode estar vazio"
                        read -p "Digite seu nome no GitHub: " GITHUB_NAME
                    done
                    if ! git config --global user.name "$GITHUB_NAME"; then
                        print_warning "Erro ao configurar o nome do usuário"
                        continue
                    fi
                    ;;
                "user.email")
                    read -p "Digite seu e-mail do GitHub: " GITHUB_EMAIL
                    while [[ ! "$GITHUB_EMAIL" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; do
                        print_warning "Por favor, insira um e-mail válido"
                        read -p "Digite seu e-mail do GitHub: " GITHUB_EMAIL
                    done
                    if ! git config --global user.email "$GITHUB_EMAIL"; then
                        print_warning "Erro ao configurar o e-mail do usuário"
                        continue
                    fi
                    ;;
                "init.defaultbranch")
                    if ! git config --global init.defaultbranch main; then
                        print_warning "Erro ao configurar a branch padrão"
                        continue
                    fi
                    ;;
                "core.editor")
                    if ! git config --global core.editor "nano"; then
                        print_warning "Erro ao configurar o editor"
                        continue
                    fi
                    ;;
                "core.autocrlf")
                    if ! git config --global core.autocrlf input; then
                        print_warning "Erro ao configurar autocrlf"
                        continue
                    fi
                    ;;
                "core.safecrlf")
                    if ! git config --global core.safecrlf true; then
                        print_warning "Erro ao configurar safecrlf"
                        continue
                    fi
                    ;;
                "core.ignorecase")
                    if ! git config --global core.ignorecase false; then
                        print_warning "Erro ao configurar ignorecase"
                        continue
                    fi
                    ;;
            esac
            print_status "Configurado: $key"
        fi
    done
}

# Função para processar a seleção do menu
process_menu_selection() {
    local opt=$1
    local num_configs=${#git_configs[@]}
    
    case $opt in
        [1-9]|[1-9][0-9])
            if (( opt <= num_configs )); then
                local i=1
                for key in "${!git_configs[@]}"; do
                    if (( i == opt )); then
                        if [[ ${selected_configs[$key]} == "true" ]]; then
                            selected_configs[$key]="false"
                        else
                            selected_configs[$key]="true"
                        fi
                        break
                    fi
                    ((i++))
                done
                return 0
            fi
            ;;
        [Aa])
            for key in "${!git_configs[@]}"; do
                selected_configs[$key]="true"
            done
            return 0
            ;;
        [Nn])
            for key in "${!git_configs[@]}"; do
                selected_configs[$key]="false"
            done
            return 0
            ;;
        [Cc])
            return 1
            ;;
        [Qq])
            cleanup_and_exit
            ;;
        *)
            print_warning "Opção inválida"
            return 0
            ;;
    esac
}

# Mostrar menu até que o usuário confirme a seleção
while true; do
    show_git_config_menu
    read -p "Escolha uma opção: " opt
    if ! process_menu_selection "$opt"; then
        break
    fi
done

# Aplicar as configurações selecionadas
apply_git_configs

# Inicializar todas as configurações como não selecionadas
for key in "${!git_configs[@]}"; do
    selected_configs[$key]="true"
done

# Verificar se o GPG está instalado
if ! command -v gpg &> /dev/null; then
    print_warning "GPG não está instalado. Instalando automaticamente..."
    install_gpg
fi

# Verificar a versão do GPG e definir o comando apropriado
GPG_VERSION="gpg"

if command -v gpg2 &> /dev/null; then
    GPG_VERSION="gpg2"
fi

print_status "Usando $GPG_VERSION"

GPG_PATH=$(which $GPG_VERSION)

# Configurar o programa GPG no Git
if ! git config --global gpg.program $GPG_PATH; then
    print_warning "Erro ao configurar o programa GPG no Git"
    exit 1
fi

# Configurações adicionais do Git

# Configurar o nome da branch padrão
if ! git config --global init.defaultbranch main; then
    print_warning "Erro ao configurar a branch padrão do Git"
    exit 1
fi

# Configurar o editor padrão
if ! git config --global core.editor "nano"; then
    print_warning "Erro ao configurar o editor padrão do Git"
    exit 1
fi

# Controla a conversão automática de quebras de linha (CRLF ↔ LF).
if ! git config --global core.autocrlf input; then
    print_warning "Erro ao configurar a conversão de terminações de linha do Git"
    exit 1
fi

# Habilita a verificação da consistência das quebras de linha ao lidar com arquivos.
if ! git config --global core.safecrlf true; then
    print_warning "Erro ao configurar a verificação de terminações de linha seguras do Git"
    exit 1
fi

# Git passa a tratar arquivos com nomes que diferem apenas por maiúsculas e minúsculas como distintos.
if ! git config --global core.ignorecase false; then
    print_warning "Erro ao configurar a coloração automática do Git"
    exit 1
fi

# Listar as chaves GPG existentes
print_status "Listando chaves GPG existentes..."
$GPG_VERSION --list-secret-keys --keyid-format=long

# Capturar automaticamente o ID da chave
key_id=$($GPG_VERSION --list-secret-keys --keyid-format=long | grep sec | awk '{print $2}' | cut -d'/' -f2)

if [ -z "$key_id" ]; then
    print_warning "Nenhuma chave GPG encontrada. Uma nova chave será gerada."
    
    # Gerar nova chave GPG usando as informações do GitHub
    print_status "Gerando nova chave GPG..."
    $GPG_VERSION --batch --generate-key <<EOF
    Key-Type: RSA
    Key-Length: 4096
    Name-Real: $GITHUB_NAME
    Name-Email: $GITHUB_EMAIL
    Name-Comment: Chave do GitHub
    Expire-Date: 0
    %commit
EOF

    # Capturar o ID da nova chave
    key_id=$($GPG_VERSION --list-secret-keys --keyid-format=long | grep sec | awk '{print $2}' | cut -d'/' -f2)
fi

if [[ ! "$key_id" =~ ^[A-F0-9]{16}$ ]]; then
    print_warning "ID da chave GPG inválido"
    exit 1
fi

print_status "Usando a chave GPG: $key_id"

# Exportar a chave GPG
print_status "Exportando a chave GPG..."
$GPG_VERSION --armor --export $key_id > gpg_key.txt

# Configurar git para usar a chave GPG
print_status "Configurando git para usar a chave GPG..."
# Após configurar a chave GPG
if ! git config --global user.signingkey "$key_id"; then
    print_warning "Erro ao configurar a chave de assinatura"
    exit 1
fi

if ! git config --global commit.gpgsign true; then
    print_warning  "Erro ao configurar a chave de commit GPG"
    exit 1
fi

if ! git config --global tag.gpgsign true; then
    print_warning "Erro ao configurar a tag de assinatura GPG"
    exit 1
fi

# Após exportar a chave
if [ ! -s gpg_key.txt ]; then
    print_warning "Erro ao exportar a chave GPG"
    exit 1
fi

print_status "Configuração concluída!"
print_status "Conteúdo da chave GPG (gpg_key.txt):"
echo "----------------------------------------"
cat gpg_key.txt
echo "----------------------------------------"

print_status "Agora você pode adicionar esta chave à sua conta do GitHub:"
echo "1. Acesse GitHub.com e faça login"
echo "2. Vá para Settings > SSH and GPG keys"
echo "3. Clique em 'New GPG key'"
echo "4. Cole o conteúdo do arquivo gpg_key.txt mostrado acima"