# MySQL Lecture 1 — Querying, LIKE, Timestamps & Transactions

In this session we created the `pal_india` database and the `students` table, loaded sample data, emptied it with `TRUNCATE` and loaded it again. Then we picked specific columns, paged through the table with `LIMIT` / `OFFSET`, fetched the latest rows with `ORDER BY ... DESC LIMIT`, sorted on more than one column, filtered rows with `WHERE`, `AND`, `OR`, `IN` and `NOT IN`, used aliases (`AS`), and searched text with `LIKE`. After that we inserted a duplicate-name row, added `createdAt` / `updateAt` timestamp columns, and started a transaction.

## What this lecture covers

| Family | Commands practiced |
|--------|--------------------|
| Navigation | `SHOW DATABASES`, `USE`, `SHOW TABLES`, `DESC` |
| Selecting columns | `SELECT *`, `SELECT col1, col2, ...` |
| Pagination | `LIMIT n OFFSET m` |
| Sorting | `ORDER BY col DESC LIMIT n` (latest rows), `ORDER BY col1 ASC, col2 DESC` (multi-column) |
| Filtering | `WHERE` with `=`, `AND`, `OR`, `IN (...)`, `NOT IN (...)` |
| Aliases | `SELECT col AS alias`, `FROM table AS alias` |
| Pattern matching | `LIKE` with `%` — starts with / ends with / contains, and `LIKE` with an exact string |
| DML | `INSERT`, `UPDATE` |
| DDL | `CREATE DATABASE`, `CREATE TABLE`, `DROP TABLE`, `TRUNCATE TABLE`, `RENAME TABLE`, `ALTER TABLE ... ADD / RENAME COLUMN / DROP COLUMN / MODIFY COLUMN` |
| Transactions | `START TRANSACTION` (+ `COMMIT` / `ROLLBACK`) |

**Tool used:** MySQL Shell — DB Notebook (execute a line with `Ctrl+Enter`)

> **Prerequisite:** the `pal_india` database with the `students` table holding 100 sample rows (ids 1–100), and `student_email` set to `UNIQUE`. Section 0 and section 1 show how to get there.

---

## 0. Creating the database and the `students` table

### Create the database

```sql
SHOW DATABASES;              -- list every database on the server
CREATE DATABASE pal_india;   -- create a new, empty database
SHOW DATABASES;              -- pal_india now appears in the list
USE pal_india;               -- make it the "current" database
```

Step by step:

1. `SHOW DATABASES` lists every database the server has. Some of them (`mysql`, `information_schema`, `performance_schema`, `sys`) are MySQL's own system databases — don't touch them.
2. `CREATE DATABASE pal_india` creates an empty container for tables.
3. `USE pal_india` tells MySQL "from now on, every table name I write belongs to `pal_india`". It returns no rows, just `OK`.

> **Gotcha — database already exists.** In the notebook, `pal_india` had been created earlier, so `CREATE DATABASE` failed with:
> `MySQL Error (1007): Can't create database 'pal_india'; database exists`
> This is harmless. To avoid the error, write `CREATE DATABASE IF NOT EXISTS pal_india;`

> **Try it yourself:** run `CREATE DATABASE IF NOT EXISTS pal_india;` twice. The second run gives a warning instead of an error.

### Create the table

```sql
CREATE TABLE students(
    student_id INT PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT,   -- row number, filled in by MySQL
    student_name VARCHAR(50) NOT NULL,                           -- text up to 50 chars, required
    student_age INT NULL,                                        -- whole number, optional
    student_address VARCHAR(100) NULL,                           -- optional
    student_email VARCHAR(50) NOT NULL,                          -- required
    student_gender VARCHAR(20) NULL,                             -- optional
    student_contact VARCHAR(25)                                  -- no rule written → NULL allowed
);
SHOW TABLES;      -- students
DESC students;    -- shows every column, its type, NULL rule and key
```

- `PRIMARY KEY` → uniquely identifies each row (it is already unique and not null, so `UNIQUE NOT NULL` is redundant here)
- `AUTO_INCREMENT` → MySQL fills in `student_id` automatically: 1, 2, 3, ...
- `NOT NULL` → the column must have a value; `NULL` → the value is optional
- `VARCHAR(50)` → text of **up to** 50 characters. Storing a longer string gives an error (`Data too long for column`).
- `INT` → a whole number. Ages like `16` fit; `16.5` would be rounded.
- If you write no `NULL` / `NOT NULL` rule (like `student_contact`), MySQL assumes `NULL` is allowed.

