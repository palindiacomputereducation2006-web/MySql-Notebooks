# MySQL Lecture 3 — UPDATE, Auto Timestamps, Aggregates, GROUP BY & Views

In this lecture we renamed two students with `UPDATE ... WHERE`, taught the `updateAt` column to refresh itself with `ON UPDATE CURRENT_TIMESTAMP`, summarised the table with the aggregates (`COUNT`, `SUM`, `AVG`, `MIN`, `MAX`), collapsed rows with `GROUP BY` + `HAVING`, filtered with a subquery and `IN`, combined `LIKE` with `AND` / `OR`, narrowed ranges with `BETWEEN`, saved a query as a **view**, and peeked at the list of stored procedures.

## What this lecture covers

| Family | Commands practiced |
|--------|--------------------|
| Shell | `\about` |
| Navigation | `USE`, `SHOW TABLES`, `DESC`, `SELECT *` |
| DML | `UPDATE ... WHERE` |
| DDL | `ALTER TABLE ... MODIFY ... DEFAULT / ON UPDATE CURRENT_TIMESTAMP` |
| Aggregates | `COUNT`, `SUM`, `AVG`, `MIN`, `MAX`, column alias `AS` |
| Grouping | `GROUP BY`, `HAVING`, `ANY_VALUE` |
| Subqueries | `WHERE col IN (SELECT ...)` |
| Logic | `AND` / `OR` precedence with `LIKE` |
| Ranges | `BETWEEN`, `NOT BETWEEN` |
| Sorting & paging | `ORDER BY` (multiple columns), `LIMIT ... OFFSET` |
| Views | `CREATE VIEW ... AS SELECT` |
| Metadata | `SHOW PROCEDURE STATUS WHERE Db = ...` |

**Tool used:** MySQL Shell — DB Notebook (execute a line with `Ctrl+Enter`)

> **Prerequisite:** the `pal_india` database with the `students` table — now **101 rows** (the `Sharon Alvarez` row, id 101, from Lecture 1 is back in the data).

---

## 1. Reconnecting and checking the table structure

```sql
\about            -- MySQL Shell command (not SQL): prints the Shell / Notebook welcome text
USE pal_india;    -- make pal_india the "current" database
SHOW TABLES;      -- students
DESC students;    -- show the columns of students
SELECT * FROM students;   -- look at the data before we change anything
```

Step by step:

- `\about` starts with a backslash, so it is a **MySQL Shell command**, not SQL. It only prints the "Welcome to the MySQL Shell - DB Notebook" help text. Other backslash commands you will see: `\sql`, `\js`, `\help`.
- `USE pal_india;` sets the default database. After it, `students` means `pal_india.students`.
- `SHOW TABLES;` lists every table in the current database — here just one row: `students`.
- `DESC students;` (short for `DESCRIBE`) shows the table's **structure** instead of its data.
- `SELECT * FROM students;` returns all **101 rows**. Note that id 1 is still `Linda Patel` and id 2 is still `Pooja Turner` at this point — we change them in the next section.

> **Gotcha seen in the notebook:** the saved output of `USE pal_india;` is `MySQL Error (1049): Unknown database 'pal_india'`, yet the next statements worked. Error 1049 means "no database with that name exists *right now*" — usually a typo, or the database was not created yet on that server/connection. If you get it, run `SHOW DATABASES;` to check the exact name, create it if needed, then run `USE` again.

`DESC` returns one row per column, with six fields: `Field`, `Type`, `Null` (can it be empty?), `Key` (`PRI` = primary key), `Default`, and `Extra`:

| Field | Type | Null | Key | Default | Extra |
|-------|------|------|-----|---------|-------|
| `student_id` | `int` | NO | PRI | | auto_increment |
| `student_name` | `varchar(50)` | NO | | | |
| `student_age` | `int` | YES | | | |
| `student_address` | `varchar(100)` | YES | | | |
| `student_email` | `varchar(50)` | NO | | | |
| `student_gender` | `varchar(20)` | YES | | | |
| `student_contact` | `varchar(25)` | YES | | | |
| `student_is_active` | `tinyint(1)` | YES | | `1` | |
| `createdAt` | `timestamp` | YES | | `CURRENT_TIMESTAMP` | DEFAULT_GENERATED |
| `updateAt` | `timestamp` | YES | | `CURRENT_TIMESTAMP` | DEFAULT_GENERATED — gains `on update CURRENT_TIMESTAMP` below |

