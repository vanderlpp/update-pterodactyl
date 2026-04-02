# Pterodactyl Auto-Updater & Discord Notifier

Um utilitário em Bash desenvolvido para automatizar o monitoramento de versões e facilitar a atualização segura de ambientes rodando **Pterodactyl Panel** e **Wings** (Daemon). 

O script atua de forma silenciosa no servidor, consultando a API do GitHub a cada 6 horas. Quando uma nova versão estável é detectada, ele envia um alerta rico (Embed) para um Webhook do Discord, contendo a versão, o nome do servidor (`hostname`) e a instrução de atualização.

## ✨ Funcionalidades

* 🔍 **Detecção Universal Automática:** O instalador analisa o sistema operacional e identifica sozinho se a máquina hospeda o Painel (`/var/www/pterodactyl`) ou um Node do Wings (`/usr/local/bin/wings`).
* 💬 **Notificações Inteligentes no Discord:** Alertas visuais diferenciados (Azul para Painel, Cinza para Wings) com identificação exata de qual servidor precisa da atualização.
* ⚡ **Atualização One-Click (Alias):** Cria comandos curtos nativos no terminal (`update_painel` e `update_wings`) que executam toda a rotina de atualização (download, extração, composer, migrations, reinicialização de serviços) sem necessitar de interação do usuário.
* 🛡️ **Zero Downtime para Jogadores:** A rotina do Wings atualiza o binário e reinicia o serviço daemon de forma que os containers dos jogos continuem rodando ininterruptamente.
* 🔄 **Instalação Idempotente:** O script pode ser rodado múltiplas vezes no mesmo servidor para atualizar a URL do Webhook, sem duplicar agendamentos no Cron ou atalhos no `.bashrc`.

---

## 🚀 Como Instalar

A instalação é feita com um único comando. Acesse o terminal do seu servidor (Painel ou Node) com privilégios de `root` e execute:

```bash
bash <(curl -s [https://raw.githubusercontent.com/SEU_USUARIO/SEU_REPOSITORIO/main/install.sh](https://raw.githubusercontent.com/SEU_USUARIO/SEU_REPOSITORIO/main/install.sh))
