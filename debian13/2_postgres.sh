#!/bin/bash

if [ $# -lt 4 ]; then
  echo "Usage: $0 DB_USER DB_PASS DB_NAME IP1 [IP2 IP3 ...]"
  echo "Example: $0 myuser mypass mydb 192.168.1.100 10.0.0.50"
  exit 1
fi

if ! command -v ufw &> /dev/null
then
    echo "ufw could not be found, please run the basics setup script first."
    exit

DB_USER="$1"
DB_PASS="$2"
DB_NAME="$3"
shift 3
ALLOWED_IPS=("$@")

echo "Updating package list..."
apt update

echo "Installing PostgreSQL..."
apt install -y postgresql postgresql-contrib

echo "Enabling and starting PostgreSQL..."
systemctl enable postgresql
systemctl start postgresql

echo "Configuring PostgreSQL to allow network access..."
PG_CONF="/etc/postgresql/$(ls /etc/postgresql | head -n1)/main/postgresql.conf"
PG_HBA="/etc/postgresql/$(ls /etc/postgresql | head -n1)/main/pg_hba.conf"

sed -i "s/^#listen_addresses =.*/listen_addresses = '*'/" "$PG_CONF"

for IP in "${ALLOWED_IPS[@]}"; do
  echo "host    all             all             $IP/32            md5" >> "$PG_HBA"
  echo "Added access for IP: $IP"
done

echo "Configuring UFW to allow PostgreSQL access..."
for IP in "${ALLOWED_IPS[@]}"; do
  ufw allow from "$IP" to any port 5432 proto tcp
  echo "UFW rule added for IP: $IP"
done

echo "Creating PostgreSQL user and database..."
sudo -u postgres psql <<EOF
DO
\$do\$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_catalog.pg_roles WHERE rolname = '$DB_USER'
   ) THEN
      CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';
   END IF;
END
\$do\$;

DO
\$do\$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_database WHERE datname = '$DB_NAME'
   ) THEN
      CREATE DATABASE $DB_NAME OWNER $DB_USER;
   END IF;
END
\$do\$;

GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
EOF

systemctl restart postgresql

echo "PostgreSQL installation and setup complete."
echo "Network access enabled for: ${ALLOWED_IPS[*]}"
echo