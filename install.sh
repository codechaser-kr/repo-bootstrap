#!/usr/bin/env bash
set -e

# ===== 설정 =====
REPO="codechaser-kr/repo-bootstrap"
BRANCH="main"
BASE_URL="https://raw.githubusercontent.com/${REPO}/${BRANCH}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SKILLS=("branch" "commit" "pr-proposal" "git-hooks")
CLAUDE_SKILLS=("branch" "commit" "pr-proposal" "git-hooks")

CODEX_HUMANIZE_REPO="Squirbie/im-not-ai-codex"
CODEX_HUMANIZE_BRANCH="main"
CLAUDE_HUMANIZE_REPO="epoko77-ai/im-not-ai"
CLAUDE_HUMANIZE_BRANCH="main"
CODE_REVIEW_REPO="awesome-skills/code-review-skill"
CODE_REVIEW_BRANCH="main"
CODE_REVIEW_UPSTREAM_SKILL_NAME="code-review-skill"
CODE_REVIEW_SKILL_NAME="awesome-code-review"
CC_PLUGIN_PACKAGE="cc-plugin-codex"

CODEX_DIR="${HOME}/.codex/skills"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-${HOME}/.claude}"
CLAUDE_SKILLS_DIR="${CLAUDE_DIR}/skills"
CLAUDE_AGENTS_DIR="${CLAUDE_DIR}/agents"
CLAUDE_COMMANDS_DIR="${CLAUDE_DIR}/commands"
CLAUDE_MANIFEST="${CLAUDE_DIR}/.repo-bootstrap-humanize-files"

INSTALL_CODEX=1
INSTALL_CLAUDE=1
INSTALL_CC_PLUGIN=2
CC_PLUGIN_INSTALLED=0
CC_PLUGIN_INSTALL_FAILED=0
TMP_DIR=""
FETCHED_REPO_DIR=""
CODE_REVIEW_SOURCE_DIR=""

print_usage() {
  echo "Usage: install.sh [--codex-only] [--claude-only] [--with-cc-plugin] [--without-cc-plugin]"
  echo ""
  echo "Options:"
  echo "  --codex-only          Codex 스킬과 cc-plugin-codex만 설치합니다."
  echo "  --claude-only         Claude 스킬만 설치합니다. cc-plugin-codex는 설치하지 않습니다."
  echo "  --with-cc-plugin      cc-plugin-codex 설치를 명시합니다. Codex 설치 대상에서는 기본값입니다."
  echo "  --without-cc-plugin   cc-plugin-codex 설치를 제외합니다."
}

# ===== 옵션 처리 =====
for arg in "$@"; do
  case $arg in
    -h|--help)
      print_usage
      exit 0
      ;;
    --codex-only)
      INSTALL_CLAUDE=0
      ;;
    --claude-only)
      INSTALL_CODEX=0
      ;;
    --with-cc-plugin)
      INSTALL_CC_PLUGIN=1
      ;;
    --without-cc-plugin)
      INSTALL_CC_PLUGIN=0
      ;;
    *)
      echo "❌ 알 수 없는 옵션: ${arg}"
      print_usage
      exit 1
      ;;
  esac
done

if [ "$INSTALL_CC_PLUGIN" -eq 2 ]; then
  if [ "$INSTALL_CODEX" -eq 1 ]; then
    INSTALL_CC_PLUGIN=1
  else
    INSTALL_CC_PLUGIN=0
  fi
fi

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

require_command() {
  local name="$1"

  if ! command -v "$name" >/dev/null 2>&1; then
    echo "❌ ${name} 명령이 필요합니다."
    exit 1
  fi
}

prepare_tmp_dir() {
  if [ -z "$TMP_DIR" ]; then
    TMP_DIR="$(mktemp -d)"
    trap 'rm -rf "$TMP_DIR"' EXIT
  fi
}

