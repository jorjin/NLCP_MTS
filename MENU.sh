#!/system/bin/teTool/sh
# Program:
# 		creates by Vane .
# History:
# 		2012/08/23	Vane	Jorjin release

######################################
#               MAIN NENU            #
######################################

if [ ! -e setenv ]; then
	echo "NO setenv file !!"
	exit
else
	source setenv
fi


CURRENT_PATH=$(pwd)
WIFI_SH=$CURRENT_PATH/wifi.sh
BT_SH=$CURRENT_PATH/bt.sh
BT4_SH=$CURRENT_PATH/bt_4_trx.sh
THROUGHPUT_SH=$CURRENT_PATH/throughput.sh

chmod 777 ./*
busybox clear
while [ 1 ]; do

echo -e " ${HRE}
		\r++++++++++++++++++++++++++++++++++++++++++++++++++
		\r               MAIN NENU
		\r++++++++++++++++++++++++++++++++++++++++++++++++++\n${NO}"
#########################
	if [ ! -f ${WIFI_SH} ] ; then
	echo -e "${RE}No WIFI script! Can't test WIFI !!${NO}\n"
	else
	echo -e "${HGR}1) - WIFI Test${NO}\n"
	fi
#########################
	if [ ! -f ${BT_SH} ] ; then
	echo -e "${RE}No BT script! Can't test BT !!${NO}\n"
	else
	echo -e "${HGR}2) - BT Test${NO}\n"
	fi
#########################
	if [ ! -f ${BT4_SH} ] ; then
	echo -e "${RE}No BT 4.0 script! Can't test BT4.0 !!${NO}\n"
	else
	echo -e "${HGR}3) - BT 4.0 Test${NO}\n"
	fi
#########################
	if [ ! -f ${THROUGHPUT_SH} ] ; then
	echo -e "${RE}No throughput script! Can't test throughput !!${NO}\n"
	else
	echo -e "${HGR}4) - WIFI Throughput${NO}\n"
	fi
#########################
	echo -e "${HGR}Q) - Exit ${NO}\n"
	echo -ne "${RE}====> ${NO}"
	
read MAIN_OPT
	case "$MAIN_OPT" in
1)
	busybox clear
	./wifi.sh
;;
2)
	busybox clear
	./bt.sh
;;
3)
	busybox clear
	./bt_4_trx.sh
;;
4)
	busybox clear
	./throughput.sh
;;
q|Q)
        echo "Exit...."
        exit
;;
    esac
done
