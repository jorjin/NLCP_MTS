#!/system/bin/teTool/sh
# Program:
# 		creates by Vane .
# History:
# 		2012/08/23	Vane	Jorjin release

CHANNEL="NULL"
RANDOM_MAC=""
POWER="20000"
SHOW_PWR=""
CMD_RATE=""
RATE="not_set!!"
CMD_BAND=""
BAND="not_set!!"

source setenv

if [ ! -f ${TARGET_NVS_FILE} ]; then
	echo " Error  cannot access NVS file: No NVS file or directory !!!!!"
	exit 1
fi

#***********************************************************
#		Calibrate function
#***********************************************************
calibration(){
WIFION=`getprop init.svc.wpa_supplicant`
case "${WIFION}" in
"running") echo -e "********************************************************
					\r* Turn Wi-Fi OFF and launch the script for calibration *
					\r********************************************************"
	exit 1;;
*) echo -e "******************************
			\r* Starting Wi-Fi calibration *
			\r******************************";;
esac

	BTMAC=$(hciconfig hci0 | busybox grep 'BD Address'| busybox awk '{print $3}')
	for X in '1' '2' '3' '4' '5' '6'; do
		export M${X}=$( echo "${BTMAC}" | busybox awk -F : '{ print $'$X' }' )
	done
	WIFIMAC="${M1}:${M2}:${M3}:${M4}:${M5}:${M6}"



#========================INI============================================
	cd ${TARGET_NVS_DIR}
	SIZE=`ls -l ./wl1271-nvs.bin | busybox awk '{print $5}'`
	echo -e "NVS Size is ${SIZE}!!"
if [ "${SIZE}" != "912" -a "${SIZE}" != "1113" ]; then
	echo -e "${RE}NVS Size Wrong!! try again!!${NO}"
	SIZE=`ls -l ./wl1271-nvs.bin | busybox awk '{print $4}'`
	echo -e "NVS Size is ${SIZE}!!"
fi
case "${SIZE}" in
912) CHECK_NVS=$( calibrator get info_nvs ${TARGET_NVS_FILE} | busybox grep 'Single_Dual_Band_Solution' | busybox awk '{print $3}' )
	case "${CHECK_NVS}" in
		01) TARGET_INI_FILE=${TARGET_INI_DIR}/TQS_D_1.7_WG7350_NLCP.ini
			KFLAG=dual ;;
		00) TARGET_INI_FILE=${TARGET_INI_DIR}/TQS_S_2.6_WG7310_WG7311_NLCP.ini
			KFLAG=single ;;
		*) echo "NVS File Wrong!!"
			exit 1;;
	esac ;;
1113) CHECK_NVS=$( calibrator get info_nvs ${TARGET_NVS_FILE} | busybox grep 'Single_Dual_Band_Solution' | busybox awk '{print $3}' )
	case "${CHECK_NVS}" in
		01) TARGET_INI_FILE=${TARGET_INI_DIR}/TQS_D_1.7_WG7550_NLCP.ini
			KFLAG=dual ;;
		00) TARGET_INI_FILE=${TARGET_INI_DIR}/TQS_S_2.6_WG7500_NLCP.ini
			KFLAG=single ;;
		*) echo "NVS File Wrong!!"
			exit 1;;
	esac ;;
*) echo "NVS Size Wrong!!"
	exit 1 ;;
esac
	echo -e "INI=${HGR}${TARGET_INI_FILE}${NO}"
#=========================NVS===========================================
	insmod /system/lib/modules/wl12xx_sdio.ko
	ifconfig wlan0 down
	calibrator wlan0 plt power_mode on
	calibrator set ref_nvs ${TARGET_INI_FILE} ${TARGET_NVS_FILE}
#=========================BIP===========================================
	echo -e "NVS Size is ${SIZE}!!"
	if [ "${KFLAG}" == "dual" ]; then
		echo -e " ~~~ Calibration ${HGR}Dual${NO} band ~~~ "
		calibrator wlan0 plt tx_bip 1 1 1 1 1 1 1 1 ${TARGET_NVS_FILE}
	else
		echo -e "~~~ Calibration ${HGR}Single${NO} band ~~~ "
		calibrator wlan0 plt tx_bip 1 0 0 0 0 0 0 0 ${TARGET_NVS_FILE}
	fi
	echo -e "~~~ Calibration Done ~~~ "
	sleep 1
