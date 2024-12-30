#!/bin/bash

# 파일 리스트

file_list=("rblntrace_202405311459-llama7b_batch1_evt1_0.bin" "rblntrace_202405311525-llama7b_batch4_evt1_0.bin" "rblntrace_202405311608-llama8b_batch1_evt1_0.bin" "rblntrace_202405311619-llama8b_batch4_evt1_0.bin" "rblntrace_202405311508-llama13b_batch1_evt1_0.bin" "rblntrace_202405311541-llama13b_batch4_evt1_0.bin")


# 로컬 저장 위치
local_path="/llama"

# 원격 저장 위치
remote_host="192.168.49.200"
remote_path="/root/test_vector/llama/"

# 폴더가 없으면 생성
mkdir -p "$local_path"

# 파일 복사 및 동기화 함수
sync_files() {
    local filename="$1"
    #local dv=$2
    local local_file="$local_path$filename"
    local remote_file="$remote_host:$remote_path$filename"

    if [ ! -f "$local_file" ]; then
        # 로컬에 파일이 없는 경우 원격에서 복사
        echo "Copying $filename from remote to local..."
        rsync -avz --progress "$remote_file" "$local_file"
    else
        # 로컬에 파일이 있는 경우 용량 비교
        local local_size=$(stat -c %s "$local_file")
        local remote_size=$(ssh "$remote_host" stat -c %s "$remote_path$filename")

        if [ "$local_size" -eq "$remote_size" ]; then
            echo "File $filename already exists and sizes match. Skipping."
        else
            echo "File $filename exists but sizes differ. Re-syncing..."
            rsync -avz --progress --ignore-existing "$remote_file" "$local_file"
        fi
    fi
}

# 파일 복사 및 동기화 함수
check_files() {
    local filename="$1"
    #local dv=$2
    local local_file="$local_path$filename"
    local remote_file="$remote_host:$remote_path$filename"

    if [ ! -f "$local_file" ]; then
        # 로컬에 파일이 없는 경우 원격에서 복사
        echo "There is no file. exit"
        exit 1
    else
        # 로컬에 파일이 있는 경우 용량 비교
        local local_size=$(stat -c %s "$local_file")
        local remote_size=$(ssh "$remote_host" stat -c %s "$remote_path$filename")

        if [ "$local_size" -eq "$remote_size" ]; then
            echo "File $filename already exists and sizes match. Done"
        else
            echo "File $filename exists but sizes differ. exit"
            #rsync -avz --progress --ignore-existing "$remote_file" "$local_file"
	    exit 1
        fi
    fi
}


# 파일 리스트 순회하며 처리
for file in "${file_list[@]}"; do
    sync_files "$file"
done

for file in "${file_list[@]}"; do
    check_files "$file"
done
