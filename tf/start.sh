echo "############Inicio"
sed -i "/#\$nrconf{restart} = 'i';/s/.*/\$nrconf{restart} = 'a';/" /etc/needrestart/needrestart.conf

echo "Aguardando 60 segundos ..."
sleep 60

echo "PS1='\[\e[0;1;38;5;39m\]\u\[\e[0m\]@\[\e[0;1;37m\]\h\[\e[0m\]:\[\e[0;1;38;5;34m\]\w\[\e[0m\]#\[\e[0m\] \[\e[0m\]'" >> ~/.bashrc
echo "ClientAliveInterval 60
TCPKeepAlive yes
ClientAliveCountMax 10000" >> ~/.ssh/sshd_config
echo "AllowTcpForwarding yes" >> ~/.ssh/sshd_config

### Docker
#curl -fsSL https://get.docker.com -o get-docker.sh
#sudo sh ./get-docker.sh

sudo apt update
sudo apt install apt-transport-https ca-certificates curl software-properties-common -y

echo "Aguardando 10 segundos ..."
sleep 10

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu jammy stable" -y

echo "Aguardando 10 segundos ..."
sleep 10

sudo apt install docker-ce=5:24.0.2-1~ubuntu.22.04~jammy -y
sudo systemctl start docker
usermod -aG docker root
docker pull kindest/node:v1.24.13@sha256:cea86276e698af043af20143f4bf0509e730ec34ed3b7fa790cc0bea091bc5dd
### Fim Docker

## KIND
#https://kind.sigs.k8s.io/docs/user/quick-start/#installing-with-a-package-manager
echo "Aguardando 10 segundos ..."
sleep 10
[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.19.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
kind --version
echo "alias sc=\"kind create cluster --name cluster --config kind.yaml\"" >> .bashrc
echo "alias dc=\"kind delete cluster --name cluster\"" >> .bashrc

## Kubectl
echo "Aguardando 10 segundos ..."
sleep 10
curl -LO "https://dl.k8s.io/release/v1.27.2/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
echo "############Fim"