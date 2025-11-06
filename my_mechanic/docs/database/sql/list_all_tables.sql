-- =====================================================
-- LIST ALL TABLES IN DATABASE
-- =====================================================

-- List all tables in the public schema with row counts
SELECT 
    schemaname as schema,
    tablename as table_name,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as total_size,
    (SELECT count(*) 
     FROM information_schema.columns 
     WHERE table_schema = schemaname 
     AND table_name = tablename) as column_count
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

-- =====================================================
-- DETAILED TABLE INFORMATION
-- =====================================================

-- Get columns for each table
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
ORDER BY table_name, ordinal_position;

-- =====================================================
-- TABLE RELATIONSHIPS (Foreign Keys)
-- =====================================================

SELECT
    tc.table_name as from_table,
    kcu.column_name as from_column,
    ccu.table_name as to_table,
    ccu.column_name as to_column,
    tc.constraint_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_schema = 'public'
ORDER BY tc.table_name, tc.constraint_name;

-- =====================================================
-- RLS POLICIES
-- =====================================================

SELECT 
    schemaname as schema,
    tablename as table_name,
    policyname as policy_name,
    cmd as operation,
    roles,
    CASE 
        WHEN qual IS NOT NULL THEN 'Yes'
        ELSE 'No'
    END as has_using,
    CASE 
        WHEN with_check IS NOT NULL THEN 'Yes'
        ELSE 'No'
    END as has_check
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, cmd, policyname;
