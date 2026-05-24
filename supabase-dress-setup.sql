-- ============================================
-- 큐피 옷장 (dress_items) 테이블
-- ============================================

CREATE TABLE IF NOT EXISTS public.dress_items (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT NOT NULL,
  description TEXT DEFAULT '',
  category    TEXT NOT NULL DEFAULT 'hair', -- hair | lens | outfit
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
