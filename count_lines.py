# -*- coding: utf-8 -*-
"""全Dartファイルの行数を集計するスクリプト"""

import os
from collections import defaultdict

def count_lines_in_project():
    """プロジェクト内の全Dartファイルの行数を集計"""
    
    file_info = []
    total_lines = 0
    total_files = 0
    
    # libディレクトリ内の全dartファイルを取得
    for root, dirs, files in os.walk('lib'):
        for file in files:
            if file.endswith('.dart'):
                file_path = os.path.join(root, file)
                try:
                    with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                        lines = sum(1 for line in f)
                    file_info.append((file_path, lines))
                    total_lines += lines
                    total_files += 1
                except Exception as e:
                    print(f'エラー: {file_path} - {e}')
    
    # 行数でソート
    file_info.sort(key=lambda x: x[1], reverse=True)
    
    # ディレクトリごとの集計
    dir_stats = defaultdict(lambda: {'files': 0, 'lines': 0})
    for file_path, lines in file_info:
        dir_path = os.path.dirname(file_path)
        dir_stats[dir_path]['files'] += 1
        dir_stats[dir_path]['lines'] += lines
    
    # 結果を表示
    print('=' * 100)
    print('プロジェクト内 全Dartファイル コード量レポート')
    print('=' * 100)
    print(f'\n総ファイル数: {total_files}')
    print(f'総コード行数: {total_lines:,} 行\n')
    
    print('-' * 100)
    print('ファイル別（行数の多い順 トップ30）')
    print('-' * 100)
    for i, (file_path, lines) in enumerate(file_info[:30], 1):
        print(f'{i:3d}. {lines:6,} 行 - {file_path}')
    
    if len(file_info) > 30:
        print(f'\n... 他 {len(file_info) - 30} ファイル')
    
    print('\n' + '-' * 100)
    print('ディレクトリ別 コード量（行数の多い順）')
    print('-' * 100)
    
    sorted_dirs = sorted(dir_stats.items(), key=lambda x: x[1]['lines'], reverse=True)
    for dir_path, stats in sorted_dirs[:20]:
        print(f'{stats["lines"]:8,} 行 ({stats["files"]:3} ファイル) - {dir_path}')
    
    # 統計情報
    if file_info:
        avg_lines = total_lines / total_files
        max_lines = max(file_info, key=lambda x: x[1])[1]
        min_lines = min(file_info, key=lambda x: x[1])[1]
        
        print('\n' + '-' * 100)
        print('統計情報')
        print('-' * 100)
        print(f'平均行数: {avg_lines:.1f} 行/ファイル')
        print(f'最大行数: {max_lines:,} 行')
        print(f'最小行数: {min_lines:,} 行')
    
    print('\n' + '=' * 100)
    
    # 結果をファイルに保存
    with open('code_stats.txt', 'w', encoding='utf-8') as f:
        f.write('プロジェクト内 全Dartファイル コード量レポート\n')
        f.write('=' * 100 + '\n')
        f.write(f'\n総ファイル数: {total_files}\n')
        f.write(f'総コード行数: {total_lines:,} 行\n\n')
        
        f.write('-' * 100 + '\n')
        f.write('ファイル別（行数の多い順）\n')
        f.write('-' * 100 + '\n')
        for i, (file_path, lines) in enumerate(file_info, 1):
            f.write(f'{i:3d}. {lines:6,} 行 - {file_path}\n')
    
    print(f'\n詳細レポートを code_stats.txt に保存しました。')

if __name__ == '__main__':
    count_lines_in_project()

