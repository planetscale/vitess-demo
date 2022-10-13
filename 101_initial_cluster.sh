#!/bin/bash

# Copyright 2022 The Vitess Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# this script brings up zookeeper and all the vitess components
# required for a single shard deployment.

source ./env.sh

# start topo server
./scripts/etcd-up.sh

# start vtctld
CELL=zone1 ./scripts/vtctld-up.sh

# start vttablets in zone1 for keyspace semi_sync_ks
for i in 100 101 102 103; do
	CELL=zone1 TABLET_UID=$i ./scripts/mysqlctl-up.sh
	CELL=zone1 KEYSPACE=semi_sync_ks TABLET_UID=$i ./scripts/vttablet-up.sh
done

# start vttablets in zone2 for keyspace cross_cell_ks
for i in 200 201 202; do
	CELL=zone2 TABLET_UID=$i ./scripts/mysqlctl-up.sh
	CELL=zone2 KEYSPACE=cross_cell_ks TABLET_UID=$i ./scripts/vttablet-up.sh
done

# start vttablet in zone1 for keyspace cross_cell_ks
CELL=zone1 TABLET_UID=300 ./scripts/mysqlctl-up.sh
CELL=zone1 KEYSPACE=cross_cell_ks TABLET_UID=300 ./scripts/vttablet-up.sh

# set the correct durability policy for the keyspaces
vtctldclient --server localhost:15999 SetKeyspaceDurabilityPolicy --durability-policy=cross_cell cross_cell_ks
vtctldclient --server localhost:15999 SetKeyspaceDurabilityPolicy --durability-policy=semi_sync semi_sync_ks

# start vtorc
./scripts/vtorc-up.sh

# Wait for all the tablets to be up and registered in the topology server
for _ in $(seq 0 200); do
	vtctldclient GetTablets --keyspace cross_cell_ks --shard 0 | wc -l | grep -q "4" && break
	sleep 1
done;
vtctldclient GetTablets --keyspace cross_cell_ks --shard 0 | wc -l | grep -q "4" || (echo "Timed out waiting for tablets to be up in cross_cell_ks/0" && exit 1)
for _ in $(seq 0 200); do
	vtctldclient GetTablets --keyspace semi_sync_ks --shard 0 | wc -l | grep -q "4" && break
	sleep 1
done;
vtctldclient GetTablets --keyspace semi_sync_ks --shard 0 | wc -l | grep -q "4" || (echo "Timed out waiting for tablets to be up in semi_sync_ks/0" && exit 1)

# Wait for a primary tablet to be elected in the shard
for _ in $(seq 0 200); do
	vtctldclient GetTablets --keyspace cross_cell_ks --shard 0 | grep -q "primary" && break
	sleep 1
done;
vtctldclient GetTablets --keyspace cross_cell_ks --shard 0 | grep "primary" || (echo "Timed out waiting for primary to be elected in cross_cell_ks/0" && exit 1)
for _ in $(seq 0 200); do
	vtctldclient GetTablets --keyspace semi_sync_ks --shard 0 | grep -q "primary" && break
	sleep 1
done;
vtctldclient GetTablets --keyspace semi_sync_ks --shard 0 | grep "primary" || (echo "Timed out waiting for primary to be elected in semi_sync_ks/0" && exit 1)

# create the schema
vtctldclient ApplySchema --sql-file create_commerce_schema.sql cross_cell_ks
vtctldclient ApplySchema --sql-file create_commerce_schema.sql semi_sync_ks

# create the vschema
vtctldclient ApplyVSchema --vschema-file vschema_commerce_initial.json cross_cell_ks
vtctldclient ApplyVSchema --vschema-file vschema_commerce_initial.json semi_sync_ks

# start vtgate
./scripts/vtgate-up.sh

# start vtadmin
./scripts/vtadmin-up.sh

