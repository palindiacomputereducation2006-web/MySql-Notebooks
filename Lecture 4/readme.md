# MySQL Lecture 4 — Views, EXPLAIN, Indexes, Foreign Keys & JOINs

In this lecture we managed **views** (listing, creating, dropping), looked inside queries with `EXPLAIN` and `EXPLAIN ANALYZE`, added a composite `UNIQUE INDEX`, built a second table — `addresses` — linked to `students` with a **foreign key**, and then combined the two tables with every kind of **JOIN**: `INNER`, `LEFT`, `RIGHT`, a full-outer emulation with `UNION`, and `CROSS`.

## What this lecture covers

| Family | Commands practiced |
|--------|--------------------|
| Navigation | `USE`, `SHOW DATABASES`, `SHOW TABLES`, `SHOW FULL TABLES` |
| Views | `CREATE VIEW`, `DROP VIEW`, `SHOW FULL TABLES WHERE Table_type = 'VIEW'`, `SELECT ... FROM view ORDER BY` |
| Query plans | `EXPLAIN`, `EXPLAIN ANALYZE` |
| Indexes | `CREATE UNIQUE INDEX`, `SHOW INDEX FROM` |
| DDL | `CREATE TABLE` with `ENUM`, `ALTER TABLE ... MODIFY ... ADD CONSTRAINT ... FOREIGN KEY ... ON DELETE CASCADE`, `DESC` |
| DML | Multi-row `INSERT` |
| Joins | `INNER JOIN`, `LEFT JOIN`, `RIGHT JOIN`, `UNION`, `CROSS JOIN`, table aliases (`AS s`) |
| Aggregates | `COUNT(*)` |

**Tool used:** MySQL Shell — DB Notebook (execute a line with `Ctrl+Enter`)

> **Prerequisite:** the `pal_india` database with the 101-row `students` table and the `arbaz` view from Lecture 3.

### The students table (quick reminder)

Every query below uses this table from Lecture 3. These are its 10 columns, with one sample row:

| student_id | student_name | student_age | student_address | student_email | student_gender | student_contact | student_is_active | createdAt | updateAt |
|---|---|---|---|---|---|---|---|---|---|
| 1 | Linda Hernandez | 20 | 8945 Maple Dr, Houston, TX 87397 | linda.patel1@hotmail.com | `NULL` | +1-438-717-1434 | 1 | `NULL` | `NULL` |

---

## 1. Looking around

```sql
USE pal_india;    -- make pal_india the "current" database for everything that follows
SHOW DATABASES;   -- information_schema, mysql, pal_india, performance_schema, sakila, sys, world
SHOW TABLES;      -- tables AND views of pal_india, in one list
```

**Step by step:**

- `USE pal_india` — after this, a bare name like `students` means `pal_india.students`. The notebook replies `OK, 0 records retrieved` — it changes your session, it returns no rows.
- `SHOW DATABASES` — lists every database on the server. In the notebook it returned **7** names:

| Database | What it is |
|----------|-----------|
| `information_schema` | MySQL's read-only catalogue (descriptions of all tables, columns, indexes…) |
| `mysql` | users, privileges and server settings |
| `pal_india` | **ours** |
| `performance_schema` | live performance counters |
| `sakila` | MySQL's sample DVD-rental database |
| `sys` | friendly views built on top of `performance_schema` |
| `world` | MySQL's sample countries / cities database |

- `SHOW TABLES` — lists **tables and views together**, with nothing to tell them apart. That's why the next sections switch to `SHOW FULL TABLES`.

> In the saved notebook, `SHOW TABLES` shows only `student_search` and `students`. That's because the notebook cells were re-run later, **after** `arbaz` was dropped and `student_search` was created. Run in order on a fresh Lecture 3 database, you'd see `arbaz` and `students`.

**Common mistakes**

- Forgetting `USE` → `Error 1046: No database selected` on the next query.
- Writing `SHOW DATABASE` or `SHOW TABLE` (singular) — both are syntax errors; the plural is required.

## 2. Inspecting the arbaz view

```sql
SELECT * FROM arbaz;   -- 101 rows, identical to students
EXPLAIN arbaz;         -- same as DESC arbaz — lists the view's columns
```

`SELECT * FROM arbaz` re-runs the saved `SELECT * FROM students`, so you get the same 101 rows in the same order (Linda Hernandez, Puja Tomar, Mark Rivera, …).

`EXPLAIN <table>` is just another spelling of `DESC` — it shows the view's columns. Real output:

| Field | Type | Null | Key | Default | Extra |
|-------|------|------|-----|---------|-------|
| `student_id` | int | NO | | **0** | |
| `student_name` | varchar(50) | NO | | | |
| `student_age` | int | YES | | | |
| `student_address` | varchar(100) | YES | | | |
| `student_email` | varchar(50) | NO | | | |
| `student_gender` | varchar(20) | YES | | | |
| `student_contact` | varchar(25) | YES | | | |
| `student_is_active` | tinyint(1) | YES | | 1 | |
| `createdAt` | timestamp | YES | | CURRENT_TIMESTAMP | DEFAULT_GENERATED |
| `updateAt` | timestamp | YES | | CURRENT_TIMESTAMP | DEFAULT_GENERATED on update CURRENT_TIMESTAMP |

