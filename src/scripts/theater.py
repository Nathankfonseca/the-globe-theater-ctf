#!/usr/bin/env python3
import sys

# Othello's play verification engine
try:
    import desdemona
    desdemona.verificar_fidelidade()
except ImportError:
    print("[*] Erro no teatro: modulo 'desdemona' ausente. Verifique o cenario.")
    sys.exit(1)

