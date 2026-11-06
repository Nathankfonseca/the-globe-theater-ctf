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

