shopt -s expand_aliases
alias vtctlclient="vtctlclient -server=localhost:15999"
alias mysql="mysql -h 127.0.0.1 -P 15306 -u user"

# checkPodStatusWithTimeout:
# $1: regex used to match pod names
# $2: number of pods to match (default: 1)
function checkPodStatusWithTimeout() {
  regex=$1
  nb=$2

  # Number of pods to match defaults to one
  if [ -z "$nb" ]; then
    nb=1
  fi

  # We use this for loop instead of `kubectl wait` because we don't have access to the full pod name
  # and `kubectl wait` does not support regex to match resource name.
  for i in {1..1200} ; do
    out=$(kubectl get pods)
    echo "$out" | grep -E "$regex" | wc -l | grep "$nb" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
      echo "$regex found"
      return
    fi
    sleep 1
  done
  echo -e "ERROR: checkPodStatusWithTimeout timeout to find pod matching:\ngot:\n$out\nfor regex: $regex"
  exit 1
}

cd vtop

kind create cluster --wait 30s --name kind
killall kubectl
kubectl apply -f operator.yaml
checkPodStatusWithTimeout "vitess-operator(.*)1/1(.*)Running(.*)"

kubectl apply -f 101_initial_cluster.yaml
checkPodStatusWithTimeout "demo-zone1-vtctld(.*)1/1(.*)Running(.*)"
checkPodStatusWithTimeout "demo-zone1-vtgate(.*)1/1(.*)Running(.*)"
checkPodStatusWithTimeout "demo-etcd(.*)1/1(.*)Running(.*)" 3
checkPodStatusWithTimeout "demo-vttablet-zone1(.*)3/3(.*)Running(.*)" 2

sleep 10
./pf.sh > /dev/null 2>&1 &

vtctlclient tabletexternallyreparented "tabletname"
