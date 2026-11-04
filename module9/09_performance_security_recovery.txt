-- =====================================================================
-- 08_performance_security_recovery.sql
-- Course 4: Structured Databases | Module 9: Performance, Security and Recovery
-- Project: future_portfolio_db
--
-- Part A  PQ01-PQ08  Performance: a million practice rows, EXPLAIN, indexes
-- Part B  SEC01-SEC07 Security: least privilege, a read-only web user,
--                     prepared statements against SQL injection
-- Part C  REC01-REC05 Recovery: back up, restore into a copy, compare
--
-- HOW TO RUN: one statement at a time (Ctrl+Enter). Some statements fail
-- on purpose (error 1142), and Part C uses the command line or the
-- Workbench Data Export / Data Import screens.
--
-- Start state: the course-standard rebuild 01 -> 02 -> 02a -> 03 -> 06.
-- End state:   the course data is unchanged. Part A's practice tables are
--              dropped at the end of Part A. Part B's two users stay on the
--              server (users are not inside the database, so a rebuild does
--              not remove them; re-run Part B's GRANTs after a rebuild).
-- This file is NOT part of the rebuild.
-- =====================================================================

USE future_portfolio_db;

-- =====================  A. PERFORMANCE  ===============================
-- One resume has 17 roles: every query is instant. A recruitment platform
-- holds roles for many candidates. candidate_roles is synthetic practice
-- data: 100,000 candidates x 10 roles = 1,000,000 rows.

-- ---------------------------------------------------------------------
-- PQ01. Build the practice table (takes up to a minute)
-- Expected: digits 10 rows; candidate_roles 1,000,000 rows
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS candidate_roles;
DROP TABLE IF EXISTS digits;

CREATE TABLE digits (d TINYINT PRIMARY KEY);
INSERT INTO digits VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9);

CREATE TABLE candidate_roles (
    row_id       INT AUTO_INCREMENT PRIMARY KEY,
    candidate_id INT          NOT NULL,
    role_title   VARCHAR(100) NOT NULL,
    start_year   SMALLINT     NOT NULL,
    team_size    INT          NOT NULL,
    city         VARCHAR(40)  NOT NULL
);

INSERT INTO candidate_roles (candidate_id, role_title, start_year, team_size, city)
SELECT n DIV 10 + 1,
       ELT(n % 8 + 1, 'Software Engineer', 'Senior Software Engineer', 'Technical Lead',
                      'Engineering Manager', 'Director of Engineering',
                      'Vice President of Engineering', 'Chief Technology Officer',
                      'Data Engineer'),
       1981 + n % 45,
       (n * 7) % 2000 + 1,
       ELT(n % 5 + 1, 'Bengaluru', 'Hyderabad', 'Chennai', 'Pune', 'Tirupati')
FROM (SELECT a.d + 10 * b.d + 100 * c.d + 1000 * e.d + 10000 * f.d + 100000 * g.d AS n
      FROM digits AS a CROSS JOIN digits AS b CROSS JOIN digits AS c
      CROSS JOIN digits AS e CROSS JOIN digits AS f CROSS JOIN digits AS g) AS numbers;

SELECT COUNT(*) FROM candidate_roles;                       -- 1000000

-- ---------------------------------------------------------------------
-- PQ02. One candidate's roles, with NO index on candidate_id
-- Practises: EXPLAIN; reading the Duration in the Output panel
-- Expected: 10 rows (2001-2010). EXPLAIN: type ALL, key NULL,
--           rows about 1,000,000 (an estimate): a full table scan
-- ---------------------------------------------------------------------
SELECT * FROM candidate_roles WHERE candidate_id = 4242;
EXPLAIN SELECT * FROM candidate_roles WHERE candidate_id = 4242;

-- ---------------------------------------------------------------------
-- PQ03. Add an index and ask again
-- Expected: same 10 rows; EXPLAIN: type ref,
--           key idx_candidate_roles_candidate, rows 10
-- ---------------------------------------------------------------------
CREATE INDEX idx_candidate_roles_candidate ON candidate_roles (candidate_id);

