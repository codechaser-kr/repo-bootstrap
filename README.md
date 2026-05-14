# repo-bootstrap

Codex와 Claude에서 공통으로 사용할 수 있는 저장소 초기 세팅용 로컬 툴킷입니다.

브랜치명, 커밋 메시지, PR 설명처럼 반복해서 작성하는 Git 작업을 빠르게 처리할 수 있도록 Codex skills, Claude skills, GitHub 협업용 이슈 템플릿을 제공합니다. AI가 쓴 듯한 한글 문장을 자연스럽게 다듬는 `humanize-korean` 스킬도 Codex와 Claude 글로벌 경로에 설치할 수 있습니다.

## 포함 내용

### AI 스킬

- branch: 현재 변경사항을 분석해 더 적절한 브랜치 이름 제안
- commit: 변경사항을 분석해 Conventional Commits 형식의 커밋 메시지 제안
- pr: 현재 브랜치 기준으로 PR 제목과 설명 제안
- git-hooks: 기존 프로젝트 관리 도구와 개발 도구 구성을 확인한 뒤 Git 훅 구성
- humanize-korean: AI가 쓴 한글 문장을 의미를 유지한 채 자연스럽게 윤문

`branch`, `commit`, `pr`, `git-hooks`는 이 저장소의 스킬 파일을 설치합니다. `humanize-korean`은 설치할 때마다 upstream `main`을 받아 최신 버전으로 설치합니다.

- Codex: `Squirbie/im-not-ai-codex`의 `skills/humanize-korean`
- Claude: `epoko77-ai/im-not-ai`의 `.claude/skills/humanize-korean`, `.claude/agents`, `.claude/commands`

### GitHub 이슈 템플릿

- 기능 개발 제안
- 기능 개선 제안
- 결함 해결

## 설치

설치 스크립트는 두 가지입니다. 용도가 다르므로 필요한 스크립트를 따로 실행합니다.

### AI 스킬 설치 (`install.sh`)

Codex와 Claude의 **글로벌 경로**에 맞춰 설치합니다. 설치 후에는 어느 저장소에서든 사용할 수 있습니다.

저장소를 직접 clone한 뒤 `./install.sh`를 실행하면 `branch`, `commit`, `pr`, `git-hooks`는 현재 체크아웃된 로컬 파일을 기준으로 설치됩니다. 아래 `curl` 또는 `wget` 예시는 GitHub `main` 브랜치를 기준으로 설치합니다.

`humanize-korean`은 로컬 복사본을 쓰지 않습니다. 설치할 때 upstream GitHub tarball을 내려받으므로, 최신 윤문 스킬이 필요하면 `install.sh`를 다시 실행하면 됩니다.

```bash
curl -fsSL https://raw.githubusercontent.com/codechaser-kr/repo-bootstrap/main/install.sh | bash
```

또는

```bash
wget -qO- https://raw.githubusercontent.com/codechaser-kr/repo-bootstrap/main/install.sh | bash
```

**설치 옵션:**

Codex만 설치:

```bash
curl -fsSL https://raw.githubusercontent.com/codechaser-kr/repo-bootstrap/main/install.sh | bash -s -- --codex-only
```

Claude만 설치:

```bash
curl -fsSL https://raw.githubusercontent.com/codechaser-kr/repo-bootstrap/main/install.sh | bash -s -- --claude-only
```

**설치 위치:**

- Codex skills: `~/.codex/skills/<skill>/SKILL.md`
- Claude skills: `~/.claude/skills/<skill>/SKILL.md`
- Claude agents: `~/.claude/agents/*.md`
- Claude commands: `~/.claude/commands/*.md`

**필요 명령:**

- `curl` 또는 `wget`
- `tar`

### GitHub 템플릿 설치 (`setup-github.sh`)

**저장소별로** `.github/ISSUE_TEMPLATE/`의 이슈 템플릿과 `.github/pull_request_template.md`를 추가합니다. 템플릿을 적용할 저장소의 루트에서 실행하세요.

이 스크립트는 저장소에 포함된 `.github/ISSUE_TEMPLATE/*.md`와 `.github/pull_request_template.md`를 기준 파일로 삼아 그대로 복사합니다. `.github/workflows` 같은 다른 GitHub 설정 파일은 건드리지 않습니다.

```bash
curl -fsSL https://raw.githubusercontent.com/codechaser-kr/repo-bootstrap/main/setup-github.sh | bash
```

설치 후 변경사항을 커밋하고 푸시하면 GitHub Issues와 Pull Requests에서 템플릿을 사용할 수 있습니다.

**설치되는 템플릿:**

- 기능 개발 제안 (`feature_template.md`)
- 기능 개선 제안 (`improvement_template.md`)
- 결함 해결 (`fix_templatebug.md`)
- Pull Request 템플릿 (`pull_request_template.md`)

## 사용 방법

Claude에서는 skills로 설치되며 다음처럼 자연어로 요청할 수 있습니다:

```
현재 변경사항에 맞는 브랜치 이름 추천해줘
현재 변경사항에 맞는 커밋 메시지 추천해줘
현재 브랜치의 PR 제목과 설명 작성해줘
이 저장소에 맞는 Git 훅을 구성해줘
이 글 AI 티 안 나게 자연스럽게 다듬어줘
```

Codex에서는 skills 목록에서 사용할 수 있습니다. 예를 들어 다음처럼 자연어로 호출할 수 있습니다:

```text
현재 변경사항에 맞는 브랜치 이름 추천해줘
현재 변경사항에 맞는 커밋 메시지 추천해줘
현재 브랜치의 PR 제목과 설명 작성해줘
이 저장소에 맞는 Git 훅을 구성해줘
이 글 AI 티 안 나게 자연스럽게 다듬어줘
```

## 제거

전체 제거:

```bash
curl -fsSL https://raw.githubusercontent.com/codechaser-kr/repo-bootstrap/main/uninstall.sh | bash
```

Codex만 제거:

```bash
curl -fsSL https://raw.githubusercontent.com/codechaser-kr/repo-bootstrap/main/uninstall.sh | bash -s -- --codex-only
```

Claude만 제거:

```bash
curl -fsSL https://raw.githubusercontent.com/codechaser-kr/repo-bootstrap/main/uninstall.sh | bash -s -- --claude-only
```

Claude 제거 시 `humanize-korean` 설치 과정에서 함께 설치한 agents/commands도 manifest를 기준으로 제거합니다.

## 주의사항

- 일부 스킬은 현재 디렉토리가 Git 저장소라고 가정합니다.
- 기본 비교 브랜치는 main입니다.
- master 또는 다른 기본 브랜치를 사용하는 경우 결과가 다를 수 있습니다.

## 라이선스

MIT
