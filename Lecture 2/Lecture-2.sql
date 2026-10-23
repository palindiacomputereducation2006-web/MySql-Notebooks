SHOW DATABASES;

USE pal_india;

SHOW TABLES;

SELECT * FROM pal_india;

SHOW TABLES;

SELECT * FROM students LIMIT 10 OFFSET 0;

SELECT * FROM students LIMIT 10 OFFSET 10;

SELECT * FROM students LIMIT 10 OFFSET 20;

SELECT * FROM students LIMIT 10 OFFSET 90;

SELECT * FROM students LIMIT 10 OFFSET 0;

SELECT * FROM students LIMIT 7 OFFSET 10;

SELECT * FROM students ORDER BY student_name ASC ,student_age DESC;

SELECT * FROM students ORDER BY student_age ASC ,student_id ASC;

SELECT * FROM students as student_details;

SHOW TABLES;

SELECT student_id as id, student_name as name FROM students;

SELECT * FROM students WHERE student_name LIKE "%Z" ORDER BY student_name DESC;
