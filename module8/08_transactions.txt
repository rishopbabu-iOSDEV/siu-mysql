-- =====================================================================
-- 07_transactions.sql
-- Course 4: Structured Databases | Module 8: Transactions and Reliable Changes
-- Project: future_portfolio_db
--
-- Scenario: Ananya is offered a three-year non-executive board seat at
-- Kestrel Ridge Analytics (a fictional company). Recording it touches
-- six tables. This file practises doing that safely, then reverses it.
--
--   TX01-TX03  What goes wrong without a transaction, and how ROLLBACK fixes it
--   TX04-TX05  The appointment as one transaction: check, then COMMIT
--   TX06       SAVEPOINT: undo part of a transaction
--   TX07       Implicit commit: CREATE/ALTER/DROP end a transaction
--   TX08-TX09  Two sessions: isolation and locks (needs a second connection)
--   TX10       Compensating transaction: undo a COMMIT with a new transaction
--
-- HOW TO RUN: one statement at a time (Ctrl+Enter), NOT "Execute All".
-- TX02 and TX03 contain statements that fail ON PURPOSE (error 3819).
--
-- Start state: the course-standard rebuild 01 -> 02 -> 02a -> 03 -> 06.
-- End state:   identical to the start state. After TX10 the data is back
--              to the course standard, so this file is NOT part of the
--              rebuild. Every UPDATE and DELETE uses a primary key, so it
--              runs with Safe Updates on.
-- =====================================================================

USE future_portfolio_db;

-- =====================  A. WHY TRANSACTIONS  ==========================

-- ---------------------------------------------------------------------
-- TX01. Is every statement committed automatically?
-- Expected: 1 (autocommit is ON: each statement is its own transaction)
-- ---------------------------------------------------------------------
SELECT @@autocommit;

-- ---------------------------------------------------------------------
-- TX02. Half a job: three related inserts WITHOUT a transaction.
-- The role's end date is typed before its start date (a typing slip).
-- Expected: company 8 OK, employment 8 OK, role 18 fails with
--           error 3819 (chk_roles_dates). Company 8 and employment 8
--           are left behind with no role: the database now says she
--           works at Kestrel Ridge in no role at all.
-- ---------------------------------------------------------------------
INSERT INTO companies (company_id, company_name, description)
VALUES (8, 'Kestrel Ridge Analytics',
        'Analytics software company (fictional, Module 8 practice data).');

INSERT INTO employment (employment_id, person_id, company_id, start_date, end_date, summary)
VALUES (8, 1, 8, '2026-06-01', '2029-05-31', 'Three-year non-executive board term.');

INSERT INTO roles (role_id, employment_id, role_title, start_date, end_date, team_size, summary)
VALUES (18, 8, 'Non-Executive Director', '2026-06-01', '2026-05-31', NULL,
        'Board member; chairs the technology and risk committee.');   -- ERROR 3819

SELECT COUNT(*) FROM companies;    -- 8: the half-job is saved
SELECT COUNT(*) FROM roles;        -- 17: but no role

-- Clean up by hand, children first (RESTRICT protects the parent):
DELETE FROM employment WHERE employment_id = 8;
DELETE FROM companies  WHERE company_id    = 8;
SELECT COUNT(*) FROM companies;    -- 7 again

-- ---------------------------------------------------------------------
-- TX03. The same three inserts INSIDE a transaction.
-- Expected: the third insert fails (3819). The first two are still
--           pending: MySQL does NOT roll back for you. ROLLBACK
--           removes them. Afterwards: companies 7, employment 7.
-- ---------------------------------------------------------------------
START TRANSACTION;

INSERT INTO companies (company_id, company_name, description)
VALUES (8, 'Kestrel Ridge Analytics',
        'Analytics software company (fictional, Module 8 practice data).');

INSERT INTO employment (employment_id, person_id, company_id, start_date, end_date, summary)
VALUES (8, 1, 8, '2026-06-01', '2029-05-31', 'Three-year non-executive board term.');

