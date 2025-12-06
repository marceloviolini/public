
#!/bin/bash

# Exit on error
set -e

# Suppress needrestart prompts (list mode)
sudo sed -i 's/#$nrconf{restart} = '\''i'\'';/$nrconf{restart} = '\''l'\'';/g' /etc/needrestart/needrestart.conf

# Script to install and set up essential packages on Ubuntu 22.04:
# SSH, net-tools, Microsoft package repository, .NET 8, Nginx, and PostgreSQL.

# --- Configuration Variables ---
# The script will create a new PostgreSQL user/database with this name.
DB_USER="mydatabaseuser"
DB_NAME="mydatabase"

# Ensure the script is run with root privileges
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root or with sudo."
    exit 1
fi

echo "--- Starting Server Setup for Ubuntu 22.04 ---"
echo ""

# 1. Update and Upgrade
echo "## 🚀 1. Updating and Upgrading System Packages"
apt update && apt upgrade -y
echo "Update and upgrade complete."
echo "---"

# 2. Install SSH and net-tools
echo "## 🛠️ 2. Installing OpenSSH Server and net-tools"
# openssh-server is typically installed by default on Ubuntu, but good to ensure.
# net-tools provides 'netstat' and 'ifconfig'.
apt install net-tools openssh-server ufw -y

systemctl enable ssh
systemctl start ssh
systemctl status ssh | grep "active (running)"

sudo apt install -y net-tools

echo "SSH and net-tools installed."
echo "---"


# --- 3. CONFIGURACIÓN DE UFW (Firewall) ---
echo "--- 3. Configurando UFW (Firewall) ---"
# Denegar todo por defecto (comentado porque UFW lo hace por defecto, pero explícito es mejor)
# sudo ufw default deny incoming
# sudo ufw default allow outgoing

# Abrir puertos esenciales:
# 22/tcp: SSH (Para acceso remoto)
# 80/tcp: HTTP (Para Nginx)
# 443/tcp: HTTPS (Para Nginx)
# 21/tcp: FTP (vsftpd) - Nota: FTP es inseguro. Considera SFTP (por SSH) o FTPS.
# 990/tcp: FTPS (vsftpd - Modo seguro, recomendado)
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
# sudo ufw allow 21/tcp
sudo ufw allow 990/tcp

# Habilitar UFW
echo "Habilitando UFW..."
sudo ufw enable

# Mostrar estado de UFW
sudo ufw status



# 4. Setup Microsoft Package Repository (for .NET)
echo "## 📦 3. Setting up Microsoft Package Repository"
# Install prerequisite packages
apt install -y wget apt-transport-https software-properties-common

# Download and register the Microsoft signing key
wget -q https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb
echo "Microsoft package repository added."
echo "---"

# 5 Install .NET SDK and ASP.NET Core Runtime 8
echo "## 🌐 4. Installing .NET 8 SDK and ASP.NET Core Runtime"
apt update
# Install .NET SDK (which includes the Runtime)
apt install -y dotnet-sdk-8.0
echo "Verifying installation:"
dotnet --version
echo "---"


# 6. Install Nginx
echo "## ⚙️ 5. Installing Nginx Web Server"
apt install -y nginx
systemctl enable nginx
systemctl start nginx
echo "Nginx installed and started."
echo "---"



# 7. Install and Setup PostgreSQL
echo "## 💾 6. Installing and Setting up PostgreSQL"
# Install PostgreSQL server
apt install -y postgresql postgresql-contrib

# Enable and start the PostgreSQL service
systemctl enable postgresql
systemctl start postgresql


# --- 8. INSTALACIÓN DE VSFTPD ---
echo "--- 7. Instalando vsftpd (Servidor FTP seguro) ---"
sudo apt install vsftpd -y
sudo systemctl enable vsftpd
sudo systemctl start vsftpd


echo "Configuring PostgreSQL user and database..."

# Create a new PostgreSQL user and database. You will be prompted for a password.
# NOTE: Using 'read -sp' to securely capture the password.
read -sp "Enter desired password for PostgreSQL user '$DB_USER': " DB_PASS
echo ""

# Execute psql commands to create user and database
# Use the default 'postgres' user to perform administrative tasks
sudo -u postgres psql -c "CREATE USER $DB_USER WITH ENCRYPTED PASSWORD '$DB_PASS';"
sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;"

echo "PostgreSQL installed and a new database '$DB_NAME' with user '$DB_USER' has been created."
echo "---"
