# MySQL Lecture 3 — UPDATE, Auto Timestamps, Aggregates, GROUP BY & Views

In this lecture we renamed two students with `UPDATE ... WHERE`, taught the `updateAt` column to refresh itself with `ON UPDATE CURRENT_TIMESTAMP`, summarised the table with the aggregates (`COUNT`, `SUM`, `AVG`, `MIN`, `MAX`), collapsed rows with `GROUP BY` + `HAVING`, filtered with a subquery and `IN`, combined `LIKE` with `AND` / `OR`, narrowed ranges with `BETWEEN`, and saved a query as a **view**.

## What this lecture covers

| Family | Commands practiced |
|--------|--------------------|
| Navigation | `USE`, `SHOW TABLES`, `DESC` |
| DML | `UPDATE ... WHERE` |
| DDL | `ALTER TABLE ... MODIFY ... DEFAULT / ON UPDATE CURRENT_TIMESTAMP` |
| Aggregates | `COUNT`, `SUM`, `AVG`, `MIN`, `MAX` |
| Grouping | `GROUP BY`, `HAVING`, `ANY_VALUE` |
| Subqueries | `WHERE col IN (SELECT ...)` |
| Logic | `AND` / `OR` precedence with `LIKE` |
| Ranges | `BETWEEN`, `NOT BETWEEN` |
| Views | `CREATE VIEW ... AS SELECT` |

**Tool used:** MySQL Shell — DB Notebook (execute a line with `Ctrl+Enter`)

> **Prerequisite:** the `pal_india` database with the `students` table — now **101 rows** (the `Sharon Alvarez` row, id 101, from Lecture 1 is back in the data).

---

## 1. Reconnecting and checking the table structure

```sql
USE pal_india;
SHOW TABLES;      -- students
DESC students;
```

`DESC` (describe) shows the table's **structure** instead of its data — every column with its type, whether it can be `NULL`, its key, and its default:

| Field | Type | Notes |
|-------|------|-------|
| `student_id` | `int` | PRI, auto_increment |
| `student_name` | `varchar(50)` | NOT NULL |
| `student_age` | `int` | nullable |
| `student_address` | `varchar(100)` | nullable |
| `student_email` | `varchar(50)` | NOT NULL |
| `student_gender` | `varchar(20)` | nullable |
| `student_contact` | `varchar(25)` | nullable |
| `student_is_active` | `tinyint(1)` | default `1` |
| `createdAt` | `timestamp` | default `CURRENT_TIMESTAMP` |
| `updateAt` | `timestamp` | default `CURRENT_TIMESTAMP` — gains `ON UPDATE` below |

The table now has 10 columns: the 8 original ones plus the two timestamp columns from Lecture 1.

## 2. Changing rows with UPDATE ... WHERE

```sql
UPDATE students SET student_name = "Linda Hernandez" WHERE student_id = 1;   -- OK, 1 row affected
UPDATE students SET student_name = "Puja Tomar"     WHERE student_id = 2;   -- OK, 1 row affected
```

`Linda Patel` (id 1) became `Linda Hernandez`, and `Pooja Turner` (id 2) became `Puja Tomar`. Only `student_name` changed — the email, address and the rest of each row are untouched.

> Without the `WHERE`, every one of the 101 rows would be renamed — the same trap the Lecture 1 transaction demo warned about.

## 3. Making updateAt refresh itself

```sql
ALTER TABLE students MODIFY createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE students MODIFY updateAt  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;
DESC students;
```

- `DEFAULT CURRENT_TIMESTAMP` → fills in the current time when a row is inserted
- `ON UPDATE CURRENT_TIMESTAMP` → additionally rewrites the time **every time the row is updated**

`DESC` makes the change visible: `updateAt`'s default goes from `CURRENT_TIMESTAMP` to `CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP`.

The proof is in the data:

| Row | Updated | `updateAt` after | Why |
|-----|---------|------------------|-----|
| id 1 (Linda Hernandez) | **before** the `ALTER` | `NULL` | `ON UPDATE` didn't exist yet |
| id 2 (Puja Tomar) | **after** the `ALTER` | `2026-10-01 07:58:04` | stamped automatically, nothing was written by hand |

## 4. Aggregate functions

```sql
SELECT COUNT(student_age) FROM students;                 -- 96
SELECT COUNT(student_age) AS age FROM students;          -- 96, header renamed with AS
SELECT SUM(student_age)   AS age FROM students;          -- 2325
SELECT AVG(student_age)   AS average_age FROM students;  -- 24.2188
SELECT MIN(student_age) FROM students;                   -- 16
SELECT MAX(student_age) FROM students;                   -- 102 (!)
```

- `COUNT(col)` counts only **non-NULL** values: 96 of the 101 students have an age on file, 5 don't
- `AVG` is really `SUM / COUNT`: 2325 / 96 = 24.2188
- `MAX` = 102 — an obvious data-entry outlier. Aggregates are only as clean as the data behind them

## 5. GROUP BY and HAVING

```sql
SELECT * FROM students
WHERE student_age = 22
GROUP BY student_age, student_id
HAVING COUNT(student_age) > 0;    -- 5 rows: ids 22, 39, 48, 75, 89
```

