SHOW DATABASES;

CREATE DATABASE pal_india;

SHOW DATABASES;

use pal_india;

CREATE TABLE students(
    student_id INT PRIMARY KEY UNIQUE NOT NULL AUTO_INCREMENT,
    student_name VARCHAR(50) NOT NULL,
    student_age INT NULL,
    student_address VARCHAR(100) NULL,
    student_email VARCHAR(50) NOT NULL,
    student_gender VARCHAR(20) NULL,
    student_contact VARCHAR(25)
);

SHOW TABLES;

DESC students;

DROP TABLE students;

SHOW TABLES;

DESC students;

ALTER TABLE students ADD is_active BOOLEAN DEFAULT TRUE;

DESC students;

ALTER TABLE students RENAME COLUMN is_active TO student_is_active;

DESC students;

ALTER TABLE students ADD x VARCHAR(12);

DESC students;

ALTER TABLE students DROP COLUMN x;

DESC students;

RENAME TABLE students TO students;

SHOW TABLES;

ALTER TABLE students  MODIFY COLUMN student_email VARCHAR(50) UNIQUE NOT NULL;

DESC students;

SHOW TABLES;

INSERT INTO students(student_name,student_age,student_address,student_email,student_gender,student_contact)
VALUES("arif",16,"dharavi","arif@gmail.com","Male","+9132534546");

SELECT * FROM students;

