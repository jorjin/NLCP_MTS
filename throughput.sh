#!/system/bin/teTool/sh
# Program:
# 		creates by Vane .
# History:
# 		2012/08/23	Vane	Jorjin release
source setenv

AP_SSID=""
DUT_IP=""
PC_IP=""
TEST_DURATION=""
INSER=""
DUT_IP=$1

INSER=$(lsmod | busybox grep "^wl12xx_sdio")
INSER=$(echo "$INSER" | busybox awk -F' ' '{ print $1 }')

if [ "$INSER" != "wl12xx_sdio" ]; then
	insmod /system/lib/modules/wl12xx_sdio.ko
fi
DUT_IP=${1}
ifconfig wlan0 ${DUT_IP} up
echo "WIFI init ..."
sleep 1
if [ "$#" == "0" ] ; then 
echo -e "You can set static IP
		\rie: ${HYE}./throughput 192.168.xxx.xxx${NO}"
else
	echo "IP_ADDR=${DUT_IP}"
fi
sleep 1
#***********************************************************
#		Get SSID Name
#***********************************************************
get_ssid_name(){
        CONNECTED_SSID=$(iw dev wlan0 link | busybox grep 'SSID' | busybox sed 's/^.*SSID://g')
        CONNECTED_SSID=$(echo "${CONNECTED_SSID}" | busybox awk -F' ' '{ print $1 }')
	DUT_IP=$(ifconfig wlan0 | busybox awk -F' ' '{ print $3 }' )
}
#***********************************************************
#		Error type
#***********************************************************
error_type(){
	echo "Error type, Please try again!!!!!"
busybox clear
}

#***********************************************************
#		TX
#***********************************************************
throughput_tx()
{
	busybox clear
	get_ssid_name
	echo "AP name :$CONNECTED_SSID"
	echo "DUT IP :$DUT_IP"
	echo "Default Server IP :$RETEST_IP"
	echo -e "
			\r*****************************
			\r* If you want to retest TX, *
			\r* don't need type IP !!     *
			\r*****************************
			\rPlease type Server IP: 
			\ror
			\rkeep type 'q' to leave"
	read -p "===>" TYPE_IP

	if [ "$TYPE_IP" != "" ]; then #if you type address
		RETEST_IP=${TYPE_IP}
		PC_IP=${RETEST_IP}
	fi

	echo -e "
			\rPlease type Test duration time:
			\ror
			\rkeep type 'q' to leave
			\rex: 60"
	read -p "===>" TEST_DURATION

	if [ "${TYPE_IP}" == "" ]; then
		RETEST_IP=${PC_IP}
	elif [ "$TYPE_IP" == "q" ]; then
		busybox killall iperf
		busybox clear
		continue
	else
		RETEST_IP=" null "
		RETEST_IP=${PC_IP}
	fi
			echo "[ Iperf Tx Start ; Test $TEST_DURATION secs ]"
			iperf -c ${RETEST_IP} -w128k -l16k -i1 -t${TEST_DURATION}

}
#***********************************************************
#		RX
#***********************************************************
throughput_rx(){
busybox clear
while [ 1 ]; do
echo -e "
\r+++++++++++++++++++++++++++++++++++++++++++++++++++++
\r                Throughput Rx Test Mode  
\r+++++++++++++++++++++++++++++++++++++++++++++++++++++\n
\r1. Rx start\n
\r2. Rx stop\n
\rq. Exit"
read -p"====>" TP_R
case "$TP_R" in
1)
	get_ssid_name
	if [ "${AP_SSID}" != "${CONNECTED_SSID}" ]; then
		echo "[ Error!!! No Connection, please reconnect AP ]"
		break
	fi
	
	Server=$(ps | busybox grep 'iperf')

	if [ "$Server" != "" ]; then
		busybox killall iperf
		sleep 1
	fi

		echo "[ iperf Rx Start ]"
		sleep 1
		echo "[ Please run client at PC ]"
		iperf -s -w 128k -l 16k -i 1 -t &
		busybox clear
		continue
		;;
2)
	busybox killall iperf
	echo "[ iperf Stop ]"
	sleep 1
	busybox clear
	continue
	;;

q)
	Server=$(ps | busybox grep 'iperf')
	if [ "$Server" != "" ]; then
	busybox killall iperf
	fi
	break
	;;
*)
	error_type
	;;
esac
done
}

scan_AP()
{
	SCAN_SSID=$( iw wlan0 scan | busybox grep 'SSID:' )
	echo "${SCAN_SSID}"
}


#**********************************************
#					Main
#**********************************************
while [ 1 ]; do
echo -e "
		\r+++++++++++++++++++++++++++++++++++++++++++++++++++++
		\r                Throughput Test Mode
		\r+++++++++++++++++++++++++++++++++++++++++++++++++++++
		\r0. Scan AP\n
		\r1. Connect to AP\n
		\r2. Tx(Client)\n
		\r3. Rx(Server)\n
		\rq. Exit"
read -p "====> " TP
case "$TP" in
0)
	busybox clear
	scan_AP
	continue
;;

1)
read -p "
Please Enter SSID Name Or Type 'q' Leave...
====> " SSID
#----------------------------------------
if [ "$SSID" == "q"  ]; then
	busybox clear
	continue
fi
#----------------------------------------
	AP_SSID=${SSID}
	get_ssid_name
		if [ "$AP_SSID" != "$CONNECTED_SSID" ]; then
			echo "Connecting $AP_SSID ..."
			iw wlan0 connect $AP_SSID
		fi
#----------------------------------------
        sleep 1
	CHICK_IP=$( busybox ifconfig wlan0 | busybox grep 'inet addr:' )
	if [ "$CHICK_IP" == "" ]; then
		netcfg wlan0 dhcp
		echo "config DHCP IP address..."
		CHICK_IP=$( busybox ifconfig wlan0 | busybox grep 'inet addr:' )
		echo "$CHICK_IP"
	else
		echo "$CHICK_IP"
	fi
#----------------------------------------
	sleep 1
	DUT_IP=$(ifconfig wlan0 | busybox awk -F' ' '{ print $3 }' )
	get_ssid_name
	if [ "$AP_SSID" == "$CONNECTED_SSID" ]; then
	iw dev wlan0 link
	fi
	continue
	;;
2)
	throughput_tx
	continue
	;;
3)
	throughput_rx
	continue
	;;
q|Q)
	echo "Disconnect !!"
	CONN_STATE=$( iw wlan0 link | busybox grep 'Not' )
	if [ "${CONN_STATE}" != "Not connected." ]; then
		echo "${CONN_STATE}"
		iw wlan0 disconnect
	fi
	ifconfig wlan0 down
	rmmod wl12xx_sdio
	busybox clear
	exit
	;;
*)
	error_type
	;;
esac
done