The table now has 10 columns: the 8 original ones plus the two timestamp columns from Lecture 1.

- `NO` in the `Null` column means MySQL will reject an `INSERT` that leaves that column empty.
- `auto_increment` means MySQL picks the next id for you — you never type `student_id` in an `INSERT`.
- `tinyint(1)` is how MySQL stores a `BOOLEAN`: `1` = true, `0` = false.

> **Try it yourself:** `SHOW COLUMNS FROM students;` gives the same output as `DESC students;`.

## 2. Changing rows with UPDATE ... WHERE

```sql
UPDATE students SET student_name = "Linda Hernandez" WHERE student_id = 1;   -- OK, 1 row affected
SELECT * FROM students;                                                      -- check the change
-- (the ALTER TABLE statements from section 3 ran here)
UPDATE students SET student_name = "Puja Tomar"     WHERE student_id = 2;   -- OK, 1 row affected
SELECT * FROM students;
```

How MySQL runs an `UPDATE`:

1. `UPDATE students` — pick the table to change.
2. `WHERE student_id = 1` — find the rows to change. Because `student_id` is the primary key, this matches **exactly one** row.
3. `SET student_name = "Linda Hernandez"` — overwrite only the listed column(s) in those rows.
4. MySQL replies with a message, not a result grid: `OK, 1 row affected`.

`Linda Patel` (id 1) became `Linda Hernandez`, and `Pooja Turner` (id 2) became `Puja Tomar`. Only `student_name` changed — the email (`linda.patel1@hotmail.com` still says "patel"!), address and the rest of each row are untouched.

| student_id | student_name (before) | student_name (after) |
|-----------:|-----------------------|----------------------|
| 1 | Linda Patel | Linda Hernandez |
| 2 | Pooja Turner | Puja Tomar |

> Without the `WHERE`, every one of the 101 rows would be renamed — the same trap the Lecture 1 transaction demo warned about.

Common mistakes:

- Filtering by name instead of id (`WHERE student_name = "William Parker"`) — names are not unique; this table has **two** `William Parker` rows and **two** `Sharon Alvarez` rows, so both would change. Always update by the primary key when you mean one row.
- `0 rows affected` does not mean an error — it means the `WHERE` matched nothing, *or* the new value was the same as the old one.
- To change several columns at once, separate them with commas: `SET student_name = "...", student_age = 21`.

> **Try it yourself:** run `SELECT * FROM students WHERE student_id = 1;` *before* an update to check the `WHERE` picks the right row, then turn the same `WHERE` into the `UPDATE`.

## 3. Making updateAt refresh itself

```sql
ALTER TABLE students MODIFY createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE students MODIFY updateAt  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;
DESC students;
```

Reading the statement left to right:

- `ALTER TABLE students` → change the **structure** of the table (DDL), not its data
- `MODIFY updateAt` → redefine an existing column (keeps its name)
- `TIMESTAMP` → the column type — you must repeat it, because `MODIFY` replaces the whole column definition
- `DEFAULT CURRENT_TIMESTAMP` → fills in the current time when a row is inserted
- `ON UPDATE CURRENT_TIMESTAMP` → additionally rewrites the time **every time the row is updated**

Each `ALTER` answers `OK, 0 records retrieved` — it returns no rows, it only changes the definition.

`DESC` makes the change visible: `updateAt`'s `Extra` column goes from `DEFAULT_GENERATED` to `DEFAULT_GENERATED on update CURRENT_TIMESTAMP`.

The proof is in the data:

| Row | Updated | `updateAt` after | Why |
|-----|---------|------------------|-----|
| id 1 (Linda Hernandez) | **before** the `ALTER` | `NULL` | `ON UPDATE` didn't exist yet |
| id 2 (Puja Tomar) | **after** the `ALTER` | `2026-10-01 07:58:04` | stamped automatically, nothing was written by hand |

Gotchas:

