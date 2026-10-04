


import re
import json
from pathlib import Path
from typing import Dict, List, Any

sources_table = {
    "HusIcon": ["src/cpp/controls/husiconfont.h", "src/cpp/controls/husiconfont.cpp"],
    "HusQrCode": ["src/cpp/controls/husqrcode.h", "src/cpp/controls/husqrcode.cpp"],
    "HusRectangle": [
        "src/cpp/controls/husrectangle.h",
        "src/cpp/controls/husrectangle.cpp",
    ],
    "HusRadius": [
        "src/cpp/controls/husrectangle.h",
        "src/cpp/controls/husrectangle.cpp",
    ],
    "HusWatermark": [
        "src/cpp/controls/huswatermark.h",
        "src/cpp/controls/huswatermark.cpp",
    ],
    "HusColorGenerator": [
        "src/cpp/theme/huscolorgenerator.h",
        "src/cpp/theme/huscolorgenerator.cpp",
    ],
    "HusRadiusGenerator": [
        "src/cpp/theme/husradiusgenerator.h",
        "src/cpp/theme/husradiusgenerator.cpp",
    ],
    "HusSizeGenerator": [
        "src/cpp/theme/hussizegenerator.h",
        "src/cpp/theme/hussizegenerator.cpp",
    ],
    "HusSystemThemeHelper": [
        "src/cpp/theme/hussystemthemehelper.h",
        "src/cpp/theme/hussystemthemehelper.cpp",
    ],
    "HusThemeFunctions": [
        "src/cpp/theme/husthemefunctions.h",
        "src/cpp/theme/husthemefunctions.cpp",
    ],
    "HusTheme": [
        "src/cpp/theme/hustheme.h",
        "src/cpp/theme/hustheme_p.h",
        "src/cpp/theme/hustheme.cpp",
    ],
    "HusApi": ["src/cpp/utils/husapi.h", "src/cpp/utils/husapi.cpp"],
    "HusAsyncHasher": [
        "src/cpp/utils/husasynchasher.h",
        "src/cpp/utils/husasynchasher.cpp",
    ],
    "HusRouter": ["src/cpp/utils/husrouter.h", "src/cpp/utils/husrouter.cpp"],
    "HusApp": ["src/cpp/husapp.h", "src/cpp/husapp.cpp"],
    "HusAcrylic": ["src/imports/HusAcrylic.qml"],
    "HusAnimatedImage": ["src/imports/HusAnimatedImage.qml"],
    "HusAutoComplete": ["src/imports/HusAutoComplete.qml"],
    "HusAvatar": ["src/imports/HusAvatar.qml"],
    "HusBadge": ["src/imports/HusBadge.qml"],
    "HusBreadcrumb": ["src/imports/HusBreadcrumb.qml"],
    "HusButton": ["src/imports/HusButton.qml"],
    "HusButtonBlock": ["src/imports/HusButtonBlock.qml"],
    "HusCaptionBar": ["src/imports/HusCaptionBar.qml"],
    "HusCaptionButton": ["src/imports/HusCaptionButton.qml"],
    "HusCard": ["src/imports/HusCard.qml"],
    "HusCarousel": ["src/imports/HusCarousel.qml"],
    "HusCheckBox": ["src/imports/HusCheckBox.qml"],
    "HusCheckerBoard": ["src/imports/HusCheckerBoard.qml"],
    "HusCollapse": ["src/imports/HusCollapse.qml"],
    "HusColorPicker": ["src/imports/HusColorPicker.qml"],
    "HusColorPickerPanel": ["src/imports/HusColorPickerPanel.qml"],
    "HusContextMenu": ["src/imports/HusContextMenu.qml"],
    "HusCopyableText": ["src/imports/HusCopyableText.qml"],
    "HusDateTimePicker": ["src/imports/HusDateTimePicker.qml"],
    "HusDateTimePickerPanel": ["src/imports/HusDateTimePickerPanel.qml"],
    "HusDivider": ["src/imports/HusDivider.qml"],
    "HusDrawer": ["src/imports/HusDrawer.qml"],
    "HusEmpty": ["src/imports/HusEmpty.qml"],
    "HusFrame": ["src/imports/HusFrame.qml"],
    "HusGroupBox": ["src/imports/HusGroupBox.qml"],
    "HusIconButton": ["src/imports/HusIconButton.qml"],
    "HusIconText": ["src/imports/HusIconText.qml"],
    "HusImage": ["src/imports/HusImage.qml"],
    "HusImagePreview": ["src/imports/HusImagePreview.qml"],
    "HusInput": ["src/imports/HusInput.qml"],
    "HusInputInteger": ["src/imports/HusInputInteger.qml"],
    "HusInputNumber": ["src/imports/HusInputNumber.qml"],
    "HusLabel": ["src/imports/HusLabel.qml"],
    "HusLiquidGlass": ["src/imports/HusLiquidGlass.qml"],
    "HusMenu": ["src/imports/HusMenu.qml"],
    "HusMessage": ["src/imports/HusMessage.qml"],
    "HusModal": ["src/imports/HusModal.qml"],
    "HusMoveMouseArea": ["src/imports/HusMoveMouseArea.qml"],
    "HusMultiCheckBox": ["src/imports/HusMultiCheckBox.qml"],
    "HusMultiSelect": ["src/imports/HusMultiSelect.qml"],
    "HusNotification": ["src/imports/HusNotification.qml"],
    "HusOTPInput": ["src/imports/HusOTPInput.qml"],
    "HusPage": ["src/imports/HusPage.qml"],
    "HusPagination": ["src/imports/HusPagination.qml"],
    "HusPopconfirm": ["src/imports/HusPopconfirm.qml"],
    "HusPopover": ["src/imports/HusPopover.qml"],
    "HusPopup": ["src/imports/HusPopup.qml"],
    "HusProgress": ["src/imports/HusProgress.qml"],
    "HusRadio": ["src/imports/HusRadio.qml"],
    "HusRadioBlock": ["src/imports/HusRadioBlock.qml"],
    "HusRate": ["src/imports/HusRate.qml"],
    "HusResizeMouseArea": ["src/imports/HusResizeMouseArea.qml"],
    "HusScrollBar": ["src/imports/HusScrollBar.qml"],
    "HusSelect": ["src/imports/HusSelect.qml"],
    "HusShadow": ["src/imports/HusShadow.qml"],
    "HusSlider": ["src/imports/HusSlider.qml"],
    "HusSpace": ["src/imports/HusSpace.qml"],
    "HusSpin": ["src/imports/HusSpin.qml"],
    "HusSwitch": ["src/imports/HusSwitch.qml"],
    "HusSwitchEffect": ["src/imports/HusSwitchEffect.qml"],
    "HusSegmented": ["src/imports/HusSegmented.qml"],
    "HusTableView": ["src/imports/HusTableView.qml"],
    "HusTabView": ["src/imports/HusTabView.qml"],
    "HusTag": ["src/imports/HusTag.qml"],
    "HusText": ["src/imports/HusText.qml"],
    "HusTextArea": ["src/imports/HusTextArea.qml"],
    "HusTimeline": ["src/imports/HusTimeline.qml"],
    "HusToolTip": ["src/imports/HusToolTip.qml"],
    "HusTourFocus": ["src/imports/HusTourFocus.qml"],
    "HusTourStep": ["src/imports/HusTourStep.qml"],
    "HusTreeView": ["src/imports/HusTreeView.qml"],
    "HusTransfer": ["src/imports/HusTransfer.qml"],
    "HusWindow": ["src/imports/HusWindow.qml"],
}


