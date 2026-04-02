**🦖 Pterodactyl Auto-Updater: Guia de Ajuda**

Este documento detalha o funcionamento, a manutenção e a resolução de problemas do script de automação para o Pterodactyl (Panel e Wings).

**🛠️ Durante a Instalação**

O processo de instalação foi desenhado para ser o mais inteligente possível, exigindo o mínimo de intervenção manual:

- **Detecção de Ambiente:** O script verifica automaticamente se você está em um servidor com o **Painel** (procurando pela pasta /var/www/pterodactyl) ou em um **Node/Wings** (procurando pelo serviço ou binário do wings).
- **Inteligência de Webhook:** \* O instalador verifica se você já rodou o script antes.
  - Se encontrar um Webhook antigo, ele o exibe e pergunta se você deseja **reutilizá-lo** ou **trocá-lo**. Isso evita que você tenha que copiar e colar a URL toda vez que atualizar o script.
- **Configuração Automática:** O script move os executáveis para /usr/local/bin/, concede permissões de execução e configura o **Crontab** para rodar a cada 6 horas.

**Comando de Instalação:**

Bash

bash -c "\$(curl -fsSL <https://raw.githubusercontent.com/vanderlpp/update-pterodactyl/main/install.sh>)"

**🕹️ Comandos de Atualização**

Após a instalação, você não precisa mais decorar comandos longos. O script injeta atalhos diretamente no seu sistema:

- **Para o Painel:** Digite apenas update_painel
- **Para o Wings:** Digite apenas update_wings

\[!TIP\] **Dica de Ouro:** Se o comando não funcionar logo após a instalação, seu terminal ainda não carregou as novas configurações. Use o comando source ~/.bashrc para ativar os atalhos imediatamente.

**🧪 Como Testar o Sistema**

O sistema é "silencioso": se tudo estiver atualizado, ele não enviará nada para não poluir seu canal. Para testar se o Webhook e a lógica estão funcionando, use estes métodos:

**1\. Teste de Comunicação (Direto)**

Envia uma mensagem de teste para o Discord ignorando todas as regras:

- **Painel:** /usr/local/bin/notify_discord.sh "TESTE-OK"
- **Wings:** /usr/local/bin/notify_wings_discord.sh "TESTE-OK"

**2\. Simulação de Update (Ciclo Completo)**

Isso "engana" o script fazendo-o acreditar que a versão instalada é a v0.0.0, forçando o envio da notificação real:

- **No Painel:**

Bash

rm -f /tmp/ptero*notified*\* && echo "v0.0.0" > /tmp/ptero_current_version && /usr/local/bin/pteroupdate.sh check

- **No Wings:**

Bash

rm -f /tmp/wings*notified*\* && echo "v0.0.0" > /tmp/wings_current_version && /usr/local/bin/wingsupdate.sh check

**⚙️ Como Funciona "Por Baixo dos Panos"**

Entenda a lógica por trás da mágica:

- **Localização dos Arquivos:** Os scripts residem em /usr/local/bin/ para que possam ser acessados de qualquer lugar do sistema.
- **O "Cérebro" (Check):** O script faz uma requisição para a API do GitHub para ler a última tag_name. Ele compara esse valor com o arquivo de versão local salvo em /tmp/.
- **Sistema Anti-Spam (Lock Files):** Toda vez que o script notifica você sobre uma versão (ex: v1.11.3), ele cria um arquivo chamado /tmp/ptero_notified_v1.11.3. Enquanto esse arquivo existir, ele não enviará o alerta novamente, mesmo que a checagem rode centenas de vezes.
- **Limpeza:** Quando você executa o comando update_painel ou update_wings, o script apaga esses arquivos de trava, preparando o sistema para a próxima atualização futura.

**❓ FAQ / Solução de Problemas**

**Q: Erro de sintaxe unexpected token '(' ao instalar.**

**R:** Isso ocorre quando você tenta rodar o comando copiando a formatação de link do Markdown. Copie apenas o texto da URL, sem colchetes ou parênteses extras.

**Q: Recebo a mensagem "Comando não encontrado" ao tentar atualizar.**

**R:** Verifique se você está logado como root. Além disso, certifique-se de rodar source ~/.bashrc para atualizar os atalhos do terminal.

**Q: Quero mudar o Webhook. Preciso apagar tudo?**

**R:** Não. Basta rodar o comando de instalação novamente. O script detectará o antigo, você responde **"n"** (não reutilizar) e insere o novo.

**Q: O script altera meus arquivos de configuração do Pterodactyl?**

**R:** Não. O script segue o fluxo oficial de atualização: ele baixa os novos arquivos core, roda as migrações de banco de dados e limpa o cache. Seus arquivos .env e configurações de banco de dados permanecem intactos.
