# MySQL Lecture 4 — Views, EXPLAIN, Indexes, Foreign Keys & JOINs

In this lecture we managed **views** (listing, creating, dropping), looked inside queries with `EXPLAIN` and `EXPLAIN ANALYZE`, added a composite `UNIQUE INDEX`, built a second table — `addresses` — linked to `students` with a **foreign key**, and then combined the two tables with every kind of **JOIN**: `INNER`, `LEFT`, `RIGHT`, a full-outer emulation with `UNION`, and `CROSS`.

## What this lecture covers

| Family | Commands practiced |
|--------|--------------------|
| Navigation | `USE`, `SHOW DATABASES`, `SHOW TABLES`, `SHOW FULL TABLES` |
| Views | `CREATE VIEW`, `DROP VIEW`, `SHOW FULL TABLES WHERE Table_type = 'VIEW'` |
| Query plans | `EXPLAIN`, `EXPLAIN ANALYZE` |
| Indexes | `CREATE UNIQUE INDEX`, `SHOW INDEX FROM` |
| DDL | `CREATE TABLE` with `ENUM`, `ALTER TABLE ... ADD CONSTRAINT ... FOREIGN KEY ... ON DELETE CASCADE` |
| DML | Multi-row `INSERT` |
| Joins | `INNER JOIN`, `LEFT JOIN`, `RIGHT JOIN`, `UNION`, `CROSS JOIN`, table aliases (`AS s`) |

**Tool used:** MySQL Shell — DB Notebook (execute a line with `Ctrl+Enter`)

> **Prerequisite:** the `pal_india` database with the 101-row `students` table and the `arbaz` view from Lecture 3.

---

## 1. Looking around

```sql
USE pal_india;
SHOW DATABASES;   -- information_schema, mysql, pal_india, performance_schema, sakila, sys
SHOW TABLES;
```

`SHOW DATABASES` lists every database on the server — `pal_india` is ours, `sakila` is MySQL's sample database, and the rest are MySQL's own system databases.

`SHOW TABLES` lists **tables and views together**, with nothing to tell them apart. That's why the next section switches to `SHOW FULL TABLES`.

## 2. Inspecting the arbaz view

```sql
SELECT * FROM arbaz;   -- 101 rows, identical to students
EXPLAIN arbaz;         -- same as DESC arbaz
```

`EXPLAIN <table>` is just another spelling of `DESC` — it shows the view's columns. Compare it with `DESC students` from Lecture 3:

| Column | In `students` | In the `arbaz` view |
|--------|---------------|---------------------|
| `student_id` | `PRI`, `auto_increment` | no key, default `0` |
| everything else | same type / nullability | same type / nullability |

A view has **no keys and no indexes of its own** — it's only a saved `SELECT`. The primary key still lives on the real table underneath.

## 3. Listing only the views

```sql
SHOW FULL TABLES WHERE Table_type = 'VIEW';   -- arbaz | VIEW
```

`SHOW FULL TABLES` adds a second column, `Table_type`, which is `BASE TABLE` for real tables and `VIEW` for views. Filtering on it lists the views only.

## 4. A view with a filter

```sql
CREATE VIEW student_search AS (
    SELECT * FROM students WHERE student_name LIKE '%linda%'
);

SHOW FULL TABLES WHERE table_type = 'VIEW';   -- arbaz, student_search
SELECT * FROM student_search;                 -- 1 row: Linda Hernandez (id 1)
```

This time the view hides a `WHERE` clause. Anyone running `SELECT * FROM student_search` gets the "Linda" search without having to know the `LIKE` pattern. Because a view re-runs its query every time, renaming another student to Linda would make them appear here automatically.

## 5. Dropping a view

```sql
DROP VIEW arbaz;
```

`DROP VIEW` removes only the saved query — **no student data is deleted**, because the view never held any.

## 6. A view built on a subquery

