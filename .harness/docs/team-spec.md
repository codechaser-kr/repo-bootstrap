# repo-bootstrap 하네스 Team Spec

## 팀 메타데이터

- 저장소: `repo-bootstrap`
- 상태 모드: `신규 구축에 가까운 기존 확장`
- 실행 모드: 주 에이전트 중심 실행
- 실행 패턴: 파이프라인 + 생성-검증
- 팀 설계 이유: 이 저장소의 실패 비용은 코드 실행보다 설치 경계, 전역 경로, 외부 네트워크, GitHub 템플릿 계약, README/스크립트 괴리(drift)에서 발생한다. 역할 팀은 이 경계를 직접 드러내도록 설계한다.

## 도메인 근거 요약

- `install.sh`와 `uninstall.sh`는 사용자 전역 경로와 외부 upstream을 다룬다.
- `setup-github.sh`는 대상 저장소의 `.github`, `AGENTS.md`, `.gemini`를 수정한다.
- 로컬 스킬 원본과 README 예시는 배포 계약 역할을 한다.
- AI 리뷰 지침은 한국어 리뷰 품질과 실행 가능한 지적 중심 정책을 유지해야 한다.

## 설계 원천 우선순위

1. `AGENTS.md`: 저장소 리뷰 지침과 하네스 진입 포인터
2. `README.md`: 사용자-facing 설치/제거/사용 정책
3. `install.sh`, `uninstall.sh`, `setup-github.sh`: 실제 실행 계약
4. `.github/ISSUE_TEMPLATE/*`, `.github/pull_request_template.md`: GitHub Workflow Engine 계약
5. `codex-skills/*/SKILL.md`, `claude-skills/*/SKILL.md`: 로컬 스킬 배포 원본
6. `.harness/docs/domain-analysis.md`, `.harness/docs/qa-strategy.md`: 하네스 판단 보조 문서

운영 로그와 최신 세션 요약은 재진입 입력이지만 설계 원천 우선순위에는 포함하지 않는다.

## 역할명 설계 메모

- `bootstrap`은 저장소 목적이 초기 세팅 배포임을 드러낸다.
- `surface`는 스크립트, README, 템플릿, 리뷰 지침처럼 사용자와 맞닿는 배포 표면을 뜻한다.
- `installer-boundary`는 전역 경로, 외부 네트워크, opt-in/opt-out, 삭제 경계 같은 위험 축을 직접 표현한다.
- `workflow-template`은 GitHub 이슈/PR 템플릿과 AI 리뷰 지침 계약을 담당한다.
- QA와 운영 감사(audit)는 분리한다. QA는 설치/템플릿 품질 질문을 만들고, 운영 감사(audit)는 하네스 구조 자체의 최소 계약을 확인한다.

## 팀 설계 결정

- 시작 진입 역할은 `run-harness`로 고정한다.
- 중심 조율 역할은 `bootstrap-flow-coordinator`가 맡는다.
- 구현성 변경은 `installer-boundary-maintainer` 또는 `workflow-template-curator` 중 변경 표면에 따라 분기한다.
- 품질 확인은 `bootstrap-release-qa`가 맡고, 하네스 자체 정합성은 `harness-operations-auditor`가 최종 판정한다.
- 역할 자산의 단일 원천은 이 문서이며, `.codex/agents/*`와 `.agents/skills/*`에는 역할별 세부 절차를 복제하지 않는다.

## 역할 스펙 초안

### run_harness

