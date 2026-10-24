# MySQL Lecture 5 — IFNULL & Common Table Expressions (CTE)

In this lecture we went back to the `students` ⋈ `addresses` **INNER JOIN** from Lecture 4, picked only the columns we needed, replaced missing genders with a friendly label using **`IFNULL`**, and then saved the join under a temporary name with a **Common Table Expression** (`WITH ... AS`) so we could filter it like a normal table.

## What this lecture covers

| Family | Commands practiced |
|--------|--------------------|
| Navigation | `SHOW DATABASES`, `USE`, `SHOW TABLES` |
| Joins | `INNER JOIN ... ON`, picking columns with `table.column` |
| NULL handling | `IFNULL(column, 'replacement')`, column alias with `AS` |
| CTEs | `WITH name AS ( SELECT ... ) SELECT ... FROM name` |
| Filtering | `WHERE` with several `OR` conditions |

**Tool used:** VS Code + SQL Notebook extension (run one cell at a time with `Shift+Enter`)

> **Prerequisite:** the `pal_india` database with the 101-row `students` table (Lectures 1–3) and the 14-row `addresses` table with its foreign key (Lecture 4).

### The two tables (quick reminder)

`students` — 10 columns, one sample row:

| student_id | student_name | student_age | student_address | student_email | student_gender | student_contact | student_is_active | createdAt | updateAt |
|---|---|---|---|---|---|---|---|---|---|
| 1 | Linda Hernandez | 20 | 8945 Maple Dr, Houston, TX 87397 | linda.patel1@hotmail.com | `NULL` | +1-438-717-1434 | 1 | … | … |

`addresses` — 9 columns, one sample row:

| address_id | student_id | address_type | street | city | state | pincode | createdAt | updateAt |
|---|---|---|---|---|---|---|---|---|
| 1 | 1 | Home | 12 MG Road | Indore | Madhya Pradesh | 452001 | … | … |

The 14 addresses belong to **9 students** — ids 1, 2, 5, 7, 10, 12, 22, 44 and 101. Every query in this lecture only ever shows those 9 students, because they all use `INNER JOIN`.

---

## 1. Looking around

```sql
SHOW DATABASES;   -- information_schema, mysql, pal_india, performance_schema, sakila, sys, world
USE pal_india;    -- make pal_india the current database
SHOW TABLES;      -- addresses, select_students, student_search, students
```

**Step by step:**

- `SHOW DATABASES` — lists every database on the server; `pal_india` is ours.
- `USE pal_india` — after this, `students` means `pal_india.students`. It returns no rows, it only changes your session.
- `SHOW TABLES` — lists tables **and** views of `pal_india` in one list. After Lecture 4 you should see the two real tables (`addresses`, `students`) and the two views (`select_students`, `student_search`).

**Common mistake:** skipping `USE` → `Error 1046: No database selected` on the next query.

## 2. INNER JOIN recap

```sql
SELECT * FROM students
INNER JOIN addresses ON students.student_id = addresses.student_id;
-- 14 rows, 19 columns
```

This is exactly the join from Lecture 4, run again as a warm-up.

**How MySQL evaluates it:**

1. `FROM students INNER JOIN addresses` — look at every (student, address) pair.
2. `ON students.student_id = addresses.student_id` — keep a pair only when the ids are equal.
3. `SELECT *` — output **all** columns of both tables: 10 from `students` + 9 from `addresses` = **19 columns**.

Result: **14 rows** — one per address. Linda Hernandez (id 1) appears 3 times, Puja Tomar, Rohan Gomez and Henry Rodriguez twice each, the rest once. The 92 students without an address don't appear at all.

> `SELECT *` on a join is messy: `student_id`, `createdAt` and `updateAt` each appear **twice** (once from each table). That's why the next query picks its columns by hand.

## 3. Picking columns + IFNULL

```sql
SELECT students.student_id, students.student_name, students.student_age,
       addresses.city, addresses.state, addresses.student_id,
       IFNULL(students.student_gender, "NOT SELECTED") AS student_gender
FROM students
INNER JOIN addresses ON students.student_id = addresses.student_id;
-- 14 rows, 7 columns
```

**Clause by clause:**

