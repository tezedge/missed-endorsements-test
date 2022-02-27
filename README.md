# Endorsement with Alternative Heads

This tests checks that a node can endorse a block if it also receives another block at the same level.

During this test, the node under test is run along with endorser, and two other nodes are used to bake different blocks simulteniously. The node under test should successfully endorse one of these two blocks. This is verified by reading the node's mempool state.

Both Octez and Tezedge v1.16.0 pass the test, Tezedge v1.15.0 fails.

## How to Run with Octez Node

``` sh
$ ./run.sh octez-node
...
>>> passed after 10 level
```

## How to Run with Old Tezedge Node

``` sh
$ TEZEDGE_IMAGE=tezedge/tezedge:v1.15.1 ./run.sh
...
>>> 3 attempts failed
```

## How to Run with Old Tezedge Node

``` sh
$ TEZEDGE_IMAGE=tezedge/tezedge:latest ./run.sh
...
>>> passed after 10 level
```
