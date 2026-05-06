const SUPABASE_URL = 'https://uhzmyfvmkndrzzyeorwd.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVoem15ZnZta25kcnp6eWVvcndkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgwMjkxNDEsImV4cCI6MjA5MzYwNTE0MX0.2SRfY8nUevM6yV7E3rgguyUqJt69L_zFqGuXTn-daGg';

const { createClient } = supabase;
const supabaseClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
