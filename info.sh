#!/bin/bash

LNKSTA=($(lspci -D | grep -i accelerators | awk '{print $1}'))
LNKSTA_NUM=${#LNKSTA[@]}


host_name=$(hostname)

# 매개 변수를 받아서 hostname 변수에 저장
if [ -z "$1" ]; then
    # 매개 변수가 없는 경우 현재 호스트 이름을 사용
    host_name=$(hostname)
else
    # 매개 변수가 있는 경우 해당 값을 사용
    host_name=$1
fi

check_time=$(date +"%Y_%m_%d_%H_%M")
os_version=$(lsb_release -a |grep Description | awk '{print $3}')
kernel_version=$(uname -r)
npu_num=$(lspci | grep accelerators | wc -l)

FILE_PATH="./result/server_info.txt"
serial_number=$(dmidecode -t system | grep -i serial | awk '{print $3}')

# jq와 sshpass가 설치되어 있는지 확인
if ! command -v jq &> /dev/null || ! command -v sshpass &> /dev/null; then
]	echo "jq 또는 sshpass가 설치되어 있지 않습니다. 설치를 진행합니다."
 	sudo apt-get update
	sudo apt-get install -y jq sshpass
else
	echo "jq와 sshpass가 모두 설치되어 있습니다."
fi

FILE_PATH1="./uuid_reg.txt"
if [ -e $FILE_PATH1 ]; then
	echo "uuid exists"
else
	echo "uuid none"
	exit 1
fi

echo "npu info" >> $FILE_PATH


# JSON 데이터 출력
json_output=$(rbln-stat -j)

kmd_version=$(echo "$json_output" | jq -r ".KMD_version")
 
echo "1. NPU Information" > $FILE_PATH
echo "start time= $check_time  host_name= $host_name  os_version= $os_version  kernel_version= $kernel_version npu_num= $npu_num RBLN_NUM= $RBLN_NUM" "Serial_Num= $serial_number driver version = $kmd_version" >> $FILE_PATH


# JSON 데이터가 비어 있는지 확인
if [[ -z "$json_output" ]]; then
	echo "JSON 데이터가 없습니다."
	echo "exit code 1" >> $FILE_PATH
	exit 1
fi

RBLN_NUM=$(echo "$json_output" | jq '.devices | length')

if (( $npu_num != $RBLN_NUM )); then
	echo "## All NPU has not been loaded. ##"
	echo "exit code 2" >> $FILE_PATH
	exit 2
fi


for ((i=0; i < $npu_num; i++)); do
    port=$i
    pci_bus_id=$(echo "$json_output" | jq -r ".devices[$i].pci.bus_id")
    uuid=$(echo "$json_output" | jq -r ".devices[$i].uuid")
    
    chip_info=$(sudo rbln chip_info -d $i | grep -i 'chip info' | awk '{print $3}')
    pci_slot=$(dmidecode -t slot | grep -B 10 $pci_bus_id | grep  ID | awk '{print $2}')
	LnkStat=$(sudo lspci -vv -s $pci_bus_id | grep -o 'Speed [^,]*(downgraded)')
    LnkStat_Speed=$(echo "$json_output" | jq -r ".devices[$i].pci.link_speed")
    LnkStat_Width=$(echo "$json_output" | jq -r ".devices[$i].pci.link_width")
    npu_name=$(echo "$json_output" | jq -r ".devices[$i].name")

    echo "npu $port  busid= $pci_bus_id  uuid= $uuid  chip_info= $chip_info  LnkStat= $LnkStat  LnkStat_Width= $LnkStat_Width  slot= $pci_slot npu_name= $npu_name" >> $FILE_PATH
done

echo "" >> $FILE_PATH
echo "" >> $FILE_PATH
echo "2. RBLNs Power Information" >> $FILE_PATH

for ((i=0; i<${LNKSTA_NUM}; i++)); do
	PWR_INFO=$(rbln pwr -d "$i" | grep "Power data")
	echo "RBLN $i: $PWR_INFO" >> $FILE_PATH
done


echo "" >> $FILE_PATH
echo "" >> $FILE_PATH
echo "3. Network Information" >> $FILE_PATH

netplan=$(cat /etc/netplan/*.yaml)
ip_info=$(ip a)

echo "netplan is $netplan" >> $FILE_PATH
echo "" >> $FILE_PATH
echo "ip_info is $ip_info" >> $FILE_PATH
