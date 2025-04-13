#!/bin/bash

clear  # ✅ 실행 시 터미널 화면 정리

# 📍 구분선
divider="────────────────────────────────────────────"

# 🛠 Git 설정 자동화
echo ""
echo -e "${CYAN}🛠 Git 기본 설정을 점검하고 자동으로 적용합니다...${NC}"

# 1. 줄바꿈 설정
autocrlf_setting=$(git config --global core.autocrlf)
if [[ "$autocrlf_setting" != "input" ]]; then
    echo -e "${YELLOW}🔧 core.autocrlf 설정이 '$autocrlf_setting' → input으로 변경됩니다${NC}"
    git config --global core.autocrlf input
else
    echo -e "${GREEN}✅ 줄바꿈 설정은 이미 적절합니다 (input)${NC}"
fi

# 2. 한글 파일명 설정
quotepath_setting=$(git config --global core.quotepath)
if [[ "$quotepath_setting" != "false" ]]; then
    echo -e "${YELLOW}🔧 core.quotepath 설정이 '$quotepath_setting' → false로 변경됩니다${NC}"
    git config --global core.quotepath false
else
    echo -e "${GREEN}✅ 한글 파일명 설정도 OK (false)${NC}"
fi

# 3. 사용자 정보 설정
user_name=$(git config --global user.name)
user_email=$(git config --global user.email)

if [[ -z "$user_name" || -z "$user_email" ]]; then
    echo -e "${RED}⚠️ Git 사용자 정보가 설정되어 있지 않아요.${NC}"
    read -p "👤 이름을 입력하세요: " input_name
    read -p "📧 이메일을 입력하세요: " input_email
    git config --global user.name "$input_name"
    git config --global user.email "$input_email"
    echo -e "${GREEN}✅ 사용자 정보가 설정되었습니다: $input_name <$input_email>${NC}"
else
    echo -e "${GREEN}✅ 사용자 정보: $user_name <$user_email>${NC}"
fi

echo "$divider"
echo -e "${CYAN}🛠 Git 기본 설정이 완료되었습니다!${NC}"

clear

# 📦 Git 자동 커밋 & 푸시 스크립트
# 🎨 색상 정의
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
MAGENTA='\033[1;35m'
CYAN='\033[1;36m'
NC='\033[0m'

# 📦 출력 도우미
print_msg() {
    echo -e "${1}${2}${NC}"
}

# ❗ 에러 안내 박스
handle_error() {
    print_msg "$RED" "❌ $1"
    echo -e "${MAGENTA}$divider${NC}"
    echo "$2"
    echo -e "${MAGENTA}$divider${NC}"
}

# 💡 친절한 해결 안내
show_solution() {
    print_msg "$YELLOW" "📢 문제: $1"
    print_msg "$CYAN" "💡 해결 방법:"
    shift
    for line in "$@"; do
        echo "$line"
    done
}

# ✨ 시작 안내
print_msg "$CYAN" "✨ Git 자동 커밋 & 푸시 시작합니다 ✨"
echo "$divider"

# 🎯 Git 설정 상태 점검
autocrlf_setting=$(git config --get core.autocrlf)
quotepath_setting=$(git config --get core.quotepath)

if [[ "$autocrlf_setting" != "input" ]]; then
    echo -e "${YELLOW}⚠️ 현재 Git 설정이 'autocrlf=$autocrlf_setting' 입니다.${NC}"
    echo -e "${CYAN}👉 줄바꿈 경고(LF/CRLF)를 방지하려면 아래 명령어를 입력하세요:${NC}"
    echo -e "   ${GREEN}git config --global core.autocrlf input${NC}"
    echo ""
fi

if [[ "$quotepath_setting" != "false" ]]; then
    echo -e "${YELLOW}⚠️ Git이 한글 파일명을 깨진 문자로 표시할 수 있어요.${NC}"
    echo -e "${CYAN}👉 아래 명령어를 입력하면 한글 파일명을 정상 출력할 수 있어요:${NC}"
    echo -e "   ${GREEN}git config --global core.quotepath false${NC}"
    echo ""
