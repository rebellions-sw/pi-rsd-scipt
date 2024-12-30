import os
import csv
import json
import matplotlib.pyplot as plt
import sys
import subprocess
import re

# 각 테스트 벡터 이름과 기준값 사전
baseline_values = {
    '7b_batch1': 23833,
    '7b_batch4': 67013,
    '8b_batch1': 24061,
    '8b_batch4': 30298,
    '13b_batch1': 22834,
    '13b_batch4': 45879,
    '13b_batch_4' : 31170,
    '7b_batch_4' : 34233,
    '8b_batch_4' : 24269,
    'solar_32k' : 23753,
    'solar_4k' : 27872
}

# CSV 파일을 읽어서 json 형식으로 변환하는 함수
def csv_to_json(csv_file):
    json_data = []

    with open(csv_file, 'r', encoding='utf-8') as file:
        reader = csv.DictReader(file)
        base_file_name = extract_base_name(csv_file)  # 파일명에서 중간 부분 추출

        data = []
        report_passed = None
        average_us = None
        total_time = None  # total_time 초기화
        for row in reader:
            try:
                data.append({
                    "No": int(row['No']),
                    "waited": float(row['waited']),
                    "called": float(row['called'])
                })
            except ValueError as e:
                # float 변환이 실패할 경우를 처리
                print(f"유효하지 않은 값이 있는 행을 건너뜁니다: {row}. 오류: {e}")
                continue
            
            if report_passed is None:
                report_passed = row.get('report_passed')
            if average_us is None:
                average_us = row.get('average_us')
            if total_time is None:
                total_time = row.get('total_time')

        json_data.append({
            "base_file_name": base_file_name,
            "report_passed": report_passed,
            "average_us": average_us,
            "total_time": total_time,  # total_time 추가
            "data": data
        })
    
    return json_data

# 파일명에서 중간 부분을 추출하는 함수
def extract_base_name(csv_file):
    filename = os.path.splitext(os.path.basename(csv_file))[0]
    match = re.search(r'\b\w+batch\w*\b', filename)
    if match:
        return match.group(0)
    return None

# 현재 디렉토리에서 csv 파일을 찾아서 처리
def process_csv_files(file_name_filter):
    json_data = []
    directory = './mda_log/temp'

    for file in os.listdir(directory):
        if file.lower().startswith(file_name_filter.lower()) and (file.lower().endswith('.csv') or file.lower().endswith('.cvs')):
            csv_file = os.path.join(directory, file)
            print("csv_file", csv_file)
            json_data.extend(csv_to_json(csv_file))

    return json_data
"""
# JSON 데이터를 각각의 테스트 벡터별로 개별 그래프로 생성하고 저장
def plot_individual_graphs(json_data, file_name_filter):
    num_plots = len(json_data)
    fig, axs = plt.subplots(num_plots, 1, figsize=(12, num_plots * 6))

    for i, item in enumerate(json_data):
        base_file_name = item['base_file_name']
        report_passed = item['report_passed']
        average_us = item['average_us']
        print("base_file_name", base_file_name)
        data = item['data']

        # 기준값 확인
        baseline = None
        for key, value in baseline_values.items():
            if key in base_file_name:
                baseline = value
                break

        # 데이터 추출
        x = [entry['No'] for entry in data]
        y1 = [entry['waited'] for entry in data]

        # waited 데이터 그래프 그리기
        axs[i].plot(x, y1, linestyle='-', linewidth=1, label=f'{base_file_name} (waited)')
        if baseline is not None:
            axs[i].axhline(y=baseline, color='r', linestyle='--', label=f'Baseline: {baseline}')
        axs[i].set_title(f'{base_file_name} Waited Data - Report: {report_passed}, Avg(us): {average_us}')
        axs[i].set_xlabel('No')
        axs[i].set_ylabel('Values')
        axs[i].legend()
        axs[i].grid(True)

    plt.tight_layout()
    save_path = f'./result/{file_name_filter}_combined_waited_plot.png'
    plt.savefig(save_path)  # 그래프 저장
    plt.show()

    return save_path
"""
def plot_individual_graphs(json_data, file_name_filter):
    num_plots = len(json_data)
    fig, axs = plt.subplots(num_plots, 1, figsize=(12, num_plots * 6))

    # axs가 단일 Axes 객체인지 확인
    if num_plots == 1:
        axs = [axs]  # 리스트로 변환하여 일관된 처리

    for i, item in enumerate(json_data):
        base_file_name = item['base_file_name']
        report_passed = item['report_passed']
        average_us = item['average_us']
        total_time = item['total_time'] 
        print("base_file_name", base_file_name)
        data = item['data']

        # 기준값 확인
        baseline = None
        for key, value in baseline_values.items():
            if key in base_file_name:
                baseline = value
                break

        # 데이터 추출
        x = [entry['No'] for entry in data]
        y1 = [entry['waited'] for entry in data]

        # waited 데이터 그래프 그리기
        axs[i].plot(x, y1, linestyle='-', linewidth=1, label=f'{base_file_name} (waited)')
        if baseline is not None:
            axs[i].axhline(y=baseline, color='r', linestyle='--', label=f'Baseline: {baseline}')
        #axs[i].set_title(f'{base_file_name} Waited Data - Report: {report_passed}, Avg(us): {average_us}, Total_Time(us): {total_time}')
        axs[i].set_title(
            f'{base_file_name} Waited Data - Report: {report_passed}, Avg(us): {average_us}, Total_Time(us): {total_time}',
            fontsize=10  # 제목 글자 크기를 줄임
        )
        axs[i].set_xlabel('No')
        axs[i].set_ylabel('Values')
        axs[i].legend()
        axs[i].grid(True)

    plt.tight_layout()
    save_path = f'./result/{file_name_filter}_combined_waited_plot.png'
    plt.savefig(save_path)  # 그래프 저장
    plt.show()

    return save_path


def main():
    file_name_filter = sys.argv[1]
    print("file_name_filter is ", file_name_filter)
    json_data = process_csv_files(file_name_filter)
    save_path = plot_individual_graphs(json_data, file_name_filter)


if __name__ == "__main__":
    main()

