import json
import os
from tools.paths import (
    NEW_Q_PDS_PATH, NEW_Q_SQL_PATH, NEW_Q_VIZ_PATH
)

TOOL_PATHS = {
    "pds": NEW_Q_PDS_PATH,
    "sql": NEW_Q_SQL_PATH,
    "viz": NEW_Q_VIZ_PATH
}

def preprocess_questions(tool_list):
    """
    각 도구별 new_q_{tool}.txt 파일을 불러와 통합된 리스트로 반환
    → Notion 업로드 / Notebook 생성 등에 사용
    """
    questions = []

    for tool in tool_list:
        path = TOOL_PATHS.get(tool)
        if not path or not os.path.exists(path):
            print(f"⚠️ {tool} - 파일 없음, 스킵")
            continue

        with open(path, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if line:
                    try:
                        q = json.loads(line)
                        questions.append(q)
                    except json.JSONDecodeError:
                        print(f"❗ JSON 파싱 오류 - {tool}: {line}")

    print(f"✅ 전처리 완료: 총 {len(questions)}문제")
    return questions
