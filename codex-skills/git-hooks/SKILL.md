---
name: git-hooks
description: 사용자와 대화하며 대상 Git 저장소에 맞는 pre-commit, pre-push, commit-msg 훅을 설계하고 생성하거나 갱신합니다
---

# Git Hook 구성

사용자와 대화하며 대상 Git 저장소에 맞는 로컬 Git 훅을 설계하고 생성하거나 갱신합니다.

핵심 정책:

- 특정 언어, 프레임워크, 패키지 관리 도구, 포맷터, 린터, 테스트 도구를 스킬에 고정하지 않습니다.
- 구현 방식은 저장소 상황과 사용자 선택에 따라 정합니다.
- `pre-commit`은 스테이징된 파일에 대해서만 빠르게 포맷터와 린트를 실행하도록 구성합니다.
- `pre-push`는 푸시 대상 커밋들의 변경에 대해 린트, 타입 검사, 테스트를 실행해 정합성을 확인하도록 구성합니다.
- `commit-msg`는 아래 `commit-msg 훅` 섹션의 스크립트 그대로 구성합니다.
- `pre-commit`과 `pre-push`에 사용할 도구 후보는 저장소의 언어/프레임워크/프로젝트 관리 방식에 맞춰 제안하고, 사용자가 선택하게 합니다.
- 필요한 정보나 사용자 선택이 부족하면 훅을 만들지 말고 필요한 질문을 한 뒤 멈춥니다.

## 작업 절차

1. 현재 상태 확인
   - `git rev-parse --show-toplevel`
   - `git config --get core.hooksPath`
   - `git rev-parse --git-path hooks`
   - 기존 hook 파일은 백업/덮어쓰기 판단에 필요한 범위에서 확인
2. 대화로 필요한 정보 확인
   - 저장소의 언어/프레임워크
   - 프로젝트 관리 방식과 명령 실행 방식
   - 현재 설치된 포맷터, 린터, 타입 검사, 테스트 도구
   - 사용자가 원하는 훅 강도와 실행 비용
3. 도구 후보 제안
   - 저장소 상황에 맞는 후보를 역할별로 제안
   - 각 후보의 장단점과 훅에서 사용할 위치를 간단히 설명
   - 사용자가 선택하기 전에는 도구 설치나 훅 생성을 진행하지 않음
4. 실행 계획 합의
   - `pre-commit`에서 실행할 명령과 대상 파일 범위 제시
   - `pre-push`에서 실행할 명령과 대상 변경 범위 제시
   - 기존 훅 백업 방식 제시
   - 사용자가 승인하지 않으면 작업을 진행하지 않음
5. 도구 준비
   - 선택한 도구가 없거나 실행 명령이 불명확하면 설치/설정/대안 중 가능한 선택지를 제시
   - 사용자가 승인한 방식만 적용
   - 설치나 설정이 실패하면 훅 생성을 중단하고 실패 원인을 보고
6. 훅 작성
   - 기본은 Git 기본 hook 경로(`git rev-parse --git-path hooks`)에 직접 설치
   - 기존 훅이 있으면 덮어쓰기 전 `.bak` 또는 timestamp 백업을 만든 뒤 진행
   - 설치 후 `chmod +x` 적용
   - `pre-commit`에서 포맷터가 파일을 수정한 경우 커밋을 중단하고, 사용자가 변경 내용을 확인한 뒤 다시 스테이징하게 함

## 훅 작성 원칙

- POSIX `sh`를 기본으로 사용합니다.
- 훅 시작부에는 `set -eu`, `repo_root=$(git rev-parse --show-toplevel)`, `cd "$repo_root"`를 둡니다.
- 훅에서는 사용자와 합의한 도구와 명령만 호출합니다.
- 프로젝트의 기존 명령 실행 방식을 우선 사용합니다.
- `pre-commit`은 `git diff --cached --name-only --diff-filter=ACMR`로 스테이징된 파일만 대상으로 삼습니다.
- `pre-push`는 Git이 stdin으로 넘긴 ref 정보를 기준으로 푸시 대상 변경 파일을 계산합니다.
- 파일 목록은 `while IFS= read -r file` 패턴으로 처리합니다.

## commit-msg 훅

대상 프로젝트와 관계없이 아래 내용을 그대로 사용합니다.

```sh
#!/bin/sh
set -eu

if [ -z "${1:-}" ]; then
  echo "[commit-msg] usage: commit-msg <message-file>" >&2
  exit 1
fi

message_file=$1
header=$(sed -n '1p' "$message_file")

print_format_error() {
  cat >&2 <<'EOF'
[commit-msg] commit message must match the documented Conventional Commits format:
  <타입>: <설명>

Allowed types:
  feat, chore, refactor, fix, revert, style, test, docs
EOF
}

case "$header" in
  feat:\ *|chore:\ *|refactor:\ *|fix:\ *|revert:\ *|style:\ *|test:\ *|docs:\ *)
    type=${header%%:*}
    description=${header#"$type: "}
    if [ -z "$description" ]; then
      print_format_error
      exit 1
    fi
    ;;
  *)
    print_format_error
    exit 1
    ;;
esac

case "$header" in
  *.)
    echo "[commit-msg] commit description must not end with a period." >&2
    exit 1
    ;;
esac
```

## 완료 전 확인

- 생성된 각 훅의 문법 확인: `sh -n <hook-file>`
- 생성된 각 훅의 실행 권한 확인: `ls -l <hook-file>`
- `pre-commit`이 스테이징된 파일 목록을 사용하면 해당 목록 명령 확인
- `pre-push`가 푸시 대상 변경 목록을 계산하면 해당 계산 명령 확인
- 사용자와 합의한 도구 설치/설정 변경이 있으면 관련 설정 파일과 lockfile 변경 여부 확인
- 최종 답변에는 합의한 도구, 생성한 훅, 실행 명령, 백업 파일 위치를 간단히 보고합니다.