INSERT INTO roles (role_id, employment_id, role_title, start_date, end_date, team_size, summary)
VALUES (18, 8, 'Non-Executive Director', '2026-06-01', '2026-05-31', NULL,
        'Board member; chairs the technology and risk committee.');   -- ERROR 3819

SELECT COUNT(*) FROM companies;    -- 8 (pending, visible only to this session)
ROLLBACK;
SELECT COUNT(*) FROM companies;    -- 7
SELECT COUNT(*) FROM employment;   -- 7

-- =====================  B. THE APPOINTMENT, DONE RIGHT  ===============

-- ---------------------------------------------------------------------
-- TX04. Record the board appointment as ONE transaction (6 tables).
-- Order: parents first (company, employment, role, project), then links,
-- then the headline. Check through the Module 7 views BEFORE committing.
-- Expected before COMMIT: v_career_summary 8 | 18 | 17 | 17 | 19 | 43.0000
-- ---------------------------------------------------------------------
START TRANSACTION;

INSERT INTO companies (company_id, company_name, description)
VALUES (8, 'Kestrel Ridge Analytics',
        'Analytics software company (fictional, Module 8 practice data).');

INSERT INTO employment (employment_id, person_id, company_id, start_date, end_date, summary)
VALUES (8, 1, 8, '2026-06-01', '2029-05-31', 'Three-year non-executive board term.');

INSERT INTO roles (role_id, employment_id, role_title, start_date, end_date, team_size, summary)
VALUES (18, 8, 'Non-Executive Director', '2026-06-01', '2029-05-31', NULL,
        'Board member; chairs the technology and risk committee.');

INSERT INTO projects (project_id, project_name, description)
VALUES (17, 'Acquisition technology due diligence',
        'Board-commissioned review of an acquisition target''s platform and engineering practices.');

INSERT INTO role_projects (role_id, project_id, contribution)
VALUES (18, 17, 'Led the board''s technical review of the acquisition target.');

INSERT INTO project_skills (project_id, skill_id)
VALUES (17, 17);                     -- Technical due diligence

UPDATE people
SET headline = 'Non-Executive Director, Kestrel Ridge Analytics | Former Chief Technology Officer'
WHERE person_id = 1;

-- Check before you commit:
SELECT * FROM v_career_summary;                                    -- 8 | 18 | 17 | 17 | 19 | 43.0000
SELECT company, role, dates FROM v_experience
ORDER BY start_date DESC LIMIT 1;                                  -- Kestrel Ridge Analytics | Non-Executive Director | Jun 2026 - May 2029
SELECT skill_name FROM v_skill_evidence WHERE project_count = 0;   -- 1 row: UNIX shell scripting

COMMIT;

-- ---------------------------------------------------------------------
-- TX05. After COMMIT, ROLLBACK has nothing to undo.
-- Expected: ROLLBACK runs with no error; companies is still 8.
-- ---------------------------------------------------------------------
ROLLBACK;
SELECT COUNT(*) FROM companies;    -- 8

-- =====================  C. SAVEPOINTS  ================================

-- ---------------------------------------------------------------------
-- TX06. Add an achievement; then a second one by mistake (wrong role);
-- undo only the mistake with ROLLBACK TO SAVEPOINT; commit the rest.
-- Expected: achievements 16 after COMMIT (achievement 16 kept, 17 gone)
-- ---------------------------------------------------------------------
START TRANSACTION;

INSERT INTO achievements (achievement_id, role_id, project_id, measure, value_before, value_after, unit)
VALUES (16, 18, 17, 'Due diligence review completed', NULL, 6, 'weeks');

SAVEPOINT after_review;

INSERT INTO achievements (achievement_id, role_id, project_id, measure, value_before, value_after, unit)
VALUES (17, 17, 17, 'Due diligence review completed', NULL, 6, 'weeks');   -- wrong role (17)

SELECT COUNT(*) FROM achievements;          -- 17 (pending)
ROLLBACK TO SAVEPOINT after_review;
SELECT COUNT(*) FROM achievements;          -- 16 (pending)
COMMIT;
SELECT COUNT(*) FROM achievements;          -- 16