Compare it with `DESC students` from Lecture 3:

| Column | In `students` | In the `arbaz` view |
|--------|---------------|---------------------|
| `student_id` | `PRI`, `auto_increment` | no key, default `0` |
| everything else | same type / nullability | same type / nullability |

A view has **no keys and no indexes of its own** — it's only a saved `SELECT`. The primary key still lives on the real table underneath.

> `EXPLAIN` has two jobs: `EXPLAIN table_name` describes columns (like `DESC`), while `EXPLAIN SELECT ...` describes a **query plan** (section 7). Same keyword, different output.

## 3. Listing only the views

```sql
SHOW FULL TABLES WHERE Table_type = 'VIEW';   -- arbaz | VIEW
```

**How it works:**

1. `SHOW FULL TABLES` produces a two-column list — `Tables_in_pal_india` and `Table_type`.
2. `Table_type` is `BASE TABLE` for real tables and `VIEW` for views.
3. `WHERE Table_type = 'VIEW'` filters that list, exactly like a `WHERE` on a normal table.

| Tables_in_pal_india | Table_type |
|---------------------|-----------|
| arbaz | VIEW |

- The column name is **not case-sensitive** here — the notebook uses both `Table_type` and `table_type`.
- The value **is** compared as text: `'VIEW'` (with quotes). Writing `= VIEW` without quotes is an error.

> **Try it yourself:** `SHOW FULL TABLES WHERE Table_type = 'BASE TABLE';` lists only the real tables.

## 4. A view with a filter

```sql
CREATE VIEW student_search AS (
    SELECT * FROM students WHERE student_name LIKE '%linda%'
);
-- OK, 0 records retrieved

SHOW FULL TABLES WHERE table_type = 'VIEW';   -- arbaz, student_search
SELECT * FROM student_search;                 -- 1 row: Linda Hernandez (id 1)
```

**Step by step:**

- `CREATE VIEW student_search AS ( ... )` — stores the query under the name `student_search`. Nothing is copied; MySQL saves only the SQL text. The parentheses are optional.
- `LIKE '%linda%'` — `%` means "any number of any characters", so this matches any name **containing** "linda" anywhere. With the default collation `LIKE` is case-insensitive, so "Linda" matches the lowercase pattern.

Result:

| student_id | student_name | student_age | student_email |
|-----------|--------------|-------------|---------------|
| 1 | Linda Hernandez | 20 | linda.patel1@hotmail.com |

This time the view hides a `WHERE` clause. Anyone running `SELECT * FROM student_search` gets the "Linda" search without having to know the `LIKE` pattern. Because a view re-runs its query every time, renaming another student to Linda would make them appear here automatically.

**Common mistakes**

- Running `CREATE VIEW` twice → `Error 1050: Table 'student_search' already exists`. Use `CREATE OR REPLACE VIEW` when you want to change a view.
- `SELECT *` in a view freezes the column list at creation time — columns added to `students` later will **not** appear in the view until you recreate it.

> **Try it yourself:** create `gmail_students` with `WHERE student_email LIKE '%@gmail.com'` and count its rows with `SELECT COUNT(*) FROM gmail_students;`.

## 5. Dropping a view

```sql
DROP VIEW arbaz;
-- OK, 0 records retrieved
```

`DROP VIEW` removes only the saved query — **no student data is deleted**, because the view never held any. `SELECT COUNT(*) FROM students` would still return 101.

- Dropping a view that doesn't exist → `Error 1051: Unknown table`. `DROP VIEW IF EXISTS arbaz;` is the safe form.
- `DROP VIEW` only works on views. Using `DROP TABLE` on a view (or `DROP VIEW` on a table) fails — a useful safety net, because `DROP TABLE students` **would** delete data.

## 6. A view built on a subquery

```sql
CREATE VIEW select_students AS (
    SELECT * FROM students WHERE student_age IN (
        SELECT student_age FROM students GROUP BY student_age HAVING COUNT(*) > 1
    )
);

SHOW FULL TABLES WHERE table_type = 'VIEW';   -- select_students, student_search
SHOW FULL TABLES;                             -- + students | BASE TABLE
```

**How MySQL evaluates it (inside out):**

1. **Inner query** — `GROUP BY student_age` makes one group per age; `HAVING COUNT(*) > 1` keeps only ages that occur more than once. Real age counts from the data:

| student_age | COUNT(*) | Kept? |
|------------|----------|-------|
| 16 | 1 | no |
| 17 | 9 | yes |
| 24 | 13 | yes |
| … | … | … |
| 102 | 1 | no |
| `NULL` | 5 | group is kept, but see below |

2. **Outer query** — keeps each student whose `student_age` is `IN` that list.

`SHOW FULL TABLES` now shows `arbaz` is gone and the new view is listed:

| Tables_in_pal_india | Table_type |
|---------------------|-----------|
| select_students | VIEW |
| student_search | VIEW |
| students | BASE TABLE |

### Querying the views