| Piece | What it does |
|-------|--------------|
| `students.student_id`, `students.student_name`, … | take these columns from `students` |
| `addresses.city`, `addresses.state`, `addresses.student_id` | take these columns from `addresses` |
| `IFNULL(students.student_gender, "NOT SELECTED")` | if the gender is `NULL`, show `NOT SELECTED` instead; otherwise show the real gender |
| `AS student_gender` | name the computed column `student_gender` |
| `INNER JOIN ... ON ...` | the same join as section 2 |

### How IFNULL works

`IFNULL(value, fallback)` takes two arguments:

- if `value` is **not** `NULL` → return `value`
- if `value` **is** `NULL` → return `fallback`

| student_gender (stored) | `IFNULL(student_gender, "NOT SELECTED")` |
|-------------------------|------------------------------------------|
| `'Male'` | `Male` |
| `'Female'` | `Female` |
| `NULL` | `NOT SELECTED` |

Result (all 14 rows):

| student_id | student_name | student_age | city | state | student_id | student_gender |
|-----------|--------------|-------------|------|-------|-----------|----------------|
| 1 | Linda Hernandez | 20 | Indore | Madhya Pradesh | 1 | **NOT SELECTED** |
| 1 | Linda Hernandez | 20 | Bhopal | Madhya Pradesh | 1 | **NOT SELECTED** |
| 1 | Linda Hernandez | 20 | Pune | Maharashtra | 1 | **NOT SELECTED** |
| 2 | Puja Tomar | 26 | Jaipur | Rajasthan | 2 | Female |
| 2 | Puja Tomar | 26 | Ajmer | Rajasthan | 2 | Female |
| 5 | Frank Hughes | 27 | Kolkata | West Bengal | 5 | Male |
| 7 | Rohan Gomez | 27 | Noida | Uttar Pradesh | 7 | Male |
| 7 | Rohan Gomez | 27 | Delhi | Delhi | 7 | Male |
| 10 | James Castillo | 21 | Chennai | Tamil Nadu | 10 | Male |
| 12 | Aman Yilmaz | 29 | Hyderabad | Telangana | 12 | Male |
| 22 | Henry Rodriguez | 22 | Pune | Maharashtra | 22 | Male |
| 22 | Henry Rodriguez | 22 | Pune | Maharashtra | 22 | Male |
| 44 | Melissa Cox | 28 | Bengaluru | Karnataka | 44 | Female |
| 101 | Sharon Alvarez | 16 | Indore | Madhya Pradesh | 101 | Male |

Linda Hernandez was inserted in Lecture 1 with gender `NULL`, so her three rows show `NOT SELECTED`. Henry's two rows look identical here only because `street` isn't in the column list (`5 FC Road` vs `Magarpatta City`).

**Things to notice:**

- `IFNULL` only changes **what is displayed**. The table still stores `NULL` — run `SELECT student_gender FROM students WHERE student_id = 1;` and you'll still get `NULL`.
- Without `AS student_gender` the column heading would be the whole expression: `IFNULL(students.student_gender,"NOT SELECTED")`.
- `student_id` is listed **twice** (`students.student_id` and `addresses.student_id`), so the result has two columns with the same heading. They always hold the same value in an `INNER JOIN` — the `ON` condition guarantees it.
- The `table.column` prefix is required for `student_id` (it exists in both tables). For columns that exist in only one table (`city`, `student_name`) it's optional, but it makes the query easier to read. In Lecture 4 we shortened this with aliases (`students AS s` → `s.student_id`).

> **IFNULL vs COALESCE:** `COALESCE(a, b, c, ...)` returns the first non-`NULL` value from **any number** of arguments, and it's standard SQL (works in PostgreSQL, SQL Server…). `IFNULL` is MySQL's two-argument shortcut. `IFNULL(x, 'N/A')` and `COALESCE(x, 'N/A')` give the same result.

**Common mistakes**

- `IFNULL(student_gender)` with only one argument → `Error 1582: Incorrect parameter count`.
- Trying `WHERE student_gender = NULL` to find missing genders → always 0 rows, because `NULL = NULL` is not true. Use `WHERE student_gender IS NULL`.

> **Try it yourself:** replace `IFNULL` with `COALESCE(students.student_gender, "NOT SELECTED")` and check that the output is identical. Then show missing ages too: `IFNULL(students.student_age, 0) AS student_age`.

## 4. IFNULL without a join

