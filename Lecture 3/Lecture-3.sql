USE pal_india;

SHOW TABLES;

DESC students;

SELECT * FROM students;

UPDATE students SET student_name="Linda Hernandez" WHERE student_id=1;

SELECT * FROM students;

ALTER TABLE students MODIFY createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE students MODIFY updateAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;

DESC students;

UPDATE students SET student_name="Puja Tomar" WHERE student_id=2;

SELECT * FROM students;

SELECT COUNT(student_age) from students;

SELECT COUNT(student_age) as age from students;

SELECT SUM(student_age) as age FROM students;

SELECT AVG(student_age) as average_age FROM students;

SELECT MIN(student_age) FROM students;

SELECT MAX(student_age) FROM students;

SELECT * FROM students WHERE student_age=22 GROUP BY student_age,student_id HAVING COUNT(student_age) > 0;

use pal_india;

SELECT student_age, ANY_VALUE(student_name), ANY_VALUE(student_id) FROM students GROUP BY student_age HAVING COUNT(*) > 0;

SELECT student_age, student_name, student_id FROM students GROUP BY student_age,student_name,student_id HAVING COUNT(*) > 0;

SELECT * FROM students WHERE student_age IN( SELECT student_age FROM students GROUP BY student_age HAVING COUNT(*) > 0);

SELECT * FROM students WHERE student_age IN( SELECT student_age FROM students GROUP BY student_age HAVING COUNT(*) > 5);

SELECT * FROM students WHERE student_name LIKE "%Pine%" AND student_address LIKE "%linda%" OR student_email LIKE "%melissa%";

SELECT * FROM students WHERE student_id BETWEEN 1 AND 15;

SELECT * FROM students WHERE student_id BETWEEN 14 AND 30;

SELECT * FROM students WHERE student_id NOT BETWEEN 14 AND 30;

SELECT * FROM students WHERE student_age BETWEEN 16 AND 22 ORDER BY student_id DESC;

SELECT * FROM students WHERE student_age BETWEEN 16 AND 22 ORDER BY student_name DESC , student_id DESC;

SELECT * FROM students WHERE student_age BETWEEN 16 AND 22 ORDER BY student_name DESC , student_id DESC LIMIT 10 OFFSET 0;

CREATE VIEW arbaz AS
(
SELECT * FROM students
);

SELECT * FROM arbaz;

SHOW PROCEDURE STATUS WHERE Db = 'pal_india';
