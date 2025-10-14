#!/bin/bash

# Update package list
echo "Updating package list..."
apt update

# Install packages
echo "Installing packages..."
apt install -y ufw openssh-server vim fail2ban git
apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Configure UFW
echo "Configuring UFW..."
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw --force enable

# Enable and start OpenSSH
echo "Configuring OpenSSH..."
systemctl enable ssh
systemctl start ssh

# Enable and start Docker
echo "Configuring Docker..."
systemctl enable docker
systemctl start docker
systemctl status docker

# Configure Fail2ban
echo "Configuring Fail2ban..."
systemctl enable fail2ban
systemctl start fail2ban

# Create basic fail2ban configuration for SSH
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