`WHERE` filters **rows** before grouping; `HAVING` filters **groups** after aggregation. Here the `WHERE` already picked age 22, and the 5 students sharing it survive the `HAVING` test.

### One column in GROUP BY — the ONLY_FULL_GROUP_BY problem

```sql
SELECT student_age, ANY_VALUE(student_name), ANY_VALUE(student_id)
FROM students
GROUP BY student_age
HAVING COUNT(*) > 0;    -- 17 rows: one per distinct age
```

With `GROUP BY student_age` alone, selecting `student_name` would be ambiguous — which name represents the group? MySQL's `ONLY_FULL_GROUP_BY` mode demands every selected column be either grouped or aggregated. `ANY_VALUE(col)` answers "pick one, any one" and satisfies the rule.

The result has 17 groups: 16 distinct ages plus one group for `NULL` (NULL is its own group).

### Grouping by everything

```sql
SELECT student_age, student_name, student_id FROM students
GROUP BY student_age, student_name, student_id
HAVING COUNT(*) > 0;    -- 101 rows
```

Grouping by all three columns makes every row its own group — the output equals the whole table.

## 6. Subqueries with IN

```sql
SELECT * FROM students
WHERE student_age IN (
  SELECT student_age FROM students GROUP BY student_age HAVING COUNT(*) > 0
);    -- 96 rows
```

The inner query runs first and produces the list of ages that exist; the outer query keeps every row whose age is on that list. All 96 students with a recorded age come back — the 5 `NULL`-age rows don't, because `NULL IN (...)` is never true.

Swap the `HAVING` threshold to answer "who shares an age with more than 5 others?":

```sql
WHERE student_age IN (
  SELECT student_age FROM students GROUP BY student_age HAVING COUNT(*) > 5
);    -- 94 rows
```

Only the rarest ages (2 rows in total) drop out.

## 7. LIKE with AND / OR — precedence matters

```sql
SELECT * FROM students
WHERE student_name LIKE "%Pine%"
   AND student_address LIKE "%linda%"
    OR student_email LIKE "%melissa%";    -- 2 rows: Melissa Cox (44), Melissa Gupta (96)
```

`AND` binds **tighter** than `OR`, so MySQL reads this as:

```
(name LIKE "%Pine%" AND address LIKE "%linda%") OR email LIKE "%melissa%"
```

Nobody matches the name + address pair — both hits come from the email test. Use parentheses whenever the intended grouping isn't the default one.

## 8. BETWEEN / NOT BETWEEN

```sql
SELECT * FROM students WHERE student_id BETWEEN 1 AND 15;       -- 15 rows, ids 1–15
SELECT * FROM students WHERE student_id BETWEEN 14 AND 30;      -- 17 rows, ids 14–30
SELECT * FROM students WHERE student_id NOT BETWEEN 14 AND 30;  -- 84 rows (101 − 17)
```

- `BETWEEN a AND b` is **inclusive on both ends**
- `NOT BETWEEN` is simply the complement — every row outside the range

## 9. Filter + sort + paginate, chained

```sql
SELECT * FROM students
WHERE student_age BETWEEN 16 AND 22
ORDER BY student_id DESC;    -- 37 rows, highest ids first

SELECT * FROM students
WHERE student_age BETWEEN 16 AND 22
ORDER BY student_name DESC, student_id DESC;    -- 37 rows, Z→A by name

SELECT * FROM students
WHERE student_age BETWEEN 16 AND 22
ORDER BY student_name DESC, student_id DESC
LIMIT 10 OFFSET 0;           -- just the first 10 of those
```

The clauses always run in this order: `WHERE` filters → `ORDER BY` sorts → `LIMIT`/`OFFSET` trims. This is exactly how a real app builds "page 1 of teenagers, newest first".

## 10. Views — a saved query with a name

```sql
CREATE VIEW arbaz AS
(
  SELECT * FROM students
);

SELECT * FROM arbaz;    -- 101 rows, same as the students table
```

A view is a **virtual table**: it stores no data of its own, just the query. Every read of `arbaz` re-runs the underlying `SELECT`, so it always shows the current contents of `students`. Views shine later, when a long join or filter deserves a short, friendly name.

---

## Commands Summary

| Command | What it does |
|---|---|
| `DESC table` | Show the table's columns, types, keys and defaults |
| `UPDATE t SET col = v WHERE ...` | Change only the matching rows |
| `MODIFY col TIMESTAMP DEFAULT CURRENT_TIMESTAMP` | Auto-fill the insert time |
| `... ON UPDATE CURRENT_TIMESTAMP` | Auto-refresh the time on every update |
| `COUNT / SUM / AVG / MIN / MAX(col)` | Count, total, mean, smallest, largest — NULLs skipped |
| `GROUP BY a, b` | Collapse rows with equal values into one group row |
| `HAVING condition` | Filter groups after aggregation |
| `ANY_VALUE(col)` | Pick an arbitrary value from a group (satisfies ONLY_FULL_GROUP_BY) |
| `WHERE col IN (SELECT ...)` | Match against the subquery's result list |
| `LIKE ... AND / OR ...` | Combine conditions — `AND` binds before `OR` |
| `BETWEEN a AND b` / `NOT BETWEEN` | Inclusive range test / everything outside it |
| `CREATE VIEW name AS SELECT ...` | Save a query as a virtual table |
