# 하네스 아키텍처

## 선택한 패턴

- 기본 패턴: 파이프라인
- 보조 패턴: 생성-검증
- 실행 모드: 주 에이전트 중심 실행

## 구조 결정

`repo-bootstrap`은 애플리케이션 런타임보다 배포 스크립트와 Markdown 계약이 중심이다. 따라서 역할 팀도 구현자 중심이 아니라 설치 경계, 템플릿 계약, QA, 운영 감사(audit)를 분리하는 구조가 적합하다.

## 역할 흐름

1. `run-harness`: 요청과 최신 상태를 읽고 시작 역할을 고른다.
2. `bootstrap-surface-analyst`: 설치/템플릿/리뷰 지침 표면을 분석한다.
3. `bootstrap-flow-coordinator`: 다음 역할과 재진입 Phase를 조율한다.
4. `installer-boundary-maintainer` 또는 `workflow-template-curator`: 변경 표면에 따라 구현/문서 정렬을 맡는다.
5. `bootstrap-release-qa`: 검증과 잔여 위험을 정리한다.
6. `harness-operations-auditor`: 하네스 구조 자체의 운영 가능성을 판정한다.

## 재구성 조건

- 전역 설치 정책이 크게 바뀌면 `하네스 Phase 1~2`로 재진입한다.
- 역할 인벤토리가 바뀌면 `하네스 Phase 2~4`로 재진입한다.
- 로그나 오케스트레이션이 최신 상태를 안내하지 못하면 `하네스 Phase 5~6`으로 재진입한다.
