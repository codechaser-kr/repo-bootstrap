# QA 전략

## 검증 범위

- 설치/제거 스크립트의 셸 문법과 옵션 UX
- README 설치/제거 예시와 실제 옵션 파서 정합성
- GitHub 이슈/PR 템플릿 계약
- AI 리뷰 지침 보존
- 하네스 agent/skill 포인터와 `team-spec` 정합성

## 자동 검증

- `bash -n install.sh`
- `bash -n uninstall.sh`
- `bash -n setup-github.sh`
- `git diff --check`
- `./install.sh --help`
- `./uninstall.sh --help`
- 알 수 없는 옵션이 설치/제거 실행 전에 오류 처리되는지 확인

## 수동 검증

- 실제 `npx --yes cc-plugin-codex install`과 `uninstall`은 사용자 전역 설정 변경 위험 때문에 필요 시 별도 승인 후 수행한다.
- `setup-github.sh`는 임시 Git 저장소에서 기존 `AGENTS.md`와 `.gemini/styleguide.md` 섹션이 보존 또는 삽입/갱신(upsert)되는지 확인한다.
- README 예시가 현재 기본 정책과 맞는지 사람이 확인한다.

## 미실행 항목

- 사용자 홈 디렉터리의 실제 `~/.codex/config.toml` 변경 검증
- upstream GitHub tarball 최신 구조 검증
- npm registry에서 `cc-plugin-codex` 최신 버전 실행

## 잔여 위험

- `cc-plugin-codex` 최신 버전 실행 정책은 재현성보다 최신성을 택한 의식적 결정이므로 향후 호환성 문제가 생기면 버전 핀 고정으로 재진입해야 한다.
- 전역 경로 삭제 범위는 자동 테스트보다 코드 리뷰와 임시 HOME 검증을 병행해야 한다.

## 다음 조치

- PR 전에는 셸 문법, diff whitespace, 도움말, unknown option 처리를 다시 확인한다.
- 실제 설치/제거 검증이 필요하면 `HOME=/tmp/...` 임시 환경과 네트워크 승인 범위를 별도로 정한다.

## 학습 후보

- 설치 스크립트 하네스에서는 외부 네트워크 실패를 fatal/non-fatal로 나누는 정책을 역할 스펙에 유지한다.
- README/옵션 파서 괴리(drift)는 반복될 수 있으므로 QA 체크리스트에서 계속 확인한다.
