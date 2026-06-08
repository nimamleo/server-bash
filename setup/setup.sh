#!/usr/bin/env bash
set -e

# DNS
f=$(ls /etc/netplan/*.yaml | head -1)
grep -q 94.182.153.78 "$f" || sed -i '/dhcp4:/a\      nameservers:\n        addresses:\n          - 94.182.153.78' "$f"
netplan apply

# apt mirror
cat > /etc/apt/sources.list.d/ubuntu.sources <<'EOF'
Types: deb
URIs: http://ir.archive.ubuntu.com/ubuntu/
Suites: noble noble-updates noble-backports
Components: main universe restricted multiverse
#Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

## Ubuntu security updates. Aside from URIs and Suites,
## this should mirror your choices in the previous section.
#Types: deb
#URIs: http://security.ubuntu.com/ubuntu
#Suites: noble-security
#Components: main universe restricted multiverse
#Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
EOF

grep -q 'mirror.arvancloud.ir/ubuntu' /etc/apt/sources.list || \
  echo 'deb http://mirror.arvancloud.ir/ubuntu noble universe' >> /etc/apt/sources.list

apt update

# docker
curl -fsSL https://archive.ito.gov.ir/docker-ce/linux/ubuntu/gpg \
  | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://archive.ito.gov.ir/docker-ce/linux/ubuntu noble stable" \
  > /etc/apt/sources.list.d/docker.list

apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

: "${UBUNTU_PASSWORD:?set UBUNTU_PASSWORD}"
echo "ubuntu:$UBUNTU_PASSWORD" | chpasswd

systemctl enable docker
usermod -aG docker ubuntu

mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<'EOF'
{
  "insecure-registries": ["https://docker.arvancloud.ir"],
  "registry-mirrors": ["https://docker.arvancloud.ir"]
}
EOF

systemctl restart docker