- `MODIFY` does **not** back-fill old rows. Every row that existed before still has `createdAt = NULL` and (unless updated later) `updateAt = NULL`. The default only applies to *future* inserts.
- `ON UPDATE` only fires when some value in the row **actually changes**. Running the same `UPDATE` twice (same name again) gives `0 rows affected` and the timestamp stays put.
- If you forget the type (`MODIFY updateAt DEFAULT ...`) you get a syntax error — `MODIFY` always needs the full column definition.

> **Try it yourself:** `UPDATE students SET student_age = 21 WHERE student_id = 3;` then `SELECT student_id, updateAt FROM students WHERE student_id = 3;` — the time should be "now".

## 4. Aggregate functions

```sql
SELECT COUNT(student_age) FROM students;                 -- 96
SELECT COUNT(student_age) AS age FROM students;          -- 96, header renamed with AS
SELECT SUM(student_age)   AS age FROM students;          -- 2325
SELECT AVG(student_age)   AS average_age FROM students;  -- 24.2188
SELECT MIN(student_age) FROM students;                   -- 16
SELECT MAX(student_age) FROM students;                   -- 102 (!)
```

An **aggregate function** squeezes many rows into **one value**. With no `GROUP BY`, the whole table is one big group, so each query above returns exactly **1 row, 1 column**.

How MySQL evaluates `SELECT SUM(student_age) AS age FROM students;`:

1. `FROM students` — take all 101 rows
2. `SUM(student_age)` — add up the age of every row, skipping `NULL`s
3. `AS age` — name the output column `age` (otherwise the header is literally `SUM(student_age)`)

| Function | What it returns | Result here |
|----------|-----------------|-------------|
| `COUNT(student_age)` | number of rows where age is **not NULL** | 96 |
| `SUM(student_age)` | total of all ages | 2325 |
| `AVG(student_age)` | `SUM / COUNT` (NULLs ignored) | 24.2188 |
| `MIN(student_age)` | smallest age | 16 |
| `MAX(student_age)` | largest age | 102 |

- `COUNT(col)` counts only **non-NULL** values: 96 of the 101 students have an age on file, 5 don't (ids 17, 19, 28, 43, 81)
- `COUNT(*)` counts **rows**, NULL or not — `SELECT COUNT(*) FROM students;` would give 101
- `AVG` is really `SUM / COUNT`: 2325 / 96 = 24.2188 — the 5 NULL ages are left out, *not* treated as 0
- `MAX` = 102 (id 95, `William Parker`) — an obvious data-entry outlier. Aggregates are only as clean as the data behind them; one bad value pulls the average up

The alias in the second and third queries just renames the result header:

| COUNT(student_age) | → with `AS age` → | age |
|---:|---|---:|
| 96 | | 96 |

> **Naming tip:** the notebook reused `age` as the alias for both `COUNT` and `SUM`. That works, but a name like `total_age` or `students_with_age` tells the reader what the number means.

Common mistakes:

- `SELECT student_name, MAX(student_age) FROM students;` — mixing a plain column with an aggregate (without `GROUP BY`) is rejected under `ONLY_FULL_GROUP_BY`. To find *who* is oldest, use `ORDER BY student_age DESC LIMIT 1` instead.
- Putting a space between the function and `(` — `COUNT (student_age)` can fail in MySQL. Write `COUNT(student_age)`.

> **Try it yourself:** `SELECT COUNT(*), COUNT(student_age), COUNT(student_gender) FROM students;` — compare the three numbers to see how many NULLs each column has.

## 5. GROUP BY and HAVING

```sql
SELECT * FROM students
WHERE student_age = 22
GROUP BY student_age, student_id
HAVING COUNT(student_age) > 0;    -- 5 rows: ids 22, 39, 48, 75, 89
```

For any query with aggregates, MySQL **logically** evaluates the clauses in this order (not the order you type them):

```
FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY → LIMIT
```

Walking through this query:

1. `FROM students` — start with all 101 rows
2. `WHERE student_age = 22` — keep only rows with age 22 → **5 rows**
3. `GROUP BY student_age, student_id` — make one group per *(age, id)* pair. Since every id is unique, each of the 5 rows becomes its own group
4. `HAVING COUNT(student_age) > 0` — each group has 1 row, so `COUNT` = 1 and every group passes
5. `SELECT *` — show all columns of each group

