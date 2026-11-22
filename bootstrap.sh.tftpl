#!/bin/bash
set -euo pipefail
dnf install -y nginx
install -d -m 0750 /etc/novasphere
aws ssm get-parameter --region ${region} --name "${secret_parameter_name}" --with-decryption --query Parameter.Value --output text > /etc/novasphere/app.conf
chmod 0640 /etc/novasphere/app.conf
LOADED=$([ -s /etc/novasphere/app.conf ] && echo oui || echo non)
echo "<h1>NovaSphere - ${environment}</h1><p>Serveur : $(hostname)</p><p>Secret charge depuis Parameter Store : $LOADED</p>" > /usr/share/nginx/html/index.html
systemctl enable --now nginx
