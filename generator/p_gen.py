import os
from tools.paths import (
    PROMPT_DIR, RECENT_EX_DIR,
    P_PDS_PATH, P_SQL_PATH, P_VIZ_PATH,
    EX_PDS_PATH, EX_SQL_PATH, EX_VIZ_PATH
)

def load_recent_examples(tool):
    """ recent_ex/{tool}에서 최신 예시 3개 불러오기 """
    path = os.path.join(RECENT_EX_DIR, f"ex_{tool}.txt")
    if not os.path.exists(path):
        return "# (예시 없음)"
    
    with open(path, "r", encoding="utf-8") as f:
        lines = [line.strip() for line in f if line.strip()]
        return "\n".join(lines[-3:]) if lines else "# (예시 없음)"

def format_prompt(tool, dataset_list, difficulty_list, count, examples):
    dataset_line = ", ".join(dataset_list)
    difficulty_line = " → ".join(difficulty_list)

    prompt = f"""아래 조건에 따라 {tool.upper()} 문제를 생성해 주세요.

🟡 조건:
- 데이터셋: {dataset_line}
- 문제 수: {count}문제
- 난이도: {difficulty_line}
- 문제는 반드시 한국어로 작성하세요.

❗ 출력은 반드시 아래 형식을 따르세요:
- 다른 문장, 설명, 힌트, 이모지 등을 절대 추가하지 마세요.
- 번호는 1부터 시작하고, 순서대로 출력하세요.

(출력 형식)
1|중|tips|카테고리|결측값이 있는 행을 제거하세요.
2|상|tips|요약 통계|성별별 평균 팁 금액을 구하세요.
3|최상|tips|시각화|요일별 생존율을 그래프로 나타내세요.

📝 최근 예시:
{examples}
"""
    return prompt

def update_prompt_templates(tool_list, dataset_list, difficulty_map, count):
    """ 도구별 프롬프트 템플릿 자동 생성 """
    for tool in tool_list:
        prompt_path = os.path.join(PROMPT_DIR, f"p_{tool}.txt")
        difficulty_list = difficulty_map.get(tool, [])

        examples = load_recent_examples(tool)
        content = format_prompt(tool, dataset_list, difficulty_list, count, examples)

        with open(prompt_path, "w", encoding="utf-8") as f:
            f.write(content)

        print(f"📄 [{tool}] 프롬프트 템플릿 저장 완료 → {os.path.basename(prompt_path)}")
