---
allowed-tools: Bash(git rev-parse:*), Bash(git config:*), Bash(git diff:*), Bash(git status:*), Bash(git ls-files:*), Bash(find:*), Bash(rg:*), Bash(sed:*), Bash(ls:*), Bash(chmod:*), Bash(mkdir:*), Bash(cp:*)
description: 타겟 Git 저장소의 언어와 모노레포 구조를 분석해 pre-commit, pre-push, commit-msg 훅을 생성하거나 갱신합니다
---

## Your task

타겟 저장소를 분석해 로컬 Git hook을 생성하거나 갱신하세요. 핵심 목표는 `pre-commit`은 빠른 staged 파일 검사, `pre-push`는 push 범위 기준의 더 무거운 검사를 수행하게 만드는 것입니다. `commit-msg`는 모든 프로젝트에서 동일한 Conventional Commits 검사 훅을 사용합니다.

## Workflow

1. 저장소 루트를 확인합니다.
   - `git rev-parse --show-toplevel`
   - `git config --get core.hooksPath`
   - `git rev-parse --git-path hooks`
2. 기존 훅과 훅 프레임워크를 확인합니다.
   - `.git/hooks/pre-commit`
   - `.git/hooks/pre-push`
   - `.git/hooks/commit-msg`
   - `.husky/`, `.githooks/`, `lefthook.yml`, `.pre-commit-config.yaml`
3. 프로젝트 구조를 분석합니다.
   - 모노레포 여부: `workspaces`, `pnpm-workspace.yaml`, `turbo.json`, `nx.json`, 여러 `Cargo.toml`, 여러 Gradle 프로젝트, `apps/`, `packages/`
   - 언어와 도구: `package.json`, `Cargo.toml`, `build.gradle(.kts)`, `gradlew`, `.swiftlint.yml`, `pubspec.yaml`, `go.mod`, `pyproject.toml`
   - 기존 스크립트: `lint`, `format`, `typecheck`, `test`, `clippy`, `ktlint`, `swiftlint`
4. 훅 정책을 결정합니다.
   - `pre-commit`: staged 파일에 해당하는 빠른 포맷/린트만 실행
   - `pre-push`: push 대상 commit들의 변경 파일에 해당하는 lint/typecheck/test를 실행
   - 포맷터가 파일을 수정하면 자동 stage 하지 말고 실패 처리해 사용자가 검토 후 다시 stage 하게 함
5. 훅을 설치합니다.
   - 기본은 Git 기본 hook 경로(`git rev-parse --git-path hooks`)에 직접 설치
   - 기존 훅이 있으면 내용을 확인하고, 덮어쓰기 전 `.bak` 또는 timestamp 백업을 만든 뒤 진행
   - 설치 후 `chmod +x` 적용

## Language policy

타겟 레포의 실제 스크립트와 설정을 우선합니다. 아래는 기본 후보입니다.

- JavaScript/TypeScript: `lint-staged`가 있으면 패키지 매니저에 맞춰 `yarn lint-staged`, `pnpm lint-staged`, `npx lint-staged`를 `pre-commit`에 사용합니다. `pre-push`는 변경 범위에 따라 `lint`, `typecheck`, 관련 테스트를 사용합니다.
- Rust: `pre-commit`은 staged `.rs` 파일에 `rustfmt` 또는 `cargo fmt --check`, `pre-push`는 변경된 crate/workspace에 `cargo clippy --all-targets`와 필요한 테스트를 사용합니다.
- Kotlin/Android: `pre-commit`은 staged `.kt`/`.kts` 파일이 있는 Gradle 프로젝트에서 `ktlintFormat`, `pre-push`는 `ktlintCheck`와 Android app의 `lintDebug` 같은 lint task를 사용합니다.
- Swift/iOS: `pre-commit`은 staged `.swift` 파일만 대상으로 `swiftlint lint --strict --use-script-input-files` 또는 repo wrapper 스크립트를 실행하고, `pre-push`는 변경 범위에 Swift/iOS가 포함될 때 전체 lint를 실행합니다.
- Flutter/Dart: `pre-commit`은 staged `.dart` 파일에 format/analyze, `pre-push`는 `flutter analyze`와 필요한 테스트를 사용합니다.
- Go: `pre-commit`은 staged `.go` 파일에 `gofmt` 결과 검사, `pre-push`는 해당 모듈에서 `go test ./...`를 사용합니다.
- Python: repo 설정에 따라 `ruff`, `black`, `pytest`를 사용합니다.

## Fixed commit-msg hook

타겟 프로젝트와 관계없이 아래 내용을 사용합니다.

```sh
#!/bin/sh
set -eu

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

## Hook authoring rules

- POSIX `sh`를 기본으로 사용합니다.
- 훅 시작부에는 `set -eu`, `repo_root=$(git rev-parse --show-toplevel)`, `cd "$repo_root"`를 둡니다.
- staged 파일은 `git diff --cached --name-only --diff-filter=ACMR`로 구합니다.
- `pre-push`는 Git이 stdin으로 넘긴 ref 정보를 임시 파일에 저장한 뒤, remote에 없는 commit들의 변경 파일을 계산합니다.
- 파일 목록 처리 시 `while IFS= read -r file` 패턴을 선호합니다.
- 프로젝트 전역 명령이 너무 무거우면 변경된 package/app/crate/module에 한정합니다.
- 도구가 없거나 설정이 불명확하면 훅에 추측 명령을 넣지 말고 사용자에게 확인합니다.
- `.git/hooks`는 보통 버전관리되지 않으므로, 재사용이 필요하면 `scripts/install-hooks.sh`나 문서 업데이트도 제안합니다.

## Final checks

- `sh -n <hook-file>`
- `ls -l <hook-file>`
- 가능하면 staged 파일 감지 로직 확인
- 최종 답변에는 감지한 언어/구조, 생성한 훅, 실행되는 명령, 백업 파일 위치를 간단히 보고합니다.
