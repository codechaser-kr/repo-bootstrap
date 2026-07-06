# 오케스트레이션 계획

## 현재 상태

- 상태 모드: 신규 구축에 가까운 기존 확장
- 실행 모드: 주 에이전트 중심 실행
- 이번 기준: 기존 산출물 무조건 덮어쓰기 금지, Phase 0 감사 후 필요한 하네스 Phase만 재진입

## 요청 유형별 시작 역할

- 하네스 실행/갱신/점검: `run-harness`
- 설치/제거 정책 변경: `installer-boundary-maintainer`
- GitHub 템플릿 또는 AI 리뷰 지침 변경: `workflow-template-curator`
- PR 리뷰 대응 후 검증: `bootstrap-release-qa`
- 하네스 구조 불일치 점검: `harness-operations-auditor`

## Handoff 규칙

```text
handoff:
- from: run-harness
- to: bootstrap-surface-analyst 또는 bootstrap-flow-coordinator
- inputs: AGENTS.md, .harness/docs/team-spec.md, .harness/logs/latest-session-summary.md
- output: 시작 역할, 하네스 재진입 Phase, 우선 입력 목록
- reentry: 입력 근거가 약하면 하네스 Phase 1
```

```text
handoff:
- from: bootstrap-surface-analyst
- to: bootstrap-flow-coordinator
- inputs: README.md, install.sh, uninstall.sh, setup-github.sh, .github/*
- output: .harness/docs/domain-analysis.md
- reentry: 표면 분석이 일반론이면 하네스 Phase 1
```

```text
handoff:
- from: bootstrap-flow-coordinator
- to: installer-boundary-maintainer 또는 workflow-template-curator
- inputs: .harness/docs/team-spec.md, .harness/docs/domain-analysis.md, 최신 변경 diff
- output: 변경 역할과 검증 기준
- reentry: 역할 경계가 애매하면 하네스 Phase 2
```

```text
handoff:
- from: 변경 역할
- to: bootstrap-release-qa
- inputs: 변경 diff, README.md, 스크립트 또는 템플릿, .harness/docs/qa-strategy.md
- output: 검증 결과와 잔여 위험
- reentry: 검증 기준이 약하면 하네스 Phase 5
```

```text
handoff:
- from: bootstrap-release-qa
- to: harness-operations-auditor
- inputs: team-spec, agent/skill 포인터, 오케스트레이션, 로그
- output: 운영 가능 / 재작성 필요 / 재구성 필요 판정
- reentry: 구조 불일치 축에 따라 하네스 Phase 2~6
```

## 보류/실패 흐름

- 외부 네트워크 또는 전역 설정 변경 검증은 기본 자동 실행하지 않고 미실행 위험으로 남긴다.
- 스크립트 문법이나 도움말 검증 실패는 해당 변경 역할로 되돌린다.
- 하네스 포인터 불일치는 `harness-operations-auditor`가 판정하고 `bootstrap-flow-coordinator`가 재진입 Phase를 정한다.

## 보존 문서 호환성

- `.harness/logs/github-workflow-log.md`는 기존 GitHub Workflow Engine 로그다.
- 현재 하네스 세션 로그는 `.harness/logs/session-log.md`와 `.harness/logs/latest-session-summary.md`를 기준으로 한다.
- 두 로그는 목적이 다르므로 병합하지 않고, GitHub 상태 판단이 필요할 때만 GitHub Workflow 로그를 보조 입력으로 읽는다.
