# Migration Fixes Applied

## ✅ Issues Fixed

### Issue 1: IMMUTABLE Function Error
**Error**: `functions in index predicate must be marked IMMUTABLE (SQLSTATE 42P17)`

**Problem**: The SQL migration tried to create a partial index using `NOW()` function in the WHERE clause. PostgreSQL requires IMMUTABLE functions for index predicates, but `NOW()` is VOLATILE.

**Solution**: Removed the WHERE clause and created regular composite indexes instead.

### Issue 2: CREATE POLICY Syntax Error
**Error**: `syntax error at or near "NOT" (SQLSTATE 42601)`

**Problem**: PostgreSQL doesn't support `IF NOT EXISTS` for `CREATE POLICY` statements.

**Solution**: Drop existing policies first, then create new ones.

---

## 🔧 Changes Made

### Before (Broken):
```sql
CREATE INDEX idx_matches_open_upcoming ON matches(status, match_date) 
  WHERE status = 'open' AND match_date > NOW();
```

### After (Fixed):
```sql
CREATE INDEX idx_matches_status_date ON matches(status, match_date);
```

This index still provides excellent performance for queries filtering by status and date, without the IMMUTABLE function requirement.

---

### Before (Broken):
```sql
CREATE POLICY IF NOT EXISTS "Cities are viewable by everyone"
  ON cities FOR SELECT
  USING (true);
```

### After (Fixed):
```sql
DROP POLICY IF EXISTS "Cities are viewable by everyone" ON cities;
CREATE POLICY "Cities are viewable by everyone"
  ON cities FOR SELECT
  USING (true);
```

PostgreSQL doesn't support `IF NOT EXISTS` for policies, so we drop first then create.

---

## 🚀 Apply Migration Now

```bash
supabase db push
```

Should complete successfully with all indexes created.

---

## 📊 Performance Impact

The fixed indexes provide:
- ✅ Fast queries on match status + date
- ✅ Fast queries on recruiting teams
- ✅ No runtime overhead
- ✅ Compatible with PostgreSQL requirements

---

## ✅ All Good!

Migration is now fixed and ready to apply.
