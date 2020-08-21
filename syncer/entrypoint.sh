#!/bin/bash

arsenal=https://github.com/cloud-bulldozer/arsenal.git
dashboards="ocp-performance.json api-performance-overview.json etcd-on-cluster-dashboard.json"

git clone ${arsenal} --depth=1
make -C arsenal/jsonnet build
pushd arsenal/jsonnet/rendered
while [[ $(curl -s -o /dev/null -w '%{http_code}' http://localhost:3000/api/health) != "200" ]]; do 
  echo "Grafana still not ready, waiting 5 seconds"
  sleep 5
done

for d in ${dashboards}; do
  if [[ ! -f $d ]]; then
    echo "Dashboard ${d} not found"
    continue
  else
    echo "Importing dashboard $d"
    dashboard=$(cat ${d})
    echo "{\"dashboard\": ${dashboard}, \"overwrite\": true}" | \
      curl -Ss -XPOST -H "Content-Type: application/json" -H "Accept: application/json" -d@- \
      "http://admin:${GRAFANA_ADMIN_PASSWORD}@localhost:3000/api/dashboards/db" -o /dev/null
  fi    
done

echo "Dittybopper ready"
exec sleep inf
