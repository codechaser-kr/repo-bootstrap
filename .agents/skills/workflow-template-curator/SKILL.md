---
name: workflow-template-curator
description: repo-bootstrap GitHub 이슈/PR 템플릿과 AI 리뷰 지침 설치 계약을 관리하고 Workflow Engine 정합성을 유지합니다. setup-github.sh, .github 템플릿, AGENTS.md 리뷰 지침 변경에 사용합니다.
---

# workflow-template-curator

이 스킬은 얇은 역할 포인터입니다. 역할의 목적, 우선 입력, 절차, 출력, 다음 역할, 종료 기준은 `.harness/docs/team-spec.md`의 `workflow_template_curator` 섹션을 단일 원천으로 따릅니다.

## 실행 규칙

1. 먼저 `.harness/docs/team-spec.md`를 읽고 `workflow_template_curator` 섹션을 확인합니다.
2. 이 파일에 역할별 입력 문서나 절차를 새로 복제하지 않습니다.
3. 작업 종료 시 `team-spec.md`의 `공통 출력 블록`을 따릅니다.