def extract_component_name(qml_file_path: Path) -> str:
    """从QML文件路径提取组件名称

    Args:
        qml_file_path: QML文件路径，格式为 ...Examples/Category/ExpComponentName.qml

    Returns:
        组件名称，如HusComponentName；如果无法提取则返回空字符串
    """
    filename = qml_file_path.stem
    if filename.startswith("Exp"):
        return "Hus" + filename[3:]
    return ""


def extract_category(file_path: str) -> str:
    """从文件路径中提取组件分类

    Args:
        file_path: 文件路径，格式为 gallery/qml/Examples/Category/ExpComponent.qml

    Returns:
        分类名称，如DataDisplay、Feedback等
    """
    for separator in ["/", "\\"]:
        parts = file_path.split(separator)
        try:
            examples_idx = parts.index("Examples")
            if examples_idx + 1 < len(parts):
                return parts[examples_idx + 1]
        except ValueError:
            continue
    return "Unknown"


def extract_docs_from_qml(qml_file_path: Path, project_root: Path) -> Dict[str, Any]:
    """
    从单个 QML 文件中提取文档信息

    Args:
        qml_file_path: QML 文件路径

    Returns:
        包含文档信息的字典
    """
    with open(qml_file_path, "r", encoding="utf-8") as f:
        content = f.read()


    doc_description = ""



    doc_desc_start = content.find("DocDescription")
    if doc_desc_start != -1:

        desc_start = content.find("desc: qsTr(`", doc_desc_start)
        if desc_start != -1:

            backtick_start = content.find("`", desc_start) + 1
            if backtick_start > 0:


                in_escape = False
                pos = backtick_start
                while pos < len(content):
                    if content[pos] == "\\" and not in_escape:

                        in_escape = True
                    elif content[pos] == "`" and not in_escape:


                        if (
                            pos + 2 < len(content)
                            and content[pos + 1] == "`"
                            and content[pos + 2] == "`"
                        ):

                            pos += 3
                        else:

                            backtick_end = pos
                            doc_description = content[
                                backtick_start:backtick_end
                            ].strip()
                            break
                    else:
                        in_escape = False
                    pos += 1


    if not doc_description:

        doc_description_match = re.search(
            r"DocDescription\s*\{[^}]*desc:\s*qsTr\(`([^`]*(?:`(?!``)[^`]*)*)`",
            content,
            re.DOTALL,
        )
        if doc_description_match:
            doc_description = doc_description_match.group(1).strip()


    if not doc_description:
        doc_description_match = re.search(
            r"DocDescription\s*\{[^}]*desc:\s*qsTr\(\s*`([^`]+)`\s*\)",
            content,
            re.DOTALL,
        )
        if doc_description_match:
            doc_description = doc_description_match.group(1).strip()


    if not doc_description:
        desc_start = content.find("desc: qsTr(`")
        if desc_start != -1:
            desc_start = content.find("`", desc_start) + 1
            if desc_start > 0:
                desc_end = content.find("`)`", desc_start)
                if desc_end != -1:
                    doc_description = content[desc_start:desc_end].strip()


    code_boxes = []



    codebox_start = 0
    while True:
        codebox_start = content.find("CodeBox", codebox_start)
        if codebox_start == -1:
            break


        brace_start = content.find("{", codebox_start)
        if brace_start == -1:
            break


        brace_count = 1
        pos = brace_start + 1
        while pos < len(content) and brace_count > 0:
            if content[pos] == "{":
                brace_count += 1
            elif content[pos] == "}":
                brace_count -= 1
            pos += 1

        if brace_count == 0:
            codebox_content = content[brace_start + 1 : pos - 1]



            desc_start_str = "desc: qsTr(`"
            desc_start_pos = codebox_content.find(desc_start_str)
            if desc_start_pos != -1:

                search_start = desc_start_pos + len(desc_start_str)

                closing_seq = "`)"
                closing_pos = codebox_content.find(closing_seq, search_start)
                if closing_pos != -1:

                    desc = codebox_content[search_start:closing_pos].strip()
                else:
                    desc = ""
            else:
                desc = ""



            code_match_pos = re.search(r"code:\s*`", codebox_content)
            if code_match_pos:
                code_start = code_match_pos.end()

                remaining_content = codebox_content[code_start:]


                next_field_match = re.search(
                    r"\s+(?:desc|descTitle|exampleDelegate):\s*", remaining_content
                )
                if next_field_match:
                    code = remaining_content[: next_field_match.start()].rstrip("` ")
                else:


                    in_escape = False
                    pos = 0
                    while pos < len(remaining_content):
                        if remaining_content[pos] == "\\" and not in_escape:

                            in_escape = True
                        elif remaining_content[pos] == "`" and not in_escape:


                            if (
                                pos + 2 < len(remaining_content)
                                and remaining_content[pos + 1] == "`"
                                and remaining_content[pos + 2] == "`"
                            ):

                                pos += 3
                            else:

                                code = remaining_content[:pos]
                                break
                        else:
                            in_escape = False
                        pos += 1
                    else:

                        code = remaining_content


                code = code.rstrip("`").strip()
            else:

                code_match = re.search(
                    r"code:\s*`([^`]*(?:`(?!``)[^`]*)*)`", codebox_content, re.DOTALL
                )
                code = code_match.group(1).strip() if code_match else ""



            title_match = re.search(
                r"descTitle:\s*qsTr\(`([^`]+)`\)", codebox_content, re.DOTALL
            )
            if not title_match:

                title_match = re.search(
                    r"descTitle:\s*qsTr\('([^']+)'\)", codebox_content, re.DOTALL
                )
            title = title_match.group(1).strip() if title_match else ""

            if desc and code:
                code_boxes.append({"title": title, "description": desc, "code": code})

        codebox_start = pos


    component_name = extract_component_name(qml_file_path)
    sources = sources_table.get(component_name, [])


    rel_path = qml_file_path.relative_to(project_root).as_posix()

    return {
        "name": component_name,
        "doc": doc_description,
        "docPath": rel_path,
        "category": extract_category(rel_path),
        "examples": code_boxes,
        "sources": sources,
    }


