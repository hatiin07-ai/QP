# 드레스룸 기능 구축 가이드

## 구성 개요

```
어드민 페이지 (admin)
    │
    ├─ 이미지 업로드 ──► Pages Functions ──► R2 버킷
    │                  (/api/r2/upload)
    │
    ├─ 이미지 목록 ──► Pages Functions ──► R2 버킷
    │                  (/api/r2/list)
    │
    ├─ 이미지 삭제 ──► Pages Functions ──► R2 버킷
    │                  (/api/r2/delete)
    │
    └─ 카드 저장 ──────────────────────────► Supabase (dress_items 테이블)

공개 페이지 (/dress)
    └─ 카드 목록 ──────────────────────────► Supabase (dress_items 테이블)
    └─ 이미지 표시 ────────────────────────► R2 퍼블릭 URL (직접 서빙)
```

> ⚠️ **Workers.dev 도메인 우회 필수**
> Cloudflare Workers의 `xxx.workers.dev` 도메인은 일부 네트워크(기업망 등)에서
> 포트 443이 차단될 수 있음. Pages Functions를 사용하면 `pages.dev` 도메인으로
> 동일 기능을 제공하므로 차단 문제 없음.

---

## 1. Cloudflare R2 버킷 생성

```
1. Cloudflare 대시보드 → R2 → Create bucket
2. 버킷 이름 설정 (예: qpnyanya)
3. Settings → Public access → Enable
4. 퍼블릭 URL 복사: https://pub-xxxx.r2.dev
```

### 폴더 구조
```
버킷/
├── hair/     # 헤어 이미지
├── lens/     # 렌즈 이미지
└── outfit/   # 의상 이미지
```

---

## 2. Supabase 테이블 생성

Supabase SQL Editor에서 실행:

```sql
CREATE TABLE IF NOT EXISTS public.dress_items (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT NOT NULL,
  description TEXT DEFAULT '',
  category    TEXT NOT NULL DEFAULT 'hair', -- hair | lens | outfit
  image_key   TEXT DEFAULT '',
  image_url   TEXT DEFAULT '',
  badges      JSONB DEFAULT '[]',
  is_event    BOOLEAN DEFAULT FALSE,
  glow_color  TEXT DEFAULT '#ffb3d1',
  sort_order  INT DEFAULT 0,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_dress_items_category ON dress_items(category);

ALTER TABLE public.dress_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "dress_read_all" ON public.dress_items FOR SELECT USING (true);
CREATE POLICY "dress_insert_auth" ON public.dress_items FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "dress_update_auth" ON public.dress_items FOR UPDATE TO authenticated USING (true);
CREATE POLICY "dress_delete_auth" ON public.dress_items FOR DELETE TO authenticated USING (true);
```

---

## 3. Pages Functions 파일 구성

> Workers.dev 우회 핵심 — Pages 프로젝트 안에 `functions/` 폴더로 구성

### 파일 구조
```
프로젝트 루트/
└── functions/
    └── api/
        └── r2/
            ├── list.js      # GET  /api/r2/list?prefix=hair/
            ├── upload.js    # PUT  /api/r2/upload
            └── delete.js    # DELETE /api/r2/delete
```

### list.js
```javascript
const PUBLIC_URL = "https://pub-xxxx.r2.dev"; // R2 퍼블릭 URL 교체
const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, X-Key"
};

export async function onRequestGet({ request, env }) {
  const url = new URL(request.url);
  const prefix = url.searchParams.get("prefix") || "";
  try {
    const list = await env.DRESS.list({ prefix });
    const objects = (list.objects || []).map(o => ({
      key: o.key,
      url: `${PUBLIC_URL}/${o.key}`,
      size: o.size
    }));
    return new Response(JSON.stringify({ objects }), {
      headers: { ...CORS, "Content-Type": "application/json" }
    });
  } catch(e) {
    return new Response(JSON.stringify({ error: e.message }), {
      status: 500, headers: { ...CORS, "Content-Type": "application/json" }
    });
  }
}

export async function onRequestOptions() {
  return new Response(null, { headers: CORS });
}
```