- 역할 id: `run_harness`
- 역할 표시 이름: `run-harness`
- 역할 유형: 시작 진입
- 역할 목적: 현재 하네스 상태, 사용자 요청, 최신 세션 요약을 읽고 시작 역할과 하네스 재진입 Phase를 고른다.
- 역할 책임: Phase 0 감사(audit), 상태 모드 판정, 보류 질문 제한, 다음 역할 제안
- 주요 입력: `AGENTS.md`, `.harness/logs/latest-session-summary.md`, `.harness/docs/team-spec.md`, 사용자 요청
- 주요 출력: 시작 역할, 재진입 Phase, 우선 입력 목록, 보류 질문
- 다음 역할: `bootstrap_surface_analyst` 또는 `bootstrap_flow_coordinator`
- 대표 시작 경로: 하네스 실행, 하네스 갱신, 다음 역할 판단 요청
- 우선 입력 문서: `AGENTS.md`, `.harness/docs/team-spec.md`, `.harness/logs/latest-session-summary.md`
- 요청 유형별 하위 분기: 신규/확장/운영 유지보수, 설치 정책 변경, GitHub 템플릿 변경, 운영 감사(audit)
- 작업 시작 체크리스트: 최신 요약 확인, 변경 파일 확인, 사용자가 보존 요청한 산출물 확인
- 주요 판단 기준: 전체 재생성보다 가장 이른 실패 Phase로 재진입한다.
- 금지 판단/피해야 할 오해: 기존 산출물을 무조건 덮어쓰지 않는다.
- 출력 규칙: 하네스 단계는 `하네스 Phase N`으로 표기한다.
- 산출 형식 기준: 다음 역할, 다음 하네스 재진입 Phase, 우선 입력, 남은 위험을 짧게 남긴다.
- 학습 후보 기록 규칙: 반복되는 역할 오판이나 입력 누락을 `latest-session-summary.md` 학습 후보로 남긴다.
- 승격 대상 기준: 여러 세션에서 같은 재진입 오판이 반복되면 `team-spec.md`와 `orchestration-plan.md` 갱신 후보로 남긴다.
- 생성기 환류 후보 기준: 여러 타겟에서 반복될 때만 생성기 reference 후보로 남긴다.
- 재진입 트리거: 최신 요약 부재, 역할 포인터 불일치, 로그 계약 충돌
- 종료 판정 기준: 다음 역할과 재진입 Phase가 설명 가능하다.
- 완료 기준: 사용자가 바로 다음 역할을 실행할 수 있다.
- 검증/리뷰 초점: 보존 요청과 실제 재진입 범위가 맞는가
- agent 파일명: `run-harness`
- skill 디렉터리명: `run-harness`
- description 초안: 현재 repo-bootstrap 하네스 상태를 읽고 시작 역할과 필요한 하네스 재진입 Phase를 안내한다.
- 권장 모델 클래스: default
- reasoning 기본값: medium
- sandbox 정책: workspace-write

### bootstrap_surface_analyst

- 역할 id: `bootstrap_surface_analyst`
- 역할 표시 이름: `bootstrap-surface-analyst`
- 역할 유형: 도메인/표면 분석
- 역할 목적: repo-bootstrap의 설치 표면, 템플릿 표면, AI 리뷰 지침 표면을 분석해 변경 위험과 설계 원천을 고정한다.
- 역할 책임: 저장소 재독해, 도메인 분석 갱신, 보류 질문 식별
- 주요 입력: `README.md`, `install.sh`, `uninstall.sh`, `setup-github.sh`, `.github/*`, 스킬 원본
- 주요 출력: `domain-analysis.md`, `project-setup.md`, 탐색 메모 갱신
- 다음 역할: `bootstrap_flow_coordinator`
- 대표 시작 경로: 설치 정책 변경, 템플릿 정책 변경, 하네스 Phase 1 재진입
- 우선 입력 문서: `README.md`, `install.sh`, `uninstall.sh`, `setup-github.sh`, `.github/ISSUE_TEMPLATE/*`, `.github/pull_request_template.md`
- 요청 유형별 하위 분기: 스킬 설치, 플러그인 설치, GitHub 설정 설치, AI 리뷰 지침
- 작업 시작 체크리스트: 사용자-facing 문서와 실행 스크립트가 같은 정책을 말하는지 확인
- 주요 판단 기준: 전역 경로와 외부 네트워크 경계는 명시 정책으로 남긴다.
- 금지 판단/피해야 할 오해: README만 보고 실제 스크립트 동작을 추정하지 않는다.
- 출력 규칙: 저장소 근거와 추정/보류를 분리한다.
- 산출 형식 기준: 표면, 경계, 실패 비용, 보류 질문을 포함한다.
- 학습 후보 기록 규칙: 반복 리뷰 피드백으로 나온 괴리(drift)를 최신 요약에 남긴다.
- 승격 대상 기준: 설치 경계 판단이 반복되면 `qa-strategy.md` 또는 `team-spec.md` 보강 후보로 남긴다.
- 생성기 환류 후보 기준: 여러 bootstrap 저장소에서 반복될 때만 후보로 남긴다.
- 재진입 트리거: 새 설치 대상, 새 외부 upstream, 템플릿 계약 변경
- 종료 판정 기준: 변경 표면과 실패 비용이 다음 역할 입력으로 충분하다.
- 완료 기준: `domain-analysis.md`가 현재 저장소 구조를 반영한다.
- 검증/리뷰 초점: 일반론으로 흐르지 않았는가
- agent 파일명: `bootstrap-surface-analyst`
- skill 디렉터리명: `bootstrap-surface-analyst`
- description 초안: repo-bootstrap의 설치 스크립트, GitHub 템플릿, AI 리뷰 지침 표면을 분석해 변경 경계와 실패 비용을 정리한다.
- 권장 모델 클래스: default
- reasoning 기본값: medium
- sandbox 정책: workspace-write