#==========================OK==========================================
	calibrator wlan0 plt power_mode off
	calibrator set nvs_mac ${TARGET_NVS_FILE} ${WIFIMAC}
	NOWMAC=$(calibrator get nvs_mac ${TARGET_NVS_FILE})
	NOWMAC=$(echo ${NOWMAC} | busybox awk '{print substr($0,20)}')
	echo -e "--------> Write BT MAC To WIFI= ${HGR}${NOWMAC}${NO} "
	sleep 1
	echo "--------> Reset WIFI "
	rmmod wl12xx_sdio
	insmod /system/lib/modules/wl12xx_sdio.ko
}

#***********************************************************
#		Error type
#***********************************************************
error_type(){
	echo -e"\n\rError type, Please try again!!!!!"
sleep 1
busybox clear
}
#***********************************************************
#		WIFI Load
#***********************************************************
wifi_load() {
echo -e "
		\r------------------------
		\r-  WIFI enter PLT Mode -
		\r------------------------"
	insmod /system/lib/modules/wl12xx_sdio.ko
	ifconfig wlan0 down
	VERSION=$(calibrator wlan0 plt power_mode on | dmesg -c | busybox grep 'firmware booted in PLT mode')
	VERSION=$(echo $VERSION | busybox sed 's/^.*mode//g')
	busybox clear
}

#***********************************************************
#		WIFI Unload
#***********************************************************
wifi_unload() {
echo -e "
		\r------------------------
		\r-  WIFI Driver Unload  -
		\r------------------------"
	rmmod wl12xx_sdio
	busybox clear
}

#***********************************************************
#		WIFI set channel
#***********************************************************
setchannel(){
while [ 1 ];  do

echo -e "
		\r+++++++++++++++++++++++++++++++++++++++++++++++++++++
		\r		Set Channel :
		\r		2.4G=1~14
		\r		5.0G=36~165
		\r+++++++++++++++++++++++++++++++++++++++++++++++++++++\n
		\rPlease pass channel or pass Q to leave...\n"
read -p "====>" CH
if [ "$CH" -lt "166" ]; then
	if [ "$CH" -gt "35" -o "$CH" -lt "15"  ]; then
		CHANNEL=${CH}
		CMD_BAND=1
			if [ "$CH" -lt "15" -a "$CH" -gt "0" ]; then
				CHANNEL=${CH}
				CMD_BAND=0
				echo "2.4G"

			else
				echo "5G"

			fi
	fi
fi
calibrator wlan0 plt tune_channel ${CMD_BAND} ${CHANNEL}
busybox clear
break
       done
}

#***********************************************************
#		MAC Address
#***********************************************************
change_mac(){
while [ 1 ]; do
	cd ${TARGET_NVS_DIR}
	OLDMAC=$(calibrator get nvs_mac $TARGET_NVS_FILE)
	OLDMAC=$(echo $OLDMAC | busybox awk '{print substr($0,20)}')
echo -e " 
		\r++++++++++++++++++++++++++++++++++++++++++++++++++
		\r               WIFI MENU [Mac Address]
		\r++++++++++++++++++++++++++++++++++++++++++++++++++
		\rOld MAC address : ${YE}${OLDMAC}${NO}
		\rPlease type new MAC address
		\rOr pass 'q' leave...
		\r(Ex: 12:34:56:78:90:AB !! ) "
read -p "====>" MAC

MAC_LEN=${#MAC}

if [ ${MAC} == "q" ]; then
	break
fi
if [ ! ${MAC_LEN} -eq '17' ] ; then
	echo "MAC length=${MAC_LEN}"
	echo "MAC won't be change!!"
	continue
fi

TR_MAC=$(echo $MAC | busybox tr  "[:lower:]" "[:upper:]")
	for X in '1' '2' '3' '4' '5' '6'; do
		export M${X}=$( echo "${TR_MAC}" | busybox awk -F : '{ print $'$X' }' )
	done

NEW_MAC="${M1}:${M2}:${M3}:${M4}:${M5}:${M6}"

	calibrator set nvs_mac ${TARGET_NVS_FILE} ${NEW_MAC}
	sleep 1
	rmmod wl12xx_sdio
	echo "unload wifi ... "
	insmod /system/lib/modules/wl12xx_sdio.ko
	echo "load wifi ... "
	break
done
}

#***********************************************************
#		WIFI set power
#***********************************************************
power_fun(){
echo -e "Please refer example type (Ex:10000)
		\rPlease type Power :"
read -p "===>" PW
if [ "$PW" -gt 20000 -o "${PW}" -lt 1000 ]; then
echo -e "You type wrong Power!! 
		\rPower set to default!!"
POWER=20000
else
POWER=${PW}
fi
}

#***********************************************************
#		WIFI set band
#***********************************************************
bandrate_fun(){
while [ 1 ]; do
echo -n "++++++++++++++++++++++++++++++++++++++++++++++++++
		WIFI set band
++++++++++++++++++++++++++++++++++++++++++++++++++
1) - 11B

2) - 11G

