#!/usr/bin/env bash

# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
echo "Creating the gke cluster..."
gcloud beta container clusters create ${C1_NAME} \
    --zone ${C1_ZONE} \
    --no-enable-basic-auth \
    --enable-autoupgrade \
    --max-surge-upgrade 1 \
    --max-unavailable-upgrade 0 \
    --enable-autorepair \
    --image-type "COS_CONTAINERD" \
    --release-channel "regular" \
    --machine-type=n1-standard-4 \
    --num-nodes=${C1_NODES} \
    --workload-pool=${WORKLOAD_POOL} \
    --logging=SYSTEM,WORKLOAD \
    --monitoring=SYSTEM \
    --metadata disable-legacy-endpoints=true \
    --labels mesh_id=${MESH_ID} \
    --addons HorizontalPodAutoscaling,HttpLoadBalancing \
    --default-max-pods-per-node "110" \
    --enable-ip-alias \
    --no-enable-master-authorized-networks \
    --subnetwork=default \
    --scopes ${C1_SCOPE}


echo "Registering the gke cluster..."
for (( i=1; i<=4; i++))
do
  res=$(gcloud container fleet memberships register ${C1_NAME}-connect --gke-cluster=${C1_ZONE}/${C1_NAME} --enable-workload-identity 2>&1)
  g1=$(echo $res | grep "PERMISSION_DENIED: hub default service account does not have access to the GKE cluster project for")
  g2=$(echo $res | grep -c "PERMISSION_DENIED: hub default service account does not have access to the GKE cluster project for")
  if [[ "$g2" == "0" ]]; then
    echo "Cluster registered!"
    break;
  fi
    echo "Permissions problem, waiting and retrying"
    sleep 60
done

# should add error checking