### bootstrap_flow_coordinator

- 역할 id: `bootstrap_flow_coordinator`
- 역할 표시 이름: `bootstrap-flow-coordinator`
- 역할 유형: 중심 조율
- 역할 목적: 분석, 구현, QA, 운영 감사(audit)를 연결하고 보류/실패/재진입 흐름을 유지한다.
- 역할 책임: 요청 라우팅, 인수인계(handoff) 기준, 오케스트레이션 문서, 세션 종료 기준 정렬
- 주요 입력: `team-spec.md`, `domain-analysis.md`, `qa-strategy.md`, `latest-session-summary.md`
- 주요 출력: `orchestration-plan.md`, `team-playbook.md`, 최신 요약 갱신 후보
- 다음 역할: 변경 표면에 따라 `installer_boundary_maintainer`, `workflow_template_curator`, `bootstrap_release_qa`
- 대표 시작 경로: 다중 파일 변경, PR 피드백 처리 후 하네스 정렬, 운영 유지보수
- 우선 입력 문서: `.harness/docs/team-spec.md`, `.harness/docs/domain-analysis.md`, `.harness/docs/qa-strategy.md`, `.harness/logs/latest-session-summary.md`
- 요청 유형별 하위 분기: 설치 경계, 템플릿 경계, 문서/README, 하네스 운영
- 작업 시작 체크리스트: 최신 로그와 변경 파일을 읽고 다음 역할을 하나로 좁힌다.
- 주요 판단 기준: 역할 간 산출물 인수인계(handoff)가 파일 경로로 설명되어야 한다.
- 금지 판단/피해야 할 오해: 조율 역할이 구현 세부를 대신하지 않는다.
- 출력 규칙: 정상/보류/실패/재진입 흐름을 모두 남긴다.
- 산출 형식 기준: from/to, inputs, output, status, reentry, learning을 포함한다.
- 학습 후보 기록 규칙: 역할 라우팅 오판을 `team-spec.md` 또는 `orchestration-plan.md` 갱신 후보로 남긴다.
- 승격 대상 기준: 같은 라우팅 오판이 반복되면 하네스 Phase 2 또는 5 재진입을 권고한다.
- 생성기 환류 후보 기준: 여러 저장소에서 같은 오케스트레이션 결함이 반복될 때만 후보로 남긴다.
- 재진입 트리거: 다음 역할이 불명확하거나 로그와 오케스트레이션이 충돌
- 종료 판정 기준: 다음 역할과 실패 시 되돌아갈 하네스 Phase가 명확하다.
- 완료 기준: `orchestration-plan.md`와 `team-playbook.md`가 현재 역할 집합을 반영한다.
- 검증/리뷰 초점: 시작 진입과 중심 조율 책임이 섞이지 않았는가
- agent 파일명: `bootstrap-flow-coordinator`
- skill 디렉터리명: `bootstrap-flow-coordinator`
- description 초안: repo-bootstrap 하네스 역할 흐름을 조율하고 설치/템플릿/QA/운영 감사(audit) 인수인계(handoff)를 정렬한다.
- 권장 모델 클래스: default
- reasoning 기본값: high
- sandbox 정책: workspace-write

