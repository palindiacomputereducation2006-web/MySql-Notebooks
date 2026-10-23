use pal_india;

SHOW DATABASES;

SHOW TABLES;

SELECT * FROM arbaz;

EXPLAIN arbaz;

SHOW FULL TABLES WHERE Table_type='VIEW';

CREATE VIEW student_search AS (
    SELECT * FROM students WHERE student_name LIKE '%linda%'
);

SHOW FULL TABLES WHERE table_type='VIEW';

SELECT * FROM student_search;

DROP VIEW arbaz;

CREATE VIEW select_students AS (
    SELECT * FROM students WHERE student_age IN(
    SELECT student_age FROM students GROUP BY student_age HAVING COUNT(*) > 1
    )
);

SHOW FULL TABLES WHERE table_type='VIEW';

SHOW FULL TABLES;

SELECT * FROM student_search;

SELECT * FROM select_students;

SELECT * FROM select_students ORDER BY student_name DESC,student_id ASC;

SELECT * FROM students WHERE student_age LIKE 22;

EXPLAIN SELECT * FROM students WHERE student_age LIKE 22;

CREATE UNIQUE INDEX idx_search_name ON students (student_age,student_email,student_name);

SHOW FULL TABLES;

SHOW INDEX FROM students;

SELECT * FROM students WHERE student_age like 22;

SELECT * FROM students WHERE student_age like '%22';

EXPLAIN ANALYZE SELECT * FROM students WHERE student_age like '%22';

CREATE TABLE addresses (
    address_id   INT PRIMARY KEY AUTO_INCREMENT,
    student_id   INT NOT NULL,
    address_type ENUM("Home", "Hostel", "Office", "Permanent") NOT NULL,
    street       VARCHAR(150),
    city         VARCHAR(50) NOT NULL,
    state        VARCHAR(50),
    pincode      VARCHAR(10),
    createdAt    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updateAt     TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

ALTER TABLE addresses
MODIFY student_id INT NOT NULL,
ADD CONSTRAINT fk_address_student FOREIGN KEY (student_id)
REFERENCES students(student_id) ON DELETE CASCADE;

DESC addresses;

INSERT INTO addresses (student_id, address_type, street, city, state, pincode) VALUES
(1,  "Home",      "12 MG Road",            "Indore",    "Madhya Pradesh", "452001"),
(1,  "Hostel",    "Block B, Room 204",     "Bhopal",    "Madhya Pradesh", "462001"),
(1,  "Office",    "Tech Park, Tower 3",    "Pune",      "Maharashtra",    "411057"),
(2,  "Home",      "45 Civil Lines",        "Jaipur",    "Rajasthan",      "302006"),
(2,  "Permanent", "Village Rampura",       "Ajmer",     "Rajasthan",      "305001"),
(5,  "Home",      "8 Park Street",         "Kolkata",   "West Bengal",    "700016"),
(7,  "Home",      "221 Sector 15",         "Noida",     "Uttar Pradesh",  "201301"),
(7,  "Hostel",    "PG near Metro Station", "Delhi",     "Delhi",          "110001"),
(10, "Home",      "3 Anna Salai",          "Chennai",   "Tamil Nadu",     "600002"),
(12, "Home",      "77 Banjara Hills",      "Hyderabad", "Telangana",      "500034"),
(22, "Home",      "5 FC Road",             "Pune",      "Maharashtra",    "411004"),
(22, "Office",    "Magarpatta City",       "Pune",      "Maharashtra",    "411013"),
(44, "Home",      "19 Residency Road",     "Bengaluru", "Karnataka",      "560025"),
(101, "Home",     "60 Vijay Nagar",        "Indore",    "Madhya Pradesh", "452010");

SELECT * from addresses;

SELECT * FROM students
INNER JOIN addresses
ON students.student_id=addresses.student_id;

SELECT s.student_id,s.student_name,s.student_age,s.student_email,a.street,a.city,a.student_id FROM students AS s
INNER JOIN addresses as a
ON s.student_id=a.student_id;

SELECT s.student_id,s.student_name,s.student_age,s.student_email,a.street,a.city,a.student_id FROM students AS s
LEFT JOIN addresses as a
ON s.student_id=a.student_id;

SELECT s.student_id,s.student_name,s.student_age,s.student_email,a.street,a.city,a.student_id FROM students AS s
RIGHT JOIN addresses as a
ON s.student_id=a.student_id;

SELECT s.student_id,s.student_name,s.student_age,s.student_email,a.street,a.city,a.student_id FROM students AS s
LEFT JOIN addresses as a
ON s.student_id=a.student_id
UNION
SELECT s.student_id,s.student_name,s.student_age,s.student_email,a.street,a.city,a.student_id FROM students AS s
RIGHT JOIN addresses as a
ON s.student_id=a.student_id;

SELECT * FROM students CROSS JOIN addresses;

SELECT COUNT(*) FROM students;
