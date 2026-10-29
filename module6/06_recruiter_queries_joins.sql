-- =====================================================================
-- 05_recruiter_queries_joins.sql
-- Course 4: Structured Databases | Module 6: Connect Tables with Joins
-- Project: future_portfolio_db
--
-- Sixteen labelled join questions (JQ01-JQ16) plus one stretch (JQ17).
-- Module 5 answered with IDs ("employment 4 had 4 roles"). These
-- queries follow the foreign keys designed in Module 1 to bring the
-- names back, find what is missing, and rebuild a resume section
-- from tables alone.
--
-- Run after the course-standard rebuild:
--   01_schema.sql -> 02_seed_core.sql -> 02a_constraints.sql
--   -> 03_crud_practice.sql (provided version)
--
-- This file only reads data. It is safe to run as often as you like.
--
-- Table aliases used in every query:
--   c companies   e employment   r roles   p projects   s skills
--   rp role_projects   ps project_skills   a awards   ach achievements
--
-- Join paths (child.fk = parent.pk):
--   e.company_id    = c.company_id
--   r.employment_id = e.employment_id
--   rp.role_id      = r.role_id      rp.project_id = p.project_id
--   ps.project_id   = p.project_id   ps.skill_id   = s.skill_id
--   a.company_id    = c.company_id   (NULL for industry and community awards)
--   ach.role_id     = r.role_id
-- =====================================================================

USE future_portfolio_db;

-- =====================  A. INNER JOIN: names for IDs  =================

-- ---------------------------------------------------------------------
-- JQ01. Which company was each employment period at?
-- Practises: INNER JOIN of two tables, table aliases
-- Expected: 7 rows, oldest first: Meridian Systems (1986) ...
--           Lumina Software (2021)
-- ---------------------------------------------------------------------
SELECT e.employment_id, c.company_name, e.start_date, e.end_date
FROM employment AS e
JOIN companies  AS c ON e.company_id = c.company_id
ORDER BY e.start_date;

-- ---------------------------------------------------------------------
-- JQ02. List every role with its company name, newest first.
-- Practises: a chain of three tables, qualified column names
-- Expected: 17 rows; first: Lumina Software, Chief Technology Officer
-- Note: roles and employment both have start_date, so it must be
--       written r.start_date (plain start_date gives error 1052).
-- ---------------------------------------------------------------------
SELECT c.company_name, r.role_title, r.start_date, r.end_date
FROM roles      AS r
JOIN employment AS e ON r.employment_id = e.employment_id
JOIN companies  AS c ON e.company_id    = c.company_id
ORDER BY r.start_date DESC;

-- ---------------------------------------------------------------------
-- JQ03. How many roles did she hold at each company? (RQ11 with names)
-- Practises: JOIN + GROUP BY a name
-- Expected: 7 rows: CloudHarbor Software 4; MarketBridge Technologies 3,
--           Meridian Systems 3; Aster Data Platforms 2, NexaCollab 2,
--           VectorWorks Software 2; Lumina Software 1
-- ---------------------------------------------------------------------
SELECT c.company_name, COUNT(*) AS role_count
FROM roles      AS r
JOIN employment AS e ON r.employment_id = e.employment_id
JOIN companies  AS c ON e.company_id    = c.company_id
GROUP BY c.company_name
ORDER BY role_count DESC, c.company_name;

-- ---------------------------------------------------------------------
-- JQ04. Where was her longest employment period? (RQ14 with a name)
-- Practises: JOIN + calculated column
-- Expected: 1 row: CloudHarbor Software, 96 months
-- ---------------------------------------------------------------------
SELECT c.company_name,
       TIMESTAMPDIFF(MONTH, e.start_date, e.end_date) + 1 AS months
FROM employment AS e
JOIN companies  AS c ON e.company_id = c.company_id
ORDER BY months DESC
LIMIT 1;

-- =====================  B. Through a junction table  ==================

