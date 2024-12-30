#!/bin/bash
chip_info=$1
port=$2
test_vector=$3
test_num=$4
test_flg=$5
test_count=$6
vector_count=$7
vector_name=$(basename -s .bin ${test_vector})
host_name=$(hostname)
file_start_time_stamp=$(date +"%Y-%m-%d %H:%M:%S.%N")
temp_pek=0
echo "==================================================================="
echo "$vector_name // data_loging start $file_start_time_stamp"
echo "$vector_name // chip_id = $1, port = $2,  tv = $3, test_num = $4"
echo "==================================================================="
FILE_PATH1="./result/${chip_info}_test_log.csv"
FILE_PATH2="/home/jenkins/www/test_log/v13/${test_num}_${host_name}_${chip_info}_test_log.csv"
FILE_PATH3="./rb/${chip_info}_is_test_status_m.rb"
FILE_PATH4="./rb/${chip_info}_is_test_status_s.rb"
FILE_PATH5="./rb/${chip_info}_peak_$vector_name.rb"


if [ $test_flg = "start" ]; then
	echo $(scp root@192.168.49.200:$FILE_PATH2 $FILE_PATH1)
	check_start_time_stamp=$(date +"%Y-%m-%d %H:%M:%S")
	echo "$vector_name // check scp $check_start_time_stamp"
	sleep 5
fi

if [ -e $FILE_PATH1 ]; then
	echo "$vector_name // File exists."
else
	touch $FILE_PATH1
	echo "time_stamp, no, test_num, host_name, chip_info, vector_name, host_driver, fw_release, smc_version,CA53_temp, DNC0_temp, DNC1_temp, DNC2_temp, DNC3_temp, DNC4_temp, DNC5_temp, DRAM_temp, PCIE_temp, SHM_temp, DNC_CORE_V, DNC_CORE_A, DNC_CORE_W, PCIEA_V, PCIEA_A, PCIEA_W, GDR_VDDQ_V, GDR_VDDQ_A, GDR_VDDQ_W, GDR_CORE_V, GDR_CORE_A, GDR_CORE_W, exe_time, RBLN_PWR," > $FILE_PATH1
	echo "$vector_name // File create."
fi
echo "start" > $FILE_PATH4
count=0
break_p="stop"

function exit_rm_file()
{

	if [ $test_flg = "end" ]; then
		exit_function_time_stamp=$(date +"%Y-%m-%d %H:%M:%S.%N")
		echo "$vector_name // exit rm function in $exit_function_time_stamp"
		echo $(scp $FILE_PATH1 root@192.168.49.200:$FILE_PATH2)
		exit_function_time_stamp=$(date +"%Y-%m-%d %H:%M:%S.%N")
		echo "$vector_name // scp uplaod ok $exit_function_time_stamp"
		sleep 2
		echo $(rm $FILE_PATH1)
       		exit_function_time_stamp=$(date +"%Y-%m-%d %H:%M:%S.%N")
		echo "$vector_name // local csv file delete $exit_function_time_stamp"
		sleep 2
	fi

	echo "idle" > $FILE_PATH3
	echo "idle" > $FILE_PATH4
	
}