`DESC students` (short for `DESCRIBE`) answers "what does this table look like?". It returns one row per column:

| Field | Type | Null | Key | Default | Extra |
|---|---|---|---|---|---|
| student_id | int | NO | PRI | NULL | auto_increment |
| student_name | varchar(50) | NO | | NULL | |
| student_age | int | YES | | NULL | |
| ... | ... | ... | | | |

> **Why `student_contact VARCHAR` and not `INT`?** Phone numbers contain `+` and `-`, can start with `0`, and you never do maths on them. Store them as text.

> **Common mistake:** a comma after the **last** column (`student_contact VARCHAR(25),`) gives a syntax error. Every column is separated by a comma, but the last one has none before `)`.

### Dropping a table

```sql
DROP TABLE students;
SHOW TABLES;      -- empty
DESC students;    -- ❌ Table 'pal_india.students' doesn't exist
```

`DROP TABLE` deletes the table **and all its data** permanently — the structure (columns) is gone too, which is why `DESC` now fails. There is no "undo" and MySQL does not ask "are you sure?". Run the `CREATE TABLE` above again before continuing.

> Safer form: `DROP TABLE IF EXISTS students;` — it does not fail when the table is already gone.

### Changing the table with ALTER

```sql
-- add a column with a default value
ALTER TABLE students ADD is_active BOOLEAN DEFAULT TRUE;
DESC students;

-- rename a column
ALTER TABLE students RENAME COLUMN is_active TO student_is_active;
DESC students;

-- add a column, then remove it
ALTER TABLE students ADD x VARCHAR(12);
DESC students;
ALTER TABLE students DROP COLUMN x;
DESC students;

-- rename a table (here to the same name, so nothing changes)
RENAME TABLE students TO students;
SHOW TABLES;

-- change a column definition: make email unique
ALTER TABLE students MODIFY COLUMN student_email VARCHAR(50) UNIQUE NOT NULL;
DESC students;    -- student_email now shows Key = UNI
```

`ALTER TABLE` changes the **structure** of a table without losing its rows. Read each one as "in table `students`, do this to a column".

After all the changes above, `DESC students` in the notebook shows:

| Field | Type | Null | Key | Default | Extra |
|---|---|---|---|---|---|
| student_id | int | NO | PRI | NULL | auto_increment |
| student_name | varchar(50) | NO | | NULL | |
| student_age | int | YES | | NULL | |
| student_address | varchar(100) | YES | | NULL | |
| student_email | varchar(50) | NO | **UNI** | NULL | |
| student_gender | varchar(20) | YES | | NULL | |
| student_contact | varchar(25) | YES | | NULL | |
| student_is_active | tinyint(1) | YES | | 1 | |

| Command | What it does |
|---|---|
| `ALTER TABLE t ADD col TYPE` | Add a new column (it goes to the end of the table) |
| `ALTER TABLE t RENAME COLUMN a TO b` | Rename a column (type and data stay the same) |
| `ALTER TABLE t DROP COLUMN col` | Remove a column and its data |
| `ALTER TABLE t MODIFY COLUMN col NEW_DEFINITION` | Change a column's type / constraints |
| `RENAME TABLE old TO new` | Rename a table |

> `BOOLEAN` is stored as `TINYINT(1)` in MySQL, so `DESC` shows `tinyint(1)` and `TRUE` is stored as `1` (that is the `Default = 1` above).

> **Gotchas with ALTER:**
> - `MODIFY COLUMN` replaces the **whole** definition. If you write `MODIFY COLUMN student_email VARCHAR(50) UNIQUE` and forget `NOT NULL`, the column becomes nullable again.
> - Adding `UNIQUE` fails with a `Duplicate entry` error if the table **already** has two rows with the same email. Clean the data first.
> - `DROP COLUMN` cannot be undone — the data in that column is gone.

### First insert

```sql
INSERT INTO students(student_name, student_age, student_address, student_email, student_gender, student_contact)
VALUES("arif", 16, "dharavi", "arif@gmail.com", "Male", "+9132534546");
SELECT * FROM students;
```

How it works:

1. The first bracket lists the **columns** you are giving values for.
2. `VALUES(...)` gives the values **in the same order** — 1st value → 1st column, and so on.
3. `student_id` and `student_is_active` are left out of the column list, so MySQL fills them from `AUTO_INCREMENT` and the default (`TRUE`).

Result of the `SELECT` (1 row):

