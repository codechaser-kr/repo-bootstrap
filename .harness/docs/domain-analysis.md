# 도메인 분석

## 저장소 목적

`repo-bootstrap`은 여러 저장소에 반복 적용되는 초기 협업 설정을 배포한다. 핵심은 프로젝트 코드가 아니라 설치 스크립트와 Markdown 기반 운영 규칙이다.

## 주요 표면

- `install.sh`: Codex/Claude 전역 스킬 설치, upstream GitHub tarball 다운로드, Codex plugin 설치 호출
- `uninstall.sh`: 전역 스킬 제거, Claude 보조 파일 manifest 제거, Codex plugin 제거 opt-in
- `setup-github.sh`: 대상 저장소의 GitHub 이슈/PR 템플릿과 AI 리뷰 지침 설치
- `codex-skills/*`, `claude-skills/*`: 로컬 배포 대상 스킬 원본
- `.github/ISSUE_TEMPLATE/*`, `.github/pull_request_template.md`: GitHub Workflow Engine이 기대하는 이슈/PR 계약
- `AGENTS.md`, `.gemini/styleguide.md`: AI 리뷰 도구가 읽는 저장소별 지침

## 핵심 런타임 경계

- 로컬 저장소 쓰기: 현재 checkout 안의 스크립트와 템플릿을 수정한다.
- 사용자 홈 전역 쓰기: `install.sh`와 `uninstall.sh`는 Codex 스킬 경로 `~/.agents/skills`와 Claude 경로 `~/.claude`를 다룬다. `cc-plugin-codex` 설정은 `~/.codex/config.toml`을 사용한다.
- 외부 네트워크: GitHub tarball, raw GitHub, npm `npx` 호출이 있다.
- 대상 저장소 설치: `setup-github.sh`는 실행 위치의 `.github`, `AGENTS.md`, `.gemini`를 수정한다.

## 실패 비용

- 잘못된 삭제는 사용자 전역 스킬과 Claude commands/agents를 잃게 할 수 있다.
- 버전 미고정 npm 실행은 재현성보다 최신성을 택하는 정책이므로 README와 코드가 같은 결정을 말해야 한다.
- 설치 옵션 설명과 실제 옵션 파서가 어긋나면 `curl | bash` 사용자에게 복구 경로가 약해진다.
- GitHub 템플릿 계약이 깨지면 Workflow Engine 이슈/PR 흐름이 연결 이슈를 읽지 못한다.

## 하네스에 필요한 관점

- 설치 경계 유지보수: 전역 경로, 네트워크, opt-in/opt-out 정책을 코드와 문서에서 같이 관리한다.
- GitHub 템플릿 관리: 이슈/PR 템플릿과 AI 리뷰 지침의 계약을 유지한다.
- 릴리즈 QA: 셸 문법, 옵션 도움말, 알 수 없는 옵션, non-fatal 처리, README 예시를 교차 확인한다.
- 운영 감사(audit): `team-spec`, agent/skill 포인터, 로그 정책과 최신 세션 요약이 맞물리는지 확인한다.
