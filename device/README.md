

## Install go

Download go binary, in the raspberry pi for the model 3b the architecture is ARM6  [link](https://golang.org/dl/)

```
tar -C ~ -xzf go$VERSION.$OS-$ARCH.tar.gz
```

Install on the home directory

Run
```
cd ~
mkdir gopath
cd gopath
mkdir src bin pkg
```

Add the path for go on .bashrc

```
export PATH=$PATH:/home/pi/go/bin
export GOROOT=/home/pi/go
export GOPATH=/home/pi/gopath
```

## Install dependencies
```
go get github.com/paypal/gatt
```

## Run code
GOPATH=$(pwd) go run src/central/central.go
