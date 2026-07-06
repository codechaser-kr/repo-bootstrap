# 팀 구조

## 역할 목록

- `run-harness`: 시작 진입과 재진입 판단
- `bootstrap-surface-analyst`: 저장소 표면과 실패 비용 분석
- `bootstrap-flow-coordinator`: 중심 조율과 handoff 관리
- `installer-boundary-maintainer`: 설치/제거 스크립트 경계 유지보수
- `workflow-template-curator`: GitHub 템플릿과 AI 리뷰 지침 계약 유지보수
- `bootstrap-release-qa`: 변경 검증과 릴리즈 위험 정리
- `harness-operations-auditor`: 하네스 운영 감사(audit)

## 책임 경계

- 시작 진입과 중심 조율은 분리한다.
- 설치 스크립트 변경과 GitHub 템플릿 변경은 분리한다.
- QA는 제품 품질과 릴리즈 위험을 보고, 운영 감사(audit)는 하네스 구조 정합성을 본다.

## 보존 자산

- `AGENTS.md`의 ChatGPT Codex Connector 리뷰 지침은 유지한다.
- `.harness/logs/github-workflow-log.md`는 GitHub Workflow Engine 보조 로그로 유지한다.
