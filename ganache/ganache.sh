#!/bin/bash

echo "start ganache locally"
nohup ganache --chain.chainId 1337 --chain.networkId 1337 --miner.blockTime 3 > ./ganache/ganache.log 2>&1 &