| student_id | student_name | student_age | student_address | student_email | student_gender | student_contact | student_is_active |
|---|---|---|---|---|---|---|---|
| 1 | arif | 16 | dharavi | arif@gmail.com | Male | +9132534546 | 1 |

> **Common mistakes:**
> - The number of values must match the number of columns, otherwise: `Column count doesn't match value count`.
> - Text values need quotes (`"arif"`), numbers don't (`16`).
> - Running the same insert twice fails now, because `student_email` is `UNIQUE`: `Duplicate entry 'arif@gmail.com' for key ...`.

### Loading the sample data (bulk insert)

```sql
INSERT INTO students (student_name, student_age, student_address, student_email, student_gender, student_contact) VALUES
('Linda Patel', 20, '8945 Maple Dr, Houston, TX 87397', 'linda.patel1@hotmail.com', NULL, '+1-438-717-1434'),
('Pooja Turner', 26, '2625 Highland Ave, New York, NY 65392', 'pooja.turner2@outlook.com', 'Female', '+1-981-544-2674'),
-- ... 96 more rows ...
('Raymond Martinez', 30, '8317 Lincoln Ave, Columbus, OH 70648', 'raymond.martinez100@university.edu', 'Male', '+1-242-660-4084');
-- OK, 100 rows affected
```

- One `INSERT` can add **many rows**: write several `( ... )` groups separated by commas, and end the whole statement with a single `;`.
- `NULL` (no quotes) means "no value". `'NULL'` in quotes would be the 4-letter text "NULL" — a different thing.
- Some rows have `NULL` age (6 students), `NULL` address or `NULL` gender — useful later for seeing how `NULL` sorts and filters.

Because `arif` already had `student_id = 1`, these 100 rows got ids **2–101**. The next section fixes that.

---

## 1. Emptying a table with TRUNCATE TABLE

```sql
TRUNCATE TABLE students;   -- delete ALL rows, keep the table structure
SELECT * FROM students;    -- empty result (0 rows)
```

What `TRUNCATE` does:

- Removes **every row** in the table in one go.
- Keeps the table itself: columns, types, keys and constraints are untouched (`DESC students` still works).
- **Resets `AUTO_INCREMENT`**, so the next inserted row gets `student_id = 1` again.

In the notebook, the bulk `INSERT` was run again right after `TRUNCATE`, so `SELECT * FROM students` came back with **100 rows**, and this time `Linda Patel` has id **1** (before the truncate, id 1 was `arif`). That is the counter reset in action:

| student_id | student_name | student_age | student_email |
|---|---|---|---|
| 1 | Linda Patel | 20 | linda.patel1@hotmail.com |
| 2 | Pooja Turner | 26 | pooja.turner2@outlook.com |
| ... | ... | ... | ... |
| 100 | Raymond Martinez | 30 | raymond.martinez100@university.edu |

`DROP` vs `TRUNCATE` vs `DELETE`:

| Command | Rows | Table structure | AUTO_INCREMENT | Can use `WHERE`? |
|---|---|---|---|---|
| `DROP TABLE t` | gone | **gone** | gone | no |
| `TRUNCATE TABLE t` | all gone | kept | reset to 1 | no |
| `DELETE FROM t` | all gone (or only matching rows with `WHERE`) | kept | **not** reset | yes |

> ⚠️ `TRUNCATE` cannot be undone, even inside a transaction (it commits automatically). Use it only when you really want an empty table.

> **Try it yourself:** run `DELETE FROM students;`, then the bulk insert again, and look at the ids. They continue from 101 instead of starting at 1, because `DELETE` does not reset the counter.

---

## 2. Reconnecting to the database

```sql
SHOW DATABASES;   -- the list includes pal_india
USE pal_india;
SHOW TABLES;      -- students
```

Every new notebook session starts with no database selected. Run `USE` first, or queries fail with `No database selected`.

- The number of databases in the list depends on your server (it was 7 in one session and 12 in the notebook run) — what matters is that `pal_india` is there.
- `SHOW TABLES` only works after `USE`, because it lists the tables of the **current** database.

> **Tip:** `SELECT DATABASE();` tells you which database is currently selected (`NULL` if none).

## 3. A common mistake — database name in FROM

```sql
SELECT * FROM pal_india;   -- ❌ Table 'pal_india.pal_india' doesn't exist
```

`pal_india` is the **database**, not a table. `FROM` needs a **table** name. Look at the error closely: MySQL read `pal_india` as a table name and searched for it inside the current database, i.e. `pal_india.pal_india`.