3) - 11N

Q) - Quit

Please select Band :
===>"
read BAND_SELECT
busybox clear
case "$BAND_SELECT" in
1)
	CMD_BAND=0
	BAND=802.11B
	read -p "++++++++++++++++++++++++++++++++++++++++++++++++++
		802.11B
++++++++++++++++++++++++++++++++++++++++++++++++++
1) - 1M
 
2) - 2M

3) - 5.5M

4) - 11M

Q) - Back to Previous

Please select rate
===>" RT
		case $RT in
			1)
			RATE=1M
			CMD_RATE=0x00000001
			;;
			2)
			RATE=2M
			CMD_RATE=0x00000002
			;;
			3)
			RATE=5.5M
			CMD_RATE=0x00000004
			;;
			4)
			RATE=11M
			CMD_RATE=0x00000020
			;;
			q|Q)
			busybox clear
			CMD_RATE=""
			RATE="not_set!!"
			CMD_BAND=""
			BAND="not_set!!"
			;;
			*)
			error_type
			busybox clear
			continue
		esac
		break
		;;

2)
	CMD_BAND=4
	BAND=802.11G
	read -p "++++++++++++++++++++++++++++++++++++++++++++++++++
		802.11G
++++++++++++++++++++++++++++++++++++++++++++++++++
1) - 6M

2) - 9M

3) - 12M

4) - 18M

5) - 24M

6) - 36M

7) - 48M

8) - 54M

Q) - Back to Previous

Please select rate
===>" RT
		case $RT in
			1)
			RATE=6M
			CMD_RATE=0x00000008
			;;
			2)
			RATE=9M
			CMD_RATE=0x00000010
			;;
			3)
			RATE=12M
			CMD_RATE=0x00000040
			;;
			4)
			RATE=18M
			CMD_RATE=0x00000080
			;;
			5)
			RATE=24M
			CMD_RATE=0x00000200
			;;
			6)
			RATE=36M
			CMD_RATE=0x00000400	
			;;
			7)
			RATE=48M
			CMD_RATE=0x00000800
			;;
			8)
			RATE=54M
			CMD_RATE=0x00001000
			;;
			q|Q)
			busybox clear
			CMD_RATE=""
			RATE="not_set!!"
			CMD_BAND=""
			BAND="not_set!!"
			;;
			*)
			error_type
			busybox clear
			continue
		esac
		break
		;;


3)
	CMD_BAND=6
	BAND=802.11N
	read -p "++++++++++++++++++++++++++++++++++++++++++++++++++
		802.11N
++++++++++++++++++++++++++++++++++++++++++++++++++
1) - MCS0

2) - MCS1

3) - MCS2

4) - MCS3

5) - MCS4

6) - MCS5

7) - MCS6

8) - MCS7

Q)Back to Previous

