# 탐색 메모

## Phase 0 감사 결과

- 현재 하네스 자산은 `AGENTS.md`와 `.harness/logs/github-workflow-log.md`만 존재했다.
- `.codex/agents`, `.agents/skills`, `.harness/docs`, `.harness/logs/session-log.md`, `.harness/logs/latest-session-summary.md`는 없었다.
- 기존 `AGENTS.md`에는 ChatGPT Codex Connector 리뷰 지침이 있으므로 보존 대상이다.
- `.harness/logs/github-workflow-log.md`는 GitHub Workflow Engine 보조 로그이므로 삭제하지 않는다.

## 상태 모드 판정

- 판정: `신규 구축에 가까운 기존 확장`
- 근거: 기존 로그 한 개와 리뷰 지침은 있지만, 최신 codex-harness의 역할 팀 본체와 로그 계약이 없다.
- 재진입 Phase: `하네스 Phase 1`부터 `하네스 Phase 6`까지 필요한 최소 범위로 진입한다.

## 자동 판단 보류

- 실제 전역 설치 검증은 사용자 홈 디렉터리와 네트워크를 수정할 수 있어 자동 실행하지 않는다.
- Codex native plugin 제거 후 `~/.codex/config.toml` feature gate를 되돌릴지는 사용자 운영 정책에 따른다.

## 다음 확인 질문

- 기본 설치에서 `cc-plugin-codex` 최신 버전을 계속 사용할지, 특정 버전 핀 고정을 도입할지는 향후 정책 변경 시 재확인한다.
- GitHub Workflow Engine 로그를 하네스 세션 로그로 통합할지, 별도 운영 로그로 계속 유지할지는 다음 운영 감사(audit) 때 확인한다.