-- ---------------------------------------------------------------------
-- JQ05. Which skills are used on at least two projects? (RQ13 with names)
-- Practises: JOIN + GROUP BY + HAVING
-- Expected: 11 rows: Platform migration 6; Relational data access 3,
--           Site reliability engineering 3; eight skills with 2
-- ---------------------------------------------------------------------
SELECT s.skill_name, COUNT(*) AS project_count
FROM project_skills AS ps
JOIN skills         AS s ON ps.skill_id = s.skill_id
GROUP BY s.skill_name
HAVING COUNT(*) >= 2
ORDER BY project_count DESC, s.skill_name;

-- ---------------------------------------------------------------------
-- JQ06. List every project with each skill it used.
-- Practises: many-to-many: project -> junction -> skill
-- Expected: 32 rows (one per project_skills row)
-- ---------------------------------------------------------------------
SELECT p.project_name, s.skill_name
FROM projects       AS p
JOIN project_skills AS ps ON ps.project_id = p.project_id
JOIN skills         AS s  ON ps.skill_id   = s.skill_id
ORDER BY p.project_id, s.skill_name;

-- ---------------------------------------------------------------------
-- JQ07. Which projects used Platform migration?
-- Practises: JOIN through a junction table + WHERE on a name
-- Expected: 6 rows: projects 3, 7, 8, 12, 14, 15
-- ---------------------------------------------------------------------
SELECT p.project_id, p.project_name
FROM projects       AS p
JOIN project_skills AS ps ON ps.project_id = p.project_id
JOIN skills         AS s  ON ps.skill_id   = s.skill_id
WHERE s.skill_name = 'Platform migration'
ORDER BY p.project_id;

-- ---------------------------------------------------------------------
-- JQ08. Which projects did more than one of her roles work on?
-- Practises: JOIN + GROUP BY + HAVING
-- Expected: 2 rows: Application-core migration 2,
--           Multi-tenant platform conversion 2
-- ---------------------------------------------------------------------
SELECT p.project_name, COUNT(*) AS roles_involved
FROM role_projects AS rp
JOIN projects      AS p ON rp.project_id = p.project_id
GROUP BY p.project_name
HAVING COUNT(*) > 1
ORDER BY p.project_name;

-- =====================  C. LEFT JOIN: keep every row  =================

-- ---------------------------------------------------------------------
-- JQ09. Which awards came from an employer, and which one?
-- Practises: INNER JOIN drops rows with no match
-- Expected: 9 rows (the Company awards only); 10 awards have
--           company_id NULL and disappear
-- ---------------------------------------------------------------------
SELECT a.award_year, a.award_name, c.company_name
FROM awards    AS a
JOIN companies AS c ON a.company_id = c.company_id
ORDER BY a.award_year DESC;

-- ---------------------------------------------------------------------
-- JQ10. List ALL awards, with the employer's name where there is one.
-- Practises: LEFT JOIN keeps every row from the left table
-- Expected: 19 rows; company_name is NULL for the 10 Industry and
--           Community awards
-- ---------------------------------------------------------------------
SELECT a.award_year, a.award_name, a.award_category, c.company_name
FROM awards         AS a
LEFT JOIN companies AS c ON a.company_id = c.company_id
ORDER BY a.award_year DESC, a.award_id;

-- ---------------------------------------------------------------------
-- JQ11. Which skills have no project evidence?
-- Practises: LEFT JOIN ... WHERE right side IS NULL (find the missing)
-- Expected: 2 rows: skill 2 UNIX shell scripting,
--           skill 17 Technical due diligence
-- ---------------------------------------------------------------------
SELECT s.skill_id, s.skill_name
FROM skills              AS s
LEFT JOIN project_skills AS ps ON ps.skill_id = s.skill_id
WHERE ps.skill_id IS NULL;

-- ---------------------------------------------------------------------
-- JQ12. Which roles have no linked project?
-- Practises: LEFT JOIN ... IS NULL
-- Expected: 2 rows: role 1 Engineering Intern, role 7 Engineering Manager
-- ---------------------------------------------------------------------
SELECT r.role_id, r.role_title
FROM roles              AS r
LEFT JOIN role_projects AS rp ON rp.role_id = r.role_id
WHERE rp.project_id IS NULL;

