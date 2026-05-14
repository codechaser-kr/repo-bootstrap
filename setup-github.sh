#!/usr/bin/env bash
set -e

REPO="codechaser-kr/repo-bootstrap"
BRANCH="main"
BASE_URL="https://raw.githubusercontent.com/${REPO}/${BRANCH}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ISSUE_TEMPLATES=("feature_template" "fix_templatebug" "improvement_template")

GITHUB_DIR="./.github"
ISSUE_TEMPLATE_DIR="./.github/ISSUE_TEMPLATE"
PR_TEMPLATE_PATH="./.github/pull_request_template.md"

# ===== 유틸 =====
download() {
  local url="$1"
  local dest="$2"

  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url" -o "$dest"
  elif command -v wget >/dev/null 2>&1; then
    wget -q "$url" -O "$dest"
  else
    echo "❌ curl 또는 wget이 필요합니다."
    exit 1
  fi
}

install_file() {
  local source_path="$1"
  local dest="$2"
  local local_file="${SCRIPT_DIR}/${source_path}"

  if [ -f "$local_file" ]; then
    cp "$local_file" "$dest"
  else
    download "${BASE_URL}/${source_path}" "$dest"
  fi
}

validate_target_paths() {
  if [ -e "$GITHUB_DIR" ] && [ ! -d "$GITHUB_DIR" ]; then
    echo "❌ 디렉터리가 아닙니다: ${GITHUB_DIR}"
    exit 1
  fi

  if [ -L "$GITHUB_DIR" ] || [ -L "$ISSUE_TEMPLATE_DIR" ] || [ -L "$PR_TEMPLATE_PATH" ]; then
    echo "❌ 심볼릭 링크 경로에는 설치하지 않습니다."
    exit 1
  fi

  if [ -e "$ISSUE_TEMPLATE_DIR" ] && [ ! -d "$ISSUE_TEMPLATE_DIR" ]; then
    echo "❌ 디렉터리가 아닙니다: ${ISSUE_TEMPLATE_DIR}"
    exit 1
  fi

  if [ -d "$PR_TEMPLATE_PATH" ]; then
    echo "❌ 파일이어야 하는데 디렉터리입니다: ${PR_TEMPLATE_PATH}"
    exit 1
  fi
}

# ===== 실행 =====

if [ ! -d ".git" ]; then
  echo "❌ Git 저장소가 아닙니다. 저장소 루트에서 실행해주세요."
  exit 1
fi

echo "🚀 GitHub 템플릿 설치 시작"
echo "📁 이슈 템플릿 경로: ${ISSUE_TEMPLATE_DIR}"
echo "📁 PR 템플릿 경로: ${PR_TEMPLATE_PATH}"
echo ""

validate_target_paths
mkdir -p "$ISSUE_TEMPLATE_DIR"

for template in "${ISSUE_TEMPLATES[@]}"; do
  echo "→ 설치 중: ${template}.md → ${ISSUE_TEMPLATE_DIR}"
  install_file ".github/ISSUE_TEMPLATE/${template}.md" "${ISSUE_TEMPLATE_DIR}/${template}.md"
done

echo "→ 설치 중: pull_request_template.md → ${PR_TEMPLATE_PATH}"
install_file ".github/pull_request_template.md" "$PR_TEMPLATE_PATH"

echo ""
echo "✅ GitHub 템플릿 설치 완료!"
echo ""
echo "👉 설치된 이슈 템플릿:"
echo "   - 기능 개발 제안 (feature_template.md)"
echo "   - 기능 개선 제안 (improvement_template.md)"
echo "   - 결함 해결 (fix_templatebug.md)"
echo "👉 설치된 PR 템플릿:"
echo "   - PR 템플릿 (pull_request_template.md)"
echo ""
echo "💡 변경사항을 커밋하고 푸시하면 GitHub 이슈에서 사용할 수 있습니다."
