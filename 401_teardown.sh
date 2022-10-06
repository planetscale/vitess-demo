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

# We should not assume that any of the steps have been executed.
# This makes it possible for a user to cleanup at any point.

source ./env.sh

./scripts/vtadmin-down.sh

./scripts/vtorc-down.sh

./scripts/vtgate-down.sh

for uid in 100 101; do
  printf -v alias '%s-%010d' 'zone2' $uid
  echo "Shutting down tablet $alias"
  CELL=zone1 TABLET_UID=$uid ./scripts/vttablet-down.sh
  CELL=zone1 TABLET_UID=$uid ./scripts/mysqlctl-down.sh
done

for uid in 200 201; do
  printf -v alias '%s-%010d' 'zone2' $uid
  echo "Shutting down tablet $alias"
  CELL=zone2 TABLET_UID=$uid ./scripts/vttablet-down.sh
  CELL=zone2 TABLET_UID=$uid ./scripts/mysqlctl-down.sh
done

./scripts/vtctld-down.sh


./scripts/etcd-down.sh

# pedantic check: grep for any remaining processes

if [ ! -z "$VTDATAROOT" ]; then

	if pgrep -f -l "$VTDATAROOT" >/dev/null; then
		echo "ERROR: Stale processes detected! It is recommended to manuallly kill them:"
		pgrep -f -l "$VTDATAROOT"
	else
		echo "All good! It looks like every process has shut down"
	fi

	# shellcheck disable=SC2086
	rm -r ${VTDATAROOT:?}/*

fi

disown -a