Please select rate
===>" RT
		case $RT in
			1)
			RATE=MCS0
			CMD_RATE=0x00002000
			;;
			2)
			RATE=MCS1
			CMD_RATE=0x00004000
			;;
			3)
			RATE=MCS2
			CMD_RATE=0x00008000
			;;
			4)
			RATE=MCS3
			CMD_RATE=0x00010000
			;;
			5)
			RATE=MCS4
			CMD_RATE=0x00020000
			;;
			6)
			RATE=MCS5
			CMD_RATE=0x00040000
			;;
			7)
			RATE=MCS6
			CMD_RATE=0x00080000
			;;
			8)
			RATE=MCS7
			CMD_RATE=0x00100000
			;;
			q|Q)
			CMD_RATE=""
			RATE="not_set!!"
			CMD_BAND=""
			BAND="not_set!!"
			busybox clear
			;;
			*)
			error_type
			busybox clear
			continue
		esac
	break
		;;
q|Q)
	CMD_RATE=""
	RATE="not_set!!"
	CMD_BAND=""
	BAND="not_set!!"
	busybox clear
	break
;;
*)
	error_type
	busybox clear
;;
esac
done
}

#***********************************************************
#		Rate
#***********************************************************
rate(){
while [ 1 ]; do

SHOW_PWR=$(echo ${POWER} 1000 | busybox awk '{printf("%.1f", ($1/$2))}')

echo -e "++++++++++++++++++++++++++++++++++++++++++++++++++
		\r		TX POWER MENU
		\rCHANNEL:${CHANNEL}
		\rBand:	${BAND}
		\rRate:	${RATE}
		\rPower:	${SHOW_PWR} dBm
		\r++++++++++++++++++++++++++++++++++++++++++++++++++
		\r1) - Set Power\n
		\r2) - Select Band & Rate\n
		\r3) - Start Test\n
		\r4) - Change Channel\n
		\rQ) - Quit to WIFI MENU\n"
read -p "====>" TX_OPT

	case "$TX_OPT" in
	1)
		busybox clear
		power_fun
		continue
		;;

	2)
		busybox clear
		bandrate_fun
		continue
		;;

	3)
		busybox clear
		sleep 1
		calibrator wlan0 plt tx_stop

		if [ ${RATE} == "not_set!!" ]; then
			break
			echo "Type ERROR!! Please try again!! "
		else
			echo "Runing Tx Power "
			calibrator wlan0 plt tx_cont 20 ${CMD_RATE} 1000 0 ${POWER} 10000 3 1 0 ${CMD_BAND} 0 1 1 1 DE:AD:BE:EF:00:00
				while [ 1 ]; do
				read -p "Pass t to Stop TX..." PAUSE
						if [ ${PAUSE} == "t" ]; then
						calibrator wlan0 plt tx_stop
							echo "Stop Runing Tx Power "
							break
						else
							echo "Type ERROR!! Please try again!! "
						fi		
				done
		fi
			continue
		;;
	4)
		setchannel
		continue
		;;
	q|Q)
		calibrator wlan0 plt tx_stop
		echo " Stop Runing Tx Power "
		busybox clear
		break
			;;
	esac
done

}

#-------------------------------------- Main --------------------------------------
while [ 1 ]; do
echo -e "
		\r++++++++++++++++++++++++++++++++++++++++++++++++++
               MAIN NENU -> WIFI NENU
		\r++++++++++++++++++++++++++++++++++++++++++++++++++
		\r1) - Test TX Power\n
		\r2) - Test RX Sensitivity\n
		\r3) - Test Single Tone (CW)\n
		\r4) - Calibration\n
		\r5) - Change MAC address"
echo -e "\nQ) - Exit With Wifi Shut Down\n"
echo -n "====> "
	read WIFI_OPT

	case "$WIFI_OPT" in
########### Test TX Power ###########
	1)
	wifi_load
	while [ 1 ];	do
		echo -e "\n\r++++++++++++++++++++++++++++++++++++++++++++++++++
				\r               WIFI NENU [Test TX] \n\t\t$VERSION
				\r++++++++++++++++++++++++++++++++++++++++++++++++++\n
				\r1) - Set Channel  (Now CHANNEL: CH ${RE}${CHANNEL}${NO})\n
				\r2) - Set Rate and Start Test\n
				\rQ) - Exit"
		echo -ne "\n====> "
	read TX_OPT
			case "$TX_OPT" in
				1)
					setchannel
					continue;;
				2)
					busybox clear
					rate
					continue;;
				q|Q)
					calibrator wlan0 plt power_mode off
					wifi_unload
					break;;
				*)
					error_type
					;;
			esac
	done  
	;;

