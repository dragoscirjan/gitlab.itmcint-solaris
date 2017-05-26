exit 0;
# make sure you've set the correct interface

NETWORK_IF=${NETWORK_IF:-ifext};
NETWORK_TO_80=${NETWORK_TO_80:-172.18.0.1};
	
iptables -t nat -D PREROUTING -i $NETWORK_IF -p tcp --dport 80 -j DNAT --to $TO_80:80 || true;
iptables -t nat -A PREROUTING -i $NETWORK_IF -p tcp --dport 80 -j DNAT --to $TO_80:80;
iptables -t nat -nL;