```sql
SELECT * FROM students;             -- ✅ table in the current database
SELECT * FROM pal_india.students;   -- ✅ fully qualified: database.table (works without USE)
```

Think of it as folders: the database is the folder, the table is the file. `FROM` must point to a file.

## 4. Selecting specific columns

```sql
SELECT * FROM students;                                     -- every column, 100 rows
SELECT student_id, student_name, student_age FROM students; -- only 3 columns, still 100 rows
```

- `*` means "all columns", in the order they were created.
- Listing column names returns **only those columns**, in the order **you** write them.
- Choosing columns changes the **width** of the result, not the number of rows. Both queries above return 100 rows.

Result of the second query (first rows):

| student_id | student_name | student_age |
|---|---|---|
| 1 | Linda Patel | 20 |
| 2 | Pooja Turner | 26 |
| 3 | Mark Rivera | 26 |
| 4 | Sarah Garcia | 29 |
| ... | ... | ... |

> **Why not always use `*`?** Real tables can have dozens of columns. Asking only for what you need is faster, easier to read, and your query keeps working the same way if someone adds a column later.

> **Common mistakes:**
> - A trailing comma before `FROM` (`SELECT student_id, student_name, FROM students`) is a syntax error.
> - A misspelled column gives `Unknown column 'student_nam' in 'field list'`. Check the spelling with `DESC students`.

> **Try it yourself:** `SELECT student_name, student_email FROM students;` — note the columns come back in the order you typed them.

## 5. Pagination with LIMIT / OFFSET

```sql
SELECT student_id, student_name, student_age FROM students LIMIT 20 OFFSET 0;   -- first 20 rows, 3 columns
SELECT * FROM students LIMIT 10 OFFSET 0;    -- page 1  → ids 1–10
SELECT * FROM students LIMIT 10 OFFSET 10;   -- page 2  → ids 11–20
SELECT * FROM students LIMIT 10 OFFSET 20;   -- page 3  → ids 21–30
SELECT * FROM students LIMIT 10 OFFSET 90;   -- page 10 → ids 91–100 (last page)
SELECT * FROM students LIMIT 7  OFFSET 10;   -- 7 rows after skipping 10 → ids 11–17
```

- `LIMIT n` → return at most `n` rows
- `OFFSET m` → skip the first `m` rows first

How MySQL runs it: it builds the full result, **skips** `m` rows, then **keeps** the next `n` and stops.

```
rows:   1  2  3 ... 10 | 11 12 ... 20 | 21 ...
        └─ OFFSET 10 ──┘└─ LIMIT 10 ──┘          → page 2 = ids 11–20
```

For page `p` with page size `s`: **`LIMIT s OFFSET (p - 1) * s`**. With 100 rows and a page size of 10 there are 10 pages, so `OFFSET 90` is the last one.

The first query combines column selection with paging: it returns 20 rows (ids 1–20) with only `student_id`, `student_name`, `student_age`. Row 19 (`Dennis Davis`) shows `NULL` in `student_age` because his age was inserted as `NULL`.

What to expect at the edges:

- `OFFSET 95 LIMIT 10` → only 5 rows (ids 96–100). `LIMIT` is a maximum, not a promise.
- `OFFSET 100` or more → 0 rows, **no error**.
- `LIMIT 10` alone is the same as `LIMIT 10 OFFSET 0`.

> Without `ORDER BY`, the row order isn't guaranteed. It looks like id order here only because of the primary key. For stable pages in real apps, always add `ORDER BY`.

> **Shortcut syntax:** `LIMIT 10, 10` means `LIMIT 10 OFFSET 10` — the **offset comes first** in this form, which confuses many people. Prefer the `LIMIT ... OFFSET ...` form.

> **Try it yourself:** show page 4 with a page size of 15. (Answer: `LIMIT 15 OFFSET 45` → ids 46–60.)

## 6. Getting the latest rows — ORDER BY ... DESC LIMIT

```sql
SELECT * FROM students ORDER BY student_id DESC LIMIT 10 OFFSET 0;   -- the 10 newest students
```

MySQL evaluates this in order:

1. `FROM students` — take all 100 rows.
2. `ORDER BY student_id DESC` — sort from the highest id to the lowest (`DESC` = descending, big → small).
3. `LIMIT 10 OFFSET 0` — skip nothing, keep the first 10 rows of the **sorted** list.

Because `AUTO_INCREMENT` gives each new row a bigger id, "highest ids" means "most recently inserted". Result: ids **100 down to 91**.

