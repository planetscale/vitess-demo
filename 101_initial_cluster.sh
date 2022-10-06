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

# start vttablets in zone1 for keyspace commerce
for i in 100 101; do
	CELL=zone1 TABLET_UID=$i ./scripts/mysqlctl-up.sh
	CELL=zone1 KEYSPACE=commerce TABLET_UID=$i ./scripts/vttablet-up.sh
done

# start vttablets in zone2 for keyspace commerce
for i in 200 201; do
	CELL=zone2 TABLET_UID=$i ./scripts/mysqlctl-up.sh
	CELL=zone2 KEYSPACE=commerce TABLET_UID=$i ./scripts/vttablet-up.sh
done

# set the correct durability policy for the keyspace
vtctldclient --server localhost:15999 SetKeyspaceDurabilityPolicy --durability-policy=cross_cell commerce

# start vtorc
./scripts/vtorc-up.sh

# Wait for all the tablets to be up and registered in the topology server
for _ in $(seq 0 200); do
	vtctldclient GetTablets --keyspace commerce --shard 0 | wc -l | grep -q "4" && break
	sleep 1
done;
vtctldclient GetTablets --keyspace commerce --shard 0 | wc -l | grep -q "4" || (echo "Timed out waiting for tablets to be up in commerce/0" && exit 1)

# Wait for a primary tablet to be elected in the shard
for _ in $(seq 0 200); do
	vtctldclient GetTablets --keyspace commerce --shard 0 | grep -q "primary" && break
	sleep 1
done;
vtctldclient GetTablets --keyspace commerce --shard 0 | grep "primary" || (echo "Timed out waiting for primary to be elected in commerce/0" && exit 1)

# create the schema
vtctldclient ApplySchema --sql-file create_commerce_schema.sql commerce

# create the vschema
vtctldclient ApplyVSchema --vschema-file vschema_commerce_initial.json commerce

# start vtgate
./scripts/vtgate-up.sh

# start vtadmin
./scripts/vtadmin-up.sh

