#!/bin/bash

clear
echo "======================================================"
echo "  Instalador Universal: Pterodactyl Auto-Updater"
echo "======================================================"
echo ""
echo "Este script criará rotinas automáticas para verificar novas"
echo "versões do Pterodactyl (Painel ou Wings) a cada 6 horas."
echo ""
echo "O QUE ELE FARÁ:"
echo "Sempre que uma atualização for lançada no GitHub, você receberá"
echo "um alerta no Discord com o nome do servidor e o comando exato"
echo "para atualizar o sistema de forma segura."
echo ""
echo "COMO CONSEGUIR O SEU WEBHOOK DO DISCORD:"
echo "1. No seu servidor do Discord, vá até o canal desejado."
echo "2. Clique na engrenagem (Editar Canal) > Integrações > Webhooks."
echo "3. Clique em 'Novo Webhook' e depois em 'Copiar URL do Webhook'."
echo "------------------------------------------------------"
echo ""

# Solicita o Webhook ao usuário
read -p "Cole aqui a URL do seu Webhook: " USER_WEBHOOK

# Valida se o usuário não deixou em branco
if [ -z "$USER_WEBHOOK" ]; then
    echo ""
    echo "[✖] Erro: A URL do Webhook não pode ficar em branco."
    echo "Instalação cancelada."
    exit 1
fi

echo ""
echo "Analisando este servidor..."
echo "------------------------------------------------------"

IS_PANEL=false
IS_WINGS=false

# Verificação de ambiente
if [ -f "/var/www/pterodactyl/artisan" ]; then
    IS_PANEL=true
    echo "[✔] Painel Pterodactyl detectado."
fi

if [ -f "/usr/local/bin/wings" ] || systemctl list-unit-files | grep -q "wings.service"; then
    IS_WINGS=true
    echo "[✔] Wings (Node) detectado."
fi

if [ "$IS_PANEL" = false ] && [ "$IS_WINGS" = false ]; then
    echo "[✖] Erro: Nenhum Painel ou Wings encontrado nesta máquina."
    echo "Cancelando a instalação."
    exit 1
fi

echo "------------------------------------------------------"

# ==========================================
# INSTALAÇÃO DO PAINEL
# ==========================================
if [ "$IS_PANEL" = true ]; then
    echo ">> Instalando automação para o PAINEL..."

    # Cria o arquivo de notificação com um placeholder
    cat << 'EOF' > /usr/local/bin/notify_discord.sh
#!/bin/bash
VERSION=$1
WEBHOOK_URL="PLACEHOLDER_WEBHOOK_URL"
SERVER_NAME=$(hostname)

if [ -z "$VERSION" ]; then exit 1; fi

JSON_PAYLOAD=$(cat <<INNER_EOF
{
  "content": null,
  "embeds": [
    {
      "title": "🔄 Atualização do Pterodactyl Disponível",
      "description": "Uma nova versão (**$VERSION**) do painel Pterodactyl foi detectada.\n\n🖥️ **Servidor:** \`$SERVER_NAME\`\n\nPara aplicar o update de forma automatizada, acesse o terminal deste servidor e execute:\n\`\`\`bash\nupdate_painel\n\`\`\`",
      "color": 3447003
    }
  ]
}
INNER_EOF
)
curl -s -H "Content-Type: application/json" -X POST -d "$JSON_PAYLOAD" "$WEBHOOK_URL"
EOF

    # Injeta a URL do usuário no arquivo criado
    sed -i "s|PLACEHOLDER_WEBHOOK_URL|$USER_WEBHOOK|g" /usr/local/bin/notify_discord.sh

    # Cria o script principal
    cat << 'EOF' > /usr/local/bin/pteroupdate.sh
