#!/usr/bin/env bash
set -e

# ===== 설정 =====
REPO="codechaser-kr/repo-bootstrap"
BRANCH="main"
BASE_URL="https://raw.githubusercontent.com/${REPO}/${BRANCH}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SKILLS=("branch" "commit" "pr" "git-hooks")
CLAUDE_SKILLS=("branch" "commit" "pr" "git-hooks")

CODEX_HUMANIZE_REPO="Squirbie/im-not-ai-codex"
CODEX_HUMANIZE_BRANCH="main"
CLAUDE_HUMANIZE_REPO="epoko77-ai/im-not-ai"
CLAUDE_HUMANIZE_BRANCH="main"

CODEX_DIR="${HOME}/.codex/skills"
CLAUDE_SKILLS_DIR="${HOME}/.claude/skills"
CLAUDE_AGENTS_DIR="${HOME}/.claude/agents"
CLAUDE_COMMANDS_DIR="${HOME}/.claude/commands"
CLAUDE_MANIFEST="${HOME}/.claude/.repo-bootstrap-humanize-files"

INSTALL_CODEX=1
INSTALL_CLAUDE=1
TMP_DIR=""
FETCHED_REPO_DIR=""

# ===== 옵션 처리 =====
for arg in "$@"; do
  case $arg in
    --codex-only)
      INSTALL_CLAUDE=0
      ;;
    --claude-only)
      INSTALL_CODEX=0
      ;;
    *)
      ;;
  esac
done

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

  echo "❌ ${skill_name} 소스 디렉터리를 찾을 수 없습니다." >&2
  echo "   repo: ${repo_label}" >&2
  echo "   추출 위치: ${repo_dir}" >&2
  echo "   확인한 후보:" >&2
  for candidate in "${candidates[@]}"; do
    echo "   - ${candidate}" >&2
  done
  return 1
}

remove_manifest_entries() {
  if [ ! -f "$CLAUDE_MANIFEST" ]; then
    return
  fi

  while IFS= read -r relative_path; do
    if [ -n "$relative_path" ]; then
      rm -f "${HOME}/.claude/${relative_path}"
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

# ===== 실행 =====

echo "🚀 repo-bootstrap 설치 시작"

if [ "$INSTALL_CODEX" -eq 1 ]; then
  echo ""
  echo "📦 Codex 스킬 설치: ${CODEX_DIR}"
  install_codex_skills "$CODEX_DIR" "${SKILLS[@]}"
  install_codex_humanize_korean
fi

if [ "$INSTALL_CLAUDE" -eq 1 ]; then
  echo ""
  echo "📦 Claude 스킬 설치: ${CLAUDE_SKILLS_DIR}"
  install_claude_skills "$CLAUDE_SKILLS_DIR" "${CLAUDE_SKILLS[@]}"
  install_claude_humanize_korean
fi

echo ""
echo "✅ 설치 완료!"
echo ""
echo "👉 Claude에서:"
echo "   현재 변경사항에 맞는 브랜치 이름 추천해줘"
echo "   현재 변경사항에 맞는 커밋 메시지 추천해줘"
echo "   현재 브랜치의 PR 제목과 설명 작성해줘"
echo "   이 레포에 맞는 Git hook 만들어줘"
echo "   이 글 AI 티 안 나게 자연스럽게 다듬어줘"
echo ""
echo "👉 Codex에서:"
echo "   현재 변경사항에 맞는 브랜치 이름 추천해줘"
echo "   현재 변경사항에 맞는 커밋 메시지 추천해줘"
echo "   현재 브랜치의 PR 제목과 설명 작성해줘"
echo "   이 레포에 맞는 Git hook 만들어줘"
echo "   이 글 AI 티 안 나게 자연스럽게 다듬어줘"