```sql
CREATE VIEW select_students AS (
    SELECT * FROM students WHERE student_age IN (
        SELECT student_age FROM students GROUP BY student_age HAVING COUNT(*) > 1
    )
);

SHOW FULL TABLES WHERE table_type = 'VIEW';   -- select_students, student_search
SHOW FULL TABLES;                             -- + students | BASE TABLE

SELECT * FROM select_students;                                       -- 94 rows
SELECT * FROM select_students ORDER BY student_name DESC, student_id ASC;  -- 94 rows, Zachary King → Aaron Gupta
```

The Lecture 3 subquery is now saved under a name: "students whose age is shared by at least one other student". 94 of the 101 rows qualify:

- 5 students have `NULL` age — `NULL IN (...)` is never true
- 2 students have an age nobody else has — their group's `COUNT(*)` is 1

You can query a view like any table — here it's sorted Z→A by name, with `student_id` breaking ties.

## 7. Reading a query plan with EXPLAIN

```sql
SELECT * FROM students WHERE student_age LIKE 22;           -- 5 rows: ids 22, 39, 48, 75, 89
EXPLAIN SELECT * FROM students WHERE student_age LIKE 22;
```

`EXPLAIN` in front of a query doesn't run it — it shows **how MySQL plans to run it**:

| Column | Value | Meaning |
|--------|-------|---------|
| `type` | `ALL` | full table scan — every row is read |
| `possible_keys` / `key` | `NULL` | no index could be used |
| `rows` | `101` | estimated rows to examine |
| `filtered` | `11.11` | estimated % of those rows that pass the `WHERE` |
| `Extra` | `Using where` | the filter is applied row by row |

`type = ALL` on a large table is the classic sign of a slow query that needs an index.

> `LIKE` on an `INT` column works because MySQL converts the number to text first — but that conversion is also what stops an index being used. `WHERE student_age = 22` is the proper way to write it.

## 8. Creating a composite UNIQUE INDEX

```sql
CREATE UNIQUE INDEX idx_search_name ON students (student_age, student_email, student_name);
SHOW INDEX FROM students;
```

An **index** is a sorted lookup structure (a B-tree) that lets MySQL jump to matching rows instead of scanning the whole table. `UNIQUE` additionally forbids two rows with the same combination of the three values.

`SHOW INDEX` result:

| Key_name | Seq_in_index | Column_name | Cardinality |
|----------|--------------|-------------|-------------|
| `PRIMARY` | 1 | `student_id` | 101 |
| `student_id` | 1 | `student_id` | 101 |
| `idx_search_name` | 1 | `student_age` | 17 |
| `idx_search_name` | 2 | `student_email` | 101 |
| `idx_search_name` | 3 | `student_name` | 101 |

- **Composite index** — one index covering three columns; `Seq_in_index` gives their order. It helps queries that filter on the **leftmost** column(s) (`student_age`, or `student_age` + `student_email`, …), not ones that filter on `student_name` alone.
- **Cardinality** — the estimated number of distinct values: 17 ages (16 + `NULL`) vs 101 unique emails.
- The separate `student_id` index duplicates `PRIMARY` — a leftover `UNIQUE` on the same column. It's redundant and only slows down writes.

## 9. When an index can't help — EXPLAIN ANALYZE

```sql
SELECT * FROM students WHERE student_age LIKE 22;      -- 5 rows
SELECT * FROM students WHERE student_age LIKE '%22';   -- 5 rows (same students)
EXPLAIN ANALYZE SELECT * FROM students WHERE student_age LIKE '%22';
```

`EXPLAIN ANALYZE` **actually runs** the query and reports real timings next to the estimates:

```
-> Filter: (students.student_age like '%22')  (cost=10.3 rows=11.2) (actual time=0.0718..0.158 rows=5 loops=1)
    -> Table scan on students  (cost=10.3 rows=101) (actual time=0.0419..0.119 rows=101 loops=1)
```

Read it from the inside out: a **table scan** reads all 101 rows, then the **filter** keeps 5. Even with `idx_search_name` in place, MySQL still scans because:

- a pattern starting with `%` can't use a B-tree — the index is sorted by the *start* of the value
- `LIKE` on a number forces a number → text conversion on every row

Indexes only help when the condition can be matched against the sorted values directly (`=`, `<`, `>`, `BETWEEN`, `LIKE 'abc%'`).

