#!/bin/bash

# Define o diretório onde estão os scripts
SCRIPT_DIR="./scripts"

# Verifica se a pasta scripts existe
if [ ! -d "$SCRIPT_DIR" ]; then
    echo "A pasta $SCRIPT_DIR não existe. Certifique-se de que ela está no mesmo diretório deste script."
    exit 1
fi

# Dá permissão de execução a todos os arquivos na pasta scripts
echo "Dando permissão de execução para todos os scripts em $SCRIPT_DIR..."
chmod +x "$SCRIPT_DIR"/*.sh

# Executa os scripts em ordem alfabética
echo "Executando os scripts em ordem alfabética..."
for script in $(ls "$SCRIPT_DIR"/*.sh | sort); do
    echo "Executando: $script"
    "$script"
done

echo "Todos os scripts foram executados com sucesso!"