fetch_repo_archive() {
  local repo="$1"
  local branch="$2"
  local name="$3"
  local archive_path
  local extract_dir

  require_command tar
  prepare_tmp_dir

  archive_path="${TMP_DIR}/${name}.tar.gz"
  extract_dir="${TMP_DIR}/${name}"

  mkdir -p "$extract_dir"
  download "https://github.com/${repo}/archive/refs/heads/${branch}.tar.gz" "$archive_path"
  tar -xzf "$archive_path" -C "$extract_dir" --strip-components=1

  FETCHED_REPO_DIR="$extract_dir"
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

install_local_skill_dir() {
  local target_dir="$1"
  local source_root="$2"
  local name="$3"
  local skill_dir="${target_dir}/${name}"

  mkdir -p "$skill_dir"
  echo "→ 설치 중: ${name} → ${skill_dir}/SKILL.md"
  install_file "${source_root}/${name}/SKILL.md" "${skill_dir}/SKILL.md"
}

replace_dir() {
  local source_dir="$1"
  local target_dir="$2"

  if [ ! -d "$source_dir" ]; then
    echo "❌ 소스 디렉터리를 찾을 수 없습니다: ${source_dir}"
    exit 1
  fi

  rm -rf "$target_dir"
  mkdir -p "$(dirname "$target_dir")"
  cp -R "$source_dir" "$target_dir"
}

rewrite_skill_name() {
  local skill_dir="$1"
  local new_name="$2"
  local skill_file="${skill_dir}/SKILL.md"
  local tmp_file="${skill_file}.tmp"

  if [ ! -f "$skill_file" ]; then
    echo "❌ SKILL.md를 찾을 수 없습니다: ${skill_file}"
    exit 1
  fi

  if ! awk -v new_name="$new_name" '
    BEGIN { in_frontmatter = 0; renamed = 0 }
    { sub(/\r$/, "") }
    NR == 1 && $0 == "---" { in_frontmatter = 1; print; next }
    in_frontmatter && renamed == 0 && $0 ~ /^name:[[:space:]]*/ {
      print "name: " new_name
      renamed = 1
      next
    }
    in_frontmatter && NR > 1 && $0 == "---" { in_frontmatter = 0 }
    { print }
    END { if (renamed == 0) exit 42 }
  ' "$skill_file" > "$tmp_file"; then
    rm -f "$tmp_file"
    echo "❌ SKILL.md name 필드를 변경할 수 없습니다: ${skill_file}"
    exit 1
  fi

  mv "$tmp_file" "$skill_file"
}

find_skill_dir() {
  local repo_dir="$1"
  local skill_name="$2"
  local repo_label="$3"
  local candidate
  local candidates=(
    "${repo_dir}/skills/${skill_name}"
    "${repo_dir}/plugins/im-not-ai/skills/${skill_name}"
    "${repo_dir}/.claude/skills/${skill_name}"
  )

  for candidate in "${candidates[@]}"; do
    if [ -f "${candidate}/SKILL.md" ]; then
      echo "$candidate"
      return 0
    fi
  done

  if [ -f "${repo_dir}/SKILL.md" ] && grep -Eq "^name:[[:space:]]*[\"']?${skill_name}[\"']?[[:space:]]*$" "${repo_dir}/SKILL.md"; then
    echo "$repo_dir"
    return 0
  fi

  echo "❌ ${skill_name} 소스 디렉터리를 찾을 수 없습니다." >&2
  echo "   repo: ${repo_label}" >&2
  echo "   추출 위치: ${repo_dir}" >&2
  echo "   확인한 후보:" >&2
  for candidate in "${candidates[@]}"; do
    echo "   - ${candidate}" >&2
  done
  echo "   - ${repo_dir} (SKILL.md name이 ${skill_name}인 경우)" >&2
  return 1
}

remove_manifest_entries() {
  if [ ! -f "$CLAUDE_MANIFEST" ]; then
    return
  fi

  while IFS= read -r relative_path; do
    if [ -n "$relative_path" ]; then
      rm -f "${CLAUDE_DIR}/${relative_path}"
    fi
  done < "$CLAUDE_MANIFEST"
}

copy_managed_files() {
  local source_dir="$1"
  local target_dir="$2"
  local manifest_prefix="$3"
  local manifest_tmp="$4"
  local source_file
  local file_name

  if [ ! -d "$source_dir" ]; then
    return
  fi

  mkdir -p "$target_dir"

  for source_file in "$source_dir"/* "$source_dir"/.[!.]* "$source_dir"/..?*; do
    if [ -f "$source_file" ]; then
      file_name="$(basename "$source_file")"
      cp "$source_file" "${target_dir}/${file_name}"
      echo "${manifest_prefix}/${file_name}" >> "$manifest_tmp"
    fi
  done
}

install_codex_skills() {
  local target_dir="$1"
  shift

  for name in "$@"; do
    install_local_skill_dir "$target_dir" "codex-skills" "$name"
  done
}

install_claude_skills() {
  local target_dir="$1"
  shift

  for name in "$@"; do
    install_local_skill_dir "$target_dir" "claude-skills" "$name"
  done
}

install_codex_humanize_korean() {
  local repo_dir
  local source_dir

  echo "→ humanize-korean 설치 중: ${CODEX_HUMANIZE_REPO}@${CODEX_HUMANIZE_BRANCH}"
  fetch_repo_archive "$CODEX_HUMANIZE_REPO" "$CODEX_HUMANIZE_BRANCH" "codex-humanize"
  repo_dir="$FETCHED_REPO_DIR"
  if ! source_dir="$(find_skill_dir "$repo_dir" "humanize-korean" "${CODEX_HUMANIZE_REPO}@${CODEX_HUMANIZE_BRANCH}")"; then
    exit 1
  fi
  replace_dir "$source_dir" "${CODEX_DIR}/humanize-korean"
}

install_claude_humanize_korean() {
  local repo_dir
  local manifest_tmp
  local source_dir

  echo "→ humanize-korean 설치 중: ${CLAUDE_HUMANIZE_REPO}@${CLAUDE_HUMANIZE_BRANCH}"
  fetch_repo_archive "$CLAUDE_HUMANIZE_REPO" "$CLAUDE_HUMANIZE_BRANCH" "claude-humanize"
  repo_dir="$FETCHED_REPO_DIR"
  if ! source_dir="$(find_skill_dir "$repo_dir" "humanize-korean" "${CLAUDE_HUMANIZE_REPO}@${CLAUDE_HUMANIZE_BRANCH}")"; then
    exit 1
  fi
  replace_dir "$source_dir" "${CLAUDE_SKILLS_DIR}/humanize-korean"

  remove_manifest_entries
  manifest_tmp="${TMP_DIR}/claude-humanize-files.txt"
  : > "$manifest_tmp"
  copy_managed_files "${repo_dir}/.claude/agents" "$CLAUDE_AGENTS_DIR" "agents" "$manifest_tmp"
  copy_managed_files "${repo_dir}/.claude/commands" "$CLAUDE_COMMANDS_DIR" "commands" "$manifest_tmp"
  mkdir -p "$(dirname "$CLAUDE_MANIFEST")"
  cp "$manifest_tmp" "$CLAUDE_MANIFEST"
}

prepare_code_review_skill_source() {
  local repo_dir
  local source_dir

  if [ -n "$CODE_REVIEW_SOURCE_DIR" ]; then
    return
  fi

  echo "→ ${CODE_REVIEW_SKILL_NAME} 소스 다운로드 중: ${CODE_REVIEW_REPO}@${CODE_REVIEW_BRANCH}"
  fetch_repo_archive "$CODE_REVIEW_REPO" "$CODE_REVIEW_BRANCH" "code-review-skill"
  repo_dir="$FETCHED_REPO_DIR"
  if ! source_dir="$(find_skill_dir "$repo_dir" "$CODE_REVIEW_UPSTREAM_SKILL_NAME" "${CODE_REVIEW_REPO}@${CODE_REVIEW_BRANCH}")"; then
    exit 1
  fi
  CODE_REVIEW_SOURCE_DIR="$source_dir"
}

install_remote_code_review_skill() {
  local target_dir="$1"
  local source_dir
  local target_skill_dir="${target_dir}/${CODE_REVIEW_SKILL_NAME}"

  prepare_code_review_skill_source
  source_dir="$CODE_REVIEW_SOURCE_DIR"
  echo "→ ${CODE_REVIEW_SKILL_NAME} 설치 중: ${target_skill_dir}"
  replace_dir "$source_dir" "$target_skill_dir"
  rewrite_skill_name "$target_skill_dir" "$CODE_REVIEW_SKILL_NAME"
}

install_codex_cc_plugin() {
  if ! command -v npx >/dev/null 2>&1; then
    echo "❌ npx 명령이 필요합니다."
    return 1
  fi

  echo "→ cc-plugin-codex 설치 중: npx --yes ${CC_PLUGIN_PACKAGE} install"
  npx --yes "$CC_PLUGIN_PACKAGE" install
}

# ===== 실행 =====

echo "🚀 repo-bootstrap 설치 시작"

if [ "$INSTALL_CODEX" -eq 1 ]; then
  echo ""
  echo "📦 Codex 스킬 설치: ${CODEX_DIR}"
  install_codex_skills "$CODEX_DIR" "${SKILLS[@]}"
  install_codex_humanize_korean
  install_remote_code_review_skill "$CODEX_DIR"
fi

if [ "$INSTALL_CLAUDE" -eq 1 ]; then
  echo ""
  echo "📦 Claude 스킬 설치: ${CLAUDE_SKILLS_DIR}"
  install_claude_skills "$CLAUDE_SKILLS_DIR" "${CLAUDE_SKILLS[@]}"
  install_claude_humanize_korean
  install_remote_code_review_skill "$CLAUDE_SKILLS_DIR"
fi

if [ "$INSTALL_CC_PLUGIN" -eq 1 ]; then
  if [ "$INSTALL_CODEX" -eq 1 ]; then
    echo ""
    echo "📦 Codex 플러그인 설치: cc-plugin-codex"
    if install_codex_cc_plugin; then
      CC_PLUGIN_INSTALLED=1
    else
      CC_PLUGIN_INSTALL_FAILED=1
      echo ""
      echo "⚠️  cc-plugin-codex 설치에 실패했습니다."
      echo "   Codex/Claude 스킬 설치는 완료된 상태입니다."
      echo "   나중에 다시 시도: npx --yes ${CC_PLUGIN_PACKAGE} install"
    fi
  else
    echo ""
    echo "⚠️  --claude-only가 지정되어 cc-plugin-codex 설치를 건너뜁니다."
  fi
fi

echo ""
echo "✅ 설치 완료!"

if [ "$CC_PLUGIN_INSTALL_FAILED" -eq 1 ]; then
  echo "⚠️  cc-plugin-codex 설치는 완료되지 않았습니다. 위 안내의 재시도 명령을 확인하세요."
fi

if [ "$INSTALL_CLAUDE" -eq 1 ]; then
  echo ""
  echo "👉 Claude에서:"
  echo "   현재 변경사항에 맞는 브랜치 이름 추천해줘"
  echo "   현재 변경사항에 맞는 커밋 메시지 추천해줘"
  echo "   현재 브랜치의 PR 제목과 설명 작성해줘"
  echo "   이 저장소에 맞는 Git 훅을 구성해줘"
  echo "   이 글 AI 티 안 나게 자연스럽게 다듬어줘"
  echo "   /awesome-code-review 현재 변경사항을 코드 리뷰해줘"
fi

if [ "$INSTALL_CODEX" -eq 1 ]; then
  echo ""
  echo "👉 Codex에서:"
  echo "   현재 변경사항에 맞는 브랜치 이름 추천해줘"
  echo "   현재 변경사항에 맞는 커밋 메시지 추천해줘"
  echo "   현재 브랜치의 PR 제목과 설명 작성해줘"
  echo "   이 저장소에 맞는 Git 훅을 구성해줘"
  echo "   이 글 AI 티 안 나게 자연스럽게 다듬어줘"
  echo "   /awesome-code-review 현재 변경사항을 코드 리뷰해줘"

  if [ "$CC_PLUGIN_INSTALLED" -eq 1 ]; then
    echo "   \$cc:setup"
  fi
fi
