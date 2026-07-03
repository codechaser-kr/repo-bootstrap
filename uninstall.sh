#!/usr/bin/env bash
set -e

SKILLS=("branch" "commit" "pr" "git-hooks" "humanize-korean" "awesome-code-review" "code-review-skill")
CLAUDE_SKILLS=("branch" "commit" "pr" "git-hooks" "humanize-korean" "awesome-code-review" "code-review-skill")

CODEX_DIR="${HOME}/.codex/skills"
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

# ===== 옵션 처리 =====
for arg in "$@"; do
  case $arg in
    --codex-only)
      REMOVE_CLAUDE=0
      ;;
    --claude-only)
      REMOVE_CODEX=0
      ;;
    *)
      ;;
  esac
done

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

echo ""
echo "✅ 제거 완료"
