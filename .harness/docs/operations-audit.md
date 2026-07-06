# 하네스 운영 감사(audit)

## 감사(audit) 범위

- `AGENTS.md`
- `.codex/config.toml`
- `.codex/agents/*.toml`
- `.agents/skills/*/SKILL.md`
- `.harness/docs/*`
- `.harness/logs/*`

## 통과한 항목

- `team-spec.md`에 최종 역할 인벤토리가 fenced `text` 블록으로 존재한다.
- `.codex/config.toml`은 `[agents.<role_id>] config_file` 형식으로 역할을 연결한다.
- `.codex/agents/*.toml`은 `model_reasoning_effort`와 `sandbox_mode`를 사용한다.
- `.agents/skills/*/SKILL.md`는 역할별 세부 기준을 복제하지 않고 `team-spec.md`의 해당 `role_id` 섹션을 참조한다.
- 시작 진입 역할(`run-harness`)과 중심 조율 역할(`bootstrap-flow-coordinator`)이 분리되어 있다.
- QA 역할(`bootstrap-release-qa`)과 운영 감사(audit) 역할(`harness-operations-auditor`)이 분리되어 있다.
- 기존 `AGENTS.md`의 ChatGPT Codex Connector 리뷰 지침과 `.harness/logs/github-workflow-log.md`는 보존했다.

## 수정 필요한 항목

- 실제 `npx cc-plugin-codex` 설치/제거 검증은 전역 설정 변경 위험 때문에 수행하지 않았다.
- GitHub 템플릿 설치 스크립트는 임시 Git 저장소 기반 통합 검증을 별도 세션에서 수행하는 것이 좋다.

## 재진입 권장 하네스 Phase

- 현재 판정: `운영 가능`
- 다음 재진입: 설치 정책이나 템플릿 계약이 바뀌면 `하네스 Phase 1~2`, 역할/스킬 구조가 바뀌면 `하네스 Phase 2~4`, 로그/오케스트레이션 drift가 생기면 `하네스 Phase 5~6`

## 남은 위험

- 외부 upstream 구조와 npm 최신 버전은 실행 시점에 바뀔 수 있다.
- 실제 사용자 홈 디렉터리 변경은 자동 검증보다 명시 승인 기반 수동 검증이 필요하다.

## 학습 후보와 승격 대상

- 학습 후보: 설치 스크립트형 저장소는 전역 경로, 외부 네트워크, non-fatal 처리, README 옵션 drift를 별도 QA 축으로 유지해야 한다.
- 승격 대상: `qa-strategy.md`와 `team-spec.md`에 이미 반영함.
- 생성기 환류 후보: `no - 현재 저장소 특화 관찰로 유지`