SELECT * FROM candidate_roles WHERE candidate_id = 4242;
EXPLAIN SELECT * FROM candidate_roles WHERE candidate_id = 4242;
EXPLAIN ANALYZE SELECT * FROM candidate_roles WHERE candidate_id = 4242;   -- actual time (MySQL 8.0.18+)

-- ---------------------------------------------------------------------
-- PQ04. Indexes the course tables already have
-- Expected: roles has PRIMARY (role_id) and fk_roles_employment
--           (employment_id): MySQL indexes every foreign key column.
--           EXPLAIN: type ref, key fk_roles_employment, rows 4
-- ---------------------------------------------------------------------
SHOW INDEX FROM roles;
EXPLAIN SELECT * FROM roles WHERE employment_id = 4;

-- ---------------------------------------------------------------------
-- PQ05. A composite index for a two-column question
-- Question: how many CTO roles started in 2020 or later?
-- Expected: 16666. Before the index: type ALL. After: type range,
--           key idx_candidate_roles_title_year
-- ---------------------------------------------------------------------
SELECT COUNT(*) FROM candidate_roles
WHERE role_title = 'Chief Technology Officer' AND start_year >= 2020;

EXPLAIN SELECT COUNT(*) FROM candidate_roles
WHERE role_title = 'Chief Technology Officer' AND start_year >= 2020;

CREATE INDEX idx_candidate_roles_title_year ON candidate_roles (role_title, start_year);

EXPLAIN SELECT COUNT(*) FROM candidate_roles
WHERE role_title = 'Chief Technology Officer' AND start_year >= 2020;

-- ---------------------------------------------------------------------
-- PQ06. Leftmost prefix: the composite index starts with role_title
-- Expected: 22222 roles started in 2020. EXPLAIN: the index can't be
--           used to find start_year alone (type ALL, or type index:
--           reading the whole index)
-- ---------------------------------------------------------------------
SELECT COUNT(*) FROM candidate_roles WHERE start_year = 2020;
EXPLAIN SELECT COUNT(*) FROM candidate_roles WHERE start_year = 2020;

-- ---------------------------------------------------------------------
-- PQ07. What stops an index: a leading wildcard
-- Expected: both 125000. 'Chief%' -> type range (index used);
--           '%Officer' -> no range search (type ALL or index)
-- ---------------------------------------------------------------------
SELECT COUNT(*) FROM candidate_roles WHERE role_title LIKE 'Chief%';
EXPLAIN SELECT COUNT(*) FROM candidate_roles WHERE role_title LIKE 'Chief%';

SELECT COUNT(*) FROM candidate_roles WHERE role_title LIKE '%Officer';
EXPLAIN SELECT COUNT(*) FROM candidate_roles WHERE role_title LIKE '%Officer';

-- ---------------------------------------------------------------------
-- PQ08. Indexes cost space (and slow down every INSERT and UPDATE)
-- Expected: index_mb is a large share of data_mb (exact sizes vary)
-- Then clean up: the practice tables are dropped.
-- ---------------------------------------------------------------------
ANALYZE TABLE candidate_roles;
SELECT table_name,
       ROUND(data_length  / 1024 / 1024, 1) AS data_mb,
       ROUND(index_length / 1024 / 1024, 1) AS index_mb
FROM information_schema.tables
WHERE table_schema = 'future_portfolio_db' AND table_name = 'candidate_roles';

DROP TABLE candidate_roles;
DROP TABLE digits;

-- =====================  B. SECURITY  ==================================
-- All week you have connected as root, who can do anything, including
-- DROP DATABASE. A web page must never connect as root.
-- Choose your OWN passphrase below. Never put a real password in a file
-- you commit to Git.

-- ---------------------------------------------------------------------
-- SEC01. Who am I?
-- Expected: root@localhost (or the lab account)
-- ---------------------------------------------------------------------
SELECT CURRENT_USER();

-- ---------------------------------------------------------------------
-- SEC02. A user for the portfolio web page
-- ---------------------------------------------------------------------
CREATE USER IF NOT EXISTS 'portfolio_web'@'localhost'
    IDENTIFIED BY 'Replace-With-Your-Own-Passphrase-1';

