#!/bin/bash

echo "Updating package list..."
apt update

echo "Installing packages..."
apt install -y ufw openssh-server vim fail2ban git
apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "Configuring UFW..."
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw --force enable

echo "Configuring OpenSSH..."
systemctl enable ssh
systemctl start ssh

echo "Configuring Docker..."
systemctl enable docker
systemctl start docker
systemctl status docker

echo "Configuring Fail2ban..."
systemctl enable fail2ban
systemctl start fail2ban

cat > /etc/fail2ban/jail.local <<EOF
[sshd]
enabled = true
port = ssh
logpath = /var/log/auth.log
maxretry = 5
bantime = 3600
EOF

systemctl restart fail2ban

echo "Installation and setup complete"
echo "UFW status:"
ufw status verbose