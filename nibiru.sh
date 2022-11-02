#!/bin/bash
exists()
{
  command -v "$1" >/dev/null 2>&1
}
if exists curl; then
echo ''
else
  sudo apt update && sudo apt install curl -y < "/dev/null"
fi
bash_profile=$HOME/.bash_profile
if [ -f "$bash_profile" ]; then
    . $HOME/.bash_profile
fi
sleep 1 && curl -s https://api.nodes.guru/logo.sh | bash && sleep 1


if [ ! $NIBIRU_NODENAME ]; then
read -p "Enter node name: " NIBIRU_NODENAME
echo 'export NIBIRU_NODENAME='\"${NIBIRU_NODENAME}\" >> $HOME/.bash_profile
fi
echo 'source $HOME/.bashrc' >> $HOME/.bash_profile
. $HOME/.bash_profile
sleep 1
cd $HOME
sudo apt update
sudo apt install make clang pkg-config libssl-dev build-essential git jq ncdu bsdmainutils htop -y < "/dev/null"

echo -e '\n\e[42mInstall Go\e[0m\n' && sleep 1
cd $HOME
wget -O go1.19.2.linux-amd64.tar.gz https://golang.org/dl/go1.19.2.linux-amd64.tar.gz
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.19.2.linux-amd64.tar.gz && rm go1.19.2.linux-amd64.tar.gz
echo 'export GOROOT=/usr/local/go' >> $HOME/.bash_profile
echo 'export GOPATH=$HOME/go' >> $HOME/.bash_profile
echo 'export GO111MODULE=on' >> $HOME/.bash_profile
echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> $HOME/.bash_profile && . $HOME/.bash_profile
go version

echo -e '\n\e[42mInstall software\e[0m\n' && sleep 1
rm -rf $HOME/nibiru
cd $HOME
git clone https://github.com/NibiruChain/nibiru
cd nibiru
git checkout v0.15.0
make build
sudo mv ./build/nibid /usr/local/bin/ || exit
nibid init "$NIBIRU_NODENAME" --chain-id=nibiru-testnet-1

#seeds="8e1590558d8fede2f8c9405b7ef550ff455ce842@51.79.30.9:26656,bfffaf3b2c38292bd0aa2a3efe59f210f49b5793@51.91.208.71:26656,106c6974096ca8224f20a85396155979dbd2fb09@198.244.141.176:26656"
peers="37713248f21c37a2f022fbbb7228f02862224190@35.243.130.198:26656,ff59bff2d8b8fb6114191af7063e92a9dd637bd9@35.185.114.96:26656,cb431d789fe4c3f94873b0769cb4fce5143daf97@35.227.113.63:26656"
#sed -i "s/^seeds *=.*/seeds = \"$seeds\"/;" $HOME/.nibid/config/config.toml
sed -i.default "s/^persistent_peers *=.*/persistent_peers = \"$peers\"/;" $HOME/.nibid/config/config.toml

sed -i.default 's/minimum-gas-prices =.*/minimum-gas-prices = "0.025unibi"/g' $HOME/.nibid/config/app.toml
CONFIG_TOML="$HOME/.nibid/config/config.toml"
sed -i 's/timeout_propose =.*/timeout_propose = "100ms"/g' $CONFIG_TOML
sed -i 's/timeout_propose_delta =.*/timeout_propose_delta = "500ms"/g' $CONFIG_TOML
sed -i 's/timeout_prevote =.*/timeout_prevote = "100ms"/g' $CONFIG_TOML
sed -i 's/timeout_prevote_delta =.*/timeout_prevote_delta = "500ms"/g' $CONFIG_TOML
sed -i 's/timeout_precommit =.*/timeout_precommit = "100ms"/g' $CONFIG_TOML
sed -i 's/timeout_precommit_delta =.*/timeout_precommit_delta = "500ms"/g' $CONFIG_TOML
sed -i 's/timeout_commit =.*/timeout_commit = "1s"/g' $CONFIG_TOML
sed -i 's/skip_timeout_commit =.*/skip_timeout_commit = false/g' $CONFIG_TOML
sed -i.default "s/pruning *=.*/pruning = \"custom\"/g" $HOME/.nibid/config/app.toml
sed -i "s/pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/g" $HOME/.nibid/config/app.toml
sed -i "s/pruning-interval *=.*/pruning-interval = \"10\"/g" $HOME/.nibid/config/app.toml

wget -O $HOME/.nibid/config/genesis.json https://raw.githubusercontent.com/Pa1amar/testnets/main/nibiru/nibiru-testnet-1/genesis.json
nibid tendermint unsafe-reset-all
echo -e '\n\e[42mRunning\e[0m\n' && sleep 1
echo -e '\n\e[42mCreating a service\e[0m\n' && sleep 1

echo "[Unit]
Description=Nibiru Node
After=network.target

[Service]
User=$USER
Type=simple
ExecStart=/usr/local/bin/nibid start
Restart=on-failure
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target" > $HOME/nibid.service
sudo mv $HOME/nibid.service /etc/systemd/system
sudo tee <<EOF >/dev/null /etc/systemd/journald.conf
Storage=persistent
EOF
echo -e '\n\e[42mRunning a service\e[0m\n' && sleep 1
sudo systemctl restart systemd-journald
sudo systemctl daemon-reload
sudo systemctl enable nibid
sudo systemctl restart nibid

echo -e '\n\e[42mCheck node status\e[0m\n' && sleep 1
if [[ `service nibid status | grep active` =~ "running" ]]; then
  echo -e "Your nibiru node \e[32minstalled and works\e[39m!"
  echo -e "You can check node status by the command \e[7mservice nibid status\e[0m"
  echo -e "Press \e[7mQ\e[0m for exit from status menu"
else
  echo -e "Your nibiru node \e[31mwas not installed correctly\e[39m, please reinstall."
fi