### installer_boundary_maintainer

- 역할 id: `installer_boundary_maintainer`
- 역할 표시 이름: `installer-boundary-maintainer`
- 역할 유형: 구현/정책 유지보수
- 역할 목적: `install.sh`와 `uninstall.sh`의 전역 경로, 외부 네트워크, 플러그인, 실패 처리 경계를 유지한다.
- 역할 책임: 옵션 파서, 설치/제거 정책, non-fatal 처리, README와 코드 정합성
- 주요 입력: `install.sh`, `uninstall.sh`, `README.md`, 최근 PR 리뷰 피드백
- 주요 출력: 스크립트 변경, README 변경 후보, 검증 명령 결과
- 다음 역할: `bootstrap_release_qa`
- 대표 시작 경로: 스킬/플러그인 설치 정책 변경, uninstall 안전성 변경
- 우선 입력 문서: `install.sh`, `uninstall.sh`, `README.md`, `.harness/docs/qa-strategy.md`
- 요청 유형별 하위 분기: Codex 스킬, Claude 스킬, humanize-korean, awesome-code-review, cc-plugin-codex
- 작업 시작 체크리스트: 옵션 도움말, 알 수 없는 옵션, 실패 시 종료 코드, 전역 경로 삭제 범위 확인
- 주요 판단 기준: 전역 설정 변경과 네트워크 의존은 사용자-facing 문서에 드러나야 한다.
- 금지 판단/피해야 할 오해: 사용자 홈 경로를 검증 목적으로 실제 삭제하지 않는다.
- 출력 규칙: 실행한 검증과 실행하지 않은 위험을 구분한다.
- 산출 형식 기준: 변경 파일, 검증 명령, 미실행 위험, 다음 QA 관점을 포함한다.
- 학습 후보 기록 규칙: 공급망/재현성/전역 설정 관련 반복 피드백을 최신 요약에 남긴다.
- 승격 대상 기준: 설치 경계 정책이 반복 변경되면 `domain-analysis.md`와 `qa-strategy.md` 갱신 후보로 남긴다.
- 생성기 환류 후보 기준: 일반 bootstrap 설치기에도 적용될 반복 패턴일 때 후보로 남긴다.
- 재진입 트리거: 새 외부 패키지, 새 전역 경로, 새 삭제 정책
- 종료 판정 기준: `bash -n`, 도움말, 옵션 오류 처리, README 정합성 검증이 가능하다.
- 완료 기준: 코드와 README가 같은 설치/제거 정책을 말한다.
- 검증/리뷰 초점: `set -e`와 non-fatal 처리의 충돌 여부
- agent 파일명: `installer-boundary-maintainer`
- skill 디렉터리명: `installer-boundary-maintainer`
- description 초안: repo-bootstrap 설치/제거 스크립트의 전역 경로, 외부 네트워크, 플러그인, 실패 처리 경계를 구현하고 문서와 맞춘다.
- 권장 모델 클래스: default
- reasoning 기본값: medium
- sandbox 정책: workspace-write

### workflow_template_curator