#!/bin/bash
PANEL_PATH="/var/www/pterodactyl"
VERSION_FILE="/tmp/ptero_current_version"
REMOTE_VERSION=$(curl -s https://api.github.com/repos/pterodactyl/panel/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

check_version() {
    if [ ! -f $VERSION_FILE ]; then php $PANEL_PATH/artisan ptero:info | grep "Panel Version" | awk '{print $4}' > $VERSION_FILE; fi
    LOCAL_VERSION=$(cat $VERSION_FILE)
    if [ "$REMOTE_VERSION" != "$LOCAL_VERSION" ] && [ -n "$REMOTE_VERSION" ]; then
        if [ ! -f "/tmp/ptero_notified_$REMOTE_VERSION" ]; then
            /usr/local/bin/notify_discord.sh "$REMOTE_VERSION"
            touch "/tmp/ptero_notified_$REMOTE_VERSION"
        fi
    fi
}

do_update() {
    echo "Atualizando Painel para $REMOTE_VERSION..."
    cd $PANEL_PATH
    php artisan down
    curl -L https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz | tar -xzv
    chmod -R 755 storage/* bootstrap/cache
    composer install --no-dev --optimize-autoloader --no-interaction
    php artisan view:clear
    php artisan config:clear
    php artisan migrate --seed --force
    chown -R www-data:www-data $PANEL_PATH/*
    php artisan queue:restart
    php artisan up
    echo $REMOTE_VERSION > $VERSION_FILE
    rm -f "/tmp/ptero_notified_$REMOTE_VERSION"
    echo "Painel atualizado!"
}

case "$1" in
    check) check_version ;;
    run) do_update ;;
    *) echo "Uso: $0 {check|run}"; exit 1 ;;
esac
EOF

    chmod +x /usr/local/bin/notify_discord.sh
    chmod +x /usr/local/bin/pteroupdate.sh

    if ! grep -q "alias update_painel=" ~/.bashrc; then echo "alias update_painel='sudo /usr/local/bin/pteroupdate.sh run'" >> ~/.bashrc; fi
    source ~/.bashrc

    if ! crontab -l 2>/dev/null | grep -q "/usr/local/bin/pteroupdate.sh check"; then
        (crontab -l 2>/dev/null; echo "0 */6 * * * /usr/local/bin/pteroupdate.sh check") | crontab -
    fi
fi

# ==========================================
# INSTALAÇÃO DO WINGS
# ==========================================
if [ "$IS_WINGS" = true ]; then
    echo ">> Instalando automação para o WINGS..."

    # Cria o arquivo de notificação com um placeholder
    cat << 'EOF' > /usr/local/bin/notify_wings_discord.sh
#!/bin/bash
VERSION=$1
WEBHOOK_URL="PLACEHOLDER_WEBHOOK_URL"
SERVER_NAME=$(hostname)

if [ -z "$VERSION" ]; then exit 1; fi

JSON_PAYLOAD=$(cat <<INNER_EOF
{
  "content": null,
  "embeds": [
    {
      "title": "⚙️ Atualização do Wings Disponível",
      "description": "Uma nova versão (**$VERSION**) do Wings (Daemon) foi detectada.\n\n🖥️ **Node:** \`$SERVER_NAME\`\n\nPara aplicar o update, acesse o terminal deste Node e execute:\n\`\`\`bash\nupdate_wings\n\`\`\`",
      "color": 15105570
    }
  ]
}
INNER_EOF
)
curl -s -H "Content-Type: application/json" -X POST -d "$JSON_PAYLOAD" "$WEBHOOK_URL"
EOF

    # Injeta a URL do usuário no arquivo criado
    sed -i "s|PLACEHOLDER_WEBHOOK_URL|$USER_WEBHOOK|g" /usr/local/bin/notify_wings_discord.sh

    # Cria o script principal
    cat << 'EOF' > /usr/local/bin/wingsupdate.sh
#!/bin/bash
VERSION_FILE="/tmp/wings_current_version"
REMOTE_VERSION=$(curl -s https://api.github.com/repos/pterodactyl/wings/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

check_version() {
    if [ ! -f "$VERSION_FILE" ]; then
        if command -v wings &> /dev/null; then wings version | awk '{print $2}' > "$VERSION_FILE"; else echo "v0.0.0" > "$VERSION_FILE"; fi
    fi
    LOCAL_VERSION=$(cat "$VERSION_FILE")
    if [ "$REMOTE_VERSION" != "$LOCAL_VERSION" ] && [ -n "$REMOTE_VERSION" ]; then
        if [ ! -f "/tmp/wings_notified_$REMOTE_VERSION" ]; then
            /usr/local/bin/notify_wings_discord.sh "$REMOTE_VERSION"
            touch "/tmp/wings_notified_$REMOTE_VERSION"
        fi
    fi
}

do_update() {
    echo "Atualizando Wings para $REMOTE_VERSION..."
    systemctl stop wings
    curl -L -o /usr/local/bin/wings "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_$([[ "$(uname -m)" == "x86_64" ]] && echo "amd64" || echo "arm64")"
    chmod u+x /usr/local/bin/wings
    systemctl restart wings
    echo "$REMOTE_VERSION" > "$VERSION_FILE"
    rm -f "/tmp/wings_notified_$REMOTE_VERSION"
    echo "Wings atualizado!"
}

case "$1" in
    check) check_version ;;
    run) do_update ;;
    *) echo "Uso: $0 {check|run}"; exit 1 ;;
esac
EOF

    chmod +x /usr/local/bin/notify_wings_discord.sh
    chmod +x /usr/local/bin/wingsupdate.sh

    if ! grep -q "alias update_wings=" ~/.bashrc; then echo "alias update_wings='sudo /usr/local/bin/wingsupdate.sh run'" >> ~/.bashrc; fi
    source ~/.bashrc

    if ! crontab -l 2>/dev/null | grep -q "/usr/local/bin/wingsupdate.sh check"; then
        (crontab -l 2>/dev/null; echo "0 */6 * * * /usr/local/bin/wingsupdate.sh check") | crontab -
    fi
fi

echo "------------------------------------------------------"
echo "✅ Processo de instalação finalizado com sucesso!"
echo "As verificações ocorrerão automaticamente a cada 6 horas."
echo "------------------------------------------------------"
echo ""
echo "======================================================"
echo "🧪 COMO TESTAR O SISTEMA AGORA MESMO:"
echo "======================================================"
echo "Dica inicial: Para os atalhos funcionarem imediatamente,"
echo "pode ser necessário rodar o comando: source ~/.bashrc"
echo ""

if [ "$IS_PANEL" = true ]; then
    echo "▶ PARA O PAINEL:"
    echo "1. Para forçar a verificação de update (não fará nada se já estiver atualizado):"
    echo "   /usr/local/bin/pteroupdate.sh check"
    echo ""
    echo "2. Para rodar o comando de atualização manual:"
    echo "   update_painel"
    echo ""
fi

if [ "$IS_WINGS" = true ]; then
    echo "▶ PARA O WINGS:"
    echo "1. Para forçar a verificação de update (não fará nada se já estiver atualizado):"
    echo "   /usr/local/bin/wingsupdate.sh check"
    echo ""
    echo "2. Para rodar o comando de atualização manual:"
    echo "   update_wings"
    echo ""
fi
echo "======================================================"
