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

