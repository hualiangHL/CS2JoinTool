import os
import re

def strip_comments(text):
    result = []
    i = 0
    n = len(text)
    in_string = False
    string_char = None
    in_line_comment = False
    in_block_comment = False
    while i < n:
        c = text[i]
        nxt = text[i+1] if i+1 < n else ''
        if in_line_comment:
            if c == '\n':
                in_line_comment = False
                result.append(c)
            i += 1
            continue
        if in_block_comment:
            if c == '*' and nxt == '/':
                in_block_comment = False
                i += 2
            else:
                if c == '\n':
                    result.append(c)
                i += 1
            continue
        if in_string:
            result.append(c)
            if c == '\\' and nxt:
                result.append(nxt)
                i += 2
                continue
            if c == string_char:
                in_string = False
            i += 1
            continue
        if c == '"' or c == "'":
            in_string = True
            string_char = c
            result.append(c)
            i += 1
            continue
        if c == '/' and nxt == '/':
            in_line_comment = True
            i += 2
            continue
        if c == '/' and nxt == '*':
            in_block_comment = True
            i += 2
            continue
        result.append(c)
        i += 1
    # 清理多余空行（连续3个以上换行变成2个）
    text = ''.join(result)
    text = re.sub(r'\n{3,}', '\n\n', text)
    return text

def process_file(src_path, dst_path):
    with open(src_path, 'r', encoding='utf-8') as f:
        content = f.read()
    cleaned = strip_comments(content)
    os.makedirs(os.path.dirname(dst_path), exist_ok=True)
    with open(dst_path, 'w', encoding='utf-8') as f:
        f.write(cleaned)

src_root = r"C:\Users\HL\Desktop\cs2模组\CS2挤服工具v4版本"
dst_root = r"C:\Users\HL\Desktop\V4"

# main.cpp
process_file(os.path.join(src_root, "main.cpp"), os.path.join(dst_root, "main.cpp"))
# CMakeLists.txt
process_file(os.path.join(src_root, "CMakeLists.txt"), os.path.join(dst_root, "CMakeLists.txt"))
# resources.qrc
process_file(os.path.join(src_root, "resources.qrc"), os.path.join(dst_root, "resources.qrc"))
# app.rc
process_file(os.path.join(src_root, "app.rc"), os.path.join(dst_root, "app.rc"))

# src/*.h, *.cpp
src_dir = os.path.join(src_root, "src")
for f in os.listdir(src_dir):
    if f.endswith(('.h', '.cpp')):
        process_file(os.path.join(src_dir, f), os.path.join(dst_root, "src", f))

# qml root qml files
qml_dir = os.path.join(src_root, "qml")
for f in os.listdir(qml_dir):
    fp = os.path.join(qml_dir, f)
    if os.path.isfile(fp) and f.endswith('.qml'):
        process_file(fp, os.path.join(dst_root, "qml", f))
    elif os.path.isfile(fp) and f == 'qmldir':
        process_file(fp, os.path.join(dst_root, "qml", f))

# qml/pages
pages_dir = os.path.join(qml_dir, "pages")
for f in os.listdir(pages_dir):
    fp = os.path.join(pages_dir, f)
    if os.path.isfile(fp) and f.endswith('.qml'):
        process_file(fp, os.path.join(dst_root, "qml", "pages", f))
    elif os.path.isfile(fp) and f == 'qmldir':
        process_file(fp, os.path.join(dst_root, "qml", "pages", f))

# qml/components
comp_dir = os.path.join(qml_dir, "components")
for f in os.listdir(comp_dir):
    fp = os.path.join(comp_dir, f)
    if os.path.isfile(fp) and f.endswith('.qml'):
        process_file(fp, os.path.join(dst_root, "qml", "components", f))
    elif os.path.isfile(fp) and f == 'qmldir':
        process_file(fp, os.path.join(dst_root, "qml", "components", f))

print("All source files processed, comments stripped.") 


