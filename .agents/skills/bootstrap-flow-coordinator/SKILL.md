---
name: bootstrap-flow-coordinator
description: repo-bootstrap 하네스 역할 흐름을 조율하고 설치/템플릿/QA/운영 감사(audit) 인수인계(handoff)를 정렬합니다. 다음 역할 판단, 재진입 Phase 결정, 오케스트레이션 갱신에 사용합니다.
---

# bootstrap-flow-coordinator

이 스킬은 얇은 역할 포인터입니다. 역할의 목적, 우선 입력, 절차, 출력, 다음 역할, 종료 기준은 `.harness/docs/team-spec.md`의 `bootstrap_flow_coordinator` 섹션을 단일 원천으로 따릅니다.

## 실행 규칙

1. 먼저 `.harness/docs/team-spec.md`를 읽고 `bootstrap_flow_coordinator` 섹션을 확인합니다.
2. 이 파일에 역할별 입력 문서나 절차를 새로 복제하지 않습니다.
3. 작업 종료 시 `team-spec.md`의 `공통 출력 블록`을 따릅니다.