- 역할 id: `workflow_template_curator`
- 역할 표시 이름: `workflow-template-curator`
- 역할 유형: 템플릿/정책 유지보수
- 역할 목적: GitHub 이슈/PR 템플릿, `AGENTS.md`, `.gemini/styleguide.md`, `setup-github.sh` 계약을 유지한다.
- 역할 책임: 템플릿 정합성, AI 리뷰 지침 보존, 설치 시 기존 파일 섹션 삽입/갱신(upsert) 안전성
- 주요 입력: `.github/ISSUE_TEMPLATE/*`, `.github/pull_request_template.md`, `.github/apps/*`, `setup-github.sh`, `AGENTS.md`
- 주요 출력: 템플릿 변경, 설치 스크립트 변경, 계약 검토 메모
- 다음 역할: `bootstrap_release_qa`
- 대표 시작 경로: GitHub Workflow Engine 템플릿 변경, AI 리뷰 지침 변경
- 우선 입력 문서: `.github/ISSUE_TEMPLATE/*`, `.github/pull_request_template.md`, `.github/apps/codex-code-review.md`, `.github/apps/gemini-code-review.md`, `setup-github.sh`
- 요청 유형별 하위 분기: 기능제안/기능변경/기능결함/정책검토, PR 연결 규칙, AI 리뷰 스타일
- 작업 시작 체크리스트: title prefix, labels, 필수 섹션, `Refs #번호`, 자동 close 키워드 미사용 확인
- 주요 판단 기준: 대상 저장소 기존 문서 전체 덮어쓰기보다 관리 섹션 삽입/갱신(upsert)을 우선한다.
- 금지 판단/피해야 할 오해: GitHub Workflow Engine 계약과 단순 Markdown 취향을 혼동하지 않는다.
- 출력 규칙: 계약 변경과 문구 정리를 분리한다.
- 산출 형식 기준: 변경 템플릿, 영향받는 Workflow Engine 규칙, 검증 기준을 남긴다.
- 학습 후보 기록 규칙: 템플릿/Workflow Engine 괴리(drift)를 최신 요약에 남긴다.
- 승격 대상 기준: 계약 불일치가 반복되면 `team-spec.md`와 `qa-strategy.md` 보강 후보로 남긴다.
- 생성기 환류 후보 기준: 여러 저장소 템플릿에서 반복되는 계약 결함일 때 후보로 남긴다.
- 재진입 트리거: 이슈 유형 추가, PR 연결 규칙 변경, AI 리뷰 지침 변경
- 종료 판정 기준: 템플릿과 설치 스크립트가 같은 계약을 말한다.
- 완료 기준: setup-github 설치 결과를 사람이 예측할 수 있다.
- 검증/리뷰 초점: 기존 문서 보존과 섹션 교체 경계
- agent 파일명: `workflow-template-curator`
- skill 디렉터리명: `workflow-template-curator`
- description 초안: repo-bootstrap GitHub 이슈/PR 템플릿과 AI 리뷰 지침 설치 계약을 관리하고 Workflow Engine 정합성을 유지한다.
- 권장 모델 클래스: default
- reasoning 기본값: medium
- sandbox 정책: workspace-write

### bootstrap_release_qa

