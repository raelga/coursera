# 21490 - Virtual Private Networks (VPN) v1.5

Virtual Private Networks (VPN)


In this lab, you create two networks in separate regions and establish VPN tunnels between them such that a VM in one network can ping a VM in the other network over its internal IP.

```bash
gcloud compute networks create vpn-network-1 --subnet-mode custom
gcloud compute networks create vpn-network-2 --subnet-mode custom
gcloud compute networks subnets create subnet-a --network vpn-network-1 --range 10.5.4.0/24 --region us-east1
gcloud compute networks subnets create subnet-b --network vpn-network-2 --range 10.1.3.0/24 --region europe-west1
gcloud compute instances create server-1 --zone us-east1-b --machine-type f1-micro --network vpn-network-1 --subnet subnet-a
gcloud compute instances create server-2 --zone europe-west1-b --machine-type f1-micro --network vpn-network-2 --subnet subnet-b

gcloud compute firewall-rules create allow-icmp-ssh-network-1 --allow tcp:22,icmp --network vpn-network-1 --source-ranges 0.0.0.0/0
gcloud compute firewall-rules create allow-icmp-ssh-network-2 --allow tcp:22,icmp --network vpn-network-2 --source-ranges 0.0.0.0/0

gcloud compute target-vpn-gateways create vpn-1 --network vpn-network-1 --region us-east1
gcloud compute target-vpn-gateways create vpn-2 --network vpn-network-2 --region europe-west1

gcloud compute addresses create --region us-east1 vpn-1-static-ip && export STATIC_IP_VPN_1=$(gcloud compute addresses list --filter="name=('vpn-1-static-ip')" --format="value(address_range())")

gcloud compute addresses create --region europe-west1 vpn-2-static-ip && export STATIC_IP_VPN_2=$(gcloud compute addresses list --filter="name=('vpn-2-static-ip')" --format="value(address_range())")

gcloud compute forwarding-rules create vpn-1-esp --region us-east1 --ip-protocol ESP --address $STATIC_IP_VPN_1 --target-vpn-gateway vpn-1
gcloud compute forwarding-rules create vpn-2-esp --region europe-west1 --ip-protocol ESP --address $STATIC_IP_VPN_2 --target-vpn-gateway vpn-2

gcloud compute forwarding-rules create vpn-1-udp500 --region us-east1 --ip-protocol UDP --ports 500 --address $STATIC_IP_VPN_1 --target-vpn-gateway vpn-1
gcloud compute forwarding-rules create vpn-2-udp500 --region europe-west1 --ip-protocol UDP --ports 500 --address $STATIC_IP_VPN_2 --target-vpn-gateway vpn-2

gcloud compute forwarding-rules create vpn-1-udp4500 --region us-east1 --ip-protocol UDP --ports 4500 --address $STATIC_IP_VPN_1 --target-vpn-gateway vpn-1
gcloud compute forwarding-rules create vpn-2-udp4500 --region europe-west1 --ip-protocol UDP --ports 4500 --address $STATIC_IP_VPN_2 --target-vpn-gateway vpn-2

gcloud compute vpn-tunnels create tunnel1to2 --peer-address $STATIC_IP_VPN_2 --region us-east1 --ike-version 2 --shared-secret gcprocks --target-vpn-gateway vpn-1 --local-traffic-selector 0.0.0.0/0 --remote-traffic-selector 0.0.0.0/0

gcloud compute vpn-tunnels create tunnel2to1 --peer-address $STATIC_IP_VPN_1 --region europe-west1 --ike-version 2 --shared-secret gcprocks --target-vpn-gateway vpn-2 --local-traffic-selector 0.0.0.0/0 --remote-traffic-selector 0.0.0.0/0

gcloud compute routes create route1to2 --network vpn-network-1 --next-hop-vpn-tunnel tunnel1to2 --next-hop-vpn-tunnel-region us-east1 --destination-range 10.1.3.0/24
gcloud compute routes create route2to1 --network vpn-network-2 --next-hop-vpn-tunnel tunnel2to1 --next-hop-vpn-tunnel-region europe-west1 --destination-range 10.5.4.0/24
```