trap exit_rm_file EXIT
check_start_time_stamp=$(date +"%Y-%m-%d %H:%M:%S.%N")
echo "$vector_name // while start $check_start_time_stamp "
while_count=0
while true :
do
	state=$(<$FILE_PATH3)
	bp_flg=0
	echo "$vector_name // read state = $state"
	
	if [ $state == $break_p ]; then
		echo "$vector_name // this is break point"
		break
	else
		bp_flg=0
		time_stamp=$(date +"%Y-%m-%d %H:%M:%S:%3N")
		time_start_stamp=$(date +"%S.%3N")
		
		#Read rbln ver
		rbln_ver=$(rbln ver -d ${port})

		host_driver=$(echo "${rbln_ver}" | awk '$1 == "[Host" {print $3}')
	        fw_release=$(echo "${rbln_ver}" | awk '$1 == "[FW" {print $3}')
		smc_version=$(echo "${rbln_ver}" | awk '$1 == "[SMC" {print $3}')

		#Read rbln chip_info
		chip_info=$(rbln chip_info -d ${port} | awk '$1 == "Chip" {print $3}')
		
		#Read rbln temp
		rbln_temp=$(rbln temp -d ${port})
		
		temp_pek_t=$(echo "${rbln_temp}" | awk '$1 == "PEAK"{print $3}')
		
		if [ "$temp_pek" -lt "$temp_pek_t" ]; then
			temp_pek="$temp_pek_t"
			echo "$temp_pek" > $FILE_PATH5
		fi

		CA53_temp=$(echo "${rbln_temp}" | awk '$1 == "CA53"{print $3}')
		DNC0_temp=$(echo "${rbln_temp}" | awk '$1 == "DNC0"{print $3}')
		DNC1_temp=$(echo "${rbln_temp}" | awk '$1 == "DNC1"{print $3}')
		DNC2_temp=$(echo "${rbln_temp}" | awk '$1 == "DNC2"{print $3}')
		DNC3_temp=$(echo "${rbln_temp}" | awk '$1 == "DNC3"{print $3}')
		DNC4_temp=$(echo "${rbln_temp}" | awk '$1 == "DNC4"{print $3}')
		DNC5_temp=$(echo "${rbln_temp}" | awk '$1 == "DNC5"{print $3}')
		DRAM_temp=$(echo "${rbln_temp}" | awk '$1 == "DRAM"{print $3}')
		PCIE_temp=$(echo "${rbln_temp}" | awk '$1 == "PCIE"{print $3}')
		SHM_temp=$(echo "${rbln_temp}" | awk '$1 == "SHM"{print $3}')

		#Read rbln pmic
		rbln_pmic=$(rbln pmic -d ${port})

		DNC_CORE_V=$(echo "${rbln_pmic}" | awk '$1 == "DNC" && $2 == "CORE"{print $4}')
		DNC_CORE_A=$(echo "${rbln_pmic}" | awk '$1 == "DNC" && $2 == "CORE"{print $7}')
		DNC_CORE_W=$(echo "${rbln_pmic}" | awk '$1 == "DNC" && $2 == "CORE"{print $10}')

		PCIEA_V=$(echo "${rbln_pmic}" | awk '$1 == "PCIEA"{print $3}')
		PCIEA_A=$(echo "${rbln_pmic}" | awk '$1 == "PCIEA"{print $6}')
		PCIEA_W=$(echo "${rbln_pmic}" | awk '$1 == "PCIEA"{print $9}')

		GDR_VDDQ_V=$(echo "${rbln_pmic}" | awk '$1 == "GDR" && $2 == "VDDQ"{print $4}')
		GDR_VDDQ_A=$(echo "${rbln_pmic}" | awk '$1 == "GDR" && $2 == "VDDQ"{print $7}')
		GDR_VDDQ_W=$(echo "${rbln_pmic}" | awk '$1 == "GDR" && $2 == "VDDQ"{print $10}')

		GDR_CORE_V=$(echo "${rbln_pmic}" | awk '$1 == "GDR" && $2 == "CORE"{print $4}')
		GDR_CORE_A=$(echo "${rbln_pmic}" | awk '$1 == "GDR" && $2 == "CORE"{print $7}')
		GDR_CORE_W=$(echo "${rbln_pmic}" | awk '$1 == "GDR" && $2 == "CORE"{print $10}')

		RBLN_PWR=$(rbln pwr -d ${port} | awk '$1 == "Power"{print $7}')
		

		#Write rbln infomation
		time_end_stamp=$(date +"%S.%3N")
		
		if (( $(echo "$time_end_stamp > $time_start_stamp" | bc -l) )); then
			check_start_time_stamp=$(echo "$time_end_stamp - $time_start_stamp" | bc -l)
		else
			check_start_time_stamp=$(echo "($time_end_stamp+60) - $time_start_stamp" | bc -l)
		fi

		



		echo "$time_stamp, $test_count '/' $vector_count  $test_num, $host_name, $chip_info, $vector_name, $host_driver, $fw_release $smc_version, $CA53_temp, $DNC0_temp, $DNC1_temp, $DNC2_temp, $DNC3_temp, $DNC4_temp, $DNC5_temp, $DRAM_temp, $PCIE_temp, $SHM_temp, $DNC_CORE_V, $DNC_CORE_A, $DNC_CORE_W, $PCIEA_V, $PCIEA_A, $PCIEA_W, $GDR_VDDQ_V, $GDR_VDDQ_A, $GDR_VDDQ_W, $GDR_CORE_V, $GDR_CORE_A, $GDR_CORE_W, $check_start_time_stamp, $RBLN_PWR" >> $FILE_PATH1

		#sleep_time=$(echo "0.5 - $check_start_time_stamp" | bc -l)
		bp_flg=1
		sleep 0.3
		while_count=$(( ${while_count}+1 ))
		echo "$vector_name, //  count is =$while_count, start time is =$time_start_stamp, end time is =$time_end_stamp , def time is =$check_start_time_stamp, time sleep is $sleep_time"

	fi
	sleep 0.5

done