-- 500 sample rows for students (5 batches of 100)
INSERT INTO students (student_name, student_age, student_address, student_email, student_gender, student_contact) VALUES
('Linda Patel', 20, '8945 Maple Dr, Houston, TX 87397', 'linda.patel1@hotmail.com', NULL, '+1-438-717-1434'),
('Pooja Turner', 26, '2625 Highland Ave, New York, NY 65392', 'pooja.turner2@outlook.com', 'Female', '+1-981-544-2674'),
('Mark Rivera', 26, '7537 2nd St, Los Angeles, CA 26361', 'mark.rivera3@hotmail.com', 'Male', '+1-843-833-6925'),
('Sarah Garcia', 29, '3824 Cedar Ln, Chicago, IL 59823', 'sarah.garcia4@outlook.com', 'Female', '+1-366-579-6820'),
('Frank Hughes', 27, NULL, 'frank.hughes5@student.edu', 'Male', '+1-367-673-7216'),
('Mustafa Lewis', 30, '3762 Oak Ave, Los Angeles, CA 51347', 'mustafa.lewis6@hotmail.com', 'Male', '+1-780-935-6155'),
('Rohan Gomez', 27, '2297 Lake Rd, Dallas, TX 83579', 'rohan.gomez7@university.edu', 'Male', '+1-797-608-6930'),
('Brian Rogers', 29, NULL, 'brian.rogers8@gmail.com', 'Male', '+1-896-632-2040'),
('Aiden Ortiz', 25, '1886 Spring St, New York, NY 80381', 'aiden.ortiz9@mail.com', 'Male', '+1-314-500-8123'),
('James Castillo', 21, '8327 Cedar Ln, Philadelphia, PA 91959', 'james.castillo10@outlook.com', 'Male', '+1-403-356-7126'),
('Pooja Sharma', 17, '329 Cedar Ln, Portland, OR 57576', 'pooja.sharma11@mail.com', 'Female', '+1-446-780-2290'),
('Aman Yilmaz', 29, '2113 Spring St, Phoenix, AZ 72296', 'aman.yilmaz12@university.edu', 'Male', '+1-821-633-4470'),
('Sharon Alvarez', 27, '8489 High St, Miami, FL 25860', 'sharon.alvarez13@yahoo.com', 'Female', '+1-802-767-4770'),
('Mary Martinez', 17, '5423 Maple Dr, Los Angeles, CA 77391', 'mary.martinez14@yahoo.com', 'Female', '+1-752-335-8744'),
('Arjun Verma', 18, '5814 Church St, Atlanta, GA 63883', 'arjun.verma15@hotmail.com', 'Male', '+1-869-861-2612'),
('Aaron Gupta', 20, '7360 Pine St, Detroit, MI 65296', 'aaron.gupta16@yahoo.com', 'Male', '+1-277-653-2604'),
('Mehmet Sahin', NULL, '2734 Church St, San Diego, CA 73653', 'mehmet.sahin17@hotmail.com', 'Male', '+1-260-368-7209'),
('Zachary King', 29, '9115 Spring St, Atlanta, GA 73788', 'zachary.king18@yahoo.com', 'Male', '+1-259-793-9883'),
('Dennis Davis', NULL, '2589 Oak Ave, Nashville, TN 76562', 'dennis.davis19@gmail.com', 'Male', '+1-269-891-4853'),
('Emre Young', 17, '9572 3rd Ave, Atlanta, GA 78522', 'emre.young20@outlook.com', 'Male', '+1-933-521-4910'),
('Kevin Bennett', 24, '162 High St, Chicago, IL 91416', 'kevin.bennett21@university.edu', 'Male', '+1-418-718-5345'),
('Henry Rodriguez', 22, '8910 Highland Ave, Miami, FL 49651', 'henry.rodriguez22@university.edu', 'Male', '+1-741-208-5905'),
('Sandra Moore', 18, '4472 River Rd, Phoenix, AZ 89276', 'sandra.moore23@yahoo.com', 'Female', '+1-849-470-9280'),
('Richard Lopez', 30, '5474 Ridge Rd, New York, NY 27146', 'richard.lopez24@student.edu', 'Male', '+1-652-764-8007'),
('Ashley Martinez', 28, '600 Washington St, Detroit, MI 86350', 'ashley.martinez25@university.edu', 'Female', '+1-515-573-1653'),
('Laura Mendoza', 18, '6668 Willow Way, Detroit, MI 30257', 'laura.mendoza26@yahoo.com', 'Female', '+1-381-622-1406'),
('Tyler Singh', 29, '4381 Elm St, San Diego, CA 24168', 'tyler.singh27@hotmail.com', 'Male', '+1-427-404-8541'),
('Justin Lewis', NULL, '4574 Maple Dr, Seattle, WA 46585', 'justin.lewis28@outlook.com', 'Male', '+1-749-539-1452'),
('Samuel Thompson', 21, NULL, 'samuel.thompson29@university.edu', 'Male', '+1-521-646-9379'),
('Burak Harris', 28, '8831 Spring St, Nashville, TN 97900', 'burak.harris30@yahoo.com', 'Male', '+1-880-538-6143'),
('Kimberly Castillo', 25, '5354 Lincoln Ave, Atlanta, GA 48752', 'kimberly.castillo31@university.edu', 'Female', '+1-588-893-3851'),
('Samantha Phillips', 17, '7053 3rd Ave, San Antonio, TX 89516', 'samantha.phillips32@student.edu', 'Female', '+1-891-418-9375'),
('Jason James', 25, '5501 Maple Dr, Columbus, OH 40784', 'jason.james33@student.edu', 'Male', '+1-350-225-1757'),
('Arjun Ward', 18, '3195 Highland Ave, Charlotte, NC 60328', 'arjun.ward34@hotmail.com', 'Male', '+1-904-205-2746'),
('Kathleen Thompson', 28, '9142 Lake Rd, Los Angeles, CA 25906', 'kathleen.thompson35@hotmail.com', 'Female', '+1-743-772-6198'),
('Joan Ward', 25, '7315 Elm St, Detroit, MI 72216', 'joan.ward36@hotmail.com', 'Female', '+1-852-483-9540'),
('Scott Scott', 28, '5512 Sunset Blvd, Dallas, TX 80798', 'scott.scott37@gmail.com', 'Male', '+1-910-356-4505'),
('Noah Nelson', 23, NULL, 'noah.nelson38@mail.com', 'Male', '+1-798-912-1320'),
('Ayse Carter', 22, '6875 2nd St, Boston, MA 81582', 'ayse.carter39@mail.com', 'Female', '+1-424-479-8140'),
('Zachary Baker', 29, '7667 Pine St, Philadelphia, PA 91560', 'zachary.baker40@university.edu', NULL, '+1-777-878-1444'),
('Lucas Moore', 19, NULL, 'lucas.moore41@hotmail.com', 'Male', '+1-545-979-7211'),
('Liam Allen', 24, NULL, 'liam.allen42@university.edu', 'Male', '+1-429-865-2124'),
('Barbara Long', NULL, '2506 Lake Rd, New York, NY 26544', 'barbara.long43@hotmail.com', 'Female', '+1-423-676-5198'),
('Melissa Cox', 28, '5106 Cedar Ln, Philadelphia, PA 85849', 'melissa.cox44@gmail.com', 'Female', '+1-584-606-4249'),
('Brandon Wilson', 21, '1993 3rd Ave, Columbus, OH 15383', 'brandon.wilson45@outlook.com', 'Male', '+1-270-718-6590'),
('Liam Kaya', 23, '2516 Church St, Miami, FL 33086', 'liam.kaya46@student.edu', 'Male', '+1-830-751-8921'),
('Kerem Wright', 20, '4579 High St, Chicago, IL 41963', 'kerem.wright47@mail.com', 'Male', '+1-588-544-1470'),
('Jerry White', 22, '4591 Willow Way, Seattle, WA 46211', 'jerry.white48@university.edu', NULL, '+1-287-447-7658'),
('Scott Ruiz', 28, '1534 River Rd, New York, NY 39045', 'scott.ruiz49@hotmail.com', 'Male', '+1-795-577-8753'),
('Janet Diaz', 25, '4448 River Rd, Miami, FL 42951', 'janet.diaz50@yahoo.com', 'Female', '+1-322-960-9779'),
('Stephanie Harris', 24, '8605 Willow Way, Charlotte, NC 47093', 'stephanie.harris51@gmail.com', 'Female', '+1-569-383-5952'),
('Ravi Taylor', 17, '8052 Cedar Ln, Phoenix, AZ 11607', 'ravi.taylor52@university.edu', 'Male', '+1-548-388-1841'),
('Rahul Anderson', 23, '888 Pine St, Charlotte, NC 29555', 'rahul.anderson53@mail.com', 'Male', '+1-454-321-7818'),
('Kathleen Sharma', 24, '9652 Church St, Austin, TX 50026', 'kathleen.sharma54@university.edu', 'Female', '+1-957-301-4404'),
('Brenda James', 20, '2574 Main St, Chicago, IL 63545', 'brenda.james55@hotmail.com', 'Female', '+1-233-437-5720'),
('Judith Martinez', 21, '3251 Church St, Charlotte, NC 25043', 'judith.martinez56@university.edu', 'Female', '+1-472-345-2169'),
('Jack Kim', 26, '2047 High St, Miami, FL 49857', 'jack.kim57@student.edu', 'Male', '+1-752-705-8172'),
('William Parker', 26, '3760 Spring St, Chicago, IL 85392', 'william.parker58@university.edu', 'Male', '+1-888-475-1659'),
('Deborah Stewart', 24, '9600 Church St, Philadelphia, PA 93202', 'deborah.stewart59@mail.com', 'Female', '+1-556-618-6460'),
('Steven Lee', 28, '9022 Oak Ave, Boston, MA 69614', 'steven.lee60@gmail.com', 'Male', '+1-991-613-9431'),
('Mary James', 24, '8504 Washington St, San Antonio, TX 91609', 'mary.james61@mail.com', 'Female', '+1-252-408-5375'),
('Nicole Cruz', 24, '3930 Highland Ave, Columbus, OH 30758', 'nicole.cruz62@outlook.com', 'Female', '+1-295-430-2858'),
('Andrew Chavez', 24, '8347 Highland Ave, Austin, TX 45838', 'andrew.chavez63@hotmail.com', 'Male', '+1-449-667-3369'),
('Karan Myers', 30, NULL, 'karan.myers64@mail.com', 'Male', '+1-719-473-1042'),
('Patrick Sahin', 27, '7326 2nd St, Phoenix, AZ 73483', 'patrick.sahin65@outlook.com', 'Male', '+1-586-666-6272'),
('Angela Kelly', 30, '5223 Meadow Ln, Los Angeles, CA 71993', 'angela.kelly66@student.edu', 'Female', '+1-879-867-3492'),
('David Taylor', 26, '7223 Cedar Ln, Houston, TX 78937', 'david.taylor67@hotmail.com', NULL, '+1-870-358-2225'),
('Samuel Baker', 23, '8752 Lincoln Ave, Seattle, WA 51505', 'samuel.baker68@student.edu', 'Male', '+1-754-236-2121'),
('Raymond Robinson', 23, '7279 Elm St, Houston, TX 49251', 'raymond.robinson69@gmail.com', NULL, '+1-500-567-7141'),
('Brandon Ortiz', 27, '2878 Maple Dr, Philadelphia, PA 89887', 'brandon.ortiz70@mail.com', 'Male', '+1-709-797-3344'),
('Benjamin Collins', 17, '4722 Spring St, Miami, FL 81643', 'benjamin.collins71@yahoo.com', 'Male', '+1-801-506-7951'),
('Judith Celik', 23, '3896 Lincoln Ave, Houston, TX 84963', 'judith.celik72@outlook.com', 'Female', '+1-502-222-7484'),
('Emre Mendoza', 17, '4699 Ridge Rd, Portland, OR 40162', 'emre.mendoza73@university.edu', 'Male', '+1-394-835-5106'),
('Donna Watson', 27, '7232 Oak Ave, Austin, TX 85965', 'donna.watson74@outlook.com', 'Female', '+1-502-534-7807'),
('Kevin Singh', 22, '2705 Hill St, Dallas, TX 73156', 'kevin.singh75@mail.com', 'Male', '+1-317-679-2233'),
('Larry Gray', 23, '6002 Maple Dr, Detroit, MI 61717', 'larry.gray76@gmail.com', 'Male', '+1-577-888-5295'),
('Heather Wilson', 24, NULL, 'heather.wilson77@university.edu', 'Female', '+1-863-264-8606'),
('Samantha Wood', 19, NULL, 'samantha.wood78@gmail.com', 'Female', '+1-299-440-9807'),
('Levi Mitchell', 28, '6876 3rd Ave, Detroit, MI 30253', 'levi.mitchell79@hotmail.com', 'Male', '+1-830-617-5583'),
('Nathan Ramirez', 20, '6028 2nd St, Houston, TX 94518', 'nathan.ramirez80@outlook.com', 'Male', '+1-325-665-2501'),
('Merve Williams', NULL, '9260 Park Ave, Phoenix, AZ 18992', 'merve.williams81@mail.com', 'Female', '+1-421-438-6383'),
('Merve Smith', 19, '4116 Elm St, Detroit, MI 24408', 'merve.smith82@student.edu', 'Female', '+1-566-443-6304'),
('Samuel Miller', 23, '7812 High St, Chicago, IL 57453', 'samuel.miller83@university.edu', 'Male', '+1-426-829-1710'),
('Priya Hill', 17, NULL, 'priya.hill84@hotmail.com', 'Female', '+1-310-702-8267'),
('Matthew Adams', 18, '9600 2nd St, Columbus, OH 52622', 'matthew.adams85@hotmail.com', 'Male', '+1-664-717-8048'),
('Paul Wood', 29, '7056 High St, San Antonio, TX 39949', 'paul.wood86@hotmail.com', 'Male', '+1-625-947-2557'),
('Dennis Bennett', 19, '1109 Maple Dr, Portland, OR 21188', 'dennis.bennett87@gmail.com', 'Male', '+1-581-333-1982'),
('Sneha Bailey', 18, '852 River Rd, Atlanta, GA 88696', 'sneha.bailey88@outlook.com', 'Female', '+1-417-358-8900'),
('Steven Hall', 22, '9416 Lake Rd, Dallas, TX 66244', 'steven.hall89@mail.com', 'Male', '+1-836-828-1430'),
('Pamela Brown', 28, '5761 Main St, Seattle, WA 33777', 'pamela.brown90@mail.com', 'Female', '+1-271-345-1502'),
('Sanjay Ramirez', 24, '5115 Meadow Ln, Denver, CO 52517', 'sanjay.ramirez91@mail.com', 'Male', '+1-253-359-3579'),
('Susan Gray', 24, '9956 High St, Portland, OR 64287', 'susan.gray92@outlook.com', 'Female', '+1-553-640-2816'),
('Kerem Morales', 21, NULL, 'kerem.morales93@hotmail.com', 'Male', '+1-409-508-4460'),
('Anna Nguyen', 17, '2888 Pine St, Atlanta, GA 59834', 'anna.nguyen94@university.edu', 'Female', '+1-884-562-2180'),
('William Parker', NULL, '9443 Church St, Seattle, WA 85156', 'william.parker95@hotmail.com', 'Male', '+1-317-614-1341'),
('Melissa Gupta', 24, '1453 Church St, Denver, CO 23875', 'melissa.gupta96@yahoo.com', 'Female', '+1-280-605-6083'),
('Kathleen Nelson', 18, '8703 Broadway, Houston, TX 35415', 'kathleen.nelson97@mail.com', 'Female', '+1-860-351-4871'),
('Benjamin Sanchez', 19, '2912 Ridge Rd, Chicago, IL 92306', 'benjamin.sanchez98@hotmail.com', 'Male', '+1-793-659-6295'),
('Christine Martin', 24, '4510 3rd Ave, Austin, TX 17362', 'christine.martin99@outlook.com', 'Female', '+1-662-238-1932'),
('Raymond Martinez', 30, '8317 Lincoln Ave, Columbus, OH 70648', 'raymond.martinez100@university.edu', 'Male', '+1-242-660-4084');

TRUNCATE TABLE students;

SELECT * FROM students;

SELECT student_id,student_name,student_age FROM students;

SELECT student_id,student_name,student_age FROM students LIMIT 20 OFFSET 0;

SELECT * FROM students LIMIT 10 OFFSET 0;

SELECT * FROM students ORDER BY student_id DESC LIMIT 10 OFFSET 0;

SELECT * FROM students WHERE student_id=1 AND student_name="Linda Patel";

SELECT * FROM students WHERE student_id=1 OR student_name="fjhfjoer";

SELECT * FROM students WHERE student_id NOT IN(1,2,3,4);

SELECT * FROM students WHERE student_id IN (1,23,3,4,5,5,43,21,22);

SELECT * FROM students WHERE student_email LIKE "linda.patel1@hotmail.com";
