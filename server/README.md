# Vexatonic Dash 2 서버 (PocketBase)

채보 파일과 플레이어별 기록(점수/랭크 등)을 저장하는 백엔드입니다. [PocketBase](https://pocketbase.io/)를 사용하며, 실시간 통신 없이 REST API로 클라이언트와 정보를 주고받는 구조입니다.

## 로컬에서 실행하기

1. [PocketBase 릴리즈 페이지](https://github.com/pocketbase/pocketbase/releases)에서 OS에 맞는 실행 파일을 받아 이 `server/` 폴더에 둡니다. (테스트는 v0.28.4 기준으로 확인했습니다.)
2. 아래 명령으로 실행합니다. `pb_migrations` 폴더의 스키마가 최초 실행 시 자동으로 적용됩니다.

```bash
./pocketbase serve --migrationsDir ./pb_migrations
```

3. 콘솔에 표시되는 주소(기본 `http://127.0.0.1:8090`)로 접속해 `/api/_/` (Admin UI)에서 최초 관리자(superuser) 계정을 생성합니다. 또는 CLI로:

```bash
./pocketbase superuser create admin@example.com <비밀번호>
```

4. `pb_data/` 폴더에 SQLite DB와 업로드된 파일이 저장됩니다. 이 폴더는 git에 커밋하지 않습니다 (`.gitignore` 참고).

## 스키마

### `users` (PocketBase 기본 Auth 컬렉션)
이메일/비밀번호 로그인. 별도 커스텀 필드는 아직 추가하지 않았습니다.

### `charts`
곡(채보) 메타데이터와 파일. **superuser만 생성/수정 가능** — 플레이어가 직접 업로드하는 게 아니라, 채보 제작자(=개발자)가 Admin UI 또는 API로 올리는 방식입니다.

| 필드 | 타입 | 설명 |
|---|---|---|
| chart_key | text | 클라이언트의 채보 폴더 식별자와 대응하는 고유 키 (unique) |
| song_name | text | 곡 이름 |
| artist | text | 아티스트 |
| difficulty_levels | json | `[Easy, Hard, Vex]` 난이도 숫자 배열 (METADATA.txt의 LEVEL 라인과 대응) |
| length_ms | number | 곡 길이 (ms) |
| music_file | file | 음원 파일 |
| easy_chart / hard_chart / vex_chart | file | 난이도별 채보(.txt) 파일 |

### `scores`
유저별 채보/난이도별 최고 기록. 클라이언트의 `play_data.cfg`에 저장되던 값과 1:1로 대응됩니다 (`IngameDataManager.on_song_end()` 참고).

| 필드 | 타입 | 설명 |
|---|---|---|
| user | relation → users | 소유자 |
| chart | relation → charts | 대상 채보 |
| difficulty | number | 난이도 인덱스 (0=Easy, 1=Hard, 2=Vex) |
| best_score | number | 최고 점수 |
| vexatonic_count | number | 최고 Vexatonic 판정 수 |
| combo_lamp | number | IngameDataManager.ComboLamp (0=GameOver, 1=None, 2=FullCombo, 3=FullVexatonic) |
| paint_lamp | bool | Perfect Paint 달성 여부 |
| rank | number | IngameDataManager.Rank |
| best_paint_ratio | number | 최고 Paint 비율 (0.0~1.0) |

권한 규칙: `user`, `chart`, `difficulty` 조합이 unique이고, 본인(`@request.auth.id = user`) 소유의 레코드만 생성/수정할 수 있습니다. 목록/조회는 로그인한 유저만 가능합니다.

## 알려진 제한사항 (다음 단계에서 다룰 것)
- 클라이언트(`ServerAPI.gd`)는 로그인 토큰을 저장만 하고 **자동 갱신은 아직 구현하지 않았습니다** — 토큰 만료 시 재로그인이 필요합니다.
- 실제 게임플레이 코드(`IngameDataManager`, `SelectManager` 등)는 아직 이 서버와 연동되어 있지 않습니다. 지금은 서버 스키마와 Godot 쪽 통신 래퍼(`ServerAPI.gd`)만 준비된 상태입니다.
- 실시간 랭킹은 아직 없지만, PocketBase가 SSE 기반 realtime 구독을 기본 지원하므로 나중에 `scores` 컬렉션을 구독하는 방식으로 확장할 수 있습니다.
