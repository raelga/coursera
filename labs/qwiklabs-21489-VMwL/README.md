gcloud compute instances create webserver1 --zone us-central1-a --scopes storage-ro --metadata startup-script-url=gs://cloud-training/archinfra/mystartupscript,my-server-id=WebServer-1 --tags http-server,network-lb

gcloud compute instances create webserver2 --zone us-central1-a --scopes storage-ro --metadata startup-script-url=gs://cloud-training/archinfra/mystartupscript,my-server-id=WebServer-2 --tags http-server,network-lb

gcloud compute instances create webserver3 --zone us-central1-a --scopes storage-ro --metadata startup-script-url=gs://cloud-training/archinfra/mystartupscript,my-server-id=WebServer-3 --tags http-server,network-lb

gcloud compute addresses create network-lb-ip --region us-central1 && export STATIC_EXTERNAL_IP=$(gcloud compute addresses list --filter="name=('network-lb-ip')" --format="value(address_range())")

gcloud compute instances add-tags --tags network-lb --zone us-central1-a webserver1
gcloud compute instances add-tags --tags network-lb --zone us-central1-a webserver2
gcloud compute instances add-tags --tags network-lb --zone us-central1-a webserver3

gcloud compute http-health-checks create webserver-health

gcloud compute target-pools create extloadbalancer --region us-central1 --http-health-check webserver-health

gcloud compute target-pools add-instances extloadbalancer --instances webserver1,webserver2,webserver3 --instances-zone=us-central1-a

gcloud compute forwarding-rules create webserver-rule --region us-central1 --ports 80 --address $STATIC_EXTERNAL_IP --target-pool extloadbalancer

gcloud compute instances create webserver4 \
    --image-family debian-9 \
    --image-project debian-cloud \
    --tags int-lb \
    --zone us-central1-f \
    --subnet default \
    --metadata startup-script-url="gs://cloud-training/archinfra/mystartupscript",my-server-id="WebServer-4"

gcloud compute instances create webserver5 \
    --image-family debian-9 \
    --image-project debian-cloud \
    --tags int-lb \
    --zone us-central1-f \
    --subnet default \
    --metadata startup-script-url="gs://cloud-training/archinfra/mystartupscript",my-server-id="WebServer-5"

gcloud compute instances remove-tags --tags network-lb --zone us-central1-a webserver2
gcloud compute instances remove-tags --tags network-lb --zone us-central1-a webserver3
gcloud compute instances add-tags --tags int-lb --zone us-central1-a webserver2
gcloud compute instances add-tags --tags int-lb --zone us-central1-a webserver3

gcloud compute instance-groups unmanaged create ig1 --zone us-central1-a

gcloud compute instance-groups unmanaged add-instances ig1 --instances=webserver2,webserver3 --zone us-central1-a

gcloud compute instance-groups unmanaged create ig2 --zone us-central1-f
gcloud compute instance-groups unmanaged add-instances ig2 --instances=webserver4,webserver5 --zone us-central1-f

gcloud compute health-checks create tcp my-tcp-health-check --port 80

gcloud compute backend-services create my-int-lb --load-balancing-scheme internal --region us-central1 --health-checks my-tcp-health-check --protocol tcp

gcloud compute backend-services add-backend my-int-lb --instance-group ig1 --instance-group-zone us-central1-a --region us-central1

gcloud compute backend-services add-backend my-int-lb --instance-group ig2 --instance-group-zone us-central1-f --region us-central1

gcloud compute forwarding-rules create my-int-lb-forwarding-rule --load-balancing-scheme internal --ports 80 --network default --subnet default --region us-central1 --backend-service my-int-lb

gcloud compute firewall-rules create allow-internal-lb --network default --source-ranges 0.0.0.0/0 --target-tags int-lb --allow tcp:80,tcp:443

gcloud compute firewall-rules create allow-health-check -network default --source-ranges 130.211.0.0/22,35.191.0.0/16 --target-tags int-lb --allow tcp
