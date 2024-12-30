#!/bin/bash

# Global Environment Variables Start
export RBLNTHUNK_PERF=1
current_kernel_version=$(uname -r | awk -F '.' '{print $1 "." $2}')
minimum_kernel_version=5.10
RBLN_LSPCI_NUM=$(lspci | grep accelerators | wc -l)
RBLN_STAT_NUM=$(rbln-stat -L | wc -l)
DRIVER_VER=$(rbln-stat | grep "Device Information" | awk '{print $6}')
LNKSTA=($(lspci -D | grep -i accelerators | awk '{print $1}'))
LNKSTA_NUM=${#LNKSTA[@]}
HOST=$(hostname)
CPU_MODEL=$(lscpu | grep "Model name"  | awk -F':' '{{print $2}}'| sed 's/[[:blank:]]//g')
KERNEL=$(cat /proc/cmdline)
DATE=$(date)
FILE_DATE=$(date '+%Y-%m-%d_%H-%M')
UUID_INFO=$(rbln-stat -L)
TEST_VECTOR=($(ls -l ./vector/ | awk '{print $9}'))
IP_INFO=$(cat /etc/netplan/*.yaml)


# Kernel Version Check
if (( $(echo "$current_kernel_version < $minimum_kernel_version" | bc -l) )); then
    cat << EOF
Error: Linux kernel version is 5.10.77 or below

++ System Requirement
OS : ubuntu 20.04 or ubuntu 22.04
Kernel : 5.10.77 version or later required
 - You can check the kernel version : uname -r
 - Kernel update steps
   1. sudo apt-cache search linux-image-5.
   2. sudo apt install linux-{image,headers}-5.xx-generic
   3. reboot
OS Packages : dkms
 - sudo apt update && sudo apt install -y dkms

EOF
    exit 1
fi


# RBLN Driver Check
if ! command -v rbln-stat &>/dev/null; then
    echo "RBLN Driver not installed. Please install manually."
    exit 1
else
    if [[ $RBLN_LSPCI_NUM -eq 0 || $RBLN_LSPCI_NUM -ne $RBLN_STAT_NUM ]]; then
        echo "\n#### All RBLN driver of device has not been loaded."
        echo "#### Please, Check your PCIe slots and reinstall the RBLN Device"
        echo "\nHW installed rbln : ${RBLN_LSPCI_NUM} EA"
        rbln-stat
        exit 1
    else
        echo "\n#### All rbln drivers are already installed. ####"
    fi
fi


print_menu() {
    cat << EOF

+-------------------------------------------------------------------------------------------------+
|                                                                                                 |
|  Welcome to the RBLN Testing                                                                    |
|  Please, input the test number                                                                  |
|                                                                                                 |
+-------------------------------------------------------------------------------------------------+

It has $RBLN_LSPCI_NUM rblns installed.

1. RBLN driver install
2. RBLN RSD test
3. Single Workload test 
4. EXIT

EOF
}


select_2_result() {
    declare -A FILE_HASHES=(
        ["solar_32k_batch_4.bin"]="614d89b783ae0eb4c7e735e07cbaa71e"
        ["llama2_7b_batch_4.bin"]="2829f6627263b4880502f6c1f376b28a"
        ["solar_4k_batch_8.bin"]="4fc22e6d4786f860d223106f8cef7df1"
        ["llama3_8b_batch_4.bin"]="873b43680570a0043c1f169f2169aad2"
        ["llama2_13b_batch_4.bin"]="4f844538f7446fb6574a313db41b97d7"
    )

    TARGET_DIR="./rsd"

    echo -e "\033[33m=== Verifying file integrity in $TARGET_DIR... ===\033[0m"

    for FILE in "${!FILE_HASHES[@]}"; do
        FILE_PATH="$TARGET_DIR/$FILE"

        if [ ! -f "$FILE_PATH" ]; then
	    echo -e "\033[31mError: File missing - $FILE\033[0m"
            continue
        fi

        FILE_MD5=$(md5sum "$FILE_PATH" | awk '{ print $1 }')

        if [ "$FILE_MD5" != "${FILE_HASHES[$FILE]}" ]; then
            echo -e "\033[31mHash mismatch: $FILE\033[0m"
            echo -e "Expected: ${FILE_HASHES[$FILE]}"
            echo -e "Got: $FILE_MD5"
            echo "Please replace the corrupted file."
            exit 1
        else
            echo -e "\033[32mFile verified: $FILE (hash matched)\033[0m"
        fi
    done

    echo -e "\033[32m=== File integrity verification completed successfully. ===\033[0m"


    echo "rsd test start"
    test_date=$(date +"%y%m%d")
    server_name=$(dmidecode -s system-product-name | head -n 1 | sed 's/ //g')
    host_name=$(hostname)
    test_num="${server_name}_${host_name}_${test_date}"
    run_command="./tests/mda_test.sh ${test_num} ${test_date} evt1"
    ${run_command}
}


select_3_result() {
    declare -A FILE_HASHES=(
        ["mlperf_bert_large.bin"]="7ea8e8ad92ddfb5bde748661e9304fb7"
        ["mlperf_resnet_ms.bin"]="349052f869bc5404f92551e394db90f2"
        ["mlperf_resnet_ss.bin"]="6f3105033697613a258270b4f5bb1fd7"
        ["mlperf_retinanet.bin"]="f319e2b92e592725c5835b6564112d16"
        ["pytorch_bert_large.bin"]="da8c442f24d3b483578f2eb0f3e8d4fa"
        ["pytorch_deit_base_distilled_224.bin"]="70e7a4e0a4c623e92504a668f74de991"
        ["pytorch_efficientnet_b7.bin"]="06c0b5f1350ece81ce02e24c9348bada"
        ["pytorch_fcn_resnet101.bin"]="61b32ef4d60fdb898767a510ce59531e"
        ["pytorch_t5_large.bin"]="2cebd1bf13f38e5d962bfc98203d120f"
        ["pytorch_yolox_l.bin"]="6efa36f07612ce0fd66277b0951bf0bf"
        ["stable_diffusion_text2img_unet.bin"]="03d06c6bdc55162809e5404210880594"
        ["stable_diffusion_text2img_vae_decoder.bin"]="539d435d83412e0e0185e6ab06a27072"
        ["tensorflow_unet.bin"]="c887bb48a843c948f499f5c4ed5f8869"
        ["tf_keras_efficientnetv2l.bin"]="950e5977820b948c2c82b5bfed1527a4"
        ["tf_keras_xception.bin"]="07a44dab1da5dd1a3e67171c972dae24"
    )

    TARGET_DIR="./vector"

    echo -e "\033[33m"Verifying file integrity in $TARGET_DIR..."\033[0m"
    for FILE in "${!FILE_HASHES[@]}"; do
        FILE_PATH="$TARGET_DIR/$FILE"

        if [ ! -f "$FILE_PATH" ]; then
            echo -e"\033[31mFile missing: $FILE\033[0m"
            continue
        fi

        FILE_MD5=$(md5sum "$FILE_PATH" | awk '{ print $1 }')

        if [ "$FILE_MD5" != "${FILE_HASHES[$FILE]}" ]; then
            echo "Hash mismatch: $FILE (expected: ${FILE_HASHES[$FILE]}, got: $FILE_MD5)"
            echo "Please replace the corrupted file."
            exit 1
        else
            echo "File verified: $FILE"
        fi
    done


    mkdir -p ./result/${FILE_DATE}

    # 보고서 헤더
    echo "" 						                                                							        | tee -a ./result/${FILE_DATE}/swt_result.txt
    echo "+-------------------------------------------------------------------------------------------------+"          | tee -a ./result/${FILE_DATE}/swt_result.txt
    echo "|                               No. 3 Single Workload Test Report                                 |"          | tee -a ./result/${FILE_DATE}/swt_result.txt
    echo "+-------------------------------------------------------------------------------------------------+"          | tee -a ./result/${FILE_DATE}/swt_result.txt
    echo "" 												                                                	        | tee -a ./result/${FILE_DATE}/swt_result.txt

    # 기본 시스템 정보
    echo "SYSTEM INFO REPORT" 						                                        					        | tee -a ./result/${FILE_DATE}/swt_result.txt
    echo "" 													                                                        | tee -a ./result/${FILE_DATE}/swt_result.txt
    echo "DATE      : $DATE" 											                                                | tee -a ./result/${FILE_DATE}/swt_result.txt
    echo "HOST      : $HOST" 										                                        	        | tee -a ./result/${FILE_DATE}/swt_result.txt
    echo "KERNEL    : $KERNEL"									                                                | tee -a ./result/${FILE_DATE}/swt_result.txt
    echo "DRIVER    : $DRIVER_VER" 										                                                | tee -a ./result/${FILE_DATE}/swt_result.txt
    echo "RBLNs     : $RBLN_LSPCI_NUM EA" 									                                    	        | tee -a ./result/${FILE_DATE}/swt_result.txt
    echo "CPU MODEL : $CPU_MODEL" 										                                                | tee -a ./result/${FILE_DATE}/swt_result.txt
    echo "SYSTEM    :" 											                                            	        | tee -a ./result/${FILE_DATE}/swt_result.txt
    dmidecode -t 1 | grep -A 20 "System Information" 								                                    | tee -a ./result/${FILE_DATE}/swt_result.txt
    echo "" 													                                                        | tee -a ./result/${FILE_DATE}/swt_result.txt

    # PCIe 링크 테스트 섹션
    echo "1. PCIe Link Test"                                         											        | tee -a ./result/${FILE_DATE}/swt_result.txt
    for ((num=0; num<${LNKSTA_NUM}; num++)); do
    	LNKSTAT=$(lspci -vv -s ${LNKSTA[$num]} | grep -i lnksta:)
        LNKSTAT_Speed=$(lspci -vv -s ${LNKSTA[$num]} | grep -i lnkcap: | awk '{print $5}')
        LNKSTAT_Width=$(lspci -vv -s ${LNKSTA[$num]} | grep -i lnksta: | awk '{print $6}')
        LNK_ADDRESS=$(dmidecode | grep -B 10 -i ${LNKSTA[$num]} | grep ID)
        
        if  [[ "$LNKSTAT_Speed" != "32GT/s," ]] || [[ "$LNKSTAT_Width" != "x16" ]]; then
             echo "RBLN${num} $LNK_ADDRESS(${LNKSTA[$num]}) Error"                                                      | tee -a ./result/${FILE_DATE}/swt_result.txt
             if [[ $num -eq $(($LNKSTA_NUM-1)) ]]; then
                 exit 1
             fi
        else
             echo " - RBLN${num} $LNK_ADDRESS(${LNKSTA[$num]}) LNKSTAT_Speed CAP = $LNKSTAT_Speed Pass"                 | tee -a ./result/${FILE_DATE}/swt_result.txt
        fi
    done

    # UUID 정보
    echo ""                                                                   		                                    | tee -a ./result/${FILE_DATE}/swt_result.txt
    echo ""                                                                               	                            | tee -a ./result/${FILE_DATE}/swt_result.txt
    echo "2. UUID Information"                                                                                          | tee -a ./result/${FILE_DATE}/swt_result.txt
    UUID_INFO=$(echo "$UUID_INFO" | sed 's/NPU / - RBLN/g')
    echo "$UUID_INFO"                                                                                                   | tee -a ./result/${FILE_DATE}/swt_result.txt
    
    # RBLN Power 정보
    echo ""                                                                                                             | tee -a ./result/${FILE_DATE}/swt_result.txt
    echo ""                                                                                                             | tee -a ./result/${FILE_DATE}/swt_result.txt
    echo "3. RBLNs Power Information"                                                                                   | tee -a ./result/${FILE_DATE}/swt_result.txt
	for ((i=0; i<${LNKSTA_NUM}; i++)); do
		PWR_INFO=$(rbln pwr -d "$i" | grep "Power data") 
		echo "RBLN $i: $PWR_INFO"						                      									        | tee -a ./result/${FILE_DATE}/swt_result.txt
	done
    
    echo ""                                                                                                             | tee -a ./result/${FILE_DATE}/swt_result.txt
    echo ""                                                                                                             | tee -a ./result/${FILE_DATE}/swt_result.txt
	echo "4. Network Information"							    			        							        | tee -a ./result/${FILE_DATE}/swt_result.txt
	echo "IP_INFO  : $IP_INFO"									    				            				        | tee -a ./result/${FILE_DATE}/swt_result.txt

	echo ""                                                                                                             | tee -a ./result/${FILE_DATE}/swt_result.txt
	echo ""                                                                                                             | tee -a ./result/${FILE_DATE}/swt_result.txt
    echo "5. RBLN Stress Test(default is 60 seconds per each vector)"                                                   | tee -a ./result/${FILE_DATE}/swt_result.txt
    while true; do
        read -p "Do you want to see the information about the RBLN being tested displayed on the screen? [Y or N]: " DISPLAY_TEST
        if [[ "$DISPLAY_TEST" =~ ^[YyNn]$ ]]; then
            break
        else
            echo "Please enter Y or N."
        fi
    done
    DISPLAY_TEST=$(echo "$DISPLAY_TEST" | tr '[:upper:]' '[:lower:]')

    read -p "Please enter seconds to repeat [Default is 60]: " auto_test_inferences
    if [[ -z "$auto_test_inferences" || "$auto_test_inferences" =~ [[:alpha:]] ]]; then
        auto_test_inferences=60
    fi
    echo "The test will be conducted for $auto_test_inferences seconds"                                                 | tee -a ./result/${FILE_DATE}/swt_result.txt
    sleep 2;

    TEST_NUM_DEVICE=$RBLN_LSPCI_NUM
    for ((i=0; i<${#TEST_VECTOR[@]}; i++)); do
        echo ""                                                                                                         | tee -a ./result/${FILE_DATE}/swt_result.txt
        echo "++ Test Items : ${TEST_VECTOR[i]}"                                                                        | tee -a ./result/${FILE_DATE}/swt_result.txt

        for ((j=0; j<$TEST_NUM_DEVICE; j++)); do
            RBLNTHUNK_FORCE_PRIORITY=4 rblnreplayer ./vector/${TEST_VECTOR[i]} -e $auto_test_inferences -d $j | grep -E "Report|ERR"  | sed "s/^/rbln$j /" | tee -a ./result/${FILE_DATE}/swt_result.txt >> ./test_result_.txt & bg_pid=$!;
            echo "++ The test lasts $auto_test_inferences seconds and the raw data is ./result/${FILE_DATE}/${TEST_VECTOR[i]}_rbln${j}.txt"
            echo -e "RBLN\t|\tPCI_BUS_ID\t|\tTEMP\t|\t MEMORY            \t|\tUTIL\t|\tPWR" >> ./result/${FILE_DATE}/${TEST_VECTOR[i]}_rbln${j}.txt
        done
                        
        if [ "$DISPLAY_TEST" = "y" ]; then
            echo -e "RBLN\t|\tPCI_BUS_ID\t|\tTEMP\t|\t MEMORY            \t|\tUTIL\t|\tPWR"
        fi
                        
        while true; do
            bg_pid_status=$(ps -aux | grep $bg_pid | wc -l)
            sleep 1;
            if [ $bg_pid_status -gt 1 ]; then
                for ((j=0; j<$TEST_NUM_DEVICE; j++)); do
                    rbln_pci=$(rbln-stat -d $j | grep "rbln$j" | awk -F'|' '{{print $5}}' | sed 's/[[:blank:]]//g')
                    rbln_temp=$(rbln-stat -d $j | grep "rbln$j" | awk -F'|' '{{print $6}}' | sed 's/[[:blank:]]//g')
                    rbln_mem=$(rbln-stat -d $j | grep "rbln$j" | awk -F'|' '{{print $8}}' | sed 's/[[:blank:]]//g')
                    rbln_util=$(rbln-stat -d $j | grep "rbln$j" | awk -F'|' '{{print $9}}' | sed 's/[[:blank:]]//g')
                    rbln_pwr=$(rbln-stat -d $j | grep "rbln$j" | awk -F'|' '{{print $7}}' | sed 's/[[:blank:]]//g')
                    if [ "$DISPLAY_TEST" = "y" ]; then
                        echo -e "rbln$j\t|\t$rbln_pci\t|\t$rbln_temp\t|\t $rbln_mem      \t|\t$rbln_util\t|\t$rbln_pwr" | tee -a ./result/${FILE_DATE}/${TEST_VECTOR[i]}_rbln${j}.txt
                    else
                        echo -e "rbln$j\t|\t$rbln_pci\t|\t$rbln_temp\t|\t $rbln_mem      \t|\t$rbln_util\t|\t$rbln_pwr" >> ./result/${FILE_DATE}/${TEST_VECTOR[i]}_rbln${j}.txt
                    fi
                done
            else
                break
            fi
        done
        wait $bg_pid
        test_result_=$(<./test_result_.txt)
        rm ./test_result_.txt
        echo "$test_result_"
        sleep 3;
    done

    # RSD Test
    sleep 5; 
    echo ""                                                                                                             | tee -a ./result/${FILE_DATE}/swt_result.txt
    echo "++ Test Items : Rebellions Scalable Design (RSD) Test"                                                        | tee -a ./result/${FILE_DATE}/swt_result.txt
                
    if [ $RBLN_LSPCI_NUM -lt 4 ]; then
        echo "The RBLN numbers is not enough"                                                                           | tee -a ./result/${FILE_DATE}/swt_result.txt
    elif [ $RBLN_LSPCI_NUM -lt 8 ]; then
        echo "4RSD"                                                                                                     | tee -a ./result/${FILE_DATE}/swt_result.txt 
        RBLNTHUNK_PERF=1 ./tests/rblntrace retrace ./rsd/llama3_8b_batch_4.bin                                          | tee -a ./result/${FILE_DATE}/swt_result.txt 
    elif [ $RBLN_LSPCI_NUM -lt 16 ]; then
        echo "8RSD"                                                                                                     | tee -a ./result/${FILE_DATE}/swt_result.txt 
        RBLNTHUNK_PERF=1 ./tests/rblntrace retrace ./rsd/llama2_13b_batch_4.bin                                         | tee -a ./result/${FILE_DATE}/swt_result.txt 
    else
        echo "16RSD"                                                                                                    | tee -a ./result/${FILE_DATE}/swt_result.txt 
        echo "Test1 : RBLN Number[rbln0-rbln7] is used for this test."                                                  | tee -a ./result/${FILE_DATE}/swt_result.txt 
        RBLNTHUNK_PERF=1 ./tests/rblntrace retrace --npu_id_list=0,1,2,3,4,5,6,7 ./rsd/llama2_13b_batch_4.bin           | tee -a ./result/${FILE_DATE}/swt_result.txt 
        echo ""                                                                                                         | tee -a ./result/${FILE_DATE}/swt_result.txt 
        echo "Test2 : RBLN Number[rbln8-rbln15] is used for this test."                                                 | tee -a ./result/${FILE_DATE}/swt_result.txt 
        RBLNTHUNK_PERF=1 ./tests/rblntrace retrace --npu_id_list=8,9,10,11,12,13,14,15 ./rsd/llama2_13b_batch_4.bin     | tee -a ./result/${FILE_DATE}/swt_result.txt 
    fi
      
    echo ""                                                                                                             | tee -a ./result/${FILE_DATE}/swt_result.txt 
	echo "+-------------------------------------------------------------------------------------------------+"          | tee -a ./result/${FILE_DATE}/swt_result.txt 
    echo ""                                                                                                             | tee -a ./result/${FILE_DATE}/swt_result.txt 
    
    test_result_data=$(cat ./result/${FILE_DATE}/auto_test_result.txt | grep "ERR")
    if [ -z "$test_result_data" ]; then
        echo "Test Result : Success"                                                                                    | tee -a ./result/${FILE_DATE}/swt_result.txt 
    else
        echo "Test Result : Fail"                                                                                       | tee -a ./result/${FILE_DATE}/swt_result.txt 
        rm ./*.bin
        echo "$test_result_data"                                                                                        | tee -a ./result/${FILE_DATE}/swt_result.txt 
    fi
                
    echo ""                                                                                                             | tee -a ./result/${FILE_DATE}/swt_result.txt 
	echo "+-------------------------------------------------------------------------------------------------+"          | tee -a ./result/${FILE_DATE}/swt_result.txt 
    echo ""  
    echo "Test was finished and the result file was saved in ./result/${FILE_DATE}/auto_test_result.txt"
    echo ""
 }

print_1_submenu() {
    echo "1. Install Qual Driver"
    echo "2. Install External Driver"
    echo "3. Back"
}

select_1_option() {
    read -p "Select an option[1-3]: " choice

    QUAL_DRIVER="./drivers/rebel_driver_external_qual_16gbps_1.1.67_amd64.deb"
    EXTERNAL_DRIVER="./drivers/rebel_driver_external_release_16gbps_1.1.67_amd64.deb"

    case $choice in
		1)
			echo "Installing Qual Driver..."
			if sudo dpkg -i "QUAL_DRIVER"; then
				rbln-stat
				echo "Qual Driver installed successfully."
			else
				echo "Error installing Qual Driver!"
			fi
			;;

        2)
			echo "Installing External Driver..."
			if sudo dpkg -i "EXTERNAL_DRIVER"; then
				rbln-stat
				echo "External Driver installed successfully."
			else
				echo "Error installing External Driver!"
            fi
            ;;
        3)
			echo "Exiting..."
            return
            ;;
        *)
            echo "Invalid option. Please try again."
            ;;
    esac
}

print_3_submenu() {
    echo "1. Update of The SMC firmware"
    echo "2. Back"
}

select_3_option() {
    read -p "Select an options [1-2]: " choice
	files=($(ls -al ./smc/*.bin | awk '{print $9}'))
	for ((i=0; i<${#files[@]}; i++)); do
	    echo "$[i] ${files[i]}"
	done
	case $choice in
	1)
        read -p "Please enter the SMC firmware number to proceed with the installation: " number
        echo ""
        if [ -z "$number" ] || ! [[ "$number" =~ ^[0-9]+$ ]] || [ "$number" -gt "$(($i-1))" ]; then
        echo "SMC Firmware do not select. Please restart."
        sleep 2;
        return
        else
            echo "======= No. 2 RBLN SMC firmware update               ========"
            echo ""
            echo "Start update firmware of ${files[$number]}"
            sleep 2;
            echo ""
            if command -v dkms &> /dev/null && command -v rbln-stat &> /dev/null; then
                echo "RBLN_NUM : $RBLN_NUM"
            for ((num=0 ; num < ${RBLN_NUM} ; num++));do
            echo "rbln fuse -f ${files[$number]} -d $num -u1"
            rbln fuse -f ${files[$number]} -d $num -u1
            echo ""
            done
                sleep 2;
            else
                if ! command -v dkms &> /dev/null; then
                    echo "++ Start installing dkms ++" >&2
                    sleep 2;
                    apt update && apt install -y dkms
                fi
                if ! command -v rbln-stat &> /dev/null; then
                    echo "++ The RBLN driver must be installed first ++" >&2
                    sleep 2;
                    echo ""
                fi
                fi
            sleep 2;
        fi
        ;;
    2)
        return
        ;;
    *)
        echo "Invalid selection. Please try again."
        ;;
    esac
}


select_option() {
    read -p "Select an option number[1-4]: " choice
    echo ""
    case $choice in
    1)
        echo "+-------------------------------------------------------------------------------------------------+"
        echo "|                              No. 1 RBLN driver install                                          |"
        echo "+-------------------------------------------------------------------------------------------------+"
        print_1_submenu
	    select_1_option
        ;;
    2)  
        echo "+-------------------------------------------------------------------------------------------------+"
        echo "|                           No. 2  Rebellions Scalable Design (RSD) test                          |"
        echo "+-------------------------------------------------------------------------------------------------+"
        sleep 2;
	    select_2_result
        ;;
    3)
	    select_3_result
	    sleep 5;
        ;;
    4)
        echo "Exiting..."
        exit 0
        ;;
    5)
        echo ""
        echo "Invalid option. Please try again."
        ;;
    esac
}

main() {
    while true; do
        print_menu
        select_option
    done
}
clear
main
