
# Ethereum installation

##  Install dependencies

* Go version: 1.22 (download release from website)
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.22.4.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin

* Geth version: 1.13.0 (download release from Github)
make all
export PATH=$PATH:<prefix>/go-ethereum-1.13.0/build/bin

Rust: follow local-testnet (standard installation)

* Lighthouse version: v5.0.0 (download release from Github)
wget https://github.com/sigp/lighthouse/archive/refs/tags/v5.0.0.tar.gz
make && make install-lcli


# FAQ

* Errors in geth.log: "retrieved hash chain is invalid"
   * sync time using ntpdate (ntp.ubuntu.com)
   * https://ethereum.stackexchange.com/questions/15379/retrieved-hash-chain-is-invalid

EL-node ip
EL-bootnode ip
EL-signer node ip