| student_id | student_name | student_age |
|-----------:|--------------|------------:|
| 22 | Henry Rodriguez | 22 |
| 39 | Ayse Carter | 22 |
| 48 | Jerry White | 22 |
| 75 | Kevin Singh | 22 |
| 89 | Steven Hall | 22 |

`WHERE` filters **rows** before grouping; `HAVING` filters **groups** after aggregation. Here the `WHERE` already picked age 22, and the 5 students sharing it survive the `HAVING` test.

> Why is `SELECT *` allowed here? Because `student_id` (the primary key) is in the `GROUP BY`. Once the id is fixed, every other column has exactly one value, so MySQL knows there is no ambiguity.

Common mistakes:

- Using an aggregate in `WHERE`: `WHERE COUNT(*) > 1` → error *Invalid use of group function*. Aggregates only exist after grouping, so they belong in `HAVING`.
- Using `HAVING` for a plain row filter (`HAVING student_age = 22`) — it may work, but `WHERE` is clearer and faster because it throws rows away *before* grouping.

### One column in GROUP BY — the ONLY_FULL_GROUP_BY problem

```sql
use pal_india;   -- re-selecting the database (harmless; keywords are case-insensitive)
SELECT student_age, ANY_VALUE(student_name), ANY_VALUE(student_id)
FROM students
GROUP BY student_age
HAVING COUNT(*) > 0;    -- 17 rows: one per distinct age
```

With `GROUP BY student_age` alone, selecting `student_name` would be ambiguous — which name represents the group? MySQL's `ONLY_FULL_GROUP_BY` mode demands every selected column be either grouped or aggregated. Without `ANY_VALUE` you get error 1055 (*"... isn't in GROUP BY ... incompatible with sql_mode=only_full_group_by"*). `ANY_VALUE(col)` answers "pick one, any one" and satisfies the rule.

The result has 17 groups: 16 distinct ages plus one group for `NULL` (NULL is its own group). The first rows from the notebook:

| student_age | ANY_VALUE(student_name) | ANY_VALUE(student_id) |
|------------:|-------------------------|----------------------:|
| 20 | Linda Hernandez | 1 |
| 26 | Puja Tomar | 2 |
| 29 | Sarah Garcia | 4 |
| 27 | Frank Hughes | 5 |
| ... | ... | ... |
| NULL | Mehmet Sahin | 17 |
| ... | ... | ... |
| 102 | William Parker | 95 |
| 16 | Sharon Alvarez | 101 |

