---
name: bootstrap-release-qa
description: repo-bootstrap 설치/제거/템플릿 변경을 릴리즈 전 관점에서 검증하고 미실행 위험을 정리합니다. 셸 스크립트 검증, README 정합성, 템플릿 계약 검토에 사용합니다.
---

# bootstrap-release-qa

이 스킬은 얇은 역할 포인터입니다. 역할의 목적, 우선 입력, 절차, 출력, 다음 역할, 종료 기준은 `.harness/docs/team-spec.md`의 `bootstrap_release_qa` 섹션을 단일 원천으로 따릅니다.

## 실행 규칙

1. 먼저 `.harness/docs/team-spec.md`를 읽고 `bootstrap_release_qa` 섹션을 확인합니다.
2. 이 파일에 역할별 입력 문서나 절차를 새로 복제하지 않습니다.
3. 작업 종료 시 `team-spec.md`의 `공통 출력 블록`을 따릅니다.
