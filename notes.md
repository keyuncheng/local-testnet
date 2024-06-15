
# Ethereum installation

##  Install dependencies

* Go version: 1.22
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.22.4.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin

* Geth version: 1.13.0 (download from Github)
make all
export PATH=$PATH:<prefix>/go-ethereum-1.13.0/build/bin

* Rust: follow local-testnet (standard installation)

* Lighthouse: follow local-testnet

download go-ethereum-v1.13.0.tar.gz
make all

EL-node ip
EL-bootnode ip
EL-signer node ip