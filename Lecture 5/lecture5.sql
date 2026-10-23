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
