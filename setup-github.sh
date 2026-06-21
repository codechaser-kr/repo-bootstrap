#!/usr/bin/env bash
set -e

REPO="codechaser-kr/repo-bootstrap"
BRANCH="main"
BASE_URL="https://raw.githubusercontent.com/${REPO}/${BRANCH}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ISSUE_TEMPLATES=("feature_template" "fix_template" "improvement_template" "decision_template")

GITHUB_DIR="./.github"
ISSUE_TEMPLATE_DIR="./.github/ISSUE_TEMPLATE"
PR_TEMPLATE_PATH="./.github/pull_request_template.md"
AGENTS_PATH="./AGENTS.md"
GEMINI_DIR="./.gemini"
GEMINI_STYLEGUIDE_PATH="./.gemini/styleguide.md"
CODEX_REVIEW_SOURCE_PATH=".github/apps/codex-code-review.md"
GEMINI_STYLEGUIDE_SOURCE_PATH=".github/apps/gemini-code-review.md"
TEMP_FILES=()

# ===== 유틸 =====
register_temp_file() {
  TEMP_FILES+=("$1")
}

cleanup_temp_files() {
  local temp_file

  for temp_file in "${TEMP_FILES[@]}"; do
    if [ -n "$temp_file" ]; then
      rm -f "$temp_file"
    fi
  done
}

trap cleanup_temp_files EXIT
trap 'cleanup_temp_files; exit 129' HUP
trap 'cleanup_temp_files; exit 130' INT
trap 'cleanup_temp_files; exit 143' TERM

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
  local temp_file

  temp_file="$(mktemp "${dest}.tmp.XXXXXX")"
  register_temp_file "$temp_file"

  if [ -f "$local_file" ] && { [ ! -e "$dest" ] || [ ! "$local_file" -ef "$dest" ]; }; then
    cp -f "$local_file" "$temp_file"
  else
    download "${BASE_URL}/${source_path}" "$temp_file"
  fi

  mv -f "$temp_file" "$dest"
}

load_source_content() {
  local source_path="$1"
  local local_file="${SCRIPT_DIR}/${source_path}"
  local temp_file

  if [ -f "$local_file" ]; then
    cat "$local_file"
    return
  fi

  temp_file="$(mktemp "${TMPDIR:-/tmp}/repo-bootstrap.tmp.XXXXXX")"
  register_temp_file "$temp_file"
  download "${BASE_URL}/${source_path}" "$temp_file"
  cat "$temp_file"
  rm -f "$temp_file"
}

extract_markdown_heading() {
  local content="$1"
  local source_path="$2"
  local heading

  heading="$(printf "%s\n" "$content" | awk 'NR == 1 { print; exit }')"
  if ! printf "%s\n" "$heading" | grep -Eq '^#+[[:space:]]+'; then
    echo "❌ 소스 파일 첫 줄은 Markdown heading이어야 합니다: ${source_path}" >&2
    exit 1
  fi

  printf "%s\n" "$heading"
}

