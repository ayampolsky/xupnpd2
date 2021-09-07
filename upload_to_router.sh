#!/bin/bash

ROUTER_IP_ADDRESS="$1"
ROUTER_DIR="/etc/"

if [[ "$ROUTER_IP_ADDRESS" == "" ]]; then
	echo "Usage: $0 ROUTER_IP_ADDRESS"
	exit 0
fi

tar -cjvf etc/xupnpd2.tar.bz2 \
	xupnpd \
	www/ \
	media/ \
	xupnpd.cfg \
	get_playlist_planeta.sh

cp xupnpd.cfg etc/

scp -r etc/* "root@${ROUTER_IP_ADDRESS}:${ROUTER_DIR}"
