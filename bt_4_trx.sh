#!/system/bin/teTool/sh
# Program:
# 		creates by Vane .
# History:
# 		2012/08/23	Vane	Jorjin release

count=0
#***********************************************************
#		Error type
#***********************************************************
error_type(){
echo "
Error type, Please try again!!!!!"
sleep 1
busybox clear
}

init_bt(){
echo "Init BT..."
hciconfig hci0 down
sleep 1
echo "BT up..."
hciconfig hci0 up
echo "Disable BT deep sleep mode..."
hcitool cmd 0x3f 0x10c 0x00 0x00 0x00 0xff 0xff 0xff 0xff 0x64
echo "Disable BT scan..."
hcitool cmd 0x03 0x1a 0x00
echo "Init BT done"
count=0
sleep 1
busybox clear
}

set_channel(){
busybox clear
read -p "
++++++++++++++++++++++++++++++++++++++++++++++++++
 Note : BT 4.0 only support CH 0 to CH 39
++++++++++++++++++++++++++++++++++++++++++++++++++
Please type your channel number or type 'q' to leave
ex: 0 ,1 ,2 ,10 ...
===> " TYPE_CH
if [ $TYPE_CH -ge 40 ]; then
	error_type
	count=0
elif [ $TYPE_CH = "q" ]; then
	busybox clear
	count=0
	continue
else
#	V_CH=$(($TYPE_CH-1))
	V_CH=$(printf "0x%02x\n" $TYPE_CH )
	count=1
	busybox clear
fi
}

bt_ctx(){
init_bt
while [ 1 ]; do
echo "++++++++++++++++++++++++++++++++++++++++++++++++++"
if [ $count == 1 ]; then
echo "               Now TX channel = $TYPE_CH "
fi
read -p "               BT-4.0 Continuous TX
++++++++++++++++++++++++++++++++++++++++++++++++++
1) - Entering BT channel

2) - Start TX

3) - Stop TX

Q) - Exit
====> " TX
case "$TX" in
1)
	set_channel
	continue;;

2)
	busybox clear
	hcitool cmd 0x08 0x01E $V_CH 0x25 0x02
	continue;;

3)
	count=0
	busybox clear
	hcitool cmd 0x08 0x01F
	continue;;

q|Q)
	busybox clear
	break;;

*)
	error_type;;
esac
done
}


bt_crx(){
init_bt
while [ 1 ]; do
echo "++++++++++++++++++++++++++++++++++++++++++++++++++"
if [ $count == 1 ]; then
echo "               Now TX channel = $TYPE_CH "
fi
read -p "               BT-4.0 Continuous RX
++++++++++++++++++++++++++++++++++++++++++++++++++
1) - Entering BT channel

2) - Start RX

3) - Stop RX

Q) - Exit
====> " TX
case "$TX" in
1)
	set_channel
	continue;;

2)
	busybox clear
	hcitool cmd 0x08 0x01D $V_CH
	continue;;

3)
	count=0
	busybox clear
#	hcitool cmd 0x08 0x01F
#PER=$(hcitool cmd 0x08 0x01F | busybox grep '01 1F 20' | busybox sed 's/^.*//g')
#PER=$(echo "$PER" | busybox awk -F' ' '{ print $4 }')
	PER=$(hcitool cmd 0x08 0x01F | busybox grep '01 1F 20')
	PER1=$(echo "$PER" | busybox awk -F' ' '{ print $5 }')
	PER2=$(echo "$PER" | busybox awk -F' ' '{ print $6 }')
	PER=0x$(echo "$PER2$PER1")
	PER=$(printf "%2d\n" $PER)
	echo "Packet Error Rate = $PER"
	continue;;

q|Q)
	busybox clear
	break;;

*)
	error_type;;
esac
done
}

#-------------------------------------- Main --------------------------------------
while [ 1 ]; do

read -p " 
++++++++++++++++++++++++++++++++++++++++++++++++++
               MAIN NENU -> BT 4.0 NENU
++++++++++++++++++++++++++++++++++++++++++++++++++
1) - Enter BT Continuous TX mode

2) - Enter BT Continuous RX mode

3) - Trun OFF BT

Q) - Exit
====> " BT

case "$BT" in
1)
	bt_ctx
	;;

2)
	bt_crx
	;;

3)
	hciconfig hci0 down
	echo "Close BT done"
	sleep 1
	busybox clear	
	continue;;

q|Q)
	hciconfig hci0 down
	sleep 1
	busybox clear
	break;;

*)
	error_type;;
esac

done
