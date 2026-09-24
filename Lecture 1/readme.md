# MySQL Lecture 1 — Databases, Tables (DDL) & Querying Data

In this lecture we created our own database, built a table inside it, practiced the main **DDL (Data Definition Language)** commands, inserted data (a single row + 500 sample rows), and started reading it back with **SELECT** — filtering, sorting and pagination.

## What this lecture covers

| Family | Commands practiced |
|--------|--------------------|
| Navigation | `SHOW DATABASES`, `USE`, `SHOW TABLES`, `DESC` |
| DDL | `CREATE TABLE`, `ALTER TABLE ... ADD / RENAME COLUMN / DROP COLUMN / MODIFY COLUMN`, `RENAME TABLE`, `TRUNCATE TABLE`, `DROP TABLE` |
| DML | `INSERT` (single row + 500 sample rows in batches), `SELECT` |
| Querying | `WHERE` with `AND` / `OR`, `IN` / `NOT IN`, `LIKE`, `ORDER BY`, `LIMIT` / `OFFSET` |

**Tool used:** MySQL Shell — DB Notebook (execute a line with `Ctrl+Enter`)

---

## 1. Listing all databases

```sql
SHOW DATABASES;
```

Shows every database on the MySQL server. By default there are 6: `information_schema`, `mysql`, `performance_schema`, `sakila`, `sys`, `world`.

## 2. Creating our own database

```sql
CREATE DATABASE pal_india;
SHOW DATABASES;   -- pal_india now appears in the list (7 total)
```

## 3. Selecting the database

```sql
USE pal_india;
```

Every command after this runs inside `pal_india`.

## 4. Creating a table

```sql
CREATE TABLE students(
    student_id INT PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT,
    student_name VARCHAR(50) NOT NULL,
    student_age INT NULL,
    student_address VARCHAR(100) NULL,
    student_email VARCHAR(50) NOT NULL,
    student_gender VARCHAR(20) NULL,
    student_contact VARCHAR(25)
);
```

**Constraints used:**

| Constraint | Meaning |
|---|---|
| `PRIMARY KEY` | Uniquely identifies each row |
| `AUTO_INCREMENT` | ID is generated automatically (1, 2, 3, ...) |
| `NOT NULL` | Value must be filled, cannot be empty |
| `UNIQUE` | No duplicate values allowed in this column |
| `NULL` | Value is optional |
| `DEFAULT TRUE` | If no value is given, the default is used |

## 5. Checking the table

```sql
SHOW TABLES;             -- lists tables in the current database
DESC students;           -- shows the table structure
```

`DESC` (DESCRIBE) shows each column's **Field, Type, Null, Key, Default, Extra**.

## 6. Deleting a table

```sql
DROP TABLE students;
```

Removes the whole table — structure **and** data. (We re-created the table afterward to continue practicing.)

## 7. ALTER TABLE — changing an existing table

### Add a new column
```sql
ALTER TABLE students ADD is_active BOOLEAN DEFAULT TRUE;
```
> Note: MySQL stores `BOOLEAN` as `tinyint(1)` — 1 = true, 0 = false.

### Rename a column
```sql
ALTER TABLE students RENAME COLUMN is_active TO student_is_active;
```

### Add a temporary column (for practice)
```sql
ALTER TABLE students ADD x VARCHAR(12);
```

### Remove a column
```sql
ALTER TABLE students DROP COLUMN x;
```

### Modify a column (adding UNIQUE to the email)
```sql
ALTER TABLE students MODIFY COLUMN student_email VARCHAR(50) UNIQUE NOT NULL;
```

After this, `DESC` shows **UNI** in the Key column for `student_email` — meaning no two students can have the same email.

## 8. Renaming a table

```sql
RENAME TABLE students TO students;   -- general form: RENAME TABLE old_name TO new_name;
SHOW TABLES;                         -- still shows: students
```

We practiced the syntax by renaming `students` to `students`, so the name stays the same — but this is exactly how any table gets renamed.

## 9. TRUNCATE TABLE — emptying a table

```sql
TRUNCATE TABLE students;
SELECT * FROM students;   -- empty set
```

Removes **all rows** but keeps the table structure (unlike `DROP TABLE`, which removes the structure too). It also resets the `AUTO_INCREMENT` counter, so the next insert starts from 1 again.

## 10. Inserting data (INSERT)

### Single row

```sql
INSERT INTO students(student_name, student_age, student_address, student_email, student_gender, student_contact)
VALUES("arif", 16, "dharavi", "arif@gmail.com", "Male", "+9132534546");
```

`student_id` is skipped — `AUTO_INCREMENT` fills it in automatically.

### Multiple rows (500 sample rows, 5 batches of 100)

