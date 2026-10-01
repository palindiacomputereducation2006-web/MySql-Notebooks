# MySQL Lecture 1 — Querying, LIKE, Timestamps & Transactions

In this session we reconnected to the `pal_india` database, paged through the `students` table with `LIMIT` / `OFFSET`, sorted on more than one column, used aliases (`AS`), and searched names with `LIKE` wildcards. After that we inserted a duplicate-name row, added `createdAt` / `updateAt` timestamp columns, and started a transaction.

## What this lecture covers

| Family | Commands practiced |
|--------|--------------------|
| Navigation | `SHOW DATABASES`, `USE`, `SHOW TABLES` |
| Pagination | `LIMIT n OFFSET m` |
| Sorting | `ORDER BY col1 ASC, col2 DESC` (multi-column) |
| Aliases | `SELECT col AS alias`, `FROM table AS alias` |
| Pattern matching | `LIKE` with `%` — starts with / ends with / contains |
| DML | `INSERT`, `UPDATE` |
| DDL | `ALTER TABLE ... ADD COLUMN`, `MODIFY COLUMN ... DEFAULT CURRENT_TIMESTAMP` |
| Transactions | `START TRANSACTION` (+ `COMMIT` / `ROLLBACK`) |

**Tool used:** MySQL Shell — DB Notebook (execute a line with `Ctrl+Enter`)

> **Prerequisite:** the `pal_india` database with the `students` table holding 100 sample rows (ids 1–100), and `student_email` set to `UNIQUE`.

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

## 7. Inserting a row with a duplicate name

```sql
INSERT INTO students(student_name, student_age, student_address, student_email, student_gender, student_contact)
VALUES("Sharon Alvarez", 16, "dharavi", "arif@gmail.com", "Male", "+9132534546");

SELECT * FROM students WHERE student_name = "Sharon Alvarez";   -- 2 rows now
```

A `Sharon Alvarez` (id 13, age 27) already exists. The insert still works because `student_name` has no `UNIQUE` constraint, while the email `arif@gmail.com` is not used by any other row. The table now has **101 rows**.

> In the notebook this `SELECT` has no closing `;`, so MySQL reads it and the next `SELECT` as one statement and returns a syntax error. Always end each statement with `;`.

### Tie-breaking with the new row

```sql
SELECT * FROM students ORDER BY student_name DESC, student_age DESC;
```

The two `Sharon Alvarez` rows tie on name, so age breaks the tie: age 27 (id 13) comes before age 16 (id 101).

## 8. More LIKE patterns — where the `%` goes matters

```sql
SELECT student_name AS name FROM students WHERE student_name LIKE "%Ar";    -- ends with "ar"   → 0 rows
SELECT student_name AS name FROM students WHERE student_name LIKE "Ar%";    -- starts with "Ar" → 2 rows (Arjun Verma, Arjun Ward)
SELECT student_name AS name FROM students WHERE student_name LIKE "%Ar%";   -- contains "ar" anywhere
```

| Pattern | Reads as | Example matches |
|---------|----------|-----------------|
| `"%Ar"` | ends with `ar` | none in this data |
| `"Ar%"` | starts with `Ar` | Arjun Verma, Arjun Ward |
| `"%Ar%"` | contains `ar` | Sharon Alvarez, Mark Rivera, Sarah Garcia, ... |

The comparison ignores case, so `"%Ar%"` matches both `Ar` and `ar`.

## 9. Adding timestamp columns

```sql
ALTER TABLE students ADD COLUMN createdAt TIMESTAMP;
ALTER TABLE students ADD COLUMN updateAt  TIMESTAMP;
DESC students;

ALTER TABLE students MODIFY COLUMN createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE students MODIFY COLUMN updateAt  TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
```

- `TIMESTAMP` stores a date and time, e.g. `2026-09-27 23:02:00`
- `DEFAULT CURRENT_TIMESTAMP` fills in the current time when a row is inserted without a value
- Rows that already existed when the columns were added keep `NULL`. The default only applies to **new** inserts.

> To make `updateAt` refresh on every change, it needs `ON UPDATE` as well:
> ```sql
> ALTER TABLE students MODIFY COLUMN updateAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;
> ```
> With only `DEFAULT`, `updateAt` is set at insert time and then never changes.

## 10. Transactions

```sql
START TRANSACTION;
SELECT * FROM students;              -- 101 rows
UPDATE students SET student_age = 22;
```

`START TRANSACTION` groups the statements that follow into one unit. Changes made inside it aren't permanent until you finish the transaction:

```sql
ROLLBACK;   -- undo everything since START TRANSACTION
COMMIT;     -- make the changes permanent
```

⚠️ This `UPDATE` has **no `WHERE`**, so it sets `student_age = 22` for **all 101 students**. The notebook stops before `COMMIT` or `ROLLBACK`, which makes this the right moment for:

```sql
ROLLBACK;                                               -- restore the original ages
UPDATE students SET student_age = 22 WHERE student_id = 1;   -- update only the intended row
COMMIT;
```

Always check your `WHERE` clause before an `UPDATE` or `DELETE`. Running it inside a transaction gives you a way to undo a mistake.

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
| `INSERT INTO table(...) VALUES(...)` | Add a row |
| `ALTER TABLE t ADD COLUMN c TIMESTAMP` | Add a date-time column |
| `MODIFY COLUMN c TIMESTAMP DEFAULT CURRENT_TIMESTAMP` | Auto-fill the insert time |
| `... ON UPDATE CURRENT_TIMESTAMP` | Auto-refresh the time on every update |
| `START TRANSACTION` | Begin a group of changes you can still undo |
| `COMMIT` / `ROLLBACK` | Make the changes permanent / undo them |
| `UPDATE t SET c = v WHERE ...` | Change rows (no `WHERE` = every row) |