## 10. A second table: addresses

```sql
CREATE TABLE addresses (
    address_id   INT PRIMARY KEY AUTO_INCREMENT,
    student_id   INT NOT NULL,
    address_type ENUM("Home", "Hostel", "Office", "Permanent") NOT NULL,
    street       VARCHAR(150),
    city         VARCHAR(50) NOT NULL,
    state        VARCHAR(50),
    pincode      VARCHAR(10),
    createdAt    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updateAt     TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

One student can have **many** addresses (home, hostel, office…) — a **one-to-many** relationship. Instead of cramming them all into `students.student_address`, they get their own table, and each row records which student it belongs to via `student_id`.

- `ENUM(...)` — the column only accepts one of the listed values; `"Garage"` would be rejected
- `pincode` is `VARCHAR`, not `INT` — it's an identifier, not a number you do maths on (and it may have leading zeros)
- The two timestamp columns reuse the Lecture 3 trick from the start

## 11. Linking the tables with a FOREIGN KEY

```sql
ALTER TABLE addresses
MODIFY student_id INT NOT NULL,
ADD CONSTRAINT fk_address_student FOREIGN KEY (student_id)
REFERENCES students(student_id) ON DELETE CASCADE;
-- MySQL Error (1826): Duplicate foreign key constraint name 'fk_address_student'
```

A **foreign key** says: "every `addresses.student_id` must exist in `students.student_id`". MySQL then enforces it:

- inserting an address for student 999 (who doesn't exist) fails
- `ON DELETE CASCADE` — deleting a student automatically deletes all their addresses, so no orphan rows are left behind

The error in the notebook just means the constraint **already existed** — the statement had been run once before. Constraint names must be unique, so the second run was rejected. `DESC` confirms the key is in place:

```sql
DESC addresses;
```

| Field | Type | Null | Key | Extra |
|-------|------|------|-----|-------|
| `address_id` | `int` | NO | PRI | auto_increment |
| `student_id` | `int` | NO | **MUL** | |
| `address_type` | `enum('Home','Hostel','Office','Permanent')` | NO | | |
| `street` | `varchar(150)` | YES | | |
| `city` | `varchar(50)` | NO | | |
| `state` | `varchar(50)` | YES | | |
| `pincode` | `varchar(10)` | YES | | |
| `createdAt` | `timestamp` | YES | | DEFAULT_GENERATED |
| `updateAt` | `timestamp` | YES | | DEFAULT_GENERATED on update CURRENT_TIMESTAMP |

`MUL` (multiple) means `student_id` is indexed and **duplicates are allowed** — exactly right, since one student can have several addresses. MySQL creates this index automatically for every foreign key.

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

14 addresses spread over **9 students**: ids 1 (3 addresses), 2, 7, 22 (2 each), and 5, 10, 12, 44, 101 (1 each). `address_id`, `createdAt` and `updateAt` were filled in automatically.

## 13. INNER JOIN — only the matches

```sql
SELECT * FROM students
INNER JOIN addresses
ON students.student_id = addresses.student_id;   -- 14 rows, 19 columns
```

A **join** glues rows from two tables side by side wherever the `ON` condition is true. `INNER JOIN` keeps **only rows that match on both sides**:

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

`students AS s` and `addresses AS a` give each table a short nickname. The prefix (`s.` / `a.`) is required whenever a column name exists in both tables — plain `student_id` would be ambiguous.

> The join statements in the notebook have no trailing `;` — they work because each one was run on its own with `Ctrl+Enter`. Add the semicolon when running several statements together.

## 14. LEFT JOIN — every student, address or not

```sql
SELECT s.student_id, s.student_name, s.student_age, s.student_email,
       a.street, a.city, a.student_id
