# Kubernetes Note

## Public Server Port Fowarding

```bash
# forward public 80/443 to Traefik NodePorts on the VIP
sudo iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 80  -j DNAT --to-destination <HA-CLUSTER-IP>:12345 # change to actual port in the cluster
sudo iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 443 -j DNAT --to-destination <HA-CLUSTER-IP>:54321 # change to actual port in the cluster

# change subnet to actual subnet and --to-source to public server cluster subnet IP
sudo iptables -t nat -A POSTROUTING -s 0.0.0.0/0 -d 192.168.10.0/24 -j SNAT --to-source 192.168.10.xx

# allow forward
sudo iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -p tcp -d <HA-CLUSTER-IP> --dport 12345 -j ACCEPT # change to actual port for port 80 in the cluster
sudo iptables -A FORWARD -p tcp -d <HA-CLUSTER-IP> --dport 54321 -j ACCEPT # change to actual port for port 443 in the cluster
```