| student_id | student_name | student_age |
|---|---|---|
| 100 | Raymond Martinez | 30 |
| 99 | Christine Martin | 24 |
| 98 | Benjamin Sanchez | 19 |
| ... | ... | ... |
| 91 | Sanjay Ramirez | 24 |

> **Order of clauses matters.** It must be `SELECT ... FROM ... WHERE ... ORDER BY ... LIMIT ... OFFSET ...`. Writing `LIMIT` before `ORDER BY` is a syntax error.

> **Gotcha:** `LIMIT` is applied **after** sorting. So this query does not take "10 rows and then sort them" — it sorts all rows first, then takes the top 10. That is exactly what makes "top N" queries work.

> **Try it yourself:** the 5 **oldest** rows by id → `ORDER BY student_id ASC LIMIT 5`. The second page of newest rows → `ORDER BY student_id DESC LIMIT 10 OFFSET 10` (ids 90–81).

## 7. Sorting on multiple columns

```sql
SELECT * FROM students ORDER BY student_name ASC, student_age DESC;
SELECT * FROM students ORDER BY student_age ASC, student_id ASC;
```

MySQL sorts by the first column. The second column only breaks ties, when two rows have the same value in the first one.

- **Name ASC, age DESC:** there are two `William Parker` rows. The one with age 26 (id 58) comes before the one with age `NULL` (id 95).
- **Age ASC, id ASC:** the 6 students with `NULL` age come **first** (ids 17, 19, 28, 43, 81, 95). Next come the 17-year-olds in id order: 11, 14, 20, 32, 52, 71, ...

Illustration of the second query (first rows):

| student_id | student_age | why it is here |
|---|---|---|
| 17 | NULL | NULL ages first, tie broken by id |
| 19 | NULL | |
| ... | NULL | |
| 95 | NULL | last of the NULL ages |
| 11 | 17 | youngest real age, smallest id |
| 14 | 17 | same age → next id |
| ... | ... | |

> **NULL ordering:** MySQL treats `NULL` as smaller than any value, so NULLs come first with `ASC` and last with `DESC`.

- Each column has its **own** direction. `ORDER BY a, b DESC` means `a ASC, b DESC` — `ASC` is the default and `DESC` only applies to `b`.
- Text is sorted alphabetically and, with the default collation, case-insensitively.

> **Try it yourself:** `SELECT student_name, student_age FROM students ORDER BY student_age DESC, student_name ASC;` — the oldest students first, and students of the same age in A→Z order. Where do the `NULL` ages end up now?

## 8. Filtering rows with WHERE — AND / OR

```sql
SELECT * FROM students WHERE student_id = 1 AND student_name = "Linda Patel";   -- 1 row
SELECT * FROM students WHERE student_id = 1 OR  student_name = "fjhfjoer";      -- 1 row
```

`WHERE` keeps only the rows for which the condition is **true**. MySQL checks the condition row by row.

- `AND` → **both** conditions must be true.
- `OR` → **at least one** condition must be true.

Query 1: row 1 has id 1 **and** its name is `Linda Patel`, so it passes. Every other row fails the `student_id = 1` part. Result: 1 row.

Query 2: nobody is called `fjhfjoer`, but `OR` only needs one side to be true, and row 1 has `student_id = 1`. Result: the same 1 row (`Linda Patel`).

| student_id | student_name | student_age | student_email |
|---|---|---|---|
| 1 | Linda Patel | 20 | linda.patel1@hotmail.com |

Truth table:

| Condition A | Condition B | A AND B | A OR B |
|---|---|---|---|
| true | true | ✅ | ✅ |
| true | false | ❌ | ✅ |
| false | true | ❌ | ✅ |
| false | false | ❌ | ❌ |

What changes the result:

