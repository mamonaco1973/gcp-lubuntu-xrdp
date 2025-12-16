
#!/bin/bash

WIN_IP=$(gcloud compute instances list \
  --filter="name~'^win-ad'" \
  --format="value(networkInterfaces.accessConfigs[0].natIP)")

echo "NOTE: Windows AD instance public IP address is $WIN_IP"



NFS_IP=$(gcloud compute instances list \
  --filter="name~'^xubuntu'" \
  --format="value(networkInterfaces.accessConfigs[0].natIP)")

echo "NOTE: Xubuntu public IP address is $NFS_IP"
