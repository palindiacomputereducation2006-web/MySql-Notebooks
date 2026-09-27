# MySQL Lecture 2 — Pagination, Sorting, Aliases & LIKE

In this lecture we reconnected to the `pal_india` database, paged through the `students` table with `LIMIT` / `OFFSET`, sorted on more than one column, renamed columns and tables in the output with aliases (`AS`), and searched names with `LIKE` wildcards.

## What this lecture covers

| Family | Commands practiced |
|--------|--------------------|
| Navigation | `SHOW DATABASES`, `USE`, `SHOW TABLES` |
| Pagination | `LIMIT n OFFSET m` |
| Sorting | `ORDER BY col1 ASC, col2 DESC` (multi-column) |
| Aliases | `SELECT col AS alias`, `FROM table AS alias` |
| Pattern matching | `LIKE` with the `%` wildcard |

**Tool used:** MySQL Shell — DB Notebook (execute a line with `Ctrl+Enter`)

> **Prerequisite:** the `pal_india` database with the `students` table holding 100 sample rows (ids 1–100).

---

## 1. Reconnecting to the database

```sql
SHOW DATABASES;   -- 7 databases, including pal_india
USE pal_india;
SHOW TABLES;      -- students
```

Every new notebook session starts with no database selected. Run `USE` first, or queries fail with `No database selected`.

## 2. A common mistake — database name in FROM

```sql
SELECT * FROM pal_india;   -- ❌ Table 'pal_india.pal_india' doesn't exist
```

`pal_india` is the **database**, not a table. `FROM` needs a **table** name:

```sql
SELECT * FROM students;             -- ✅ table in the current database
SELECT * FROM pal_india.students;   -- ✅ fully qualified: database.table (works without USE)
```

## 3. Pagination with LIMIT / OFFSET

```sql
SELECT * FROM students LIMIT 10 OFFSET 0;    -- page 1  → ids 1–10
SELECT * FROM students LIMIT 10 OFFSET 10;   -- page 2  → ids 11–20
SELECT * FROM students LIMIT 10 OFFSET 20;   -- page 3  → ids 21–30
SELECT * FROM students LIMIT 10 OFFSET 90;   -- page 10 → ids 91–100 (last page)
SELECT * FROM students LIMIT 7  OFFSET 10;   -- 7 rows after skipping 10 → ids 11–17
```

- `LIMIT n` → return at most `n` rows
- `OFFSET m` → skip the first `m` rows first

For page `p` with page size `s`: **`LIMIT s OFFSET (p - 1) * s`**. With 100 rows and a page size of 10 there are 10 pages, so `OFFSET 90` is the last one.

> Without `ORDER BY`, the row order isn't guaranteed. It looks like id order here only because of the primary key. For stable pages in real apps, always add `ORDER BY`.

## 4. Sorting on multiple columns

```sql
SELECT * FROM students ORDER BY student_name ASC, student_age DESC;
SELECT * FROM students ORDER BY student_age ASC, student_id ASC;
```

MySQL sorts by the first column. The second column only breaks ties, when two rows have the same value in the first one.

- **Name ASC, age DESC:** there are two `William Parker` rows. The one with age 26 (id 58) comes before the one with age `NULL` (id 95).
- **Age ASC, id ASC:** the 6 students with `NULL` age come **first** (ids 17, 19, 28, 43, 81, 95). Next come the 17-year-olds in id order: 11, 14, 20, 32, 52, 71, ...

> **NULL ordering:** MySQL treats `NULL` as smaller than any value, so NULLs come first with `ASC` and last with `DESC`.

## 5. Aliases (AS)

### Table alias
```sql
SELECT * FROM students AS student_details;
SHOW TABLES;   -- still just: students
```
A table alias is a temporary name that only exists inside that one query. It does **not** rename the table (use `RENAME TABLE` for that). Aliases become really useful later, with joins.

### Column alias
```sql
SELECT student_id AS id, student_name AS name FROM students;
```
The result headers show `id` and `name` instead of the real column names. The table itself isn't changed.

## 6. Pattern matching with LIKE

```sql
SELECT * FROM students WHERE student_name LIKE "%Z" ORDER BY student_name DESC;   -- 18 rows
```

- `%` matches **any number of characters** (including none)
- `"%Z"` means "ends with Z", so it finds names like `Sharon Alvarez`, `Scott Ruiz` and `Rohan Gomez`
- The match is **case-insensitive** with MySQL's default collation, so `"%Z"` also matches a lowercase `z`
- `ORDER BY student_name DESC` lists the matches from Z to A

| Pattern | Meaning |
|---------|---------|
| `"Ar%"` | starts with `Ar` |
| `"%ez"` | ends with `ez` |
| `"%ar%"` | contains `ar` anywhere |
| `"_a%"` | `a` is the 2nd character (`_` = exactly one character) |

---

## Commands Summary

| Command | What it does |
|---|---|
| `SHOW DATABASES` / `USE db` / `SHOW TABLES` | Find and select the working database |
| `SELECT * FROM db.table` | Read a table by its full name, without `USE` |
| `LIMIT n OFFSET m` | Return `n` rows after skipping `m` (pagination) |
| `ORDER BY a ASC, b DESC` | Sort by `a`, then break ties with `b` |
| `col AS alias` | Rename a column in the result only |
| `FROM table AS alias` | Give a table a temporary name inside the query |
| `LIKE "pattern"` | Match strings with `%` (any chars) and `_` (one char) |
