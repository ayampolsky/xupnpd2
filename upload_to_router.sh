#!/bin/bash

ROUTER_IP_ADDRESS="$1"
ROUTER_DIR="/etc/"

if [[ "$ROUTER_IP_ADDRESS" == "" ]]; then
	echo "Usage: $0 ROUTER_IP_ADDRESS"
	exit 0
fi

FILE_LIST="xupnpd www/ media/ xupnpd.cfg get_playlist_planeta.sh"

function get_bzip2_block_size_with_best_compression_ratio {
	COMPRESSION_DIR="/tmp/xupnpd2_compression/"
	rm -rf "$COMPRESSION_DIR"
	mkdir "$COMPRESSION_DIR"
	for i in `seq 9`; do
		export "BZIP=-$i"
		tar -cjvf "$COMPRESSION_DIR/xupnpd2_$i.tar.bz2" $FILE_LIST > /dev/null
	done
	BZIP_ARG=`ls -S $COMPRESSION_DIR/xupnpd2_*.tar.bz2 | tail -n 1 | grep -o "xupnpd2_[0-9]" | cut -d '_' -f 2`
	rm -rf "$COMPRESSION_DIR"
	echo "$BZIP_ARG"
}

BZIP_ARG="-`get_bzip2_block_size_with_best_compression_ratio`"
echo "bzip2 argument is \"$BZIP_ARG\""
export "BZIP=$BZIP_ARG";
tar -cjvf etc/xupnpd2.tar.bz2 $FILE_LIST

#cp xupnpd.cfg etc/

scp -r etc/* "root@${ROUTER_IP_ADDRESS}:${ROUTER_DIR}"
