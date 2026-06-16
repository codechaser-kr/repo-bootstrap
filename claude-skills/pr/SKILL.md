---
allowed-tools: Bash(git branch:*), Bash(git log:*), Bash(git diff:*), Bash(gh issue list:*), Bash(gh issue view:*)
description: 현재 브랜치 기준으로 PR 제목과 설명을 제안합니다
---

## Context

- Current branch: !`git branch --show-current`
- Commits since `main`: !`git log main..HEAD --oneline`
- Changed files since `main`: !`git diff main...HEAD --stat`
- Detailed diff since `main`: !`git diff main...HEAD`
- Recent commits: !`git log -10 --oneline`
- Related issue lookup: 명시적 이슈 번호가 없을 때만 `gh issue list --limit 50`으로 열린 이슈를 조회합니다.

## Your task

현재 브랜치에 대해 GitHub Pull Request 제목과 설명을 제안해주세요.

### PR 제목 형식

Conventional Commits 형식을 따르되 스코프는 사용하지 않고 한글로 작성합니다.

```text
<type>: <description>
```

Type 종류:

- `feat`: 새로운 기능 추가
- `fix`: 버그 수정
- `refactor`: 코드 리팩토링, 성능 개선
- `style`: 코드 스타일 변경
- `test`: 테스트 추가 또는 수정
- `docs`: 문서 변경
- `chore`: 빌드, 설정, 의존성 등 기타 변경

제목 작성 규칙:

- 50자 이내
- 명령형 또는 명사형
- 마침표 없음

### PR Description 형식

반드시 아래 마크다운 형식을 따르세요:

```md
**왜 변경하려 하시나요?**

(변경 이유를 명확하게 작성)

**어떻게 변경하려고 하나요? (optional)**

- N/A

**해당 변경으로 영향받거나 검토해야 할 사항은 무엇인가요? (optional)**

- N/A

**머지하기 전에 반드시 확인되어야 할 사항이 있다면 작성해 주세요. (optional)**

- [ ] N/A

**연관 이슈 (optional)**

- N/A
```

Description 작성 가이드:

1. 목적과 배경을 먼저 설명합니다.
2. 주요 변경사항은 짧은 불릿으로 정리합니다.
3. 영향 범위나 검토 포인트가 있으면 분리해서 적습니다.
4. 머지 전 확인사항은 체크리스트로 적습니다.
5. 연관 이슈를 다음 순서로 확인합니다.
   - 먼저 브랜치명, 커밋 메시지, diff에서 `#123`, `issue-123`, `issues/123`, `GH-123` 같은 명시적 이슈 번호를 찾습니다.
   - 명시적 번호가 없으면 `gh issue list --limit 50`으로 열린 이슈를 조회하고, 이 PR의 주제(제목·변경 파일·diff)와 대조해 같은 기능/정책/버그를 다루는 이슈가 있는지 판단합니다. 제목만으로 모호하면 `gh issue view <번호>`로 본문을 확인합니다.
6. 주제가 분명히 일치하는 이슈가 있으면 `- Related: #이슈번호` 형식으로 적습니다. 단 `- Closes #이슈번호`는 이 PR이 이슈를 닫아야 한다는 명시가 있을 때만 사용합니다(추측으로 Closes를 쓰지 않습니다).
7. 일치하는 이슈가 없거나 연관이 확실하지 않으면 `- N/A`를 유지합니다. 후보가 있으나 확신이 낮으면 사용자에게 확인을 제안합니다.

### 출력 형식

다음 형식으로 답변해주세요:

1. 변경사항 요약
   - 브랜치명
   - 커밋 수
   - 변경된 파일 수
2. 제안하는 PR 제목 2-3개
3. 추천 제목 1개
4. PR Description