-- ---------------------------------------------------------------------
-- JQ13. How many projects is each role linked to, including none?
-- Practises: LEFT JOIN + COUNT(column) (COUNT(*) would say 1, not 0)
-- Expected: 17 rows; roles 1 and 7 -> 0; role 14 -> 2; role 17 -> 3;
--           every other role -> 1
-- ---------------------------------------------------------------------
SELECT r.role_id, r.role_title, COUNT(rp.project_id) AS project_count
FROM roles              AS r
LEFT JOIN role_projects AS rp ON rp.role_id = r.role_id
GROUP BY r.role_id, r.role_title
ORDER BY r.role_id;

-- =====================  D. Longer chains  =============================

-- ---------------------------------------------------------------------
-- JQ14. Her five most recent achievements, by the role's real start
--       date, with role and company. (RQ16, done properly)
-- Practises: four-table chain, ORDER BY a joined column
-- Expected: 5 rows: achievements 15, 14, 13 (CTO, Lumina),
--           12 (Chief Product & Technology Officer, Aster),
--           11 (Senior Vice President, Engineering, Aster)
-- ---------------------------------------------------------------------
SELECT ach.achievement_id, ach.measure, r.role_title, c.company_name
FROM achievements AS ach
JOIN roles        AS r ON ach.role_id     = r.role_id
JOIN employment   AS e ON r.employment_id = e.employment_id
JOIN companies    AS c ON e.company_id    = c.company_id
ORDER BY r.start_date DESC, ach.achievement_id DESC
LIMIT 5;

-- ---------------------------------------------------------------------
-- JQ15. Which projects did she work on at CloudHarbor Software?
-- Practises: five-table chain, DISTINCT
-- Expected: 3 rows: Shared subscription administration service,
--           Multi-tenant platform conversion, Hosting environment
--           consolidation. Without DISTINCT: 4 rows (project 7 twice,
--           because two CloudHarbor roles worked on it).
-- ---------------------------------------------------------------------
SELECT DISTINCT p.project_id, p.project_name
FROM companies     AS c
JOIN employment    AS e  ON e.company_id    = c.company_id
JOIN roles         AS r  ON r.employment_id = e.employment_id
JOIN role_projects AS rp ON rp.role_id      = r.role_id
JOIN projects      AS p  ON rp.project_id   = p.project_id
WHERE c.company_name = 'CloudHarbor Software'
ORDER BY p.project_id;

-- =====================  E. Rebuild the resume  ========================

-- ---------------------------------------------------------------------
-- JQ16. Rebuild the Experience section of the resume, newest first.
-- Practises: JOIN + DATE_FORMAT + CONCAT: formatting for a reader
-- Expected: 17 rows; first: Lumina Software | Chief Technology Officer |
--           Jun 2021 - May 2026 | 1800
-- ---------------------------------------------------------------------
SELECT c.company_name AS company,
       r.role_title   AS role,
       CONCAT(DATE_FORMAT(r.start_date, '%b %Y'), ' - ',
              DATE_FORMAT(r.end_date,   '%b %Y')) AS dates,
       r.team_size    AS team
FROM roles      AS r
JOIN employment AS e ON r.employment_id = e.employment_id
JOIN companies  AS c ON e.company_id    = c.company_id
ORDER BY r.start_date DESC;

-- ---------------------------------------------------------------------
-- JQ17 (stretch). Rebuild the Awards section: year, award, and who gave
--       it (the employer if there is one, otherwise the awarding body).
-- Practises: LEFT JOIN + COALESCE
-- Expected: 19 rows, newest first; no NULLs in awarded_by
-- ---------------------------------------------------------------------
SELECT a.award_year AS year,
       a.award_name AS award,
       COALESCE(c.company_name, a.awarding_body) AS awarded_by
FROM awards         AS a
LEFT JOIN companies AS c ON a.company_id = c.company_id
ORDER BY a.award_year DESC, a.award_id;
