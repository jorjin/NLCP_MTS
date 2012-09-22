#!/system/bin/teTool/sh
# Program:
# 		creates by Vane .
# History:
# 		2012/08/23	Vane	Jorjin release

source setenv

rmmod wl12xx_sdio.ko

echo -e "Please select your module:
		\r1)${GR} WG7310 / 7311 (WIFI 2.4G)${NO}
		\r2)${GR} WG7350 (WIFI 2.4G / 5G)${NO}
		\r3)${GR} WG7500 (WIFI 2.4G)${NO}
		\r4)${GR} WG7550 (WIFI 2.4G / 5G)${NO}"
read -p "===>" SELECT_MODULE

case ${SELECT_MODULE} in
1)
	TARGET_INI_FILE=${TARGET_INI_DIR}/TQS_S_2.6_WG7310_WG7311_NLCP.ini ;;
2)
	TARGET_INI_FILE=${TARGET_INI_DIR}/TQS_D_1.7_WG7350_NLCP.ini ;;
3)
	TARGET_INI_FILE=${TARGET_INI_DIR}/TQS_S_2.6_WG7500_NLCP.ini ;;
4)
	TARGET_INI_FILE=${TARGET_INI_DIR}/TQS_D_1.7_WG7550_NLCP.ini ;;
*)
	echo -e "No select any module !!!"
	exit;;
esac
echo -e "INI=${TARGET_INI_FILE}"

rm ${TARGET_NVS_FILE}

calibrator plt autocalibrate wlan0 /system/lib/modules/wl12xx_sdio.ko ${TARGET_INI_FILE} ${TARGET_NVS_FILE} 08:00:28:12:34:56
