#!/bin/bash

# Solicita o e-mail do usuário
read -p "Digite seu e-mail do GitHub: " email

# Define o diretório padrão para armazenar a chave
ssh_dir="$HOME/.ssh"
key_file="$ssh_dir/id_github"

# Cria o diretório .ssh caso não exista
mkdir -p "$ssh_dir"
chmod 700 "$ssh_dir"

# Gera a chave SSH
ssh-keygen -t ed25519 -C "$email" -f "$key_file" -N ""

# Inicia o ssh-agent
eval "$(ssh-agent -s)"

# Adiciona a chave SSH ao ssh-agent
ssh-add "$key_file"

# Define o caminho do arquivo
AGENT_STARTUP="$HOME/.ssh/ssh-agent-init"

# Garante que o diretório ~/.ssh existe
mkdir -p "$HOME/.ssh"

# Cria o arquivo ~/.ssh/ssh-agent-init se não existir
if [ ! -f "$AGENT_STARTUP" ]; then
    touch "$AGENT_STARTUP"
    chmod 600 "$AGENT_STARTUP"
    echo "Arquivo $AGENT_STARTUP criado."
else
    echo "Arquivo $AGENT_STARTUP já existe."
fi

# Adiciona os comandos de inicialização do SSH ao arquivo (sobrescrevendo caso já tenha algo diferente)
cat <<EOF > "$AGENT_STARTUP"
#!/bin/bash

ssh_agent_init() {
  # Verifica se o ssh-agent está rodando
    if [ -z "$SSH_AUTH_SOCK" ]; then
        {
            eval "$(ssh-agent -s)"
        } &>/dev/null
    fi

    # Inicia o ssh-agent se não estiver rodando
    if ! pgrep -u "$USER" ssh-agent > /dev/null; then
      eval "$(ssh-agent -s)" > /dev/null
    fi

    # Adiciona a chave apenas se ainda não estiver carregada
    ssh-add -l | grep -q "id_github" || ssh-add ~/.ssh/id_github > /dev/null 2>&1
}
EOF

# Garante que o arquivo seja executável
chmod +x "$AGENT_STARTUP"

echo "Arquivo $AGENT_STARTUP foi atualizado."

# Exibe a chave pública gerada
echo "Chave SSH gerada com sucesso!"
echo "Chave pública:"
cat "$key_file.pub"

echo "Adicione essa chave à sua conta no GitHub: https://github.com/settings/keys"
