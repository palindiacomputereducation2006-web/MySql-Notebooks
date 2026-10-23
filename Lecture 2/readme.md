# MySQL Lecture 2 — Pagination, Sorting, Aliases & LIKE

In this lecture we reconnected to the `pal_india` database, paged through the `students` table with `LIMIT` / `OFFSET`, sorted on more than one column, renamed columns and tables in the output with aliases (`AS`), and searched names with `LIKE` wildcards.

## What this lecture covers

| Family | Commands practiced |
|--------|--------------------|
| Navigation | `SHOW DATABASES`, `USE`, `SHOW TABLES` |
| Common mistake | `SELECT * FROM <database>` (database name used as a table) |
| Pagination | `LIMIT n OFFSET m` |
| Sorting | `ORDER BY col1 ASC, col2 DESC` (multi-column), NULL ordering |
| Aliases | `SELECT col AS alias`, `FROM table AS alias` |
| Pattern matching | `WHERE col LIKE "pattern"` with the `%` wildcard, combined with `ORDER BY` |

**Tool used:** MySQL Shell — DB Notebook (execute a line with `Ctrl+Enter`)

> **Prerequisite:** the `pal_india` database with the `students` table holding 100 sample rows (ids 1–100).

### The `students` table at a glance

These are the columns every `SELECT *` in this lecture returns:

| Column | Type (what it holds) | Can be NULL? |
|--------|----------------------|--------------|
| `student_id` | integer, primary key, auto-increment | No |
| `student_name` | text | No |
| `student_age` | integer | **Yes** (6 students have no age) |
| `student_address` | text | Yes |
| `student_email` | text | No |
| `student_gender` | text | Yes |
| `student_contact` | text | Yes |
| `student_is_active` | 1 / 0 flag (default `1`) | Yes |

---

## 1. Reconnecting to the database

```sql
SHOW DATABASES;   -- lists every database on the server (12 in our session, including pal_india)
USE pal_india;    -- make pal_india the "current" database for this session
SHOW TABLES;      -- lists the tables inside the current database → students
```

What each command does:

- **`SHOW DATABASES`** — asks the server for the list of all databases you are allowed to see. In our session it returned **12 rows**: `arbaz`, `collections`, `ecommerce`, `information_schema`, `maintainance`, `maqbool`, `mysql`, `pal_india`, `performance_schema`, `products`, `student_portal`, `sys`. Your list will be different, it depends on what exists on your machine.
- **`USE pal_india`** — does not return any rows (the notebook shows `OK, 0 records retrieved`). It just tells MySQL "from now on, when I write a table name without a database, look inside `pal_india`".
- **`SHOW TABLES`** — returns one column named `Tables_in_pal_india`. Here it has a single row: `students`.

| Tables_in_pal_india |
|---------------------|
| students |

Every new notebook session starts with no database selected. Run `USE` first, or queries fail with `No database selected`.

> **System databases:** `information_schema`, `mysql`, `performance_schema` and `sys` come with MySQL itself. They store server settings and metadata. Look, but don't change anything in them.

