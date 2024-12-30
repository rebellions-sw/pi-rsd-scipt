import sys
import subprocess
import os

# 필요한 패키지를 확인하고 설치하는 함수
def install_packages(packages):
    for package in packages:
        try:
            __import__(package)
        except ImportError:
            print(f"{package} 모듈이 설치되지 않았습니다. 설치를 시도합니다.")
            subprocess.check_call([sys.executable, "-m", "pip", "install", package])

# 필요한 패키지 목록
required_packages = ['pandas', 'matplotlib', 'csvkit']

# 패키지 설치 시도
install_packages(required_packages)

import pandas as pd
import matplotlib.pyplot as plt

baseline_values = {
    '7b_batch1': 23833,
    '7b_batch4': 67013,
    '8b_batch1': 24061,
    '8b_batch4': 30298,
    '13b_batch1': 22834,
    '13b_batch4': 45879
}



def plot_graph(csv_file, avg_waited, avg_called):
    try:
        # CSV 파일 읽기
        data = pd.read_csv(csv_file)

        # 데이터 필터링
        filtered_data = data.iloc[20:-20]
        # 그래프 그리기
        plt.figure(figsize=(10, 5))
        plt.plot(data['No'], data['waited'], label='Waited', marker='o')
        plt.plot(data['No'], data['called'], label='Called', marker='x')

        # 평균값 가이드라인 추가
        plt.axhline(y=float(avg_waited), color='r', linestyle='--', label=f'Avg Waited: {avg_waited}')
        plt.axhline(y=float(avg_called), color='b', linestyle='--', label=f'Avg Called: {avg_called}')

        plt.xlabel('Infer No')
        plt.ylabel('Perf (us)')
        plt.title('Performance Metrics')
        plt.legend()
        plt.grid(True)

        # 그래프 출력 또는 저장
        png_file = os.path.splitext(csv_file)[0] + '.png'
        plt.savefig(png_file)
        plt.close()

    except ValueError as e:
        print(f"Error: {e}")
        print("Please ensure that avg_waited and avg_called are valid numbers.")
    except Exception as e:
        print(f"An unexpected error occurred: {e}")

# 쉘 스크립트에서 전달된 인수 받기
csv_file = sys.argv[1]
avg_waited = sys.argv[2]
avg_called = sys.argv[3]

print("plot.py csv_file=",csv_file)
print("plot.py avg_waited=",avg_waited)
print("plot.py avg_called=",avg_called)

# 그래프 그리기
plot_graph(csv_file, avg_waited, avg_called)