-- ---------------------------------------------------------------------
-- TX07. The implicit-commit trap: CREATE, ALTER and DROP commit first.
-- Expected: after ROLLBACK, role 18's team_size is still 12, because
--           CREATE VIEW committed the UPDATE before it ran.
-- ---------------------------------------------------------------------
START TRANSACTION;
UPDATE roles SET team_size = 12 WHERE role_id = 18;
CREATE OR REPLACE VIEW v_board_roles AS
    SELECT role_id, role_title, team_size FROM roles WHERE role_title LIKE '%Director%';
ROLLBACK;
SELECT role_id, team_size FROM roles WHERE role_id = 18;   -- 12: not rolled back!

-- Put it right (two ordinary statements, each autocommitted):
UPDATE roles SET team_size = NULL WHERE role_id = 18;
DROP VIEW v_board_roles;

-- =====================  D. TWO SESSIONS  ==============================
-- Open a SECOND connection to the server (Workbench home screen: open the
-- same connection again; query tabs in one window share one session).
-- Run the lines marked [A] in the first window and [B] in the second,
-- in the order given.

-- ---------------------------------------------------------------------
-- TX08. Isolation: other sessions never see uncommitted changes.
-- Expected: B sees 1800 while A's change is pending, 2000 after A commits,
--           1800 again after A restores it.
-- ---------------------------------------------------------------------
-- [A] START TRANSACTION;
-- [A] UPDATE roles SET team_size = 2000 WHERE role_id = 17;
-- [A] SELECT team_size FROM roles WHERE role_id = 17;     -- 2000 (A sees its own change)
-- [B] SELECT team_size FROM roles WHERE role_id = 17;     -- 1800 (not committed yet)
-- [A] COMMIT;
-- [B] SELECT team_size FROM roles WHERE role_id = 17;     -- 2000
-- [A] UPDATE roles SET team_size = 1800 WHERE role_id = 17;   -- restore (autocommit)
-- [B] SELECT team_size FROM roles WHERE role_id = 17;     -- 1800

-- ---------------------------------------------------------------------
-- TX09. Locks: two sessions changing the same row.
-- Expected: B's UPDATE waits until A finishes. If A takes longer than
--           innodb_lock_wait_timeout (50 s by default), B gets error 1205.
-- ---------------------------------------------------------------------
-- [A] START TRANSACTION;
-- [A] UPDATE roles SET team_size = 1900 WHERE role_id = 17;
-- [B] START TRANSACTION;
-- [B] UPDATE roles SET team_size = 1950 WHERE role_id = 17;   -- waits ...
-- [A] ROLLBACK;                                               -- B's UPDATE now completes
-- [B] ROLLBACK;
-- [B] SELECT team_size FROM roles WHERE role_id = 17;         -- 1800

-- =====================  E. UNDOING A COMMIT  ==========================

-- ---------------------------------------------------------------------
-- TX10. The appointment is withdrawn. ROLLBACK can't undo a COMMIT, so
-- write a COMPENSATING transaction that reverses every row TX04 and TX06
-- created, children first, and restores the old headline exactly.
-- Expected after COMMIT: v_career_summary 7 | 17 | 16 | 17 | 19 | 40.0000;
--           achievements 15; project_skills 32; role_projects 18
-- ---------------------------------------------------------------------
START TRANSACTION;

DELETE FROM achievements WHERE achievement_id = 16;   -- RESTRICT on roles: remove first
DELETE FROM projects     WHERE project_id     = 17;   -- CASCADE removes its role_projects and project_skills rows
DELETE FROM roles        WHERE role_id        = 18;
DELETE FROM employment   WHERE employment_id  = 8;
DELETE FROM companies    WHERE company_id     = 8;

UPDATE people
SET headline = 'Former Chief Technology Officer | Candidate for non-executive board roles'
WHERE person_id = 1;

-- Check before you commit:
SELECT * FROM v_career_summary;                       -- 7 | 17 | 16 | 17 | 19 | 40.0000
SELECT COUNT(*) FROM achievements;                    -- 15
SELECT COUNT(*) FROM project_skills;                  -- 32
SELECT COUNT(*) FROM role_projects;                   -- 18
SELECT headline FROM people WHERE person_id = 1;

COMMIT;
