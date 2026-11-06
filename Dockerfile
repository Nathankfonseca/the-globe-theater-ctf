FROM --platform=linux/amd64 debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# Instalacao de pacotes necessarios
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

# Criacao dos usuarios e configuracao de senhas
RUN useradd -m -s /bin/bash hamlet \
    && echo "hamlet:To_Be_Or_Not_To_Be_1603" | chpasswd
RUN useradd -m -s /bin/bash othello \
    && echo "othello:Oth3ll0_V3n1c3_Lock3d" | chpasswd
RUN echo "root:desdemona" | chpasswd

# Configuracao de permissao no sudoers para movimento lateral
RUN echo "hamlet ALL=(othello) NOPASSWD: /usr/bin/python3 /opt/scripts/theater.py" > /etc/sudoers.d/hamlet \
    && chmod 0440 /etc/sudoers.d/hamlet

# Posicionamento das flags e pistas
RUN echo "TAC{h4ml3t_m33ts_0th3ll0_1603}" > /home/othello/user.txt \
    && chown othello:othello /home/othello/user.txt \
    && chmod 0640 /home/othello/user.txt

RUN echo "Otelo, a lealdade da corte foi maculada. O segredo da coroa esta guardado sob a assinatura: 31553b994ab5e2e085b1e1eb815a58673196dfc1f4fb68c29fbdf867077f6205" > /home/othello/recado_de_iago.txt \
    && chown othello:othello /home/othello/recado_de_iago.txt \
    && chmod 0644 /home/othello/recado_de_iago.txt

RUN echo "TAC{th3_r3st_1s_s1l3nc3_sh4k3sp34r3}" > /root/root.txt \
    && chown root:root /root/root.txt \
    && chmod 0600 /root/root.txt

# Copia dos scripts, configuracoes e arquivos web
COPY src/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY src/scripts/theater.py /opt/scripts/theater.py
RUN chmod 0755 /opt/scripts/theater.py && chown othello:othello /opt/scripts/theater.py

COPY src/web/ /var/www/html/
RUN chmod -R 0755 /var/www/html

EXPOSE 80 22

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