```sql
SELECT students.student_id, students.student_name, students.student_age,
       IFNULL(students.student_gender, "NOT SELECTED") AS student_gender
FROM students
-- 101 rows, 4 columns
```

The same `IFNULL`, this time on **all 101 students** — no join, so students without an address are included too.

| student_id | student_name | student_age | student_gender |
|-----------|--------------|-------------|----------------|
| 1 | Linda Hernandez | 20 | NOT SELECTED |
| 2 | Puja Tomar | 26 | Female |
| 3 | Mark Rivera | 26 | Male |
| … | … | … | … |

In the Lecture 1 sample data, **5 students** were inserted with a `NULL` gender (ids 1, 40, 48, 67 and 69) — all five now show `NOT SELECTED`.

- The `students.` prefix isn't needed here (there's only one table), but it doesn't hurt.

> **Gotcha — missing semicolon:** this statement has no `;` at the end. It works in SQL Notebook because the blank line after it starts a new cell, and each cell runs on its own. If you paste this query and the next one into the MySQL command line, MySQL reads them as one statement — `... FROM students WITH studentData AS(...` — and fails with a syntax error. Always end statements with `;`.

> **Try it yourself:** count the students with no gender: `SELECT COUNT(*) FROM students WHERE student_gender IS NULL;` (should be 5).

## 5. Common Table Expressions (CTE)

```sql
WITH studentData AS (
    SELECT students.student_id, students.student_name, students.student_gender, students.student_age,
           addresses.city, addresses.state
    FROM students
    INNER JOIN addresses ON students.student_id = addresses.student_id
)
SELECT * FROM studentData
WHERE student_gender = "FEMALE" OR city = "MAHARASHATRA" OR state = "PUNE";
-- 3 rows
```

A **CTE** gives a name to a query result so the rest of the statement can use it like a table. Read it as: *"let `studentData` be the result of this join — now select from `studentData`"*.

**Structure:**

```
WITH  studentData  AS  ( ...any SELECT... )     ← 1. define the temporary named result
SELECT * FROM studentData WHERE ...;            ← 2. the main query that uses it
```

**How MySQL evaluates it:**

1. **Inside the brackets** — run the join and keep 6 columns: `student_id`, `student_name`, `student_gender`, `student_age`, `city`, `state`. That's 14 rows (the same 14 as section 3, without `IFNULL` this time).
2. **Name it** — that result is called `studentData` for the rest of **this one statement**.
3. **Main query** — `SELECT * FROM studentData` reads it like a table. Because `studentData` has only one `student_id` column, there's no ambiguity and no need for `students.` / `addresses.` prefixes in the `WHERE`.
4. **`WHERE ... OR ... OR ...`** — keep a row if **at least one** of the three conditions is true.

Let's check each condition:

| Condition | Matches | Why |
|-----------|---------|-----|
| `student_gender = "FEMALE"` | Puja Tomar (2 rows), Melissa Cox (1 row) | text comparison is case-insensitive, so `'Female'` = `"FEMALE"` |
| `city = "MAHARASHATRA"` | nothing | Maharashtra is a **state**, not a city — and it's misspelled |
| `state = "PUNE"` | nothing | Pune is a **city**, not a state |

Result:

| student_id | student_name | student_gender | student_age | city | state |
|-----------|--------------|----------------|-------------|------|-------|
| 2 | Puja Tomar | Female | 26 | Jaipur | Rajasthan |
| 2 | Puja Tomar | Female | 26 | Ajmer | Rajasthan |
| 44 | Melissa Cox | Female | 28 | Bengaluru | Karnataka |

- Linda Hernandez is **not** in the result even though she has a Pune address: her gender is `NULL`, and `NULL = "FEMALE"` is not true; the city and state conditions point at the wrong columns, so they can't match her either.
- Inside the CTE we did **not** use `IFNULL`, so `student_gender` is still `NULL` for Linda. `WHERE student_gender = "NOT SELECTED"` would return 0 rows — the label only exists where `IFNULL` is applied.

### Fixing the filter

Swap city and state (and fix the spelling) to get what the query was meant to find — female students **or** anyone with an address in Pune / Maharashtra:

