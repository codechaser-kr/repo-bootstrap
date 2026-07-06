# 팀 플레이북

## 기본 사용법

1. 요청을 받으면 `run-harness` 기준으로 현재 상태와 최신 요약을 확인한다.
2. 변경 표면이 설치/제거 스크립트인지 GitHub 템플릿인지 먼저 나눈다.
3. 구현 후 `bootstrap-release-qa`로 문법, 도움말, README 정합성, 미실행 위험을 확인한다.
4. 하네스 산출물을 바꾼 경우 `harness-operations-auditor`로 운영 감사(audit)를 수행한다.

## 설치/제거 변경 흐름

- 시작 역할: `installer-boundary-maintainer`
- 우선 확인: `install.sh`, `uninstall.sh`, `README.md`
- 기본 검증: `bash -n install.sh`, `bash -n uninstall.sh`, `git diff --check`, 도움말 출력, unknown option 처리
- 미실행 위험: 실제 `~/.codex`, `~/.claude`, npm, GitHub tarball 변경

## GitHub 템플릿 변경 흐름

- 시작 역할: `workflow-template-curator`
- 우선 확인: `.github/ISSUE_TEMPLATE/*`, `.github/pull_request_template.md`, `.github/apps/*`, `setup-github.sh`
- 기본 검증: 필수 섹션, label, title prefix, `Refs #번호`, 자동 close 키워드 미사용

## 하네스 갱신 흐름

- 시작 역할: `run-harness`
- 조율 역할: `bootstrap-flow-coordinator`
- 검증 역할: `harness-operations-auditor`
- 완료 조건: `team-spec`, `.codex/config.toml`, `.codex/agents/*`, `.agents/skills/*`, 로그 문서가 같은 역할 집합을 말한다.
