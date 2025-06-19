import os
import zipfile
from datetime import datetime


def file_signature(path):
    name = os.path.basename(path)
    mtime = os.path.getmtime(path)
    date = datetime.fromtimestamp(mtime).date().isoformat()
    return name, date


def find_file_duplicates(root):
    sig_map = {}
    for dirpath, _, filenames in os.walk(root):
        for filename in filenames:
            path = os.path.join(dirpath, filename)
            sig = file_signature(path)
            sig_map.setdefault(sig, []).append(path)
    duplicates = [paths for paths in sig_map.values() if len(paths) > 1]
    return duplicates


def zip_dir_equal(zip_path, dir_path):
    try:
        with zipfile.ZipFile(zip_path) as z:
            zip_names = sorted(
                info.filename.rstrip('/')
                for info in z.infolist()
                if not info.is_dir()
            )
    except zipfile.BadZipFile:
        return False
    dir_names = []
    for root, _, files in os.walk(dir_path):
        for f in files:
            rel = os.path.relpath(os.path.join(root, f), dir_path)
            dir_names.append(rel.replace(os.sep, '/'))
    dir_names.sort()
    return zip_names == dir_names


def find_zip_folder_duplicates(root):
    duplicates = []
    for dirpath, _, filenames in os.walk(root):
        for filename in filenames:
            if filename.endswith('.zip'):
                zip_path = os.path.join(dirpath, filename)
                folder = os.path.join(dirpath, os.path.splitext(filename)[0])
                if os.path.isdir(folder) and zip_dir_equal(zip_path, folder):
                    duplicates.append((zip_path, folder))
    return duplicates


if __name__ == '__main__':
    root_dir = '.'
    file_dups = find_file_duplicates(root_dir)
    zip_dups = find_zip_folder_duplicates(root_dir)

    if file_dups:
        print('Duplicate files (same name and date):')
        for group in file_dups:
            for path in group:
                print(path)
            print()
    else:
        print('No file duplicates found.')

    if zip_dups:
        print('\nZip/folder duplicates:')
        for zip_path, folder in zip_dups:
            print(f'{zip_path} <-> {folder}')
    else:
        print('\nNo zip/folder duplicates found.')

    print('\nGit commands to remove duplicates:')
    for group in file_dups:
        for path in group[1:]:
            print(f'git rm "{path}"')
    for zip_path, folder in zip_dups:
        print(f'git rm "{zip_path}"  # or remove {folder}')