```sql
SELECT * FROM student_search;                                        -- still 1 row: Linda Hernandez
SELECT * FROM select_students;                                       -- 94 rows
SELECT * FROM select_students ORDER BY student_name DESC, student_id ASC;  -- 94 rows, Zachary King → Aaron Gupta
```

`student_search` was queried once more to confirm that dropping `arbaz` and creating another view didn't affect it — views are independent of each other.

The Lecture 3 subquery is now saved under a name: "students whose age is shared by at least one other student". 94 of the 101 rows qualify. The 7 that don't:

- 5 students have `NULL` age — `NULL IN (...)` is never true (ids 17, 19, 28, 43, 81)
- 2 students have an age nobody else has — their group's `COUNT(*)` is 1 (William Parker, id 95, age 102; Sharon Alvarez, id 101, age 16)

You can query a view like any table — here it's sorted Z→A by name, with `student_id` breaking ties:

| student_id | student_name | student_age |
|-----------|--------------|-------------|
| 18 | Zachary King | 29 |
| 40 | Zachary Baker | 29 |
| 58 | William Parker | 26 |
| … | … | … |
| 9 | Aiden Ortiz | 25 |
| 16 | Aaron Gupta | 20 |

- `ORDER BY student_name DESC` sorts by the first column; `student_id ASC` is used **only** when two names are identical (e.g. two "William Parker"s — ids 58 and 95 — but id 95 is not in this view because of age 102).
- `ASC` is the default and could be left out.

> **Gotcha:** if you leave out `ORDER BY`, MySQL returns rows in whatever order is cheapest — usually, but **not guaranteed**, by primary key. Always add `ORDER BY` when order matters.

## 7. Reading a query plan with EXPLAIN

```sql
SELECT * FROM students WHERE student_age LIKE 22;           -- 5 rows: ids 22, 39, 48, 75, 89
EXPLAIN SELECT * FROM students WHERE student_age LIKE 22;
```

The query returns the five 22-year-olds:

| student_id | student_name | student_age |
|-----------|--------------|-------------|
| 22 | Henry Rodriguez | 22 |
| 39 | Ayse Carter | 22 |
| 48 | Jerry White | 22 |
| 75 | Kevin Singh | 22 |
| 89 | Steven Hall | 22 |

`EXPLAIN` in front of a query doesn't run it — it shows **how MySQL plans to run it**. The full output row was:

| id | select_type | table | partitions | type | possible_keys | key | key_len | ref | rows | filtered | Extra |
|----|-------------|-------|-----------|------|---------------|-----|---------|-----|------|----------|-------|
| 1 | SIMPLE | students | `NULL` | ALL | `NULL` | `NULL` | `NULL` | `NULL` | 101 | 11.11 | Using where |

What each column means:

| Column | Value | Meaning |
|--------|-------|---------|
| `id` | `1` | which `SELECT` this row describes (subqueries/unions get more ids) |
| `select_type` | `SIMPLE` | a plain query — no subquery or `UNION` |
| `table` | `students` | the table being read |
| `type` | `ALL` | full table scan — every row is read |
| `possible_keys` / `key` | `NULL` | indexes MySQL *could* use / the one it *chose* — none here |
| `key_len`, `ref` | `NULL` | how much of the index is used / what it's compared to — no index, so nothing |
| `rows` | `101` | estimated rows to examine |
| `filtered` | `11.11` | estimated % of those rows that pass the `WHERE` (101 × 11.11% ≈ 11; the real answer was 5) |
| `Extra` | `Using where` | the filter is applied row by row |

The `type` column is the most important one. From worst to best, the common values are:

| type | Meaning |
|------|---------|
| `ALL` | read the whole table |
| `index` | read the whole index |
| `range` | read a slice of an index (`BETWEEN`, `>`, `<`) |
| `ref` | look up matching rows through a non-unique index |
| `eq_ref` / `const` | at most one matching row through a primary / unique key |

`type = ALL` on a large table is the classic sign of a slow query that needs an index.

> `LIKE` on an `INT` column works because MySQL converts the number to text first — but that conversion is also what stops an index being used. `WHERE student_age = 22` is the proper way to write it.

> **Try it yourself:** run `EXPLAIN SELECT * FROM students WHERE student_id = 22;` — searching by the primary key should show `type = const`, `key = PRIMARY` and `rows = 1`.

## 8. Creating a composite UNIQUE INDEX

```sql
CREATE UNIQUE INDEX idx_search_name ON students (student_age, student_email, student_name);
-- OK, 0 records retrieved
SHOW FULL TABLES;          -- still the same 3 rows
SHOW INDEX FROM students;
```

**Step by step:**