upsert_markdown_section() {
  local dest="$1"
  local heading="$2"
  local block="$3"
  local temp_file
  local block_file
  local heading_level

  if [ -e "$dest" ] && [ ! -f "$dest" ]; then
    echo "❌ 파일이어야 하는데 파일이 아닙니다: ${dest}"
    exit 1
  fi

  # Keep this guard even though validate_target_paths checks current callers.
  # upsert_markdown_section should remain safe if reused for other paths later.
  if [ -L "$dest" ]; then
    echo "❌ 심볼릭 링크 경로에는 설치하지 않습니다: ${dest}"
    exit 1
  fi

  heading_level="$(printf "%s\n" "$heading" | awk '
    match($0, /^#+/) {
      char = substr($0, RLENGTH + 1, 1)
      if (char == "" || char == " " || char == sprintf("%c", 9)) {
        print RLENGTH
      }
    }
  ')"
  if [ -z "$heading_level" ]; then
    echo "❌ Markdown heading이 필요합니다: ${heading}"
    exit 1
  fi

  temp_file="$(mktemp "${dest}.tmp.XXXXXX")"
  register_temp_file "$temp_file"

  if [ -f "$dest" ] && grep -Fxq "$heading" "$dest"; then
    block_file="$(mktemp "${dest}.block.tmp.XXXXXX")"
    register_temp_file "$block_file"
    printf "%s\n" "$block" > "$block_file"

    awk -v heading="$heading" -v level="$heading_level" -v bf="$block_file" '
      /^[[:space:]]*```/ { in_code = !in_code }
      function print_block() {
        while ((getline line < bf) > 0) {
          print line
        }
        close(bf)
      }
      $0 == heading {
        print_block()
        skipping = 1
        next
      }
      skipping && !in_code && match($0, /^#+/) {
        char = substr($0, RLENGTH + 1, 1)
        if (char == "" || char == " " || char == sprintf("%c", 9)) {
          current_level = RLENGTH
          if (current_level <= level) {
            skipping = 0
            print
          }
          next
        }
      }
      skipping { next }
      !skipping { print }
    ' "$dest" > "$temp_file"

    rm -f "$block_file"
  elif [ -s "$dest" ]; then
    cp "$dest" "$temp_file"
    printf "\n\n%s\n" "$block" >> "$temp_file"
  else
    printf "%s\n" "$block" > "$temp_file"
  fi

  mv -f "$temp_file" "$dest"
}

install_ai_review_settings() {
  local codex_heading
  local gemini_heading
  local codex_block
  local gemini_block

  codex_block="$(load_source_content "$CODEX_REVIEW_SOURCE_PATH")"
  gemini_block="$(load_source_content "$GEMINI_STYLEGUIDE_SOURCE_PATH")"
  codex_heading="$(extract_markdown_heading "$codex_block" "$CODEX_REVIEW_SOURCE_PATH")"
  gemini_heading="$(extract_markdown_heading "$gemini_block" "$GEMINI_STYLEGUIDE_SOURCE_PATH")"

  echo "→ 설치 중: ChatGPT Codex Connector 리뷰 지침 → ${AGENTS_PATH}"
  upsert_markdown_section "$AGENTS_PATH" "$codex_heading" "$codex_block"

  mkdir -p "$GEMINI_DIR"
  echo "→ 설치 중: Gemini Code Assist 리뷰 스타일 가이드 → ${GEMINI_STYLEGUIDE_PATH}"
  upsert_markdown_section "$GEMINI_STYLEGUIDE_PATH" "$gemini_heading" "$gemini_block"
}

validate_target_paths() {
  if [ -e "$GITHUB_DIR" ] && [ ! -d "$GITHUB_DIR" ]; then
    echo "❌ 디렉터리가 아닙니다: ${GITHUB_DIR}"
    exit 1
  fi

  if [ -L "$GITHUB_DIR" ] || [ -L "$ISSUE_TEMPLATE_DIR" ] || [ -L "$PR_TEMPLATE_PATH" ] || [ -L "$AGENTS_PATH" ] || [ -L "$GEMINI_DIR" ] || [ -L "$GEMINI_STYLEGUIDE_PATH" ]; then
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

  if [ -d "$AGENTS_PATH" ]; then
    echo "❌ 파일이어야 하는데 디렉터리입니다: ${AGENTS_PATH}"
    exit 1
  fi

  if [ -e "$GEMINI_DIR" ] && [ ! -d "$GEMINI_DIR" ]; then
    echo "❌ 디렉터리가 아닙니다: ${GEMINI_DIR}"
    exit 1
  fi

  if [ -d "$GEMINI_STYLEGUIDE_PATH" ]; then
    echo "❌ 파일이어야 하는데 디렉터리입니다: ${GEMINI_STYLEGUIDE_PATH}"
    exit 1
  fi
}

# ===== 실행 =====

if [ ! -d ".git" ]; then
  echo "❌ Git 저장소가 아닙니다. 저장소 루트에서 실행해주세요."
  exit 1
fi

echo "🚀 GitHub 템플릿 및 AI 리뷰 설정 설치 시작"
echo "📁 이슈 템플릿 경로: ${ISSUE_TEMPLATE_DIR}"
echo "📁 PR 템플릿 경로: ${PR_TEMPLATE_PATH}"
echo "📁 Codex 리뷰 지침 경로: ${AGENTS_PATH}"
echo "📁 Gemini 리뷰 스타일 가이드 경로: ${GEMINI_STYLEGUIDE_PATH}"
echo ""

validate_target_paths
mkdir -p "$ISSUE_TEMPLATE_DIR"

for template in "${ISSUE_TEMPLATES[@]}"; do
  echo "→ 설치 중: ${template}.md → ${ISSUE_TEMPLATE_DIR}"
  install_file ".github/ISSUE_TEMPLATE/${template}.md" "${ISSUE_TEMPLATE_DIR}/${template}.md"
done

echo "→ 설치 중: pull_request_template.md → ${PR_TEMPLATE_PATH}"
install_file ".github/pull_request_template.md" "$PR_TEMPLATE_PATH"

install_ai_review_settings

echo ""
echo "✅ GitHub 템플릿 및 AI 리뷰 설정 설치 완료!"
echo ""
echo "👉 설치된 이슈 템플릿:"
echo "   - 기능 개발 제안 (feature_template.md)"
echo "   - 기능 개선 제안 (improvement_template.md)"
echo "   - 결함 해결 (fix_template.md)"
echo "   - 정책 검토 (decision_template.md)"
echo "👉 설치된 PR 템플릿:"
echo "   - PR 템플릿 (pull_request_template.md)"
echo "👉 설치된 AI 리뷰 설정:"
echo "   - ChatGPT Codex Connector 리뷰 지침 (AGENTS.md)"
echo "   - Gemini Code Assist 리뷰 스타일 가이드 (.gemini/styleguide.md)"
echo ""
echo "💡 변경사항을 커밋하고 푸시하면 GitHub 이슈, PR 템플릿, AI 리뷰 지침을 사용할 수 있습니다."