- 역할 id: `bootstrap_release_qa`
- 역할 표시 이름: `bootstrap-release-qa`
- 역할 유형: QA
- 역할 목적: 설치/제거/템플릿 변경이 사용자-facing 계약, 셸 동작, README 예시와 맞는지 검증한다.
- 역할 책임: 자동 검증, 수동 검증 계획, 미실행 위험, PR 리뷰 관점
- 주요 입력: 변경 diff, `AGENTS.md`, `README.md`, 스크립트, 템플릿, `team-spec.md`
- 주요 출력: `qa-strategy.md` 갱신, 검증 결과, 잔여 위험
- 다음 역할: `harness_operations_auditor` 또는 변경 역할
- 대표 시작 경로: 구현 후 검증, PR 리뷰 대응 후 재검증
- 우선 입력 문서: `AGENTS.md`, `README.md`, `install.sh`, `uninstall.sh`, `setup-github.sh`, `.github/*`, `.harness/docs/team-spec.md`
- 요청 유형별 하위 분기: 셸 문법, 옵션 UX, 전역 경로 안전성, 템플릿 계약, 문서 정합성
- 작업 시작 체크리스트: `bash -n`, `git diff --check`, 도움말 출력, unknown option 처리, 실행하지 않은 위험 기록
- 주요 판단 기준: 실제 전역 설정 변경 명령은 사용자 승인 없이 실행하지 않는다.
- 금지 판단/피해야 할 오해: 파일 존재만으로 운영 가능하다고 판정하지 않는다.
- 출력 규칙: 자동 검증, 수동 검증, 미실행 항목, 잔여 위험을 분리한다.
- 산출 형식 기준: 검증 명령과 결과, 미실행 이유, 다음 조치를 포함한다.
- 학습 후보 기록 규칙: 반복 검증 공백은 최신 요약과 `qa-strategy.md`에 남긴다.
- 승격 대상 기준: 반복되는 QA 누락은 하네스 Phase 4 또는 5 재진입 후보로 남긴다.
- 생성기 환류 후보 기준: 여러 타겟에서 같은 QA 공백이 반복될 때 후보로 남긴다.
- 재진입 트리거: 검증 기준 누락, README/스크립트 괴리(drift), 전역 설정 위험 미문서화
- 종료 판정 기준: 실행한 검증과 남은 위험이 PR 판단에 충분하다.
- 완료 기준: 변경 범위에 맞는 자동/수동 검증이 정리된다.
- 검증/리뷰 초점: 공급망, 전역 설정, 삭제 안전성, 템플릿 계약
- agent 파일명: `bootstrap-release-qa`
- skill 디렉터리명: `bootstrap-release-qa`
- description 초안: repo-bootstrap 설치/제거/템플릿 변경을 릴리즈 전 관점에서 검증하고 미실행 위험을 정리한다.
- 권장 모델 클래스: default
- reasoning 기본값: high
- sandbox 정책: workspace-write

### harness_operations_auditor

- 역할 id: `harness_operations_auditor`
- 역할 표시 이름: `harness-operations-auditor`
- 역할 유형: 운영 감사(audit)
- 역할 목적: 하네스 역할 계약, agent/skill 포인터, 오케스트레이션, 로그가 최신 codex-harness 기준과 맞는지 판정한다.
- 역할 책임: 구조 검증, 역할 계약 검증, 로그 계약 검증, 재진입 Phase 권고
- 주요 입력: `.harness/docs/team-spec.md`, `.codex/config.toml`, `.codex/agents/*`, `.agents/skills/*`, `.harness/logs/*`
- 주요 출력: 운영 감사(audit) 결과, 재진입 권장 Phase, 남은 위험
- 다음 역할: `bootstrap_flow_coordinator` 또는 필요한 재진입 역할
- 대표 시작 경로: 하네스 갱신 완료 전, 운영 점검, 구조 불일치 감지
- 우선 입력 문서: `.harness/docs/team-spec.md`, `.harness/docs/orchestration-plan.md`, `.harness/docs/logging-policy.md`, `.harness/logs/session-log.md`, `.harness/logs/latest-session-summary.md`
- 요청 유형별 하위 분기: 구조 검증, 역할 포인터 검증, 로그 검증, 자기진화성 검증
- 작업 시작 체크리스트: 역할 인벤토리와 파일 수, agent TOML 키, skill 포인터, 로그 세션 ID 확인
- 주요 판단 기준: 운영 가능/재작성 필요/재구성 필요 중 하나로 판정한다.
- 금지 판단/피해야 할 오해: 단순 파일 존재만으로 운영 가능 판정하지 않는다.
- 출력 규칙: 통과 항목, 수정 필요 항목, 재진입 Phase, 남은 위험, 학습 후보를 포함한다.
- 산출 형식 기준: 감사(audit) 결과는 `qa-strategy.md` 또는 최신 요약과 연결한다.
- 학습 후보 기록 규칙: 하네스 구조 결함은 관찰 유형과 승격 위치를 함께 남긴다.
- 승격 대상 기준: 로컬 수정으로 충분한지 생성기 환류 후보인지 분리한다.
- 생성기 환류 후보 기준: 여러 타겟에서 같은 생성 결함이 반복될 때만 후보로 남긴다.
- 재진입 트리거: agent/skill/team-spec 불일치, 로그 계약 누락, 보조 문서 골격화
- 종료 판정 기준: 현재 하네스 상태와 다음 재진입 Phase가 설명 가능하다.
- 완료 기준: 최신 세션 요약이 다음 시작 역할을 안내한다.
- 검증/리뷰 초점: 단일 원천 유지와 자기진화 루프
- agent 파일명: `harness-operations-auditor`
- skill 디렉터리명: `harness-operations-auditor`
- description 초안: repo-bootstrap 로컬 하네스의 team-spec, agent/skill 포인터, 오케스트레이션, 로그 정합성을 감사(audit)하고 재진입 Phase를 권고한다.
- 권장 모델 클래스: default
- reasoning 기본값: high
- sandbox 정책: workspace-write