- `CREATE UNIQUE INDEX idx_search_name` — create an index and give it a name (you'll need the name to drop it later: `DROP INDEX idx_search_name ON students;`).
- `ON students (student_age, student_email, student_name)` — the table and the columns, **in this order**. The order matters (see "leftmost" below).
- MySQL reads all 101 rows, sorts them by the three columns and builds the index. If any two rows already had the same combination, the command would fail with a duplicate-entry error.

An **index** is a sorted lookup structure (a B-tree) that lets MySQL jump to matching rows instead of scanning the whole table — like the index at the back of a book. `UNIQUE` additionally forbids two rows with the same combination of the three values.

`SHOW FULL TABLES` was run straight after to show that an index is **not** a table — the list is unchanged (`select_students`, `student_search`, `students`). Indexes live *inside* their table; you see them with `SHOW INDEX`.

`SHOW INDEX` result:

| Key_name | Non_unique | Seq_in_index | Column_name | Cardinality | Null | Index_type |
|----------|-----------|--------------|-------------|-------------|------|-----------|
| `PRIMARY` | 0 | 1 | `student_id` | 101 | | BTREE |
| `student_id` | 0 | 1 | `student_id` | 101 | | BTREE |
| `idx_search_name` | 0 | 1 | `student_age` | 17 | YES | BTREE |
| `idx_search_name` | 0 | 2 | `student_email` | 101 | | BTREE |
| `idx_search_name` | 0 | 3 | `student_name` | 101 | | BTREE |

- **Composite index** — one index covering three columns; `Seq_in_index` gives their order. It helps queries that filter on the **leftmost** column(s) (`student_age`, or `student_age` + `student_email`, …), not ones that filter on `student_name` alone.
- **Non_unique = 0** — every index here is unique.
- **Cardinality** — the estimated number of distinct values: 17 ages (16 + `NULL`) vs 101 unique emails.
- **Null = YES** — `student_age` allows `NULL`. A `UNIQUE` index allows **many** `NULL`s, because `NULL` is never "equal" to another `NULL`.
- The separate `student_id` index duplicates `PRIMARY` — a leftover `UNIQUE` on the same column. It's redundant and only slows down writes.

The "leftmost prefix" rule, illustrated:

| Query filters on | Can use `idx_search_name`? |
|------------------|----------------------------|
| `student_age = 22` | yes |
| `student_age = 22 AND student_email = '...'` | yes |
| `student_email = '...'` only | no — skips the first column |
| `student_name = '...'` only | no |

> **Gotcha:** indexes speed up reads but every `INSERT` / `UPDATE` / `DELETE` must also update every index. Don't index every column "just in case".

## 9. When an index can't help — EXPLAIN ANALYZE

```sql
SELECT * FROM students WHERE student_age LIKE 22;      -- 5 rows
SELECT * FROM students WHERE student_age LIKE '%22';   -- 5 rows (same students)
EXPLAIN ANALYZE SELECT * FROM students WHERE student_age LIKE '%22';
```

- Both `SELECT`s return the same 5 students (ids 22, 39, 48, 75, 89). `'%22'` means "text ending in 22" — no student is 122 or 222, so only the 22-year-olds match.
- `EXPLAIN ANALYZE` **actually runs** the query and reports real timings next to the estimates:

```
-> Filter: (students.student_age like '%22')  (cost=10.3 rows=11.2) (actual time=0.0718..0.158 rows=5 loops=1)
    -> Table scan on students  (cost=10.3 rows=101) (actual time=0.0419..0.119 rows=101 loops=1)
```

Read it from the inside out (the most-indented line runs first):

| Piece | Meaning |
|-------|---------|
| `Table scan on students` | step 1 — read every row of the table |
| `cost=10.3` | the optimizer's estimated cost (a relative number, not milliseconds) |
| `rows=101` (estimate) / `rows=101` (actual) | rows it expected vs rows it really produced |
| `actual time=0.0419..0.119` | ms until the first row .. ms until the last row |
| `loops=1` | how many times this step ran |
| `Filter: ... like '%22'` | step 2 — keep only rows passing the `WHERE`: estimated 11.2, actually **5** |

So a **table scan** reads all 101 rows, then the **filter** keeps 5. Even with `idx_search_name` in place, MySQL still scans because:

- a pattern starting with `%` can't use a B-tree — the index is sorted by the *start* of the value
- `LIKE` on a number forces a number → text conversion on every row

Indexes only help when the condition can be matched against the sorted values directly (`=`, `<`, `>`, `BETWEEN`, `LIKE 'abc%'`).

| `EXPLAIN` | `EXPLAIN ANALYZE` |
|-----------|-------------------|
| does **not** run the query | **runs** the query |
| table of estimates | tree with estimates **and** real times / row counts |
| safe on any query | careful with slow queries — and it really executes them |

> **Try it yourself:** compare `EXPLAIN SELECT * FROM students WHERE student_age = 22;` with the `LIKE` version. With the index in place, the `=` version typically shows `key = idx_search_name` instead of a full scan.

## 10. A second table: addresses

```sql
CREATE TABLE addresses (
    address_id   INT PRIMARY KEY AUTO_INCREMENT,                  -- 1, 2, 3 … filled in automatically
    student_id   INT NOT NULL,                                    -- which student owns this address
    address_type ENUM("Home", "Hostel", "Office", "Permanent") NOT NULL,
    street       VARCHAR(150),                                    -- optional
    city         VARCHAR(50) NOT NULL,                            -- required
    state        VARCHAR(50),
    pincode      VARCHAR(10),
    createdAt    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updateAt     TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
-- OK, 0 records retrieved
```

One student can have **many** addresses (home, hostel, office…) — a **one-to-many** relationship. Instead of cramming them all into `students.student_address`, they get their own table, and each row records which student it belongs to via `student_id`.

```
students (1) ─────< addresses (many)
 student_id          student_id
```

- `ENUM(...)` — the column only accepts one of the listed values; `"Garage"` would be rejected (in strict mode: `Error 1265: Data truncated for column 'address_type'`)
- `pincode` is `VARCHAR`, not `INT` — it's an identifier, not a number you do maths on (and it may have leading zeros)
- The two timestamp columns reuse the Lecture 3 trick from the start
- At this point `student_id` is just a number — nothing yet stops you inserting `student_id = 999`. The next section fixes that.

## 11. Linking the tables with a FOREIGN KEY

```sql
ALTER TABLE addresses
MODIFY student_id INT NOT NULL,                            -- (re)state the column definition
ADD CONSTRAINT fk_address_student FOREIGN KEY (student_id) -- name the rule, pick the child column
REFERENCES students(student_id) ON DELETE CASCADE;         -- parent table/column + delete behaviour
-- MySQL Error (1826): Duplicate foreign key constraint name 'fk_address_student'
```

**Clause by clause:**

| Clause | What it does |
|--------|--------------|
| `ALTER TABLE addresses` | change an existing table (the *child*) |
| `MODIFY student_id INT NOT NULL` | redefine the column — here it's already `INT NOT NULL`, so this part changes nothing |
| `ADD CONSTRAINT fk_address_student` | add a rule and give it a name |
| `FOREIGN KEY (student_id)` | the child column being checked |
| `REFERENCES students(student_id)` | the *parent* table and column it must match (must be a primary or unique key) |
| `ON DELETE CASCADE` | what happens to children when a parent is deleted |

A **foreign key** says: "every `addresses.student_id` must exist in `students.student_id`". MySQL then enforces it:

- inserting an address for student 999 (who doesn't exist) fails with `Error 1452: Cannot add or update a child row: a foreign key constraint fails`
- `ON DELETE CASCADE` — deleting a student automatically deletes all their addresses, so no orphan rows are left behind

Other `ON DELETE` choices:

| Option | Deleting a student who has addresses… |
|--------|---------------------------------------|
| `RESTRICT` / `NO ACTION` (default) | is **refused** with an error |
| `CASCADE` | also deletes their addresses |
| `SET NULL` | sets `addresses.student_id` to `NULL` — impossible here, the column is `NOT NULL` |

The error in the notebook just means the constraint **already existed** — the statement had been run once before. Constraint names must be unique, so the second run was rejected. Nothing was changed by the failing run. `DESC` confirms the key is in place:

```sql
DESC addresses;
```

| Field | Type | Null | Key | Default | Extra |
|-------|------|------|-----|---------|-------|
| `address_id` | `int` | NO | PRI | | auto_increment |
| `student_id` | `int` | NO | **MUL** | | |
| `address_type` | `enum('Home','Hostel','Office','Permanent')` | NO | | | |
| `street` | `varchar(150)` | YES | | | |
| `city` | `varchar(50)` | NO | | | |
| `state` | `varchar(50)` | YES | | | |
| `pincode` | `varchar(10)` | YES | | | |
| `createdAt` | `timestamp` | YES | | CURRENT_TIMESTAMP | DEFAULT_GENERATED |
| `updateAt` | `timestamp` | YES | | CURRENT_TIMESTAMP | DEFAULT_GENERATED on update CURRENT_TIMESTAMP |

`MUL` (multiple) means `student_id` is indexed and **duplicates are allowed** — exactly right, since one student can have several addresses. MySQL creates this index automatically for every foreign key.

> `DESC` doesn't show the constraint itself. To see it, run `SHOW CREATE TABLE addresses;` — the output includes `CONSTRAINT fk_address_student FOREIGN KEY ...`.

**Common mistakes**

- Parent and child columns of different types (e.g. `INT` vs `BIGINT`) → the foreign key can't be created.
- Adding the foreign key when the child table already contains orphan rows → it fails until you fix or delete them.

## 12. Filling addresses

```sql
INSERT INTO addresses (student_id, address_type, street, city, state, pincode) VALUES
(1,  "Home",      "12 MG Road",            "Indore",    "Madhya Pradesh", "452001"),
(1,  "Hostel",    "Block B, Room 204",     "Bhopal",    "Madhya Pradesh", "462001"),
(1,  "Office",    "Tech Park, Tower 3",    "Pune",      "Maharashtra",    "411057"),
(2,  "Home",      "45 Civil Lines",        "Jaipur",    "Rajasthan",      "302006"),
(2,  "Permanent", "Village Rampura",       "Ajmer",     "Rajasthan",      "305001"),
(5,  "Home",      "8 Park Street",         "Kolkata",   "West Bengal",    "700016"),
(7,  "Home",      "221 Sector 15",         "Noida",     "Uttar Pradesh",  "201301"),
(7,  "Hostel",    "PG near Metro Station", "Delhi",     "Delhi",          "110001"),
(10, "Home",      "3 Anna Salai",          "Chennai",   "Tamil Nadu",     "600002"),
(12, "Home",      "77 Banjara Hills",      "Hyderabad", "Telangana",      "500034"),
(22, "Home",      "5 FC Road",             "Pune",      "Maharashtra",    "411004"),
(22, "Office",    "Magarpatta City",       "Pune",      "Maharashtra",    "411013"),
(44, "Home",      "19 Residency Road",     "Bengaluru", "Karnataka",      "560025"),
(101, "Home",     "60 Vijay Nagar",        "Indore",    "Madhya Pradesh", "452010");
-- OK, 14 rows affected

SELECT * FROM addresses;   -- 14 rows, address_id 1–14
```

**How it works:**

- The column list names only 6 columns. The other 3 are filled in automatically: `address_id` (auto-increment 1–14), `createdAt` and `updateAt` (the current time).
- Each `( ... )` is one row; values go into the listed columns **in order**.
- For every row, the foreign key checks that the `student_id` exists in `students` — all 14 do, so the whole insert succeeds.

First rows of `SELECT * FROM addresses`:

| address_id | student_id | address_type | street | city | state | pincode | createdAt | updateAt |
|-----------|-----------|--------------|--------|------|-------|---------|-----------|----------|
| 1 | 1 | Home | 12 MG Road | Indore | Madhya Pradesh | 452001 | 2026-10-10 09:29:25 | 2026-10-10 09:29:25 |
| 2 | 1 | Hostel | Block B, Room 204 | Bhopal | Madhya Pradesh | 462001 | 2026-10-10 09:29:25 | 2026-10-10 09:29:25 |
| 3 | 1 | Office | Tech Park, Tower 3 | Pune | Maharashtra | 411057 | 2026-10-10 09:29:25 | 2026-10-10 09:29:25 |

14 addresses spread over **9 students**: ids 1 (3 addresses), 2, 7, 22 (2 each), and 5, 10, 12, 44, 101 (1 each). All rows share the same timestamp because they were inserted by one statement.

> **Try it yourself:** `INSERT INTO addresses (student_id, address_type, city) VALUES (999, 'Home', 'Goa');` — watch the foreign key reject it. Then try `address_type = 'Garage'` with a valid student to see `ENUM` reject it.

## 13. INNER JOIN — only the matches

```sql
SELECT * FROM students
INNER JOIN addresses
ON students.student_id = addresses.student_id;   -- 14 rows, 19 columns
```

A **join** glues rows from two tables side by side wherever the `ON` condition is true. `INNER JOIN` keeps **only rows that match on both sides**.

**How MySQL evaluates it:**

1. `FROM students INNER JOIN addresses` — consider pairs of (student, address).
2. `ON students.student_id = addresses.student_id` — keep a pair only when the ids are equal.
3. `SELECT *` — output every column of both tables for each kept pair.

A small illustration (3 students, 4 addresses):

```
students                      addresses
student_id | student_name     address_id | student_id | city
-----------+---------------   -----------+------------+--------
1          | Linda Hernandez  1          | 1          | Indore
2          | Puja Tomar       2          | 1          | Bhopal
3          | Mark Rivera      3          | 1          | Pune
                              4          | 2          | Jaipur
```

INNER JOIN result:

| student_id | student_name | address_id | city |
|-----------|--------------|-----------|------|
| 1 | Linda Hernandez | 1 | Indore |
| 1 | Linda Hernandez | 2 | Bhopal |
| 1 | Linda Hernandez | 3 | Pune |
| 2 | Puja Tomar | 4 | Jaipur |

Mark Rivera has no address, so he disappears.

In the real data:

- Linda Hernandez (id 1) appears **3 times** — once per address
- The 92 students without an address don't appear at all

`SELECT *` returns all 10 `students` columns + all 9 `addresses` columns, so `student_id`, `createdAt` and `updateAt` show up twice.

### Picking columns with table aliases

```sql
SELECT s.student_id, s.student_name, s.student_age, s.student_email,
       a.street, a.city, a.student_id
FROM students AS s
INNER JOIN addresses AS a
ON s.student_id = a.student_id;   -- 14 rows, 7 columns
```

`students AS s` and `addresses AS a` give each table a short nickname. The prefix (`s.` / `a.`) is required whenever a column name exists in both tables — plain `student_id` would be ambiguous (`Error 1052: Column 'student_id' in field list is ambiguous`).

All 14 rows:

| s.student_id | student_name | age | street | city | a.student_id |
|-----------|--------------|-----|--------|------|------|
| 1 | Linda Hernandez | 20 | 12 MG Road | Indore | 1 |
| 1 | Linda Hernandez | 20 | Block B, Room 204 | Bhopal | 1 |
| 1 | Linda Hernandez | 20 | Tech Park, Tower 3 | Pune | 1 |
| 2 | Puja Tomar | 26 | 45 Civil Lines | Jaipur | 2 |
| 2 | Puja Tomar | 26 | Village Rampura | Ajmer | 2 |
| 5 | Frank Hughes | 27 | 8 Park Street | Kolkata | 5 |
| 7 | Rohan Gomez | 27 | 221 Sector 15 | Noida | 7 |
| 7 | Rohan Gomez | 27 | PG near Metro Station | Delhi | 7 |
| 10 | James Castillo | 21 | 3 Anna Salai | Chennai | 10 |
| 12 | Aman Yilmaz | 29 | 77 Banjara Hills | Hyderabad | 12 |
| 22 | Henry Rodriguez | 22 | 5 FC Road | Pune | 22 |
| 22 | Henry Rodriguez | 22 | Magarpatta City | Pune | 22 |
| 44 | Melissa Cox | 28 | 19 Residency Road | Bengaluru | 44 |
| 101 | Sharon Alvarez | 16 | 60 Vijay Nagar | Indore | 101 |

(the `student_email` column is omitted here to save space)

- Once you give a table an alias, use the alias everywhere in that query — `students.student_name` would now be an error.
- `AS` is optional: `FROM students s` works too.
- `INNER JOIN` and plain `JOIN` mean the same thing.

> The join statements in the notebook have no trailing `;` — they work because each one was run on its own with `Ctrl+Enter`. Add the semicolon when running several statements together.

> **Try it yourself:** add `WHERE a.city = 'Pune'` before the end — you should get 3 rows (Linda's office and Henry's two addresses).

## 14. LEFT JOIN — every student, address or not

```sql
SELECT s.student_id, s.student_name, s.student_age, s.student_email,
       a.street, a.city, a.student_id
FROM students AS s
LEFT JOIN addresses AS a
ON s.student_id = a.student_id;   -- 106 rows
```

`LEFT JOIN` keeps **every row of the left table** (`students`, written before `LEFT JOIN`). Where there's no matching address, the address columns come back as `NULL`.

Same small illustration as before:

| student_id | student_name | address_id | city |
|-----------|--------------|-----------|------|
| 1 | Linda Hernandez | 1 | Indore |
| 1 | Linda Hernandez | 2 | Bhopal |
| 1 | Linda Hernandez | 3 | Pune |
| 2 | Puja Tomar | 4 | Jaipur |
| 3 | Mark Rivera | `NULL` | `NULL` |

Mark Rivera is kept this time — with `NULL`s on the address side.

Real rows from the notebook:

| student_id | student_name | street | city | a.student_id |
|------------|--------------|--------|------|--------------|
| 43 | Barbara Long | `NULL` | `NULL` | `NULL` |
| 19 | Dennis Davis | `NULL` | `NULL` | `NULL` |
| 12 | Aman Yilmaz | 77 Banjara Hills | Hyderabad | 12 |
| 101 | Sharon Alvarez | 60 Vijay Nagar | Indore | 101 |

Why 106? **14** matched rows (for the 9 students with addresses) + **92** students with no address, each appearing once = 106.

> Notice the notebook output came back sorted by **age** (the `NULL`-age students first, William Parker with age 102 last), not by `student_id`. Most likely MySQL read `students` through `idx_search_name`, which already contains every `s.` column the query needs and is sorted by `student_age`. Without `ORDER BY`, row order is whatever is cheapest — add `ORDER BY s.student_id` if you need it.

> Add `WHERE a.address_id IS NULL` to turn this into "students who have **no** address on file" (92 rows).

**Common mistake:** filtering the right table in `WHERE`, e.g. `WHERE a.city = 'Pune'`, throws away the `NULL` rows and quietly turns the `LEFT JOIN` back into an `INNER JOIN`. Put such conditions in the `ON` clause instead if you want to keep every student.

## 15. RIGHT JOIN — every address

```sql
SELECT s.student_id, s.student_name, s.student_age, s.student_email,
       a.street, a.city, a.student_id
FROM students AS s
RIGHT JOIN addresses AS a
ON s.student_id = a.student_id;   -- 14 rows
```

`RIGHT JOIN` is the mirror image: keep **every row of the right table** (`addresses`). If an address had no matching student, the `s.` columns would be `NULL`:

| s.student_id | student_name | street | city | a.student_id |
|-----------|--------------|--------|------|------|
| 1 | Linda Hernandez | 12 MG Road | Indore | 1 |
| … | … | … | … | … |
| `NULL` | `NULL` | *(an orphan address)* | … | 999 |

The result equals the `INNER JOIN` here (same 14 rows, starting with Linda's three addresses), because the foreign key guarantees that every address belongs to a real student — there's nothing unmatched on the right side, so the `NULL` row above can never actually happen.

> `A RIGHT JOIN B` gives the same rows as `B LEFT JOIN A`. Most people write `LEFT JOIN` and just swap the table order.

## 16. FULL OUTER JOIN with UNION

```sql
SELECT s.student_id, s.student_name, s.student_age, s.student_email,
       a.street, a.city, a.student_id
FROM students AS s
LEFT JOIN addresses AS a
ON s.student_id = a.student_id
UNION
SELECT s.student_id, s.student_name, s.student_age, s.student_email,
       a.street, a.city, a.student_id
FROM students AS s
RIGHT JOIN addresses AS a
ON s.student_id = a.student_id;
-- 106 rows
```

MySQL has **no `FULL OUTER JOIN`**. The standard workaround is `LEFT JOIN` ∪ `RIGHT JOIN`: everything from both sides, matched where possible, `NULL` where not.

**How it's evaluated:**

1. Run the `LEFT JOIN` → 106 rows (14 matched + 92 students without address).
2. Run the `RIGHT JOIN` → 14 rows (the same 14 matched rows).
3. `UNION` stacks them (120 rows) and removes exact duplicates → 106.

| Part | Rows |
|------|------|
| `LEFT JOIN` half | 106 |
| `RIGHT JOIN` half | 14 |
| stacked (`UNION ALL`) | 120 |
| after removing duplicates (`UNION`) | **106** |

- `UNION` stacks the two result sets and **removes duplicate rows** — the 14 matched rows appear in both halves but are kept once
- `UNION ALL` would keep the duplicates (106 + 14 = 120 rows)
- Both `SELECT`s must return the same number of columns in the same order — otherwise `Error 1222: The used SELECT statements have a different number of columns`
- The column headings come from the **first** `SELECT`

Result: 106 rows — the same as the `LEFT JOIN`, again because no address is orphaned.

> **Gotcha:** `UNION` compares whole rows. If a student legitimately had two identical-looking rows (same street and city twice), `UNION` would merge them. Henry Rodriguez's two Pune addresses survive only because their streets differ.

## 17. CROSS JOIN — every combination

```sql
SELECT * FROM students CROSS JOIN addresses;   -- 101 × 14 = 1414 rows (notebook showed 1000)
SELECT COUNT(*) FROM students;                 -- 101
```

`CROSS JOIN` has **no `ON` condition** — it pairs every student with every address (the *Cartesian product*).

Tiny illustration — 2 students × 3 addresses = 6 rows:

| student_name | city |
|--------------|------|
| Linda | Indore |
| Linda | Bhopal |
| Linda | Pune |
| Puja | Indore |
| Puja | Bhopal |
| Puja | Pune |

In the real output, Linda Hernandez is paired with Sharon Alvarez's Indore address (address 14), Melissa Cox's Bengaluru address (address 13), Henry's Magarpatta City office (address 12) and so on — combinations that mean nothing.

The true result is 101 × 14 = **1414** rows; the notebook stopped displaying at **1000** (`hasMoreRows` was true) because MySQL Shell caps result sets by default. `SELECT COUNT(*) FROM students` was run to confirm the 101 in that multiplication:

| COUNT(*) |
|----------|
| 101 |

- `COUNT(*)` counts rows, including rows with `NULL`s.
- To count the cross join itself, wrap it: `SELECT COUNT(*) FROM students CROSS JOIN addresses;` → 1414.

A cross join is rarely what you want — forgetting the `ON` clause on a big join produces one by accident (1 000 students × 1 000 addresses = 1 000 000 rows).

> **Where it *is* useful:** generating every combination on purpose, e.g. every student × every subject to build a blank marks sheet.

---

## JOIN types at a glance

| Join | Keeps | Rows here |
|------|-------|-----------|
| `INNER JOIN` | only matching pairs | 14 |
| `LEFT JOIN` | all students + matching addresses | 106 |
| `RIGHT JOIN` | all addresses + matching students | 14 |
| `LEFT ... UNION ... RIGHT` | everything from both sides (full outer) | 106 |
| `CROSS JOIN` | every student × every address | 1414 |

---

## Commands Summary

| Command | What it does |
|---|---|
| `USE db` | Make `db` the current database |
| `SHOW DATABASES` | List every database on the server |
| `SHOW TABLES` | List tables and views together |
| `SHOW FULL TABLES` | List tables and views with a `Table_type` column |
| `SHOW FULL TABLES WHERE Table_type = 'VIEW'` | List only the views |
| `EXPLAIN table_or_view` | Same as `DESC` — show the columns |
| `CREATE VIEW name AS (SELECT ...)` | Save a query (with filters / subqueries) as a virtual table |
| `DROP VIEW name` | Remove a view — the underlying data is untouched |
| `ORDER BY a DESC, b ASC` | Sort by `a` (Z→A), break ties by `b` (A→Z) |
| `EXPLAIN SELECT ...` | Show the plan: scan type, usable keys, estimated rows |
| `EXPLAIN ANALYZE SELECT ...` | Run the query and show real timings and row counts |
| `CREATE UNIQUE INDEX idx ON t (a, b, c)` | Composite index that also forbids duplicate combinations |
| `SHOW INDEX FROM t` | List a table's indexes, columns and cardinality |
| `ENUM('A', 'B', ...)` | Column restricted to a fixed list of values |
| `ALTER TABLE t MODIFY col ...` | Change a column's definition |
| `ADD CONSTRAINT name FOREIGN KEY (col) REFERENCES t(col)` | Every value must exist in the parent table |
| `ON DELETE CASCADE` | Deleting the parent row deletes its child rows |
| `DESC t` | Show a table's columns, types, nulls and keys |
| `INSERT INTO t (cols) VALUES (...), (...)` | Insert many rows in one statement |
| `t1 AS a` | Give a table a short alias |
| `INNER JOIN ... ON` | Rows that match in both tables |
| `LEFT JOIN ... ON` | All left rows, `NULL` where the right has no match |
| `RIGHT JOIN ... ON` | All right rows, `NULL` where the left has no match |
| `... UNION ...` | Stack two result sets, removing duplicates (`UNION ALL` keeps them) |
| `CROSS JOIN` | Every row of one table paired with every row of the other |
| `COUNT(*)` | Count the rows in a result |
