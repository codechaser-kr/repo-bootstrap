#!/usr/bin/env bash
set -e

SKILLS=("branch" "commit" "pr-proposal" "git-hooks" "humanize-korean" "awesome-code-review")
CLAUDE_SKILLS=("branch" "commit" "pr-proposal" "git-hooks" "humanize-korean" "awesome-code-review")
CC_PLUGIN_PACKAGE="cc-plugin-codex"

CODEX_DIR="${HOME}/.agents/skills"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-${HOME}/.claude}"
CLAUDE_SKILLS_DIR="${CLAUDE_DIR}/skills"
CLAUDE_MANIFEST="${CLAUDE_DIR}/.repo-bootstrap-humanize-files"
CLAUDE_LEGACY_MANIFEST="${CLAUDE_DIR}/.git-workflow-kit-humanize-files"
CLAUDE_HUMANIZE_FALLBACK_FILES=(
  "agents/ai-tell-detector.md"
  "agents/content-fidelity-auditor.md"
  "agents/humanize-monolith.md"
  "agents/humanize-web-architect.md"
  "agents/korean-ai-tell-taxonomist.md"
  "agents/korean-style-rewriter.md"
  "agents/naturalness-reviewer.md"
  "commands/humanize.md"
  "commands/humanize-redo.md"
)

REMOVE_CODEX=1
REMOVE_CLAUDE=1
REMOVE_CC_PLUGIN=0

print_usage() {
  echo "Usage: uninstall.sh [--codex-only] [--claude-only] [--with-cc-plugin]"
  echo ""
  echo "Options:"
  echo "  --codex-only       Codex 스킬만 제거합니다."
  echo "  --claude-only      Claude 스킬만 제거합니다."
  echo "  --with-cc-plugin   cc-plugin-codex도 함께 제거합니다."
}

# ===== 옵션 처리 =====
for arg in "$@"; do
  case $arg in
    -h|--help)
      print_usage
      exit 0
      ;;
    --codex-only)
      REMOVE_CLAUDE=0
      ;;
    --claude-only)
      REMOVE_CODEX=0
      ;;
    --with-cc-plugin)
      REMOVE_CC_PLUGIN=1
      ;;
    *)
      echo "❌ 알 수 없는 옵션: ${arg}"
      print_usage
      exit 1
      ;;
  esac
done

require_command() {
  local name="$1"

  if ! command -v "$name" >/dev/null 2>&1; then
    echo "❌ ${name} 명령이 필요합니다."
    exit 1
  fi
}

remove_codex_skills() {
  local target_dir="$1"
  shift

  if [ ! -d "$target_dir" ]; then
    echo "⚠️  경로가 존재하지 않아 건너뜁니다: ${target_dir}"
    return
  fi

  for name in "$@"; do
    local skill_dir="${target_dir}/${name}"
    if [ -d "$skill_dir" ]; then
      echo "🗑 제거 중: $skill_dir"
      rm -rf "$skill_dir"
    else
      echo "⚠️  대상이 없어 건너뜁니다: $skill_dir"
    fi
  done
}

remove_claude_skills() {
  local target_dir="$1"
  shift

  if [ ! -d "$target_dir" ]; then
    echo "⚠️  경로가 존재하지 않아 건너뜁니다: ${target_dir}"
    return
  fi

  for name in "$@"; do
    local skill_dir="${target_dir}/${name}"
    if [ -d "$skill_dir" ]; then
      echo "🗑 제거 중: $skill_dir"
      rm -rf "$skill_dir"
    else
      echo "⚠️  대상이 없어 건너뜁니다: $skill_dir"
    fi
  done
}

remove_claude_humanize_files() {
  local relative_path
  local removed_from_manifest=0

  if [ -f "$CLAUDE_MANIFEST" ]; then
    while IFS= read -r relative_path; do
      if [ -n "$relative_path" ]; then
        local target="${CLAUDE_DIR}/${relative_path}"
        if [ -f "$target" ]; then
          echo "🗑 제거 중: $target"
          rm -f "$target"
        fi
      fi
    done < "$CLAUDE_MANIFEST"
    rm -f "$CLAUDE_MANIFEST"
    removed_from_manifest=1
  fi

  if [ -f "$CLAUDE_LEGACY_MANIFEST" ]; then
    while IFS= read -r relative_path; do
      if [ -n "$relative_path" ]; then
        local target="${CLAUDE_DIR}/${relative_path}"
        if [ -f "$target" ]; then
          echo "🗑 제거 중: $target"
          rm -f "$target"
        fi
      fi
    done < "$CLAUDE_LEGACY_MANIFEST"
    rm -f "$CLAUDE_LEGACY_MANIFEST"
    removed_from_manifest=1
  fi

  if [ "$removed_from_manifest" -eq 1 ]; then
    return
  fi

  for relative_path in "${CLAUDE_HUMANIZE_FALLBACK_FILES[@]}"; do
    local target="${CLAUDE_DIR}/${relative_path}"
    if [ -f "$target" ]; then
      echo "🗑 제거 중: $target"
      rm -f "$target"
    fi
  done
}

remove_codex_cc_plugin() {
  if ! command -v npx >/dev/null 2>&1; then
    echo "❌ npx 명령이 필요합니다."
    return 1
  fi

  echo "🗑 cc-plugin-codex 제거 중: npx --yes ${CC_PLUGIN_PACKAGE} uninstall"
  npx --yes "$CC_PLUGIN_PACKAGE" uninstall
}

echo "🧹 repo-bootstrap 제거 시작"

if [ "$REMOVE_CODEX" -eq 1 ]; then
  echo ""
  echo "📦 Codex 스킬 제거: ${CODEX_DIR}"
  remove_codex_skills "$CODEX_DIR" "${SKILLS[@]}"
fi

if [ "$REMOVE_CLAUDE" -eq 1 ]; then
  echo ""
  echo "📦 Claude 스킬 제거: ${CLAUDE_SKILLS_DIR}"
  remove_claude_skills "$CLAUDE_SKILLS_DIR" "${CLAUDE_SKILLS[@]}"
  remove_claude_humanize_files
fi

if [ "$REMOVE_CC_PLUGIN" -eq 1 ]; then
  if [ "$REMOVE_CODEX" -eq 1 ]; then
    echo ""
    echo "📦 Codex 플러그인 제거: cc-plugin-codex"
    if ! remove_codex_cc_plugin; then
      echo ""
      echo "⚠️  cc-plugin-codex 제거에 실패했습니다."
      echo "   나중에 직접 제거 시도: npx --yes ${CC_PLUGIN_PACKAGE} uninstall"
    fi
  else
    echo ""
    echo "⚠️  --claude-only가 지정되어 cc-plugin-codex 제거를 건너뜁니다."
  fi
fi

echo ""
echo "✅ 제거 완료"