- The name shown for each age is just *one* student of that age — usually the first one MySQL met — not a meaningful choice
- The groups are not sorted; add `ORDER BY student_age` if you want them in order
- `HAVING COUNT(*) > 0` is always true for a group (a group can't be empty), so here it filters nothing — it's there to practise the syntax

A more useful version of this query shows **how many** students have each age:

```sql
SELECT student_age, COUNT(*) AS how_many
FROM students
GROUP BY student_age
ORDER BY student_age;
```

| student_age | how_many |
|------------:|---------:|
| NULL | 5 |
| 16 | 1 |
| 17 | 9 |
| 18 | 7 |
| 19–22 | 5 each |
| 23 | 8 |
| 24 | 13 |
| 25, 26 | 5 each |
| 27 | 6 |
| 28 | 9 |
| 29 | 7 |
| 30 | 5 |
| 102 | 1 |

(Counts worked out from the table data in the notebook.)

### Grouping by everything

```sql
SELECT student_age, student_name, student_id FROM students
GROUP BY student_age, student_name, student_id
HAVING COUNT(*) > 0;    -- 101 rows
```

Grouping by all three columns makes every row its own group — the output equals the whole table (just those 3 columns). Because `student_id` is unique, no two rows can ever fall into the same group. This is a legal way around `ONLY_FULL_GROUP_BY`, but it defeats the purpose of grouping.

> **Try it yourself:** `SELECT student_gender, COUNT(*) FROM students GROUP BY student_gender;` — how many students of each gender (and how many with no gender recorded)?

## 6. Subqueries with IN

```sql
SELECT * FROM students
WHERE student_age IN (
  SELECT student_age FROM students GROUP BY student_age HAVING COUNT(*) > 0
);    -- 96 rows
```

A **subquery** is a `SELECT` inside another statement, wrapped in parentheses. Step by step:

1. The inner query runs first: group by age, keep groups with `COUNT(*) > 0` → a one-column list of ages: `20, 26, 29, 27, ... , NULL, ...`
2. The outer query reads every student and keeps the row if its `student_age` is **in** that list
3. All 96 students with a recorded age come back — the 5 `NULL`-age rows don't, because `NULL IN (...)` is never true (comparing anything with `NULL` gives "unknown", not true)

`IN (a, b, c)` is just short for `col = a OR col = b OR col = c`.

Raise the `HAVING` threshold to answer "which students have an age that **more than 5** students share?":

```sql
SELECT * FROM students
WHERE student_age IN (
  SELECT student_age FROM students GROUP BY student_age HAVING COUNT(*) > 5
);    -- 59 rows (ages 17, 18, 23, 24, 27, 28, 29)
```

Now the inner list only contains ages with **6 or more** students: 17 (9), 18 (7), 23 (8), 24 (13), 27 (6), 28 (9), 29 (7) → 9 + 7 + 8 + 13 + 6 + 9 + 7 = **59 rows**. Every age with exactly 5 students (19, 20, 21, 22, 25, 26, 30) drops out, along with the one-off ages 16 and 102.

> **Note on the notebook:** the saved result grid for this query shows **94 rows** — but that grid was produced by an earlier run with `HAVING COUNT(*) > 3`, before the threshold was edited to `> 5`. With `> 3`, only the two single-student ages (16 and 102) drop out: 96 − 2 = 94. Re-run the `> 5` version and you should see 59 rows.

Common mistakes:

- The subquery must return **one column**. `IN (SELECT * FROM ...)` fails with *Operand should contain 1 column(s)*.
- `NOT IN (subquery)` returns **nothing at all** if the subquery list contains a `NULL`. Add `WHERE student_age IS NOT NULL` inside the subquery to be safe.

> **Try it yourself:** change the threshold to `= 1` to list the students whose age nobody else has (you should get Sharon Alvarez, 16, and William Parker, 102).

## 7. LIKE with AND / OR — precedence matters

```sql
SELECT * FROM students
WHERE student_name LIKE "%Pine%"
   AND student_address LIKE "%linda%"
    OR student_email LIKE "%melissa%";    -- 2 rows: Melissa Cox (44), Melissa Gupta (96)
```

Quick `LIKE` refresher:

- `%` = any number of characters (including none); `_` = exactly one character
- `"%Pine%"` = "contains Pine anywhere"
- With the default collation `LIKE` is **case-insensitive**, so `"%melissa%"` also matches `Melissa`

`AND` binds **tighter** than `OR`, so MySQL reads this as:

```
(name LIKE "%Pine%" AND address LIKE "%linda%") OR email LIKE "%melissa%"
```

How each row is tested:

| Row | name has "Pine"? | address has "linda"? | AND part | email has "melissa"? | Final (OR) |
|-----|:---:|:---:|:---:|:---:|:---:|
| 44 Melissa Cox | no | no | false | yes | **true** |
| 96 Melissa Gupta | no | no | false | yes | **true** |
| any other row | no | no | false | no | false |

Nobody matches the name + address pair (no student is named "Pine" — it's a street name, `Pine St`, in the address column) — both hits come from the email test.

If you meant "name has Pine AND (address has linda OR email has melissa)", you must write the brackets yourself:

```sql
SELECT * FROM students
WHERE student_name LIKE "%Pine%"
  AND (student_address LIKE "%linda%" OR student_email LIKE "%melissa%");   -- 0 rows
```

Use parentheses whenever the intended grouping isn't the default one — and honestly, use them whenever you mix `AND` and `OR`, so the next reader doesn't have to remember the rule.

> **Try it yourself:** `SELECT * FROM students WHERE student_address LIKE "%Pine St%";` — find the students who live on Pine St.

## 8. BETWEEN / NOT BETWEEN

```sql
SELECT * FROM students WHERE student_id BETWEEN 1 AND 15;       -- 15 rows, ids 1–15
SELECT * FROM students WHERE student_id BETWEEN 14 AND 30;      -- 17 rows, ids 14–30
SELECT * FROM students WHERE student_id NOT BETWEEN 14 AND 30;  -- 84 rows (101 − 17)
```

- `BETWEEN a AND b` is **inclusive on both ends** — it is exactly `col >= a AND col <= b`
- `NOT BETWEEN` is simply the complement — every row outside the range: `col < a OR col > b`. Here that's ids 1–13 plus ids 31–101 = 13 + 71 = 84 rows

| Query | Same as | Rows |
|-------|---------|-----:|
| `BETWEEN 1 AND 15` | `id >= 1 AND id <= 15` | 15 |
| `BETWEEN 14 AND 30` | `id >= 14 AND id <= 30` | 17 |
| `NOT BETWEEN 14 AND 30` | `id < 14 OR id > 30` | 84 |

The two `BETWEEN` ranges overlap on ids 14 and 15 — both queries return them, because both ends are included.

Gotchas:

- Put the **smaller value first**. `BETWEEN 30 AND 14` returns **0 rows** (it means `>= 30 AND <= 14`, which is impossible).
- `BETWEEN` on a column with `NULL`s: rows with `NULL` match neither `BETWEEN` nor `NOT BETWEEN`. (Not an issue for `student_id`, which can't be `NULL`.)
- On dates/timestamps, `BETWEEN '2026-10-01' AND '2026-10-31'` stops at midnight at the *start* of the 31st — times later that day are missed.

> **Try it yourself:** `SELECT * FROM students WHERE student_age BETWEEN 18 AND 20;` — you should get 7 + 5 + 5 = 17 rows.

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

**Query 1 — sort by id, descending.** The `WHERE` keeps students aged 16–22: 1 + 9 + 7 + 5 + 5 + 5 + 5 = **37 rows**. `DESC` puts the biggest id first, so the list starts `101 Sharon Alvarez, 98 Benjamin Sanchez, 97 Kathleen Nelson, ...` and ends with id 1.

**Query 2 — sort by two columns.** `ORDER BY student_name DESC, student_id DESC` means: sort by name Z→A; only when two names are **equal** use the id (largest first) to break the tie. The second column matters here because this table has duplicate names (e.g. two `Sharon Alvarez` rows).

**Query 3 — take one page.** `LIMIT 10` = return at most 10 rows; `OFFSET 0` = skip 0 rows first (start at the top). The page from the notebook:

| # | student_id | student_name | student_age |
|--:|-----------:|--------------|------------:|
| 1 | 89 | Steven Hall | 22 |
| 2 | 88 | Sneha Bailey | 18 |
| 3 | 101 | Sharon Alvarez | 16 |
| 4 | 23 | Sandra Moore | 18 |
| 5 | 29 | Samuel Thompson | 21 |
| 6 | 78 | Samantha Wood | 19 |
| 7 | 32 | Samantha Phillips | 17 |
| 8 | 52 | Ravi Taylor | 17 |
| 9 | 84 | Priya Hill | 17 |
| 10 | 11 | Pooja Sharma | 17 |

Paging formula: **`OFFSET = (page_number − 1) × page_size`**.

| Page | Clause | Rows returned |
|-----:|--------|---------------|
| 1 | `LIMIT 10 OFFSET 0` | 1–10 |
| 2 | `LIMIT 10 OFFSET 10` | 11–20 |
| 3 | `LIMIT 10 OFFSET 20` | 21–30 |
| 4 | `LIMIT 10 OFFSET 30` | 31–37 (only 7 left) |

Common mistakes:

- Clause order is fixed when you **type** it: `WHERE` before `ORDER BY` before `LIMIT`. Writing `LIMIT` before `ORDER BY` is a syntax error.
- `DESC` applies only to the column right before it. `ORDER BY student_name, student_id DESC` sorts names A→Z and only ids descending.
- `LIMIT` without `ORDER BY` gives "some 10 rows" — the order is not guaranteed, so pages can overlap or skip rows.
- `DESC` in `ORDER BY` means *descending*; `DESC students` on its own means *describe*. Same word, different jobs.

> **Try it yourself:** write the query for page 2 of the same list. The first row should be the 11th name in Z→A order.

## 10. Views — a saved query with a name

```sql
CREATE VIEW arbaz AS
(
  SELECT * FROM students
);                      -- OK, 0 records retrieved

SELECT * FROM arbaz;    -- 101 rows, same as the students table
```

Step by step:

- `CREATE VIEW arbaz` — create a new object called `arbaz` (it now shows up in `SHOW TABLES` next to `students`)
- `AS ( SELECT * FROM students )` — the query the view stands for. The parentheses are optional
- `SELECT * FROM arbaz` — you read a view exactly like a table

A view is a **virtual table**: it stores no data of its own, just the query. Every read of `arbaz` re-runs the underlying `SELECT`, so it always shows the current contents of `students`. Views shine later, when a long join or filter deserves a short, friendly name.

A more realistic example — a view that hides the messy filter:

```sql
CREATE VIEW teen_students AS
SELECT student_id, student_name, student_age
FROM students
WHERE student_age BETWEEN 16 AND 19;

SELECT * FROM teen_students ORDER BY student_name;
```

Gotchas:

- Running `CREATE VIEW arbaz ...` a second time fails with *Table 'arbaz' already exists*. Use `CREATE OR REPLACE VIEW` to change it, or `DROP VIEW arbaz;` to remove it.
- `SELECT *` in a view is frozen at creation time: if you later add a column to `students`, the view does **not** pick it up until you recreate it.
- Give views meaningful names (`active_students`, `teen_students`) — a person's name like `arbaz` says nothing about what the view contains.

> **Try it yourself:** `SHOW FULL TABLES;` — the `Table_type` column says `BASE TABLE` for `students` and `VIEW` for `arbaz`.

## 11. Listing stored procedures

```sql
SHOW PROCEDURE STATUS WHERE Db = 'pal_india';
```

This is the last line in the notebook — a preview of the next topic, **stored procedures** (a named block of SQL saved in the database that you run with `CALL name();`).

- `SHOW PROCEDURE STATUS` lists every stored procedure on the server, from **all** databases
- `WHERE Db = 'pal_india'` narrows it to the procedures that belong to our database. `Db` is one of the output columns — `SHOW ... WHERE` filters on those columns just like a normal `WHERE`
- Useful output columns: `Db`, `Name`, `Type` (`PROCEDURE`), `Definer`, `Modified`, `Created`

What to expect: we have not created any procedures yet, so this returns an **empty result** (0 rows) — that's correct, not an error. (The notebook has no saved output for this line.)

Gotchas:

- The value is a string, so quote it: `Db = 'pal_india'`. Without quotes MySQL looks for a *column* called `pal_india`.
- Views are not procedures — `arbaz` will not appear here.

> **Try it yourself:** `SHOW FUNCTION STATUS WHERE Db = 'pal_india';` lists stored **functions** the same way.

---

## Commands Summary

| Command | What it does |
|---|---|
| `\about` | MySQL Shell command (not SQL): show the Shell welcome/help text |
| `USE db` | Make `db` the current database |
| `SHOW TABLES` | List tables (and views) in the current database |
| `DESC table` | Show the table's columns, types, keys and defaults |
| `UPDATE t SET col = v WHERE ...` | Change only the matching rows |
| `MODIFY col TIMESTAMP DEFAULT CURRENT_TIMESTAMP` | Auto-fill the insert time |
| `... ON UPDATE CURRENT_TIMESTAMP` | Auto-refresh the time on every update |
| `COUNT / SUM / AVG / MIN / MAX(col)` | Count, total, mean, smallest, largest — NULLs skipped |
| `COUNT(*)` | Count all rows, NULLs included |
| `expr AS alias` | Rename a result column |
| `GROUP BY a, b` | Collapse rows with equal values into one group row |
| `HAVING condition` | Filter groups after aggregation |
| `ANY_VALUE(col)` | Pick an arbitrary value from a group (satisfies ONLY_FULL_GROUP_BY) |
| `WHERE col IN (SELECT ...)` | Match against the subquery's result list |
| `LIKE ... AND / OR ...` | Combine conditions — `AND` binds before `OR` |
| `BETWEEN a AND b` / `NOT BETWEEN` | Inclusive range test / everything outside it |
| `ORDER BY a DESC, b DESC` | Sort by `a`; break ties with `b` |
| `LIMIT n OFFSET m` | Skip `m` rows, then return at most `n` |
| `CREATE VIEW name AS SELECT ...` | Save a query as a virtual table |
| `SHOW PROCEDURE STATUS WHERE Db = '...'` | List the stored procedures of one database |

**Logical order of a SELECT:** `FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY → LIMIT`