```sql
INSERT INTO students (student_name, student_age, student_address, student_email, student_gender, student_contact) VALUES
('Linda Patel', 20, '8945 Maple Dr, Houston, TX 87397', 'linda.patel1@hotmail.com', NULL, '+1-438-717-1434'),
('Pooja Turner', 26, '2625 Highland Ave, New York, NY 65392', 'pooja.turner2@outlook.com', 'Female', '+1-981-544-2674'),
-- ... 98 more rows in this batch ...
('Raymond Martinez', 30, '8317 Lincoln Ave, Columbus, OH 70648', 'raymond.martinez100@university.edu', 'Male', '+1-242-660-4084');
```

One `INSERT` can carry many value tuples — the columns listed once at the top apply to every row. Some rows pass `NULL` for optional columns like `student_gender` or `student_address`.

## 11. Reading data (SELECT)

```sql
SELECT * FROM students;                                        -- every column, every row
SELECT student_id, student_name, student_age FROM students;    -- only the columns you name
```

`*` means "all columns". Naming columns explicitly is how you pick just the fields you need.

## 12. Sorting results (ORDER BY)

```sql
SELECT * FROM students ORDER BY student_id DESC LIMIT 10 OFFSET 0;
```

- `ORDER BY student_id` sorts the result by that column (`ASC` is the default, lowest first)
- `DESC` flips it to highest/newest first

Combined with `LIMIT`, this is the classic "show me the latest 10 students" query.

## 13. Pagination (LIMIT / OFFSET)

```sql
SELECT student_id, student_name, student_age FROM students LIMIT 20 OFFSET 0;   -- rows 1–20
SELECT * FROM students LIMIT 10 OFFSET 0;                                       -- rows 1–10
```

- `LIMIT n` → return at most `n` rows
- `OFFSET m` → skip the first `m` rows

Page `p` with page size `s` → `LIMIT s OFFSET (p-1)*s`. Page 1 = `OFFSET 0`, page 2 = `OFFSET s`, and so on.

## 14. Filtering rows (WHERE)

```sql
-- AND: both conditions must be true
SELECT * FROM students WHERE student_id = 1 AND student_name = "Linda Patel";

-- OR: either condition is enough
SELECT * FROM students WHERE student_id = 1 OR student_name = "fjhfjoer";

-- IN: student_id matches any value in the list
SELECT * FROM students WHERE student_id IN (1, 23, 3, 4, 5);

-- NOT IN: everything EXCEPT the listed values
SELECT * FROM students WHERE student_id NOT IN (1, 2, 3, 4);

-- LIKE: pattern match on a string (exact match here)
SELECT * FROM students WHERE student_email LIKE "linda.patel1@hotmail.com";
```

> `LIKE` is usually paired with `%` wildcards — e.g. `LIKE 'linda%'` matches any email starting with `linda`. In this lecture we used it as an exact match.

---

## Final table structure (`DESC students`)

| Field | Type | Null | Key | Default | Extra |
|---|---|---|---|---|---|
| student_id | int | NO | PRI | null | auto_increment |
| student_name | varchar(50) | NO | | null | |
| student_age | int | YES | | null | |
| student_address | varchar(100) | YES | | null | |
| student_email | varchar(50) | NO | UNI | null | |
| student_gender | varchar(20) | YES | | null | |
| student_contact | varchar(25) | YES | | null | |
| student_is_active | tinyint(1) | YES | | 1 | |

## Commands Summary

| Command | What it does |
|---|---|
| `SHOW DATABASES` | List all databases |
| `CREATE DATABASE name` | Create a new database |
| `USE name` | Select a database to work in |
| `CREATE TABLE ...` | Create a new table |
| `SHOW TABLES` | List tables in current database |
| `DESC table` | Show table structure |
| `DROP TABLE table` | Delete the entire table (structure + data) |
| `TRUNCATE TABLE table` | Delete all rows, keep the structure |
| `ALTER TABLE ... ADD` | Add a new column |
| `ALTER TABLE ... RENAME COLUMN` | Rename a column |
| `ALTER TABLE ... DROP COLUMN` | Delete a column |
| `ALTER TABLE ... MODIFY COLUMN` | Change a column's definition |
| `RENAME TABLE a TO b` | Rename a table |
| `INSERT INTO table(...) VALUES(...)` | Add row(s) — one or many |
| `SELECT cols / * FROM table` | Read rows from a table |
| `WHERE` + `AND` / `OR` | Filter rows on conditions |
| `IN` / `NOT IN` | Match (or exclude) a list of values |
| `LIKE` | Pattern-match a string column |
| `ORDER BY col [DESC]` | Sort the result |
| `LIMIT n OFFSET m` | Pagination — take n rows after skipping m |
