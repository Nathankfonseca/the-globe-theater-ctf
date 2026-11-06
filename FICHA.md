# 🎭 The Globe Theater — CTF Challenge

![The Globe Theater](Hamlet.webp)

> *"All the world's a stage, and all the men and women merely players..."*

---

## 📜 Sinopse

Londres, ano de 1603. Os portões do mítico **Globe Theater** foram reabertos para encenar as mais profundas tragédias da corte real. Nos bastidores do palco, entre manuscritos inacabados e registros confidenciais da trupe, correm sussurros sombrios de conspiração, traição e loucura fingida vindos diretamente do Castelo de Elsinore e das frotas de Veneza.

Nenhum segredo permanece enterrado por muito tempo quando as cortinas se abrem. Será você capaz de perscrutar os arquivos do teatro real, desvendar as intrigas manipuladas nas sombras e ascender ao comando supremo do reino antes que o último ato chegue ao fim?

---

## ⚙️ Informações do Desafio

* **Nome do Desafio:** The Globe Theater
* **Dificuldade Estimada:** Médio (Medium)
* **Número de Flags:** 2 flags obrigatórias
* **Formato das Flags:** `TAC{...}` (1 User Flag e 1 Root Flag)
* **Plataforma:** `linux/amd64`
* **Vetor de Entrada:** Apenas rede (Pentest clássico)

---

## 🚀 Como Executar o Desafio

Para levantar o ambiente do desafio, utilize o arquivo `docker-compose-dist.yml` fornecido. O ambiente sobe de forma totalmente autônoma com um único comando:

```bash
docker compose -f docker-compose-dist.yml up -d
```

### Portas Expostas para o Ataque:
* **8080/TCP:** Serviço Web (HTTP)
* **2222/TCP:** Serviço de Terminal Seguro (SSH)

### Link da Imagem Publicada:
* **Docker Hub:** `nomedogrupo/the-globe-theater:1.0` *(substituir `nomedogrupo` pelo namespace da sua equipe após o push)*

---

*Regras:* A exploração deve ocorrer estritamente pela rede contra as portas expostas (`8080` e `2222`). Bom espetáculo!