########### Test RX Sensitivity ###########
	2)
		wifi_load
	while [ 1 ]; do    
		echo -e " 
		\r++++++++++++++++++++++++++++++++++++++++++++++++++
		\r               WIFI MENU [Test RX]] \n\t\t$VERSION
		\r++++++++++++++++++++++++++++++++++++++++++++++++++
		\r1) - Set Channel  (Now CHANNEL: CH ${RE}${CHANNEL}${NO})\n
		\r2) - Start RX\n
		\rQ) - Exit"

		echo -n "====> "
		read RX_OPT
			case "$RX_OPT" in
				1)
					setchannel
					busybox clear
					;;
				2)
					calibrator wlan0 plt tune_channel ${CMD_BAND} ${CHANNEL}
					calibrator wlan0 plt stop_rx_statcs
					sleep 1
					calibrator wlan0 plt reset_rx_statcs
					calibrator wlan0 plt start_rx_statcs
					sleep 1
					NOWMAC=$(calibrator get nvs_mac ${TARGET_NVS_FILE})
					NOWMAC=$(echo $NOWMAC | busybox awk '{print substr($0,20)}')
					busybox clear
					while [ 1 ];	do
					 echo -e "\n\rChannel is ${RE}${CHANNEL}${NO}
								\rYour MAC is :${NOWMAC}
								\rStart testing RX...
								\rPass [t] to Stop RX..."
					echo -n "===>" 
					read PAUSE

					if [ ${PAUSE} != "t"  ]; then
						echo "Type ERROR!! Please try again!! "
					else
						echo "Stop Run Rx"
						calibrator wlan0 plt stop_rx_statcs
						sleep 1
						echo "--------- Get RX statistics ---------"
						calibrator wlan0 plt get_rx_statcs
						unset PAUSE
						break
					fi		
					done
					continue;;
				3)
					calibrator wlan0 plt stop_rx_statcs
					sleep 1
					echo "--------- Get RX statistics ---------"
					calibrator wlan0 plt get_rx_statcs
					continue;;
				q|Q)
					calibrator wlan0 plt power_mode off
					sleep 1
					wifi_unload
					break;;
				*)
					error_type;;
			esac
	done
	;;
########### WIFI NENU - 3 ###########
	3)
		wifi_load
	while [ 1 ]; do    
		echo -e " 
			\r++++++++++++++++++++++++++++++++++++++++++++++++++
			\r               WIFI MENU [Test CW] \n\t\t$VERSION
			\r++++++++++++++++++++++++++++++++++++++++++++++++++
			\r1) - Set Channel  (Now CHANNEL: CH \033[31;1m$CHANNEL\033[0m)\n
			\r2) - Start CW\n
			\rQ) - Exit"

		echo -n "====> "
		read CW_OPT
	case "$CW_OPT" in
		1)
			calibrator wlan0 plt tx_stop
			setchannel
			continue;;
		2)
			calibrator wlan0 plt tx_tone 1 9000
			while [ 1 ]; do
				read -p "Pass T to Stop CW..." PAUSE
						if [ ${PAUSE} == "T"  ]; then
						calibrator wlan0 plt tx_stop
							echo "Stopping CW "
							sleep 1
							busybox clear
							break
						else
							echo "Type ERROR!! Please try again!! "
						fi		
				done
			continue;;
		q|Q)
			calibrator wlan0 plt power_mode off
			sleep 1
			wifi_unload
			busybox clear
			break;;
		*)
			error_type;;
	esac
	done
	;;
########### Calibration ###########
	4) 
		calibration
		echo -e "\rcalibration success !! 
				 \rFile path=$TARGET_NVS_FILE"
		continue;;

########### Change MAC address ###########
	5)
		if [ ! -f ${MAC_SH} ] ; then
			echo " [ERROR] Can't change MAC !! "
		else
			busybox clear
			change_mac
		fi
		continue;;

########### Quit ###########
	q|Q)
		echo "Back to menu ..."
		busybox clear
		exit 1
		;;
	esac
done