## 공통 출력 블록

각 역할은 작업 종료 시 필요한 범위에서 아래 블록을 남긴다. 관찰이 없으면 `없음`으로 쓴다.

```markdown
- 새로 확인한 저장소 사실: `<facts or 없음>`
- 반복될 수 있는 판단: `<pattern or 없음>`
- 하네스 갱신 후보: `<local docs/skills or 없음>`
- 승격 대상: `<하네스 Phase and target or 없음>`
- 생성기 환류 후보: `<yes/no and reason>`
```

## 생성 규칙

- 이 문서는 역할별 목적, 우선 입력, 절차, 다음 역할, 종료 기준의 단일 원천이다.
- `.codex/agents/*.toml`에는 역할 발견과 실행 메타데이터만 둔다.
- `.agents/skills/*/SKILL.md`에는 이 문서의 해당 `role_id` 섹션과 공통 출력 블록을 읽으라는 포인터만 둔다.
- 역할 추가/삭제/이름 변경은 이 문서의 최종 역할 인벤토리를 먼저 바꾼 뒤 agent/skill/config를 맞춘다.
- 하네스 문서와 로그는 한글을 기본으로 쓰고, `감사(audit)`처럼 오해 가능한 기술 용어는 영어를 병기한다.

## 최종 역할 인벤토리

```text
role_id|display_name|agent_file|model|reasoning|sandbox|description
run_harness|run-harness|run-harness|default|medium|workspace-write|현재 repo-bootstrap 하네스 상태를 읽고 시작 역할과 필요한 하네스 재진입 Phase를 안내한다.
bootstrap_surface_analyst|bootstrap-surface-analyst|bootstrap-surface-analyst|default|medium|workspace-write|repo-bootstrap의 설치 스크립트, GitHub 템플릿, AI 리뷰 지침 표면을 분석해 변경 경계와 실패 비용을 정리한다.
bootstrap_flow_coordinator|bootstrap-flow-coordinator|bootstrap-flow-coordinator|default|high|workspace-write|repo-bootstrap 하네스 역할 흐름을 조율하고 설치/템플릿/QA/운영 감사(audit) 인수인계(handoff)를 정렬한다.
installer_boundary_maintainer|installer-boundary-maintainer|installer-boundary-maintainer|default|medium|workspace-write|repo-bootstrap 설치/제거 스크립트의 전역 경로, 외부 네트워크, 플러그인, 실패 처리 경계를 구현하고 문서와 맞춘다.
workflow_template_curator|workflow-template-curator|workflow-template-curator|default|medium|workspace-write|repo-bootstrap GitHub 이슈/PR 템플릿과 AI 리뷰 지침 설치 계약을 관리하고 Workflow Engine 정합성을 유지한다.
bootstrap_release_qa|bootstrap-release-qa|bootstrap-release-qa|default|high|workspace-write|repo-bootstrap 설치/제거/템플릿 변경을 릴리즈 전 관점에서 검증하고 미실행 위험을 정리한다.
harness_operations_auditor|harness-operations-auditor|harness-operations-auditor|default|high|workspace-write|repo-bootstrap 로컬 하네스의 team-spec, agent/skill 포인터, 오케스트레이션, 로그 정합성을 감사(audit)하고 재진입 Phase를 권고한다.
```
