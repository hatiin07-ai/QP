-- ============================================
-- RLS 업데이트: 쓰기는 인증된 사용자만 허용
-- Supabase SQL Editor에서 실행
-- ============================================

-- 기존 쓰기 정책 삭제
DROP POLICY IF EXISTS "schedules_insert_all" ON schedules;
DROP POLICY IF EXISTS "schedules_update_all" ON schedules;
DROP POLICY IF EXISTS "schedules_delete_all" ON schedules;

-- 새 정책: 인증된 사용자만 쓰기 가능
CREATE POLICY "schedules_insert_auth" ON schedules
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "schedules_update_auth" ON schedules
  FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "schedules_delete_auth" ON schedules
  FOR DELETE USING (auth.role() = 'authenticated');
