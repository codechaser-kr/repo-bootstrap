---
name: run-harness
description: 현재 repo-bootstrap 하네스 상태를 읽고 시작 역할과 필요한 하네스 재진입 Phase를 안내합니다. 하네스 실행, 갱신, 상태 점검 요청에서 사용합니다.
---

# run-harness

이 스킬은 얇은 역할 포인터입니다. 역할의 목적, 우선 입력, 절차, 출력, 다음 역할, 종료 기준은 `.harness/docs/team-spec.md`의 `run_harness` 섹션을 단일 원천으로 따릅니다.

## 실행 규칙

1. 먼저 `.harness/docs/team-spec.md`를 읽고 `run_harness` 섹션을 확인합니다.
2. 이 파일에 역할별 입력 문서나 절차를 새로 복제하지 않습니다.
3. 작업 종료 시 `team-spec.md`의 `공통 출력 블록`을 따릅니다.
