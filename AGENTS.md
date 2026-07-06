# 저장소 지침

## ChatGPT Codex Connector 리뷰 지침

- GitHub 풀 리퀘스트 리뷰 코멘트는 한국어로 작성한다.
- 코드 식별자, 파일 경로, 명령어, 패키지명, API 이름은 원문 그대로 유지한다.
- 한국어만으로 의미가 모호한 기술 용어는 영어 용어를 괄호 안에 병기한다.
- 지적 사항은 실행 가능한 문제 중심으로 간결하게 작성한다.
- 단순 선호나 사소한 문체 차이보다 버그, 회귀, 보안, 테스트 누락을 우선한다.

## 로컬 실행 하네스 지침

- 하네스 실행, 갱신, 운영 점검 요청은 `.harness/docs/team-spec.md`를 단일 원천으로 삼는다.
- 시작 진입 역할은 `run-harness`이며, 현재 상태와 최신 요약을 읽고 필요한 하네스 Phase와 다음 역할을 고른다.
- 역할별 세부 기준은 `.codex/agents/*.toml`이나 `.agents/skills/*/SKILL.md`에 복제하지 않고 `.harness/docs/team-spec.md`의 해당 `role_id` 섹션을 따른다.
- 하네스 문서와 로그는 한글로 작성하되, 감사(audit)처럼 한국어만으로 의미가 모호한 기술 용어는 영어를 괄호 안에 병기한다.
- 하네스 작업을 마치기 전 `.harness/logs/session-log.md`와 `.harness/logs/latest-session-summary.md`를 갱신한다.