### upload.js
```javascript
const PUBLIC_URL = "https://pub-xxxx.r2.dev"; // R2 퍼블릭 URL 교체
const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "PUT, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, X-Key"
};

export async function onRequestPut({ request, env }) {
  const key = request.headers.get("X-Key");
  if (!key) return new Response(JSON.stringify({ error: "X-Key required" }), {
    status: 400, headers: { ...CORS, "Content-Type": "application/json" }
  });
  try {
    const body = await request.arrayBuffer();
    const ct = request.headers.get("Content-Type") || "image/png";
    await env.DRESS.put(key, body, { httpMetadata: { contentType: ct } });
    return new Response(JSON.stringify({ ok: true, key, url: `${PUBLIC_URL}/${key}` }), {
      headers: { ...CORS, "Content-Type": "application/json" }
    });
  } catch(e) {
    return new Response(JSON.stringify({ error: e.message }), {
      status: 500, headers: { ...CORS, "Content-Type": "application/json" }
    });
  }
}

export async function onRequestOptions() {
  return new Response(null, { headers: CORS });
}
```

### delete.js
```javascript
const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "DELETE, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, X-Key"
};

export async function onRequestDelete({ request, env }) {
  const key = request.headers.get("X-Key");
  if (!key) return new Response(JSON.stringify({ error: "X-Key required" }), {
    status: 400, headers: { ...CORS, "Content-Type": "application/json" }
  });
  try {
    await env.DRESS.delete(key);
    return new Response(JSON.stringify({ ok: true, key }), {
      headers: { ...CORS, "Content-Type": "application/json" }
    });
  } catch(e) {
    return new Response(JSON.stringify({ error: e.message }), {
      status: 500, headers: { ...CORS, "Content-Type": "application/json" }
    });
  }
}

export async function onRequestOptions() {
  return new Response(null, { headers: CORS });
}
```

---

## 4. Cloudflare Pages R2 바인딩

```
Cloudflare 대시보드
→ Workers & Pages
→ [Pages 프로젝트 선택]
→ Settings
→ Functions
→ R2 bucket bindings → Add

Variable name : DRESS
R2 bucket     : [버킷 이름]
```

> 저장 후 Pages 자동 재배포 됨. 안 되면 빈 커밋으로 강제 트리거:
> ```bash
> git commit --allow-empty -m "재배포 트리거" && git push
> ```

---

## 5. 어드민 JS 설정값

```javascript
// admin/index.html 내 상수
const R2_WORKER = 'https://[pages-domain].pages.dev/api/r2';
const R2_PUBLIC_URL = 'https://pub-xxxx.r2.dev';
```

> ⚠️ `R2_WORKER` 끝에 `/r2`까지만 — 엔드포인트는 `/list`, `/upload`, `/delete`로 자동 분기

---

## 6. API 엔드포인트 정리

| 메서드 | 경로 | 헤더 | 설명 |
|--------|------|------|------|
| `GET` | `/api/r2/list?prefix=hair/` | - | 카테고리별 이미지 목록 |
| `PUT` | `/api/r2/upload` | `X-Key: hair/파일명.png` | 이미지 업로드 |
| `DELETE` | `/api/r2/delete` | `X-Key: hair/파일명.png` | 이미지 삭제 |

---

## 7. dress_items 스키마 요약

| 컬럼 | 타입 | 설명 |
|------|------|------|
| `id` | UUID | PK |
| `name` | TEXT | 타입명 (예: A타입) |
| `description` | TEXT | 카드 설명 |
| `category` | TEXT | `hair` / `lens` / `outfit` |
| `image_key` | TEXT | R2 object key (예: hair/hair_A.png) |
| `image_url` | TEXT | R2 퍼블릭 URL |
| `badges` | JSONB | `[{"label":"색상변경"}]` |
| `is_event` | BOOLEAN | 이벤트 글로우 여부 |
| `glow_color` | TEXT | 글로우 색상 hex |
| `sort_order` | INT | 표시 순서 (드래그 정렬) |

---

## 8. 체크리스트

- [ ] R2 버킷 생성 + Public access 활성화
- [ ] Supabase `dress_items` 테이블 생성 (SQL 실행)
- [ ] `functions/api/r2/` 파일 3개 생성 (list, upload, delete)
- [ ] Pages → Settings → Functions → R2 binding (`DRESS`) 추가
- [ ] `admin/index.html` 상수 2개 설정 (`R2_WORKER`, `R2_PUBLIC_URL`)
- [ ] 재배포 확인 후 `/api/r2/list?prefix=hair/` 응답 테스트
- [ ] 어드민 의상 탭 업로드 테스트
- [ ] `/dress/` 공개 페이지 카드 노출 확인