```sql
WITH studentData AS (
    SELECT students.student_id, students.student_name, students.student_gender, students.student_age,
           addresses.city, addresses.state
    FROM students
    INNER JOIN addresses ON students.student_id = addresses.student_id
)
SELECT * FROM studentData
WHERE student_gender = 'Female' OR city = 'Pune' OR state = 'Maharashtra';
-- 6 rows
```

| student_id | student_name | student_gender | student_age | city | state |
|-----------|--------------|----------------|-------------|------|-------|
| 1 | Linda Hernandez | `NULL` | 20 | Pune | Maharashtra |
| 2 | Puja Tomar | Female | 26 | Jaipur | Rajasthan |
| 2 | Puja Tomar | Female | 26 | Ajmer | Rajasthan |
| 22 | Henry Rodriguez | Male | 22 | Pune | Maharashtra |
| 22 | Henry Rodriguez | Male | 22 | Pune | Maharashtra |
| 44 | Melissa Cox | Female | 28 | Bengaluru | Karnataka |

The 3 female rows + Linda's office in Pune + Henry's two Pune addresses = **6 rows**.

### Why use a CTE?

The same result could be written with a subquery in `FROM`:

```sql
SELECT * FROM (
    SELECT students.student_id, students.student_name, students.student_gender, students.student_age,
           addresses.city, addresses.state
    FROM students
    INNER JOIN addresses ON students.student_id = addresses.student_id
) AS studentData
WHERE student_gender = 'Female';
```

The CTE version is easier to read: the "helper" query is named at the top, and the main query underneath stays short. With bigger queries you can define several CTEs and even use one inside the next:

```sql
WITH
  studentData AS ( SELECT ... ),
  femaleStudents AS ( SELECT * FROM studentData WHERE student_gender = 'Female' )
SELECT * FROM femaleStudents;
```

### CTE vs view (Lecture 4)

| | CTE (`WITH ... AS`) | View (`CREATE VIEW ... AS`) |
|---|---|---|
| Lifetime | only for the **one statement** it's written in | saved in the database until `DROP VIEW` |
| Shows up in `SHOW TABLES` | no | yes |
| Reusable from other queries | no — copy the `WITH` block | yes — `SELECT * FROM view_name` |
| Good for | breaking one long query into readable steps | a query many people / queries use often |

Running `SELECT * FROM studentData;` on its own, after the statement has finished, fails with `Error 1146: Table 'pal_india.studentData' doesn't exist` — the name is gone.

**Common mistakes**

- Ending the CTE before the main query: `WITH x AS (...);` then `SELECT * FROM x;` → the `;` ends the statement and `x` no longer exists. The `WITH` block and its `SELECT` must be **one** statement.
- A comma after the last CTE: `WITH a AS (...), SELECT ...` → syntax error. Commas go **between** CTEs only.
- CTEs need **MySQL 8.0 or newer**. On MySQL 5.7 the `WITH` keyword gives a syntax error.

> **Strings in quotes:** the lecture uses double quotes (`"FEMALE"`). MySQL accepts them for text by default, but single quotes (`'Female'`) are the SQL standard and work in every database — prefer them.

> **Try it yourself:**
> 1. Change the CTE to use `IFNULL(students.student_gender, 'NOT SELECTED') AS student_gender`, then filter with `WHERE student_gender = 'NOT SELECTED'` — you should get Linda's 3 rows.
> 2. Write a CTE that returns only students older than 25 who have a `Home` address (hint: add `addresses.address_type` to the CTE's columns).

---

## Commands Summary

| Command | What it does |
|---|---|
| `SHOW DATABASES` | List every database on the server |
| `USE db` | Make `db` the current database |
| `SHOW TABLES` | List tables and views together |
| `t1 INNER JOIN t2 ON t1.col = t2.col` | Rows that match in both tables |
| `table.column` | Pick a column from a specific table (required when the name exists in both) |
| `IFNULL(col, 'value')` | Show `'value'` when `col` is `NULL`, otherwise the real value |
| `COALESCE(a, b, ...)` | First non-`NULL` value from the list (standard SQL) |
| `expression AS name` | Give a column (or computed expression) a heading |
| `WITH name AS (SELECT ...) SELECT ... FROM name` | Common Table Expression — a named result usable only inside this statement |
| `WHERE a OR b OR c` | Keep the row if at least one condition is true |
| `col IS NULL` | The correct way to test for `NULL` (`= NULL` never matches) |
