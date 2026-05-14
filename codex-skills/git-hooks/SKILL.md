---
name: git-hooks
description: 타겟 Git 저장소의 언어와 모노레포 구조를 분석해 pre-commit, pre-push, commit-msg 훅을 생성하거나 갱신합니다
---

# Git Hook 구성

타겟 저장소를 분석해 로컬 Git hook을 생성하거나 갱신합니다. 핵심 목표는 `pre-commit`은 빠른 staged 파일 검사, `pre-push`는 push 범위 기준의 더 무거운 검사를 수행하게 만드는 것입니다. `commit-msg`는 모든 프로젝트에서 동일한 Conventional Commits 검사 훅을 사용합니다.

## 작업 절차

1. 저장소 루트 확인
   - `git rev-parse --show-toplevel`
   - `git config --get core.hooksPath`
   - `git rev-parse --git-path hooks`
2. 기존 훅 확인
   - `.git/hooks/pre-commit`
   - `.git/hooks/pre-push`
   - `.git/hooks/commit-msg`
   - `.husky/`, `.githooks/`, `lefthook.yml`, `.pre-commit-config.yaml`
3. 프로젝트 구조 분석
   - 모노레포 여부: `workspaces`, `pnpm-workspace.yaml`, `turbo.json`, `nx.json`, 여러 `Cargo.toml`, 여러 Gradle 프로젝트, `apps/`, `packages/`
   - 언어와 도구: `package.json`, `Cargo.toml`, `build.gradle(.kts)`, `gradlew`, `.swiftlint.yml`, `pubspec.yaml`, `go.mod`, `pyproject.toml`
   - 기존 스크립트: `lint`, `format`, `typecheck`, `test`, `clippy`, `ktlint`, `swiftlint`
4. 훅 정책 결정
   - `pre-commit`: staged 파일에 해당하는 빠른 포맷/린트만 실행
   - `pre-push`: push 대상 commit들의 변경 파일에 해당하는 lint/typecheck/test를 실행
   - 포맷터가 파일을 수정하면 자동 stage 하지 말고 실패 처리해 사용자가 검토 후 다시 stage 하게 함
5. 훅 설치
   - 기본은 Git 기본 hook 경로(`git rev-parse --git-path hooks`)에 직접 설치
   - 기존 훅이 있으면 내용을 확인하고, 덮어쓰기 전 `.bak` 또는 timestamp 백업을 만든 뒤 진행
   - 설치 후 `chmod +x` 적용

## 언어별 기본 정책

타겟 레포의 실제 스크립트와 설정을 우선합니다. 아래는 기본 후보입니다.

- JavaScript/TypeScript
  - `lint-staged`가 있으면 `pre-commit`에서 `yarn lint-staged`, `pnpm lint-staged`, `npx lint-staged` 중 프로젝트 패키지 매니저에 맞는 명령 사용
  - `lint-staged`가 없으면 staged JS/TS 파일 대상으로 가능한 가장 좁은 lint/format 명령 구성
  - `pre-push`는 변경 범위에 JS/TS 패키지가 포함될 때 `lint`, `typecheck`, 관련 테스트 명령을 사용
- Rust
  - `pre-commit`: staged `.rs` 파일에 `rustfmt` 또는 `cargo fmt --check` 기반 구성
  - `pre-push`: 변경된 crate/workspace에 `cargo clippy --all-targets`와 필요한 테스트
- Kotlin/Android
  - `pre-commit`: staged `.kt`/`.kts` 파일이 있는 Gradle 프로젝트에서 `ktlintFormat` 또는 프로젝트의 포맷 task 실행
  - `pre-push`: 해당 Gradle 프로젝트에서 `ktlintCheck`, Android app이면 `lintDebug` 같은 lint task 실행
- Swift/iOS
  - `pre-commit`: staged `.swift` 파일만 대상으로 `swiftlint lint --strict --use-script-input-files` 또는 repo wrapper 스크립트 실행
  - `pre-push`: 변경 범위에 iOS/Swift 패키지가 포함되면 전체 SwiftLint 또는 프로젝트 lint 명령 실행
- Flutter/Dart
  - `pre-commit`: staged `.dart` 파일에 `dart format --set-exit-if-changed` 또는 repo 정책에 맞는 format/analyze
  - `pre-push`: 변경 범위에 Flutter/Dart 프로젝트가 포함되면 `flutter analyze`, 필요한 테스트
- Go
  - `pre-commit`: staged `.go` 파일에 `gofmt` 결과 검사
  - `pre-push`: 변경 범위에 Go 모듈이 포함되면 `go test ./...`
- Python
  - `pre-commit`: repo 설정에 따라 `ruff format --check`, `ruff check`, `black --check` 중 사용 가능한 도구 선택
  - `pre-push`: 변경 범위에 Python 패키지가 포함되면 pytest 또는 프로젝트 테스트 명령

## commit-msg 고정 훅

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

## 훅 작성 원칙

- POSIX `sh`를 기본으로 사용합니다.
- 훅 시작부에는 `set -eu`, `repo_root=$(git rev-parse --show-toplevel)`, `cd "$repo_root"`를 둡니다.
- staged 파일은 `git diff --cached --name-only --diff-filter=ACMR`로 구합니다.
- `pre-push`는 Git이 stdin으로 넘긴 ref 정보를 임시 파일에 저장한 뒤, remote에 없는 commit들의 변경 파일을 계산합니다.
- 경로에 공백이 있을 수 있으므로 파일 목록 처리 시 `while IFS= read -r file` 패턴을 선호합니다.
- 프로젝트 전역 명령이 너무 무거우면 변경된 package/app/crate/module에 한정합니다.
- 도구가 없거나 설정이 불명확하면 훅에 추측 명령을 넣지 말고 사용자에게 확인합니다.
- `.git/hooks`는 보통 버전관리되지 않으므로, 재사용이 필요하면 `scripts/install-hooks.sh`나 문서 업데이트도 제안합니다.

## 완료 전 확인

- 생성된 훅 문법 확인: `sh -n <hook-file>`
- 실행 권한 확인: `ls -l <hook-file>`
- 가능하면 dry-run에 가까운 명령으로 staged 파일 감지 로직 확인
- 최종 답변에는 감지한 언어/구조, 생성한 훅, 실행되는 명령, 백업 파일 위치를 간단히 보고합니다.