def extract_all_docs(examples_dir: Path, project_root: Path) -> List[Dict[str, Any]]:
    """从examples_dir目录下的所有QML文件中提取文档信息

    Returns:
        包含所有文档信息的列表
    """
    return [
        extract_docs_from_qml(qml_file, project_root)
        for qml_file in examples_dir.rglob("*.qml")
    ]


def clean_escape_sequences(text: str, preserve_newlines: bool = False) -> str:
    """清理文本中的转义序列

    Args:
        text: 需要清理的文本
        preserve_newlines: 是否保留\\n为字面量（代码块场景使用True）

    Returns:
        清理后的文本
    """
    if not text:
        return text

    text = text.replace("\\`\\`", "``")
    text = text.replace("\\`", "`")
    text = text.replace("\\t", "\t")
    text = text.replace('\\"', '"')
    text = text.replace("\\'", "'")
    text = text.replace("\\\\", "\\")

    if not preserve_newlines:
        text = text.replace("\\n", "\n")

    return text


def save_docs_to_json(docs: List[Dict[str, Any]], output_path: Path) -> None:
    """将文档信息保存为JSON文件

    Args:
        docs: 文档信息列表
        output_path: 输出文件路径
    """
    for doc in docs:
        if doc.get("doc"):
            docString = clean_escape_sequences(doc["doc"])
            doc["doc"] = docString
            doc["title"] = docString.splitlines()[0].replace("#", "").strip()
            
        if not doc.get("title"):
            doc["title"] = doc["name"]

        for example in doc.get("examples", []):
            if example.get("description"):
                example["description"] = clean_escape_sequences(example["description"])
            if example.get("code"):
                example["code"] = clean_escape_sequences(
                    example["code"], preserve_newlines=True
                )
            if example.get("title"):
                example["title"] = clean_escape_sequences(example["title"])

    output_path.parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(docs, f, ensure_ascii=False, indent=2)
