# ssz-z
An implementation of the Simple Serialize (SSZ) specification written in the Zig programming language.

## About
This library provides an implementation of the [Simple Serialize (SSZ)](https://github.com/ethereum/consensus-specs/tree/dev/ssz) specification, written in [Zig](https://ziglang.org/).

This follows Typescript implementation of Lodestar team https://github.com/ChainSafe/ssz

## Features
- **generic**: If you have an application struct, just write a respective ssz struct and create a ssz type then you have an ssz implementation. More on that in the example below.
- **batch hash** designed to support batch hash through `merkleize` function
- **HashFn by type** support generic `HashFn` as a parameter when creating a new type

## Installation
Clone the repository and build the project using Zig `git clone https://github.com/twoeths/ssz-z.git`
- `cd packages/ssz && zig build test:unit` to run all unit tests
- `cd packages/ssz && zig build test:lodestar` to run all lodestar tests
- `cd packages/ssz && zig build test:int` to run all integration tests (tests across types)
- `cd packages/persistent-merkle-tree && zig test --dep util -Mroot=src/merkleize.zig  -Mutil=../common/src/root.zig` run tests in merkleize.zig
- `cd packages/ssz && zig test --dep util --dep persistent_merkle_tree -Mroot=src/type/container.zig -Mutil=../common/src/root.zig -Mpersistent_merkle_tree=../persistent-merkle-tree/src/root.zig` to run tests in `src/type/container.zig`
- `zig build test:unit --verbose` to see how to map modules to run unit tests in a file
- `cd packages/ssz && zig test --dep ssz --dep persistent_merkle_tree --dep util -Mroot=test/int/type/container.zig -Mutil=../common/src/root.zig -Mpersistent_merkle_tree=../persistent-merkle-tree/src/root.zig --dep util --dep persistent_merkle_tree -Mssz=src/root.zig` to run int tests in `test/int/type/container.zig`
- `zig build test:int --verbose` to see how to map modules to run int tests in a file

## Tags

- Zig
- SSZ
- Ethereum
- Serialization
- Consensus
