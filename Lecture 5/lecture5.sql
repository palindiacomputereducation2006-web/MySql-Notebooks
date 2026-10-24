show databases;

use pal_india;

show tables;

select * from students
inner join addresses on students.student_id = addresses.student_id;

select students.student_id, students.student_name, students.student_age,addresses.city, addresses.state,addresses.student_id,
IFNULL(students.student_gender,"NOT SELECTED") as student_gender
from students 
INNER JOIN addresses ON students.student_id = addresses.student_id;

select students.student_id, students.student_name, students.student_age,
IFNULL(students.student_gender,"NOT SELECTED") as student_gender
from students 

WITH studentData AS(
    select students.student_id, students.student_name,students.student_gender ,students.student_age,addresses.city, addresses.state
    from students 
    INNER JOIN addresses ON students.student_id = addresses.student_id
)
select * from studentData
where student_gender = "FEMALE" OR city = "MAHARASHATRA" OR state = "PUNE";


use pal_india;

CREATE TABLE marks (
    mark_id    INT PRIMARY KEY AUTO_INCREMENT,
    student_id INT NOT NULL,
    subject    VARCHAR(30) NOT NULL,
    score      INT NULL,                       -- NULL = student was absent
    FOREIGN KEY (student_id) REFERENCES students(student_id)
);

INSERT INTO marks (student_id, subject, score) VALUES
(1,  'Maths', 85),   (1,  'Science', 72),   (1,  'English', NULL), (1,  'History', 64),   (1,  'Computer', 90),
(2,  'Maths', 45),   (2,  'Science', NULL), (2,  'English', 91),   (2,  'History', 58),   (2,  'Computer', 77),
(3,  'Maths', 30),   (3,  'Science', 55),   (3,  'English', 68),   (3,  'History', 42),   (3,  'Computer', 61),
(4,  'Maths', 95),   (4,  'Science', 88),   (4,  'English', 79),   (4,  'History', 92),   (4,  'Computer', 98),
(5,  'Maths', NULL), (5,  'Science', 40),   (5,  'English', 33),   (5,  'History', 28),   (5,  'Computer', 51),
(6,  'Maths', 67),   (6,  'Science', 74),   (6,  'English', 81),   (6,  'History', 70),   (6,  'Computer', 85),
(7,  'Maths', 22),   (7,  'Science', 35),   (7,  'English', 48),   (7,  'History', NULL), (7,  'Computer', 39),
(8,  'Maths', 99),   (8,  'Science', 94),   (8,  'English', 87),   (8,  'History', 90),   (8,  'Computer', 96),
(9,  'Maths', 56),   (9,  'Science', 61),   (9,  'English', 59),   (9,  'History', 47),   (9,  'Computer', NULL),
(10, 'Maths', 78),   (10, 'Science', 82),   (10, 'English', 75),   (10, 'History', 69),   (10, 'Computer', 88),
(11, 'Maths', 34),   (11, 'Science', 29),   (11, 'English', 41),   (11, 'History', 37),   (11, 'Computer', 45),
(12, 'Maths', 88),   (12, 'Science', NULL), (12, 'English', 93),   (12, 'History', 84),   (12, 'Computer', 79),
(13, 'Maths', 61),   (13, 'Science', 57),   (13, 'English', 66),   (13, 'History', 72),   (13, 'Computer', 70),
(14, 'Maths', 47),   (14, 'Science', 52),   (14, 'English', 38),   (14, 'History', 33),   (14, 'Computer', 60),
(15, 'Maths', 92),   (15, 'Science', 89),   (15, 'English', 95),   (15, 'History', 97),   (15, 'Computer', 91),
(16, 'Maths', 15),   (16, 'Science', 27),   (16, 'English', NULL), (16, 'History', 31),   (16, 'Computer', 24),
(17, 'Maths', 73),   (17, 'Science', 68),   (17, 'English', 80),   (17, 'History', 77),   (17, 'Computer', 82),
(18, 'Maths', 50),   (18, 'Science', 49),   (18, 'English', 55),   (18, 'History', 61),   (18, 'Computer', 58),
(19, 'Maths', 83),   (19, 'Science', 91),   (19, 'English', 76),   (19, 'History', NULL), (19, 'Computer', 87),
(20, 'Maths', 39),   (20, 'Science', 44),   (20, 'English', 36),   (20, 'History', 50),   (20, 'Computer', 42)

select * from marks;

Select s.*,
        m.mark_id, m.subject, m.score,
        CASE 
            when m.score >= 90 then 'A'
            when m.score >= 80 then 'B'
            when m.score >= 70 then 'C'
            when m.score >= 60 then 'D'
            when m.score >= 50 then 'E'
            when m.score is null then 'ABSENT'
            else 'F'
        end as grade
    From students s left join marks as m on s.student_id = m.student_id