**Try it yourself:** run `SELECT DATABASE();` — it shows which database is currently selected (`NULL` if you haven't run `USE` yet).

## 2. A common mistake — database name in FROM

```sql
SELECT * FROM pal_india;   -- ❌ Table 'pal_india.pal_india' doesn't exist
```

Why this fails, step by step:

1. `FROM` always expects a **table** name.
2. Because we ran `USE pal_india`, MySQL looks for a table called `pal_india` **inside** the `pal_india` database, i.e. `pal_india.pal_india`.
3. There is no such table (the only table is `students`), so MySQL stops with error 1146: *Table 'pal_india.pal_india' doesn't exist*.

`pal_india` is the **database**, not a table. Think of it like this: a database is a folder, a table is a file inside the folder. `FROM` needs a **table** name:

```sql
SELECT * FROM students;             -- ✅ table in the current database
SELECT * FROM pal_india.students;   -- ✅ fully qualified: database.table (works without USE)
```

> **Tip:** when you're not sure what the table is called, run `SHOW TABLES;` first (we did exactly that right after this mistake in class) and copy the name from the result.

## 3. Pagination with LIMIT / OFFSET

"Pagination" means showing a big result a little at a time, like page 1, page 2, page 3 of a search result. With 100 students, we show 10 per page.

```sql
SELECT * FROM students LIMIT 10 OFFSET 0;    -- page 1  → ids 1–10
SELECT * FROM students LIMIT 10 OFFSET 10;   -- page 2  → ids 11–20
SELECT * FROM students LIMIT 10 OFFSET 20;   -- page 3  → ids 21–30
SELECT * FROM students LIMIT 10 OFFSET 90;   -- page 10 → ids 91–100 (last page)
SELECT * FROM students LIMIT 7  OFFSET 10;   -- 7 rows after skipping 10 → ids 11–17
```

- `LIMIT n` → return at most `n` rows
- `OFFSET m` → skip the first `m` rows first

How MySQL runs `SELECT * FROM students LIMIT 10 OFFSET 20`:

1. **`FROM students`** — take all 100 rows of the table.
2. **`SELECT *`** — keep every column.
3. **`OFFSET 20`** — throw away the first 20 rows (ids 1–20).
4. **`LIMIT 10`** — from what is left, hand back only the next 10 rows (ids 21–30).

For page `p` with page size `s`: **`LIMIT s OFFSET (p - 1) * s`**. With 100 rows and a page size of 10 there are 10 pages, so `OFFSET 90` is the last one.

| Page | Query | Rows returned |
|------|-------|---------------|
| 1 | `LIMIT 10 OFFSET 0` | ids 1–10 (Linda Patel … James Castillo) |
| 2 | `LIMIT 10 OFFSET 10` | ids 11–20 (Pooja Sharma … Emre Young) |
| 3 | `LIMIT 10 OFFSET 20` | ids 21–30 (Kevin Bennett … Burak Harris) |
| 10 | `LIMIT 10 OFFSET 90` | ids 91–100 (Sanjay Ramirez … Raymond Martinez) |

Sample of page 1 (first 3 of 10 rows, some columns hidden):

| student_id | student_name | student_age | student_gender |
|-----------:|--------------|------------:|----------------|
| 1 | Linda Patel | 20 | NULL |
| 2 | Pooja Turner | 26 | Female |
| 3 | Mark Rivera | 26 | Male |

### The page size doesn't have to be 10

In class we also re-ran page 1 (`LIMIT 10 OFFSET 0`) and then tried a different size:

```sql
SELECT * FROM students LIMIT 7 OFFSET 10;   -- skip 10 rows, then take 7 → 7 rows
```

Result (7 records): ids 11–17 — Pooja Sharma, Aman Yilmaz, Sharon Alvarez, Mary Martinez, Arjun Verma, Aaron Gupta, Mehmet Sahin. `LIMIT` and `OFFSET` are independent numbers, so you can mix any size with any starting point.

### Gotchas

- **Asking past the end is not an error.** `LIMIT 10 OFFSET 100` simply returns **0 rows**, and `LIMIT 10 OFFSET 95` returns only the 5 rows that are left.
- **Short form:** `LIMIT 20, 10` means the same as `LIMIT 10 OFFSET 20` — note the order is **offset first, then count**. This is easy to mix up, so the `OFFSET` keyword is clearer for beginners.
- **`LIMIT` goes at the very end** of the query, after `WHERE` and `ORDER BY`. `SELECT * FROM students LIMIT 10 ORDER BY student_name;` is a syntax error.
- `LIMIT 0` returns no rows (sometimes used just to see the column names).

> Without `ORDER BY`, the row order isn't guaranteed. It looks like id order here only because of the primary key. For stable pages in real apps, always add `ORDER BY`.

**Try it yourself:** show page 4 with 15 students per page. (Answer: `LIMIT 15 OFFSET 45` → ids 46–60.)

## 4. Sorting on multiple columns

```sql
SELECT * FROM students ORDER BY student_name ASC, student_age DESC;   -- 100 rows
SELECT * FROM students ORDER BY student_age ASC, student_id ASC;      -- 100 rows
```

- `ASC` = ascending (A → Z, small → big). It's the default, so `ORDER BY student_name` means the same as `ORDER BY student_name ASC`.
- `DESC` = descending (Z → A, big → small).
- Each column in the list gets **its own** direction. `ORDER BY a, b DESC` means "`a` ascending, `b` descending" — the `DESC` does **not** apply to `a`.

MySQL sorts by the first column. The second column only breaks ties, when two rows have the same value in the first one.

How MySQL runs `ORDER BY student_name ASC, student_age DESC`:

1. Read all 100 rows from `students`.
2. Sort them alphabetically by `student_name`.
3. Wherever two or more rows have the **same** name, sort just those rows by `student_age`, biggest first.
4. Return all 100 rows — sorting never adds or removes rows, it only changes their order.

### Example 1 — Name ASC, age DESC

The list starts `Aaron Gupta`, `Aiden Ortiz`, `Aman Yilmaz`, … and ends with `Zachary Baker`, `Zachary King`. Only one name appears twice: `William Parker`. That's where the second column matters:

| student_id | student_name | student_age |
|-----------:|--------------|------------:|
| 58 | William Parker | 26 |
| 95 | William Parker | NULL |

The one with age 26 (id 58) comes before the one with age `NULL` (id 95), because with `DESC` the `NULL` goes last.

### Example 2 — Age ASC, id ASC

The 6 students with `NULL` age come **first** (ids 17, 19, 28, 43, 81, 95). Next come the 17-year-olds in id order: 11, 14, 20, 32, 52, 71, ... The list ends with the 30-year-olds (… 64, 66, 100).

| student_id | student_name | student_age |
|-----------:|--------------|------------:|
| 17 | Mehmet Sahin | NULL |
| 19 | Dennis Davis | NULL |
| … | … | NULL |
| 95 | William Parker | NULL |
| 11 | Pooja Sharma | 17 |
| 14 | Mary Martinez | 17 |
| 20 | Emre Young | 17 |
| … | … | … |

Many students share the same age (for example, 13 students are 24), so here the tie-breaker `student_id ASC` is used a lot. It keeps each age group in a predictable order.

> **NULL ordering:** MySQL treats `NULL` as smaller than any value, so NULLs come first with `ASC` and last with `DESC`.

### Gotchas

- Order of the columns matters: `ORDER BY student_age, student_name` and `ORDER BY student_name, student_age` give very different results.
- Text is sorted alphabetically, **not** by length, and (with the default collation) without caring about upper/lower case.
- If you want NULL ages at the bottom while still sorting ascending, use: `ORDER BY student_age IS NULL, student_age ASC` (`IS NULL` is 0 for real ages and 1 for NULLs, so NULLs move to the end).

**Try it yourself:** list the oldest students first, and inside the same age, alphabetically by name:
`SELECT * FROM students ORDER BY student_age DESC, student_name ASC;`

**Combine with pagination:** `SELECT * FROM students ORDER BY student_name LIMIT 10 OFFSET 0;` gives the first 10 students alphabetically — this is how real apps build stable pages.

## 5. Aliases (AS)

An alias is a **nickname** you give to a column or a table for the duration of one query.

### Table alias
```sql
SELECT * FROM students AS student_details;   -- 100 rows, same as SELECT * FROM students
SHOW TABLES;                                  -- still just: students
```

- `students AS student_details` tells MySQL "inside this query, I'll call the `students` table `student_details`".
- The result is exactly the same 100 rows and the same column headers as `SELECT * FROM students`.
- We ran `SHOW TABLES` right after to prove the point: the list still shows only `students`.

A table alias is a temporary name that only exists inside that one query. It does **not** rename the table (use `RENAME TABLE` for that). Aliases become really useful later, with joins.

You can use the alias to qualify column names in the same query:

```sql
SELECT sd.student_id, sd.student_name FROM students AS sd;   -- sd is a short alias
```

> **Gotcha:** once you give a table an alias, use the alias in that query. In MySQL, `SELECT students.student_name FROM students AS sd;` fails with *Unknown column 'students.student_name'*.

### Column alias
```sql
SELECT student_id AS id, student_name AS name FROM students;   -- 100 rows, 2 columns
```

Step by step:

1. `FROM students` — read all 100 rows.
2. `SELECT student_id, student_name` — keep only these two columns (not `*`).
3. `AS id`, `AS name` — change the **header** of each column in the result.

The result headers show `id` and `name` instead of the real column names. The table itself isn't changed.

| id | name |
|---:|------|
| 1 | Linda Patel |
| 2 | Pooja Turner |
| 3 | Mark Rivera |
| … | … |

### Gotchas

- `AS` is optional: `SELECT student_id id FROM students;` works too, but writing `AS` is clearer.
- If the alias has a space, put it in quotes or backticks: ``SELECT student_name AS `Student Name` FROM students;``
- A column alias can be used in `ORDER BY` (`... ORDER BY name`), but **not** in `WHERE` — `WHERE name LIKE "A%"` fails with *Unknown column 'name'*, because `WHERE` is checked before the `SELECT` list (and its aliases) is built.

**Try it yourself:** `SELECT student_name AS name, student_age AS age FROM students ORDER BY age DESC LIMIT 5;`

## 6. Pattern matching with LIKE

```sql
SELECT * FROM students WHERE student_name LIKE "%Z" ORDER BY student_name DESC;   -- 18 rows
```

How MySQL runs this query:

1. **`FROM students`** — start with all 100 rows.
2. **`WHERE student_name LIKE "%Z"`** — check every name against the pattern; keep only the names that end in `z`/`Z`. 18 rows survive.
3. **`SELECT *`** — keep all columns of those 18 rows.
4. **`ORDER BY student_name DESC`** — sort the 18 rows from Z to A.

- `%` matches **any number of characters** (including none)
- `"%Z"` means "ends with Z", so it finds names like `Sharon Alvarez`, `Scott Ruiz` and `Rohan Gomez`
- The match is **case-insensitive** with MySQL's default collation, so `"%Z"` also matches a lowercase `z`
- `ORDER BY student_name DESC` lists the matches from Z to A

First and last rows of the result:

| student_id | student_name | student_age |
|-----------:|--------------|------------:|
| 13 | Sharon Alvarez | 27 |
| 49 | Scott Ruiz | 28 |
| 91 | Sanjay Ramirez | 24 |
| 7 | Rohan Gomez | 27 |
| … | … | … |
| 63 | Andrew Chavez | 24 |
| 12 | Aman Yilmaz | 29 |
| 9 | Aiden Ortiz | 25 |

Notice that every name in the result really ends in a lowercase `z` (Alvarez, Ruiz, Yilmaz…). None of them ends in a capital `Z`, yet they all matched — that's the case-insensitive match in action.

| Pattern | Meaning |
|---------|---------|
| `"Ar%"` | starts with `Ar` |
| `"%ez"` | ends with `ez` |
| `"%ar%"` | contains `ar` anywhere |
| `"_a%"` | `a` is the 2nd character (`_` = exactly one character) |

### Gotchas

- **Without a wildcard, `LIKE` is just an exact match.** `LIKE "Z"` only finds a name that is exactly `Z` → 0 rows here.
- **`%Z` vs `Z%`:** `%Z` = ends with Z, `Z%` = starts with Z (would find `Zachary Baker`, `Zachary King`).
- **Spaces count as characters.** `"% %"` matches every name that contains a space.
- **Order of clauses:** `WHERE` must come before `ORDER BY`, and `LIMIT` comes last: `SELECT … FROM … WHERE … ORDER BY … LIMIT …`.
- **Quotes:** MySQL accepts `"%Z"` and `'%Z'`, but single quotes are the SQL standard and work in every database, so prefer `'%Z'` in real projects.
- Use `NOT LIKE` to get the opposite: `WHERE student_name NOT LIKE "%Z"` returns the other 82 students.

**Try it yourself:**
- Names that start with `A`: `SELECT * FROM students WHERE student_name LIKE "A%";`
- First 5 matches only, A → Z: `SELECT * FROM students WHERE student_name LIKE "%Z" ORDER BY student_name ASC LIMIT 5;`

---

## Order of clauses (cheat sheet)

Everything from this lecture fits into one query, and the keywords must be written in this order:

```sql
SELECT student_id AS id, student_name AS name   -- 5. pick columns + aliases
FROM students AS s                              -- 1. which table
WHERE student_name LIKE "%Z"                    -- 2. filter rows
ORDER BY name DESC                              -- 3. sort
LIMIT 5 OFFSET 0;                               -- 4. cut out one page
```

The numbers in the comments show roughly the order in which MySQL **thinks about** the clauses: it finds the table, filters rows, then builds the select list (that's why a column alias isn't available in `WHERE` yet, but is in `ORDER BY`), sorts, and finally applies `LIMIT`/`OFFSET`.

---

## Commands Summary

| Command | What it does |
|---|---|
| `SHOW DATABASES` / `USE db` / `SHOW TABLES` | Find and select the working database |
| `SELECT DATABASE()` | Show which database is currently selected |
| `SELECT * FROM db.table` | Read a table by its full name, without `USE` |
| `SELECT * FROM db` ❌ | Error 1146 — a database name is not a table name |
| `LIMIT n OFFSET m` | Return `n` rows after skipping `m` (pagination) |
| `LIMIT m, n` | Short form of `LIMIT n OFFSET m` (offset comes first) |
| `ORDER BY a ASC, b DESC` | Sort by `a`, then break ties with `b` |
| `col AS alias` | Rename a column in the result only |
| `FROM table AS alias` | Give a table a temporary name inside the query |
| `WHERE col LIKE "pattern"` | Match strings with `%` (any chars) and `_` (one char) |
| `WHERE col NOT LIKE "pattern"` | Keep rows that do **not** match the pattern |
