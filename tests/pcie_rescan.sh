#!/bin/bash

# 장치 이름을 인수로 받습니다.
device_name=acc

if [ -z "$device_name" ]; then
    echo "Usage: $0 <pci_devicename>"
    exit 1
fi

npu_num=$(lspci | grep accelerators | wc -l)

echo "pcie device before delete npu num is $npu_num"

# lspci 명령을 사용하여 장치를 검색하고 버스 ID를 추출합니다.
device_ids=$(lspci | grep "$device_name" | awk '{print $1}')

if [ -z "$device_ids" ]; then
    echo "No devices found with name: $device_name"
    exit 1
fi

# 추출한 버스 ID를 통해 각 장치를 삭제합니다.
for id in $device_ids; do
    echo "Removing device: $id"
    echo 1 | sudo tee /sys/bus/pci/devices/$id/remove
    sleep 1
done

npu_num=$(lspci | grep accelerators | wc -l)

echo "pcie device after delete npu num is $npu_num"

# 모든 장치를 삭제한 후, 리스캔합니다.
echo "Rescanning PCI devices..."
echo 1 | sudo tee /sys/bus/pci/rescan

npu_num=$(lspci | grep accelerators | wc -l)

echo "PCI rescan complete.  $npu_num"

