#!/bin/sh

PLAYLIST_URL="http://ott.tv.planeta.tc/plst.m3u"

rm -rf media/
mkdir -p media/
cd media/

rm -f plst.m3u
rm -f *.m3u

wget "$PLAYLIST_URL"

PLAYLIST_PREFIX=`grep -v "#EXTINF\|playlist.tv.planeta.tc"  plst.m3u`
CHANNEL_GROUPS=`grep -o 'group-title="[^"]*"' plst.m3u | cut -d '=' -f 2 | sort | uniq`
echo "$CHANNEL_GROUPS" > groups.txt

while IFS= read -r CHANNEL_GROUP; do
	PLAYLIST_FILENAME=`echo "$CHANNEL_GROUP" | grep -o '[^"]*'`".m3u"
	echo "Writing channels of group $CHANNEL_GROUP to $PLAYLIST_FILENAME"
	rm -f "$PLAYLIST_FILENAME"
	echo "$PLAYLIST_PREFIX" > "$PLAYLIST_FILENAME"
	grep -A 1 -B 0 "$CHANNEL_GROUP" plst.m3u >> "$PLAYLIST_FILENAME"
done < groups.txt

rm -f plst.m3u
rm -f groups.txt

cd ../