-- ---------------------------------------------------------------------
-- SEC03. Least privilege: SELECT on the four views the page needs, nothing else
-- Expected: SHOW GRANTS lists USAGE plus four SELECT grants
-- ---------------------------------------------------------------------
GRANT SELECT ON future_portfolio_db.v_experience      TO 'portfolio_web'@'localhost';
GRANT SELECT ON future_portfolio_db.v_awards_section  TO 'portfolio_web'@'localhost';
GRANT SELECT ON future_portfolio_db.v_skill_evidence  TO 'portfolio_web'@'localhost';
GRANT SELECT ON future_portfolio_db.v_career_summary  TO 'portfolio_web'@'localhost';

SHOW GRANTS FOR 'portfolio_web'@'localhost';

-- ---------------------------------------------------------------------
-- SEC04. Test it: open a NEW Workbench connection as portfolio_web,
-- then run these there.
-- Expected: the two view queries work; the other three fail with 1142
-- ---------------------------------------------------------------------
-- [web] SELECT * FROM future_portfolio_db.v_career_summary;      -- 7 | 17 | 16 | 17 | 19 | 40.0000
-- [web] SELECT company, role, dates FROM future_portfolio_db.v_experience
--       ORDER BY start_date DESC LIMIT 3;                          -- 3 rows
-- [web] SELECT email FROM future_portfolio_db.people;              -- 1142 SELECT command denied
-- [web] SELECT * FROM future_portfolio_db.v_role_details;          -- 1142 (not granted)
-- [web] UPDATE future_portfolio_db.roles SET team_size = 1 WHERE role_id = 17;   -- 1142

-- ---------------------------------------------------------------------
-- SEC05. An editor: may read and change data, may not delete or drop
-- Expected: in an editor connection, DELETE and DROP fail with 1142
-- ---------------------------------------------------------------------
CREATE USER IF NOT EXISTS 'portfolio_editor'@'localhost'
    IDENTIFIED BY 'Replace-With-Your-Own-Passphrase-2';
GRANT SELECT, INSERT, UPDATE ON future_portfolio_db.* TO 'portfolio_editor'@'localhost';
SHOW GRANTS FOR 'portfolio_editor'@'localhost';

-- [editor] START TRANSACTION;
-- [editor] UPDATE future_portfolio_db.roles SET team_size = 1801 WHERE role_id = 17;   -- 1 row
-- [editor] ROLLBACK;
-- [editor] DELETE FROM future_portfolio_db.interests WHERE interest_id = 5;   -- 1142 DELETE denied
-- [editor] DROP TABLE future_portfolio_db.interests;                          -- 1142 DROP denied

-- ---------------------------------------------------------------------
-- SEC06. Take a privilege away
-- Expected: SHOW GRANTS shows SELECT, INSERT only
-- ---------------------------------------------------------------------
REVOKE UPDATE ON future_portfolio_db.* FROM 'portfolio_editor'@'localhost';
SHOW GRANTS FOR 'portfolio_editor'@'localhost';

-- ---------------------------------------------------------------------
-- SEC07. SQL injection, and the defence: parameters
-- A search box on the web page sends a company name. A user types:
--     ' OR '1'='1
-- Expected: safe (parameter) version 2 rows for NexaCollab, 0 rows for
--           the attack text; unsafe (text glued into SQL) version
--           returns all 17 rows
-- ---------------------------------------------------------------------
-- Safe: the value is passed as a parameter (?), never part of the SQL text
PREPARE find_roles FROM
    'SELECT company, role FROM v_experience WHERE company = ?';

SET @company = 'NexaCollab';
EXECUTE find_roles USING @company;                          -- 2 rows

