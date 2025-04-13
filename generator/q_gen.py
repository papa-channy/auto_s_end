from scripts.base_import import add_root_path
add_root_path()
from LLM.llm_selector import call_llm

import os
import json
from tools.paths import (
    NEW_Q_PDS_PATH, NEW_Q_SQL_PATH, NEW_Q_VIZ_PATH,
    P_PDS_PATH, P_SQL_PATH, P_VIZ_PATH
)
# from LLM.llama3_groq import call_llm  # 현재 Groq 전용

TOOL_PATH_MAP = {
    "pds": {
        "prompt": P_PDS_PATH,
        "save": NEW_Q_PDS_PATH
    },
    "sql": {
        "prompt": P_SQL_PATH,
        "save": NEW_Q_SQL_PATH
    },
    "viz": {
        "prompt": P_VIZ_PATH,
        "save": NEW_Q_VIZ_PATH
    }
}

def generate_all_questions(dataset_list, tool_list, difficulty_map, llm_name, count):
    """
    도구별 프롬프트를 LLM에 넘겨 문제 생성, new_q_{tool}.txt에 저장
    """
    for tool in tool_list:
        paths = TOOL_PATH_MAP.get(tool)
        if not paths:
            print(f"❗ 지원하지 않는 도구: {tool}")
            continue

        prompt_path = paths["prompt"]
        save_path = paths["save"]

        # 🧠 프롬프트 템플릿 로딩
        with open(prompt_path, "r", encoding="utf-8") as f:
            base_prompt = f.read()

        all_q = []

        for dataset in dataset_list:
            for difficulty in difficulty_map[tool]:
                filled_prompt = base_prompt.format(
                    dataset=dataset,
                    difficulty_list=" → ".join(difficulty_map[tool]),
                    count=count
                )

                # ✨ LLM 호출
                response = call_llm(filled_prompt, llm_name, temperature=0.6)

                lines = response.strip().split("\n")

                for line in lines:
                    if "|" not in line or line.count("|") != 4:
                        continue  # ⚠️ 정확한 형식이 아닌 경우 제외

                    try:
                        idx, level, data, category, question = line.split("|", 4)
                        all_q.append({
                            "tool": tool,
                            "dataset": data.strip(),
                            "difficulty": level.strip(),
                            "category": category.strip(),
                            "question": question.strip()
                        })
                    except ValueError:
                        continue

        # 💾 저장
        with open(save_path, "w", encoding="utf-8") as f:
            for q in all_q:
                f.write(json.dumps(q, ensure_ascii=False) + "\n")

        print(f"✅ [{tool}] {len(all_q)}문제 저장 완료")
