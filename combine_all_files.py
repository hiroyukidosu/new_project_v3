# -*- coding: utf-8 -*-
"""全Dartファイルを1つのファイルに統合するスクリプト"""

import os
import glob
from datetime import datetime

def combine_files():
    """全Dartファイルを1つに統合"""
    
    # libディレクトリ内の全dartファイルを取得
    dart_files = []
    for root, dirs, files in os.walk('lib'):
        for file in files:
            if file.endswith('.dart'):
                file_path = os.path.join(root, file)
                dart_files.append(file_path)
    
    # ファイルパスでソート
    dart_files.sort()
    
    # 出力ファイル
    output_file = 'project_all_files_for_ai_review.txt'
    
    with open(output_file, 'w', encoding='utf-8') as out:
        # ヘッダー
        out.write('=' * 80 + '\n')
        out.write('=' * 80 + '\n')
        out.write('Flutter プロジェクト全ファイル統合版 - AI評価用\n')
        out.write('=' * 80 + '\n')
        out.write(f'生成日時: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}\n')
        out.write(f'プロジェクトパス: {os.getcwd()}\n')
        out.write(f'総ファイル数: {len(dart_files)}\n')
        out.write('=' * 80 + '\n')
        out.write('\n')
        
        out.write('【このファイルについて】\n')
        out.write('このファイルは、プロジェクトの全Dartファイルを1つのファイルに統合したものです。\n')
        out.write('各ファイルの前に説明メモを追加しており、AIによる評価・レビューを容易にするために作成されました。\n')
        out.write('元のファイルは全て保持されています。\n')
        out.write('\n')
        
        out.write('【ファイル構造】\n')
        out.write('各セクションは以下の形式で記載されています：\n')
        out.write('1. セパレータ（==========）\n')
        out.write('2. ファイル情報（パス、行数、目的など）\n')
        out.write('3. コード内容\n')
        out.write('4. セパレータ（ファイル終了）\n')
        out.write('\n')
        out.write('=' * 80 + '\n')
        out.write('=' * 80 + '\n')
        out.write('\n')
        
        # 各ファイルを処理
        for idx, file_path in enumerate(dart_files, 1):
            print(f'処理中: {idx}/{len(dart_files)} - {file_path}')
            
            out.write('\n')
            out.write('=' * 80 + '\n')
            out.write('=' * 80 + '\n')
            out.write('\n')
            out.write(f'ファイル {idx} / {len(dart_files)}\n')
            out.write(f'ファイルパス: {file_path}\n')
            
            if os.path.exists(file_path):
                file_stat = os.stat(file_path)
                line_count = sum(1 for line in open(file_path, 'r', encoding='utf-8', errors='ignore'))
                out.write(f'ファイルサイズ: {file_stat.st_size} bytes\n')
                out.write(f'行数: {line_count} 行\n')
                out.write(f'最終更新日時: {datetime.fromtimestamp(file_stat.st_mtime).strftime("%Y-%m-%d %H:%M:%S")}\n')
            else:
                out.write('【警告】ファイルが見つかりません\n')
            
            out.write('\n')
            out.write('【ファイルの役割と説明】\n')
            
            # ファイルパスから役割を推測
            if 'main' in file_path:
                out.write('- このファイルはアプリケーションのエントリーポイントです\n')
            elif 'model' in file_path or 'models' in file_path:
                out.write('- このファイルはデータモデルを定義しています\n')
            elif 'service' in file_path or 'services' in file_path:
                out.write('- このファイルはサービスクラス（ビジネスロジック）を定義しています\n')
            elif 'widget' in file_path or 'widgets' in file_path:
                out.write('- このファイルはUIウィジェットを定義しています\n')
            elif 'screen' in file_path or 'screens' in file_path:
                out.write('- このファイルは画面（Screen）を定義しています\n')
            elif 'controller' in file_path or 'controllers' in file_path:
                out.write('- このファイルはコントローラークラスを定義しています\n')
            elif 'handler' in file_path or 'handlers' in file_path:
                out.write('- このファイルはイベントハンドラーを定義しています\n')
            elif 'repository' in file_path or 'repositories' in file_path:
                out.write('- このファイルはリポジトリクラス（データアクセス）を定義しています\n')
            elif 'helper' in file_path or 'helpers' in file_path:
                out.write('- このファイルはヘルパー関数・クラスを定義しています\n')
            elif 'core' in file_path:
                out.write('- このファイルはコア機能を定義しています\n')
            elif 'utils' in file_path:
                out.write('- このファイルはユーティリティ関数を定義しています\n')
            elif 'config' in file_path or 'constants' in file_path:
                out.write('- このファイルは設定・定数を定義しています\n')
            else:
                out.write('- このファイルは、プロジェクトの一部として機能しています\n')
            
            out.write('- 詳細な説明はコード内のコメントを参照してください\n')
            out.write('\n')
            out.write('【コード開始】\n')
            out.write('\n')
            out.write('```dart\n')
            
            if os.path.exists(file_path):
                try:
                    with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                        content = f.read()
                        out.write(content)
                except Exception as e:
                    out.write(f'// ファイル読み込みエラー: {e}\n')
            else:
                out.write(f'// ファイルが見つかりません: {file_path}\n')
            
            out.write('\n```\n')
            out.write('\n')
            out.write('【コード終了】\n')
            out.write('\n')
            out.write('-' * 80 + '\n')
            out.write(f'ファイル終了: {file_path}\n')
            out.write('-' * 80 + '\n')
            out.write('\n')
    
    print(f'\n統合ファイルを作成しました: {output_file}')
    if os.path.exists(output_file):
        file_size = os.path.getsize(output_file)
        print(f'ファイルサイズ: {file_size / (1024*1024):.2f} MB')

if __name__ == '__main__':
    combine_files()