SET @company = ''' OR ''1''=''1';                            -- the value: ' OR '1'='1
EXECUTE find_roles USING @company;                          -- 0 rows: just odd text
DEALLOCATE PREPARE find_roles;

-- Unsafe: the value is glued into the SQL text (NEVER do this in an app)
SET @sql = CONCAT('SELECT company, role FROM v_experience WHERE company = ''', @company, '''');
SELECT @sql;              -- ... WHERE company = '' OR '1'='1'
PREPARE unsafe FROM @sql;
EXECUTE unsafe;                                             -- 17 rows: the filter is gone
DEALLOCATE PREPARE unsafe;

-- =====================  C. RECOVERY  ==================================
-- Module 8's compensating transaction undid one known change. A backup
-- protects against everything else: a dropped table, a bad script, a
-- failed disk. A backup you have never restored is only a hope.

-- ---------------------------------------------------------------------
-- REC01. Back up (command line, NOT in Workbench's SQL editor)
-- Expected: a .sql file of a few tens of KB containing CREATE TABLE,
--           INSERT and CREATE VIEW statements
-- ---------------------------------------------------------------------
--   mkdir backups
--   mysqldump -u root -p --routines --triggers future_portfolio_db > backups/future_portfolio_db_backup.sql
-- Workbench alternative: Server > Data Export > tick future_portfolio_db >
--   "Dump Structure and Data" > "Export to Self-Contained File" >
--   untick "Include Create Schema" > Start Export.
-- Add  backups/  to .gitignore: the dump contains personal data (email).

-- ---------------------------------------------------------------------
-- REC02. Restore into a COPY, never over the original while practising
-- ---------------------------------------------------------------------
CREATE DATABASE future_portfolio_restore
    CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
--   mysql -u root -p future_portfolio_restore < backups/future_portfolio_db_backup.sql
-- Workbench alternative: Server > Data Import > "Import from Self-Contained
--   File" > Default Target Schema: future_portfolio_restore > Start Import.

-- ---------------------------------------------------------------------
-- REC03. Prove the restore: compare the two databases
-- Expected: every pair equal (7/7, 17/17, 16/16, 32/32, 19/19, 15/15, 1/1)
--           and 5 views in the copy
-- ---------------------------------------------------------------------
SELECT 'companies' AS table_name,
       (SELECT COUNT(*) FROM future_portfolio_db.companies)      AS original,
       (SELECT COUNT(*) FROM future_portfolio_restore.companies) AS restored
UNION ALL SELECT 'roles',
       (SELECT COUNT(*) FROM future_portfolio_db.roles),
       (SELECT COUNT(*) FROM future_portfolio_restore.roles)
UNION ALL SELECT 'projects',
       (SELECT COUNT(*) FROM future_portfolio_db.projects),
       (SELECT COUNT(*) FROM future_portfolio_restore.projects)
UNION ALL SELECT 'project_skills',
       (SELECT COUNT(*) FROM future_portfolio_db.project_skills),
       (SELECT COUNT(*) FROM future_portfolio_restore.project_skills)
UNION ALL SELECT 'awards',
       (SELECT COUNT(*) FROM future_portfolio_db.awards),
       (SELECT COUNT(*) FROM future_portfolio_restore.awards)
UNION ALL SELECT 'achievements',
       (SELECT COUNT(*) FROM future_portfolio_db.achievements),
       (SELECT COUNT(*) FROM future_portfolio_restore.achievements)
UNION ALL SELECT 'views',
       (SELECT COUNT(*) FROM information_schema.views WHERE table_schema = 'future_portfolio_db'),
       (SELECT COUNT(*) FROM information_schema.views WHERE table_schema = 'future_portfolio_restore');

-- ---------------------------------------------------------------------
-- REC04. Disaster drill, on the copy only
-- Expected: the DROP succeeds; v_awards_section in the copy now fails
--           (error 1356, the view refers to a missing table); after
--           restoring the copy again, awards 19 and the view works
-- ---------------------------------------------------------------------
DROP TABLE future_portfolio_restore.awards;
SELECT * FROM future_portfolio_restore.v_awards_section;     -- error 1356
--   mysql -u root -p future_portfolio_restore < backups/future_portfolio_db_backup.sql
SELECT COUNT(*) FROM future_portfolio_restore.awards;        -- 19

-- ---------------------------------------------------------------------
-- REC05. Clean up the copy
-- Expected: only future_portfolio_db remains (plus the system databases)
-- ---------------------------------------------------------------------
DROP DATABASE future_portfolio_restore;
SHOW DATABASES;
