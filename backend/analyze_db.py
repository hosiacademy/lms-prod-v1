from django.db import connection

print('=' * 60)
print('DATABASE CLEANUP ANALYSIS')
print('=' * 60)

# 1. Check for empty tables
print('\n📊 EMPTY TABLES (0 records):')
with connection.cursor() as cursor:
    cursor.execute("SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE'")
    tables = [row[0] for row in cursor.fetchall()]
    empty = []
    for table in tables:
        cursor.execute(f'SELECT COUNT(*) FROM "{table}"')
        count = cursor.fetchone()[0]
        if count == 0:
            empty.append(table)
            print(f'  - {table}')
    if not empty:
        print('  None found')

# 2. Check table sizes
print('\n💾 TABLE SIZES (Top 15 largest):')
with connection.cursor() as cursor:
    cursor.execute("""
        SELECT table_name, pg_size_pretty(pg_total_relation_size(quote_ident(table_name))) as size
        FROM information_schema.tables
        WHERE table_schema = 'public'
        ORDER BY pg_total_relation_size(quote_ident(table_name)) DESC
        LIMIT 15
    """)
    for row in cursor.fetchall():
        print(f'  - {row[0]}: {row[1]}')

# 3. Old data to clean
print('\n📅 OLD DATA TO CLEAN UP:')
with connection.cursor() as cursor:
    cursor.execute("SELECT COUNT(*) FROM django_session WHERE expire_date < NOW()")
    old_sessions = cursor.fetchone()[0]
    print(f'  - Expired sessions: {old_sessions}')
    
    cursor.execute("SELECT COUNT(*) FROM analytics_activitylog WHERE created_at < NOW() - INTERVAL \'30 days\'")
    old_logs = cursor.fetchone()[0]
    print(f'  - Old activity logs (>30 days): {old_logs}')
    
    cursor.execute("SELECT COUNT(*) FROM aicerts_sync_logs WHERE created_at < NOW() - INTERVAL \'30 days\'")
    old_sync = cursor.fetchone()[0]
    print(f'  - Old sync logs (>30 days): {old_sync}')
