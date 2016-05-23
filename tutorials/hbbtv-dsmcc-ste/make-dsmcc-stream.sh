#!/bin/sh
#
# This file is part of the opencaster distribution (https://github.com/caghan/opencaster )
# Copyright (c) 2016 Caghan Ozbek.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, version 3.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#

mkdir -p output

python ./hbbtv-dsmcc.py

ait_bt="18724"
av="c:2300000 short/firstvideo.ts b:188000 short/firstaudio.ts "
pmt=""
ait=""
dsmcc_folder="ocdir1"
dsmcc_version=23
#dsmcc_version=&15
carousel_id=11
multicast_interface="eth0"
multicast_ip_addr="224.0.1.2"
multicast_port="7001"
multicast_bitrate="2496916" 
output="output/sevent.ts"
fifo="output/fifo.ts"

pkill -9 tsloop
pkill -9 tsudpsend
pkill -9 inotifywait

#oc-update
#	carousel_directory: ocdir1
#	association_tag: 0xB (11)
#	modules_version: 0x5 (5)
#	pid: 2001
#	carousel_id: 7
#	smart compress the carousel
#	don't pad
#	delete temp files
#	use 4066 bytes for DDB size (usual and maximum size)
#	sets update flag to 0 in DSI/DII
#	insert DSI/DII/SGW twice per carousel length


dsmcc_create="oc-update $dsmcc_folder 0xB 0x$dsmcc_version 2003 $carousel_id 1 0 0 4066 1 10"
echo $dsmcc_create
eval $dsmcc_create

for filename in pmt*.ts; do
        pmt="$pmt b:$ait_bt $filename"
done
for fn in ait*.ts; do
        ait="$ait b:$ait_bt $fn"
done

mux="tscbrmuxer $av b:19024 pat.ts $pmt b:1400 nit.ts b:1500 sdt.ts b:2000 ste.ts b:100000 $dsmcc_folder.ts $ait > $output";
echo $mux
eval $mux

mkfifo $fifo

tsloop="tsloop $output > $fifo &"
echo $tsloop
eval $tsloop

tsudpsend="tsudpsend $fifo $multicast_ip_addr $multicast_port $multicast_bitrate $multicast_interface &"
echo $tsudpsend
eval $tsudpsend

ste_version=1

echo "START WAITING FOR STE.TS UPDATE"

while inotifywait -rq -e close_write ste.ts; do
    echo "[$DATE]: STE.TS updated on filesystem. Re-muxing with new STE.TS file."
    echo $mux
    eval $mux
    tsloop_process_id=$(pidof tsloop)
    if [ -z $tsloop_process_id ]; then
        echo $tsloop
	eval $tsloop
        tsudpsend_process_id=$(pidof tsudpsend)
    	if [ -z $tsudpsend_process_id ]; then
		echo $tsudpsend
		eval $tsudpsend
	fi
    fi
done 
