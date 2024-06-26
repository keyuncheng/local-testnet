
# Local-Testnet Installation Guide

A distributed version of Ethereum-based local testnet running on multiple machines. The
implementation is modified based on ```git:ethereum/local-testnet```

Keyun Cheng, CUHK; June 26 2024

##  Install dependencies

* Most instructions are the same as ```git:ethereum/local-testnet```
  (please refer to the original [README](README-original.md) for details)

### Go version: 1.22.4

```
wget https://go.dev/dl/go1.22.4.linux-amd64.tar.gz
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.22.4.linux-amd64.tar.gz
```

add path to ```~/.bashrc```
```
export PATH=$PATH:/usr/local/go/bin
```

### Geth version: 1.13.0

```
git clone https://github.com/ethereum/go-ethereum.git
git checkout tags/v1.13.0
make all
```

add path to ```~/.bashrc```

```
export PATH=$PATH:<path-prefix>/go-ethereum-1.13.0/build/bin
```

### Rust (latest):

* Choose ```1 (standard installation)```
```
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"
```

add path to ```~/.bashrc```
```
. "$HOME/.cargo/env"
```

### Lighthouse: v5.0.0

```
sudo apt-get install -y git gcc g++ make cmake pkg-config llvm-dev libclang-dev clang protobuf-compiler
git clone https://github.com/sigp/lighthouse.git
cd lighthouse
git checkout tags/v5.0.0
make
make install-lcli
```

* NodeJS and JSON plugin (latest)

```
sudo apt-get install -y nodejs npm
sudo apt-get install -y jq
```

### Synchronize time

sync time using ntp and ntpdate (ntp server: ntp.ubuntu.com)

```
sudo apt-get install ntp ntpdate
sudo service ntp stop
ntpdate ntp.ubuntu.com
sudo service ntp start
```

Reference: [Link](https://ethereum.stackexchange.com/questions/15379/retrieved-hash-chain-is-invalid)
* This can address errors in Geth /node<id>/ethereum/geth.log: "retrieved hash chain is invalid"

# Run local testnet

* There are N nodes, where the first node acts as the signer node and boot
  node, while the remaining N - 1 nodes as execution clients and validator
  clients.
   * There are a total of 12 (= 3 * 4) validator clients

* Please update node configurations
   * In ```vars.env```: # of validator clients ($VALIDATOR_COUNT); # of nodes
     ($NODE_COUNT)
   * In ```node_list.txt``` and ```vars.env```: node ips

Example (please check ```node_list.txt``` and ```vars.env``` for the sample configurations): 

| Node ID | IP | Role |
|----------|:-------------:|------:|
| 0 | 192.168.10.27 | Geth signer, Geth bootnode; Lighthouse bootnode |
| 1 | 192.168.10.24 | Geth execution client; Lighthouse beacon node; 4 x Lighthouse Validator Clients |
| 2 | 192.168.10.26 | Geth execution client; Lighthouse beacon node; 4 x Lighthouse Validator Clients |
| 3 | 192.168.10.28 | Geth execution client; Lighthouse beacon node; 4 x Lighthouse Validator Clients |