fi

# 🕰 현재 시간 (KST)
current_time=$(TZ=Asia/Seoul date "+%Y-%m-%d %H:%M")

# 🌿 현재 브랜치
branch=$(git rev-parse --abbrev-ref HEAD)

# 🖥 OS 정보
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    os_type="Linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    os_type="macOS"
elif [[ "$OSTYPE" == "cygwin" || "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    os_type="Windows"
else
    os_type="Unknown OS"
fi

# 📌 Git 디렉토리 확인
if ! git rev-parse --is-inside-work-tree &> /dev/null; then
    print_msg "$RED" "❌ 현재 디렉토리에 Git 저장소(.git)가 없어요!"
    print_msg "$YELLOW" "👉 이 디렉토리는 Git 프로젝트가 아니에요. 아래 중 하나를 시도해보세요:"
    echo -e "   1. 새 Git 저장소 만들기: ${CYAN}git init${NC}"
    echo -e "   2. 기존 프로젝트 복제하기: ${CYAN}git clone <URL>${NC}"
    echo -e "   ❗ 이 스크립트는 Git 저장소 안에서만 작동해요."
    exit 1
fi

# 🔍 변경 사항 확인
if [ -z "$(git status -s)" ]; then
    print_msg "$GREEN" "✅ 변경된 파일이 없어요. 깔끔하네요!"
    exit 0
fi

# ⚠️ 병합 충돌 여부 확인
if git ls-files -u | grep . &> /dev/null; then
    print_msg "$RED" "⚠️ 병합 충돌이 감지되었어요!"
    show_solution "현재 파일 충돌 상태입니다." \
        "1️⃣ 충돌 파일을 수정해 주세요." \
        "2️⃣ 수정 후 ${CYAN}git add 파일명${NC} 으로 스테이징하세요." \
        "3️⃣ 그런 다음 이 스크립트를 다시 실행하면 돼요."
    exit 1
fi

# 👤 사용자 정보 설정 확인
if ! git config user.name &> /dev/null || ! git config user.email &> /dev/null; then
    print_msg "$RED" "⚠️ Git 사용자 정보가 설정되어 있지 않아요!"
    print_msg "$YELLOW" "👉 커밋을 하려면 본인의 이름과 이메일을 등록해야 해요."
    echo -e "   1. 이름 설정:    ${CYAN}git config --global user.name \"홍길동\"${NC}"
    echo -e "   2. 이메일 설정:  ${CYAN}git config --global user.email \"you@example.com\"${NC}"
    echo -e "   🌟 설정은 한 번만 하면 이후엔 자동 적용돼요!"
    exit 1
fi

# 🔒 lock 파일 확인
if [ -f ".git/index.lock" ]; then
    print_msg "$RED" "⚠️ lock 파일이 남아있어요!"
    show_solution "다른 Git 작업이 비정상 종료되었을 수 있어요." \
        "1️⃣ 잠긴 파일 삭제: ${CYAN}rm -f .git/index.lock${NC}" \
        "2️⃣ 다시 스크립트를 실행해 주세요."
    exit 1
fi

# 📋 변경된 파일 목록
print_msg "$BLUE" "🔍 변경된 파일 목록:"
git status -s
echo ""

# 📝 커밋 메시지 입력 (직접 입력 유도)
read -p "✏️ 커밋 메시지를 입력하세요 (엔터 누르면 자동 메시지 사용): " user_commit

# 자동 메시지 생성
default_message="🚀 [$branch] automatic commit | $current_time (KST) | $os_type"

# 입력 여부에 따라 최종 메시지 설정
if [ -z "$user_commit" ]; then
    commit_message="$default_message"
    print_msg "$YELLOW" "ℹ️ 커밋 메시지를 입력하지 않아 자동 메시지를 사용합니다."
else
    commit_message="$user_commit"
    print_msg "$GREEN" "📝 커밋 메시지: $commit_message"
fi
# ➕ git add
git add .

# ✅ 커밋 실행
commit_output=$(git commit -m "$commit_message" 2>&1)
commit_status=$?

if [ $commit_status -ne 0 ]; then
    handle_error "커밋 중 오류가 발생했어요!" "$commit_output"

    if echo "$commit_output" | grep -q "Permission denied"; then
        show_solution "파일 시스템 권한 문제" \
            "1️⃣ 파일이 현재 사용자 계정 소유인지 확인: ${CYAN}ls -l${NC}" \
            "2️⃣ 필요시 소유권 변경: ${CYAN}sudo chown -R 사용자명 .${NC}" \
            "3️⃣ 다시 실행해 주세요."
    elif echo "$commit_output" | grep -q "unable to write new index file"; then
        show_solution "디스크 쓰기 오류" \
            "1️⃣ 디스크 용량 확인: ${CYAN}df -h${NC}" \
            "2️⃣ 권한 문제일 수도 있으니 권한 확인"
    elif echo "$commit_output" | grep -q "Unable to create '.git/index.lock'"; then
        show_solution "다른 Git 작업이 충돌 중이에요." \
            "1️⃣ lock 파일 삭제: ${CYAN}rm -f .git/index.lock${NC}" \
            "2️⃣ 이후 다시 시도해 주세요."
    else
        print_msg "$YELLOW" "📢 예상치 못한 커밋 오류입니다. 위 로그를 확인해 주세요."
    fi
    exit 1
fi

# 🌐 원격 저장소 확인
remote_url=$(git config --get remote.origin.url)
if [ -z "$remote_url" ]; then
    print_msg "$RED" "❌ 원격 저장소(remote.origin.url)가 설정되어 있지 않아요!"
    show_solution "Push를 하려면 원격 저장소 주소가 필요해요." \
        "1️⃣ 원격 저장소 추가: ${CYAN}git remote add origin <URL>${NC}" \
        "2️⃣ 또는 설정 확인: ${CYAN}git remote -v${NC}"
    exit 1
fi

# 🌐 원격 저장소 접근 테스트
if ! git ls-remote "$remote_url" &> /dev/null; then
    print_msg "$RED" "❌ 원격 저장소에 연결할 수 없어요."
    show_solution "네트워크 또는 인증 문제일 수 있어요." \
        "1️⃣ 인터넷 연결 확인" \
        "2️⃣ remote URL 확인: ${CYAN}git remote -v${NC}" \
        "3️⃣ 인증 토큰 또는 SSH 키 확인"
    exit 1
fi

# 🚀 Push 실행
push_output=$(git push 2>&1)
push_status=$?

if [ $push_status -ne 0 ]; then
    handle_error "푸시 도중 문제가 발생했어요!" "$push_output"

    if echo "$push_output" | grep -qi "permission denied"; then
        show_solution "원격 저장소에 푸시 권한이 없어요." \
            "1️⃣ 계정 권한 확인" \
            "2️⃣ SSH 키 또는 Personal Access Token 설정 확인"
    elif echo "$push_output" | grep -qi "Could not resolve host"; then
        show_solution "원격 저장소 주소를 찾을 수 없어요." \
            "1️⃣ 인터넷 연결 확인" \
            "2️⃣ DNS 설정 또는 오타 확인"
    elif echo "$push_output" | grep -qi "failed to connect to"; then
        show_solution "네트워크 연결에 실패했어요." \
            "1️⃣ VPN/방화벽 확인" \
            "2️⃣ Git 서버 접근 차단 여부 확인"
    else
        print_msg "$YELLOW" "📢 예상치 못한 푸시 오류입니다. 위 로그를 참고해 주세요."
    fi
    exit 1
fi

# 🎉 마무리 메시지
echo ""
print_msg "$GREEN" "✅ 모든 작업이 정상적으로 완료되었습니다!"
print_msg "$CYAN" "📦 커밋 메시지: $commit_message"
print_msg "$GREEN" "🎯 Git 서버에 잘 반영되었어요. 수고하셨습니다! ☕"
echo ""