FROM students AS s
LEFT JOIN addresses AS a
ON s.student_id = a.student_id;   -- 106 rows
```

`LEFT JOIN` keeps **every row of the left table** (`students`). Where there's no matching address, the address columns come back as `NULL`:

| student_id | student_name | street | city | a.student_id |
|------------|--------------|--------|------|--------------|
| 43 | Barbara Long | `NULL` | `NULL` | `NULL` |
| 19 | Dennis Davis | `NULL` | `NULL` | `NULL` |
| 101 | Sharon Alvarez | 60 Vijay Nagar | Indore | 101 |

Why 106? **14** matched rows (for the 9 students with addresses) + **92** students with no address, each appearing once = 106.

> Add `WHERE a.address_id IS NULL` to turn this into "students who have **no** address on file".

## 15. RIGHT JOIN — every address

```sql
SELECT s.student_id, s.student_name, s.student_age, s.student_email,
       a.street, a.city, a.student_id
FROM students AS s
RIGHT JOIN addresses AS a
ON s.student_id = a.student_id;   -- 14 rows
```

`RIGHT JOIN` is the mirror image: keep **every row of the right table** (`addresses`). The result equals the `INNER JOIN` here, because the foreign key guarantees that every address belongs to a real student — there's nothing unmatched on the right side.

## 16. FULL OUTER JOIN with UNION

```sql
SELECT ... FROM students AS s LEFT JOIN  addresses AS a ON s.student_id = a.student_id
UNION
SELECT ... FROM students AS s RIGHT JOIN addresses AS a ON s.student_id = a.student_id;
-- 106 rows
```

MySQL has **no `FULL OUTER JOIN`**. The standard workaround is `LEFT JOIN` ∪ `RIGHT JOIN`: everything from both sides, matched where possible, `NULL` where not.

- `UNION` stacks the two result sets and **removes duplicate rows** — the 14 matched rows appear in both halves but are kept once
- `UNION ALL` would keep the duplicates (106 + 14 = 120 rows)
- Both `SELECT`s must return the same number of columns in the same order

Result: 106 rows — the same as the `LEFT JOIN`, again because no address is orphaned.

## 17. CROSS JOIN — every combination

```sql
SELECT * FROM students CROSS JOIN addresses;   -- 101 × 14 = 1414 rows (notebook showed 1000)
SELECT COUNT(*) FROM students;                 -- 101
```

`CROSS JOIN` has **no `ON` condition** — it pairs every student with every address (the *Cartesian product*). Linda Hernandez is paired with Sharon Alvarez's Indore address, a Bengaluru address, and so on — combinations that mean nothing.

The true result is 101 × 14 = **1414** rows; the notebook stopped displaying at **1000** because MySQL Shell caps result sets by default. A cross join is rarely what you want — forgetting the `ON` clause on a big join produces one by accident.

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
| `SHOW DATABASES` | List every database on the server |
| `SHOW FULL TABLES` | List tables and views with a `Table_type` column |
| `SHOW FULL TABLES WHERE Table_type = 'VIEW'` | List only the views |
| `EXPLAIN table_or_view` | Same as `DESC` — show the columns |
| `CREATE VIEW name AS (SELECT ...)` | Save a query (with filters / subqueries) as a virtual table |
| `DROP VIEW name` | Remove a view — the underlying data is untouched |
| `EXPLAIN SELECT ...` | Show the plan: scan type, usable keys, estimated rows |
| `EXPLAIN ANALYZE SELECT ...` | Run the query and show real timings and row counts |
| `CREATE UNIQUE INDEX idx ON t (a, b, c)` | Composite index that also forbids duplicate combinations |
| `SHOW INDEX FROM t` | List a table's indexes, columns and cardinality |
| `ENUM('A', 'B', ...)` | Column restricted to a fixed list of values |
| `FOREIGN KEY (col) REFERENCES t(col)` | Every value must exist in the parent table |
| `ON DELETE CASCADE` | Deleting the parent row deletes its child rows |
| `t1 AS a` | Give a table a short alias |
| `INNER JOIN ... ON` | Rows that match in both tables |
| `LEFT JOIN ... ON` | All left rows, `NULL` where the right has no match |
| `RIGHT JOIN ... ON` | All right rows, `NULL` where the left has no match |
| `... UNION ...` | Stack two result sets, removing duplicates (`UNION ALL` keeps them) |
| `CROSS JOIN` | Every row of one table paired with every row of the other |
