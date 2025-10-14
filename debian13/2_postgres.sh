#!/bin/bash

# Check for required arguments
if [ $# -lt 4 ]; then
  echo "Usage: $0 DB_USER DB_PASS DB_NAME IP1 [IP2 IP3 ...]"
  echo "Example: $0 myuser mypass mydb 192.168.1.100 10.0.0.50"
  exit 1
fi

DB_USER="$1"
DB_PASS="$2"
DB_NAME="$3"
shift 3
ALLOWED_IPS=("$@")

# Update package list
echo "Updating package list..."
apt update

# Install PostgreSQL
echo "Installing PostgreSQL..."
apt install -y postgresql postgresql-contrib

# Enable and start PostgreSQL service
echo "Enabling and starting PostgreSQL..."
systemctl enable postgresql
systemctl start postgresql

# Configure PostgreSQL to allow network access
echo "Configuring PostgreSQL to allow network access..."
PG_CONF="/etc/postgresql/$(ls /etc/postgresql | head -n1)/main/postgresql.conf"
PG_HBA="/etc/postgresql/$(ls /etc/postgresql | head -n1)/main/pg_hba.conf"

sed -i "s/^#listen_addresses =.*/listen_addresses = '*'/" "$PG_CONF"

# Add each allowed IP to pg_hba.conf
for IP in "${ALLOWED_IPS[@]}"; do
  echo "host    all             all             $IP/32            md5" >> "$PG_HBA"
  echo "Added access for IP: $IP"
done

# Set up user and database
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