- `WHERE student_id = 1 AND student_name = "fjhfjoer"` → **0 rows** (the second part is false for row 1).
- `WHERE student_id = 2 AND student_name = "Linda Patel"` → **0 rows** (Linda's id is 1, not 2).

> **Gotchas:**
> - **`AND` is evaluated before `OR`.** `WHERE a OR b AND c` means `a OR (b AND c)`. Use brackets to say what you mean: `WHERE (a OR b) AND c`.
> - Text comparisons are case-insensitive by default, so `"linda patel"` also matches `Linda Patel`.
> - To find missing values use `IS NULL`, not `= NULL`. `WHERE student_age = NULL` returns 0 rows even though 6 ages are `NULL`; `WHERE student_age IS NULL` returns them.

> **Try it yourself:** `SELECT student_name, student_age FROM students WHERE student_age >= 18 AND student_age <= 20;`

## 9. Matching a list of values — IN / NOT IN

```sql
SELECT * FROM students WHERE student_id NOT IN (1, 2, 3, 4);                -- 96 rows
SELECT * FROM students WHERE student_id IN (1, 23, 3, 4, 5, 5, 43, 21, 22); -- 8 rows
```

- `col IN (a, b, c)` is a short way to write `col = a OR col = b OR col = c`.
- `col NOT IN (a, b, c)` means "none of these" — `col <> a AND col <> b AND col <> c`.

**`NOT IN (1,2,3,4)`** → 100 rows minus the 4 excluded ids = **96 rows**, starting at id 5 (`Frank Hughes`).

**`IN (1, 23, 3, 4, 5, 5, 43, 21, 22)`** → the list has 9 values, but `5` appears twice. A row can only be returned once, so the result is **8 rows**:

| student_id | student_name | student_age |
|---|---|---|
| 1 | Linda Patel | 20 |
| 3 | Mark Rivera | 26 |
| 4 | Sarah Garcia | 29 |
| 5 | Frank Hughes | 27 |
| 21 | Kevin Bennett | 24 |
| 22 | Henry Rodriguez | 22 |
| 23 | Sandra Moore | 18 |
| 43 | Barbara Long | NULL |

Notice:

- Duplicates in the list don't create duplicate rows.
- The rows come back in the **table's** order (by id), **not** in the order you typed the list (23 was written before 3). Add `ORDER BY` if you need a specific order.
- An id that doesn't exist (e.g. `IN (1, 500)`) is simply ignored — no error.

> **Gotcha — `NOT IN` with `NULL`:** if the list contains `NULL` (e.g. `NOT IN (1, NULL)`), the query returns **0 rows**, because "not equal to unknown" is never true. Keep `NULL` out of `NOT IN` lists.

> **Try it yourself:** `SELECT student_name, student_age FROM students WHERE student_age IN (17, 18);` — all 17- and 18-year-olds. `IN` works with text too: `WHERE student_name IN ("Linda Patel", "Mark Rivera")`.

## 10. Aliases (AS)

### Table alias
```sql
SELECT * FROM students AS student_details;
SHOW TABLES;   -- still just: students
```
A table alias is a temporary name that only exists inside that one query. It does **not** rename the table (use `RENAME TABLE` for that). Aliases become really useful later, with joins.

- Once you give an alias, you can use it to prefix columns: `SELECT s.student_name FROM students AS s;`
- `AS` is optional: `FROM students s` works the same.
- After the query finishes, the alias is gone. `SELECT * FROM student_details;` fails with `Table 'pal_india.student_details' doesn't exist`.

### Column alias
```sql
SELECT student_id AS id, student_name AS name FROM students;
```
The result headers show `id` and `name` instead of the real column names. The table itself isn't changed.

| id | name |
|---|---|
| 1 | Linda Patel |
| 2 | Pooja Turner |
| ... | ... |

> **Tip:** an alias with a space needs quotes or backticks: `student_name AS "Student Name"`.

> **Gotcha:** you **cannot** use a column alias in `WHERE` — `WHERE name = "Linda Patel"` gives `Unknown column 'name'`, because `WHERE` is evaluated before the `SELECT` list. You **can** use it in `ORDER BY`: `ORDER BY name`.

## 11. Pattern matching with LIKE

```sql
SELECT * FROM students WHERE student_name LIKE "%Z" ORDER BY student_name DESC;   -- 18 rows
```

- `%` matches **any number of characters** (including none)
- `"%Z"` means "ends with Z", so it finds names like `Sharon Alvarez`, `Scott Ruiz` and `Rohan Gomez`
- The match is **case-insensitive** with MySQL's default collation, so `"%Z"` also matches a lowercase `z`
- `ORDER BY student_name DESC` lists the matches from Z to A

How MySQL runs it: `WHERE ... LIKE` first keeps the 18 names that end with `z`, then `ORDER BY` sorts only those 18. The first rows are:

| student_name |
|---|
| Sharon Alvarez |
| Scott Ruiz |
| Sanjay Ramirez |
| Rohan Gomez |
| Richard Lopez |
| ... |

| Pattern | Meaning |
|---------|---------|
| `"Ar%"` | starts with `Ar` |
| `"%ez"` | ends with `ez` |
| `"%ar%"` | contains `ar` anywhere |
| `"_a%"` | `a` is the 2nd character (`_` = exactly one character) |

> **Common mistakes:**
> - Using `=` with wildcards: `WHERE student_name = "%Z"` looks for a name that is literally `%Z` → 0 rows. Wildcards only work with `LIKE`.
> - Forgetting `%` entirely: `LIKE "Z"` matches only a name that is exactly `Z`.
> - `NOT LIKE` exists too: `WHERE student_name NOT LIKE "%Z"` returns the other 82 rows.

## 12. Inserting a row with a duplicate name

```sql
INSERT INTO students(student_name, student_age, student_address, student_email, student_gender, student_contact)
VALUES("Sharon Alvarez", 16, "dharavi", "arif@gmail.com", "Male", "+9132534546");

SELECT * FROM students WHERE student_name = "Sharon Alvarez";   -- 2 rows now
```

A `Sharon Alvarez` (id 13, age 27) already exists. The insert still works because `student_name` has no `UNIQUE` constraint, while the email `arif@gmail.com` is not used by any other row (the original `arif` row was removed by `TRUNCATE` in section 1). The table now has **101 rows**, and the new row gets id **101**.

| student_id | student_name | student_age | student_email |
|---|---|---|---|
| 13 | Sharon Alvarez | 27 | sharon.alvarez13@yahoo.com |
| 101 | Sharon Alvarez | 16 | arif@gmail.com |

- Only columns marked `UNIQUE` (or `PRIMARY KEY`) block duplicates. Two people can share a name; they cannot share an email here.
- Running this same `INSERT` a second time fails: `Duplicate entry 'arif@gmail.com' for key ...`.

> In the notebook this `SELECT` has no closing `;`, so MySQL reads it and the next `SELECT` as one statement and returns a syntax error. Always end each statement with `;`.

### Tie-breaking with the new row

```sql
SELECT * FROM students ORDER BY student_name DESC, student_age DESC;
```

The two `Sharon Alvarez` rows tie on name, so age breaks the tie: age 27 (id 13) comes before age 16 (id 101).

> **Try it yourself:** re-run `SELECT * FROM students WHERE student_name LIKE "%Z";` — it now returns 19 rows instead of 18.

## 13. More LIKE patterns — where the `%` goes matters

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

- Here the column alias `name` is used, so the result has a single column titled `name`.
- `"%Ar%"` is the broadest of the three — it also matches everything `"Ar%"` and `"%Ar"` match.
- `"Aaron Gupta"` does **not** match `"Ar%"`: the first two letters are `Aa`, not `Ar`.

> **Performance note:** `"Ar%"` (starts with) can use an index on the column; `"%Ar"` and `"%Ar%"` must check every row. On 100 rows you won't notice, on millions you will.

## 14. LIKE with an exact string (no wildcards)

```sql
SELECT * FROM students WHERE student_email LIKE "linda.patel1@hotmail.com";   -- 1 row
```

With no `%` or `_` in the pattern, `LIKE` has nothing "loose" to match, so it behaves like `=`: the value must match the whole pattern. Result: 1 row.

| student_id | student_name | student_age | student_email |
|---|---|---|---|
| 1 | Linda Patel | 20 | linda.patel1@hotmail.com |

- `.` and `@` are ordinary characters in `LIKE` (they are **not** wildcards — only `%` and `_` are).
- `WHERE student_email = "linda.patel1@hotmail.com"` gives the same row and is the clearer choice for an exact match.
- Since `student_email` is `UNIQUE`, an exact match can return **at most 1 row**.

> **Gotcha — `_` inside the value:** in an address like `linda_patel@...`, the `_` would match **any** single character (e.g. `lindaXpatel@...`). To match a real underscore, escape it: `LIKE "linda\_patel@%"`.

> **Try it yourself:** find every Hotmail user with `WHERE student_email LIKE "%@hotmail.com"`.

## 15. Adding timestamp columns

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

What you should see:

| student_id | student_name | createdAt | updateAt |
|---|---|---|---|
| 1 | Linda Patel | NULL | NULL |
| ... | ... | NULL | NULL |
| *(a new row inserted afterwards)* | ... | time of the insert | time of the insert |

> To make `updateAt` refresh on every change, it needs `ON UPDATE` as well:
> ```sql
> ALTER TABLE students MODIFY COLUMN updateAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;
> ```
> With only `DEFAULT`, `updateAt` is set at insert time and then never changes.

> **Gotchas:**
> - `TIMESTAMP` covers the years 1970–2038 and is stored in UTC (shown in your session's time zone). For dates outside that range, such as birthdays, use `DATE` or `DATETIME`.
> - To fill the old rows too, run an `UPDATE`, e.g. `UPDATE students SET createdAt = NOW() WHERE createdAt IS NULL;`

> **Try it yourself:** insert a new student without giving `createdAt`, then `SELECT student_name, createdAt FROM students ORDER BY student_id DESC LIMIT 1;`

## 16. Transactions

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

Step by step:

1. `START TRANSACTION` — MySQL starts recording your changes as "pending".
2. `UPDATE students SET student_age = 22` — every row is changed, but only **you** (this session) see the new ages until you commit.
3. `ROLLBACK` throws the pending changes away; `COMMIT` saves them for everyone. After either one, the transaction is over.

⚠️ This `UPDATE` has **no `WHERE`**, so it sets `student_age = 22` for **all 101 students**. The notebook stops before `COMMIT` or `ROLLBACK`, which makes this the right moment for:

```sql
ROLLBACK;                                               -- restore the original ages
UPDATE students SET student_age = 22 WHERE student_id = 1;   -- update only the intended row
COMMIT;
```

Always check your `WHERE` clause before an `UPDATE` or `DELETE`. Running it inside a transaction gives you a way to undo a mistake.

| Step | `student_age` of id 1 | `student_age` of id 2 |
|---|---|---|
| before | 20 | 26 |
| after `UPDATE` (no `WHERE`) | 22 | 22 ❌ |
| after `ROLLBACK` | 20 | 26 |
| after `UPDATE ... WHERE student_id = 1` + `COMMIT` | 22 | 26 ✅ |

> **Gotchas:**
> - Without `START TRANSACTION`, MySQL runs in **autocommit** mode: every `UPDATE` is saved immediately and `ROLLBACK` cannot help.
> - DDL statements (`CREATE`, `ALTER`, `DROP`, `TRUNCATE`) commit automatically and cannot be rolled back.
> - **Safe habit:** run the `WHERE` as a `SELECT` first (`SELECT * FROM students WHERE student_id = 1;`). If it returns the rows you expect, change `SELECT *` to `UPDATE ... SET ...`.

---

## Commands Summary

| Command | What it does |
|---|---|
| `SHOW DATABASES` / `USE db` / `SHOW TABLES` | Find and select the working database |
| `CREATE DATABASE [IF NOT EXISTS] db` | Create a database |
| `CREATE TABLE t(...)` / `DESC t` | Create a table / show its columns |
| `DROP TABLE t` | Delete the table and all its data |
| `TRUNCATE TABLE t` | Delete all rows, keep the structure, reset `AUTO_INCREMENT` |
| `ALTER TABLE t ADD / RENAME COLUMN / DROP COLUMN / MODIFY COLUMN` | Change a table's columns |
| `RENAME TABLE old TO new` | Rename a table |
| `SELECT * FROM db.table` | Read a table by its full name, without `USE` |
| `SELECT col1, col2 FROM t` | Return only the listed columns |
| `LIMIT n OFFSET m` | Return `n` rows after skipping `m` (pagination) |
| `ORDER BY col DESC LIMIT n` | Get the top / latest `n` rows |
| `ORDER BY a ASC, b DESC` | Sort by `a`, then break ties with `b` |
| `WHERE a AND b` / `WHERE a OR b` | Keep rows where both / at least one condition is true |
| `WHERE col IN (...)` / `NOT IN (...)` | Keep rows whose value is / isn't in the list |
| `col AS alias` | Rename a column in the result only |
| `FROM table AS alias` | Give a table a temporary name inside the query |
| `LIKE "pattern"` | Match strings with `%` (any chars) and `_` (one char); without wildcards it acts like `=` |
| `INSERT INTO table(...) VALUES(...), (...)` | Add one or many rows |
| `ALTER TABLE t ADD COLUMN c TIMESTAMP` | Add a date-time column |
| `MODIFY COLUMN c TIMESTAMP DEFAULT CURRENT_TIMESTAMP` | Auto-fill the insert time |
| `... ON UPDATE CURRENT_TIMESTAMP` | Auto-refresh the time on every update |
| `START TRANSACTION` | Begin a group of changes you can still undo |
| `COMMIT` / `ROLLBACK` | Make the changes permanent / undo them |
| `UPDATE t SET c = v WHERE ...` | Change rows (no `WHERE` = every row) |
