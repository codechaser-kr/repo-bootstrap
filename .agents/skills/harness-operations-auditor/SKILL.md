---
name: harness-operations-auditor
description: repo-bootstrap 로컬 하네스의 team-spec, agent/skill 포인터, 오케스트레이션, 로그 정합성을 감사(audit)하고 재진입 Phase를 권고합니다. 하네스 구조 점검과 운영 유지보수에 사용합니다.
---

# harness-operations-auditor

이 스킬은 얇은 역할 포인터입니다. 역할의 목적, 우선 입력, 절차, 출력, 다음 역할, 종료 기준은 `.harness/docs/team-spec.md`의 `harness_operations_auditor` 섹션을 단일 원천으로 따릅니다.

## 실행 규칙

1. 먼저 `.harness/docs/team-spec.md`를 읽고 `harness_operations_auditor` 섹션을 확인합니다.
2. 이 파일에 역할별 입력 문서나 절차를 새로 복제하지 않습니다.
3. 작업 종료 시 `team-spec.md`의 `공통 출력 블록`을 따릅니다.
