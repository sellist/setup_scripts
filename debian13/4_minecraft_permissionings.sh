#!/bin/bash

sudo apt update
sudo apt install -y ufw

sudo ufw --force reset

sudo ufw default deny incoming
sudo ufw default allow outgoing

sudo ufw limit 22/tcp

sudo ufw allow 25565/tcp

# if on da web
# sudo ufw allow 80/tcp
# sudo ufw allow 443/tcp

sudo ufw --force enable

sudo ufw status verbose

sudo apt install -y fail2ban

sudo tee /etc/fail2ban/jail.d/minecraft.conf > /dev/null <<EOF
[minecraft]
enabled = true
port = 25565
protocol = tcp
filter = minecraft
logpath = /var/lib/docker/containers/*/*.log
maxretry = 3
bantime = 3600
findtime = 600
EOF

sudo tee /etc/fail2ban/filter.d/minecraft.conf > /dev/null <<EOF
[Definition]
failregex = .*Connection attempt from <HOST>.*
ignoreregex =
EOF

sudo systemctl restart fail2ban
sudo systemctl enable fail2ban