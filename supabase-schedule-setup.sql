CREATE TABLE IF NOT EXISTS schedules (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT DEFAULT '',
  event_date DATE NOT NULL,
  event_time TIME DEFAULT NULL,
  event_type TEXT NOT NULL DEFAULT 'broadcast',
  color TEXT NOT NULL DEFAULT '#D4727A',
  highlight BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_schedules_date ON schedules(event_date);
CREATE INDEX IF NOT EXISTS idx_schedules_type ON schedules(event_type);
ALTER TABLE schedules ENABLE ROW LEVEL SECURITY;
CREATE POLICY "schedules_read_all" ON schedules FOR SELECT USING (true);
CREATE POLICY "schedules_insert_all" ON schedules FOR INSERT WITH CHECK (true);
CREATE POLICY "schedules_update_all" ON schedules FOR UPDATE USING (true);
CREATE POLICY "schedules_delete_all" ON schedules FOR DELETE USING (true);
CREATE OR REPLACE FUNCTION update_updated_at() RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER schedules_updated_at BEFORE UPDATE ON schedules FOR EACH ROW EXECUTE FUNCTION update_updated_at();
INSERT INTO schedules (title, event_date, event_time, event_type, color, highlight) VALUES
  ('정규 방송', '2026-05-07', '18:00', 'broadcast', '#D4727A', false),
  ('휴방', '2026-05-08', NULL, '休放', '#8C8C8C', false),
  ('노래 특별방송', '2026-05-10', '18:00', 'event', '#9F7AEA', true);
