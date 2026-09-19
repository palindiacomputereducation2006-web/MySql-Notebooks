# MySQL Lecture 1 — Databases & Tables (DDL Commands)

In this lecture we created our own database, built a table inside it, and practiced all the main **DDL (Data Definition Language)** commands.

## What this lecture covers

| Family | Commands practiced |
|--------|--------------------|
| Navigation | `SHOW DATABASES`, `USE`, `SHOW TABLES`, `DESC` |
| DDL | `CREATE TABLE`, `ALTER TABLE ... ADD`, `TRUNCATE TABLE`, `DROP TABLE` |
| DML | `INSERT` (single row + multi-row), `SELECT`, `UPDATE`, `DELETE` |

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
CREATE TABLE student_details(
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
DESC student_details;    -- shows the table structure
```

`DESC` (DESCRIBE) shows each column's **Field, Type, Null, Key, Default, Extra**.

## 6. Deleting a table

```sql
DROP TABLE student_details;
```

Removes the whole table — structure **and** data. (We re-created the table afterward to continue practicing.)

## 7. ALTER TABLE — changing an existing table

### Add a new column
```sql
ALTER TABLE student_details ADD is_active BOOLEAN DEFAULT TRUE;
```
> Note: MySQL stores `BOOLEAN` as `tinyint(1)` — 1 = true, 0 = false.

### Rename a column
```sql
ALTER TABLE student_details RENAME COLUMN is_active TO student_is_active;
```

### Add a temporary column (for practice)
```sql
ALTER TABLE student_details ADD x VARCHAR(12);
```

### Remove a column
```sql
ALTER TABLE student_details DROP COLUMN x;
```

### Modify a column (adding UNIQUE to the email)
```sql
ALTER TABLE students MODIFY COLUMN student_email VARCHAR(50) UNIQUE NOT NULL;
```

After this, `DESC` shows **UNI** in the Key column for `student_email` — meaning no two students can have the same email.

## 8. Renaming a table

```sql
RENAME TABLE student_details TO students;
SHOW TABLES;   -- now shows: students
```

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
| `DROP TABLE table` | Delete the entire table |
| `ALTER TABLE ... ADD` | Add a new column |
| `ALTER TABLE ... RENAME COLUMN` | Rename a column |
| `ALTER TABLE ... DROP COLUMN` | Delete a column |
| `ALTER TABLE ... MODIFY COLUMN` | Change a column's definition |
| `RENAME TABLE a TO b` | Rename a table |
