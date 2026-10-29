-- =====================================================================
-- 04_recruiter_queries_basic.sql
-- Course 4: Structured Databases | Module 5: Search, Sort and Summarize
-- Project: future_portfolio_db
--
-- Sixteen labelled recruiter questions, each answered from ONE table.
-- Each query has: a label, the recruiter's question, the clauses it
-- practises, and the expected result (from the course-standard data).
--
-- Run after the full rebuild:
--   01_schema.sql -> 02_seed_core.sql -> 02a_constraints.sql
--   -> 03_crud_practice.sql (provided version)
--
-- This file only reads data. It is safe to run as often as you like.
-- Clause order in every query:
--   SELECT ... FROM ... WHERE ... GROUP BY ... HAVING ... ORDER BY ... LIMIT
-- =====================================================================

USE future_portfolio_db;

-- ---------------------------------------------------------------------
-- RQ01. What are Ananya's five most recent roles?
-- Practises: column list, ORDER BY ... DESC, LIMIT
-- Expected: 5 rows, newest first: role 17 Chief Technology Officer,
--           16, 15, 14, 13 (Engineering Director, 2009)
-- ---------------------------------------------------------------------
SELECT role_id, role_title, start_date, end_date
FROM roles
ORDER BY start_date DESC
LIMIT 5;

-- ---------------------------------------------------------------------
-- RQ02. Which roles did she start between 2000 and 2009?
-- Practises: BETWEEN with dates, ORDER BY
-- Expected: 5 rows: roles 9, 10, 11, 12 (CloudHarbor) and 13 (NexaCollab)
-- ---------------------------------------------------------------------
SELECT role_id, role_title, start_date
FROM roles
WHERE start_date BETWEEN '2000-01-01' AND '2009-12-31'
ORDER BY start_date;

-- ---------------------------------------------------------------------
-- RQ03. Which projects mention "platform" in their name or description?
-- Practises: LIKE with % wildcards, OR
-- Expected: 4 rows: projects 5, 7, 14 (name) and 15 (description only)
-- ---------------------------------------------------------------------
SELECT project_id, project_name
FROM projects
WHERE project_name LIKE '%platform%'
   OR description  LIKE '%platform%'
ORDER BY project_id;

-- ---------------------------------------------------------------------
-- RQ04. Which roles have no stated team size?
-- Practises: IS NULL (never "= NULL")
-- Expected: 5 rows: roles 1, 2, 4, 6, 10
-- ---------------------------------------------------------------------
SELECT role_id, role_title
FROM roles
WHERE team_size IS NULL;

-- ---------------------------------------------------------------------
-- RQ05. In which roles did she lead 500 or more people, largest first?
-- Practises: comparison operator, ORDER BY ... DESC
-- Expected: 3 rows: 17 (1800), 16 (950), 14 (620)
-- ---------------------------------------------------------------------
SELECT role_id, role_title, team_size
FROM roles
WHERE team_size >= 500
ORDER BY team_size DESC;

-- ---------------------------------------------------------------------
-- RQ06. Which awards did she receive after 2020?
-- Practises: WHERE with >, ORDER BY two columns
-- Expected: 6 rows: 2026, 2025, 2024 (two), 2023, 2022
-- ---------------------------------------------------------------------
SELECT award_id, award_name, award_year
FROM awards
WHERE award_year > 2020
ORDER BY award_year DESC, award_id;

-- ---------------------------------------------------------------------
-- RQ07. Which awards came from Aster (company 6) or Lumina (company 7)?
-- Practises: IN
-- Expected: 3 rows: 2020 CEO's Transformation Award, 2024, 2026
-- ---------------------------------------------------------------------
SELECT award_id, award_name, award_year
FROM awards
WHERE company_id IN (6, 7)
ORDER BY award_year;

-- ---------------------------------------------------------------------
-- RQ08. Which skills are outside Architecture and Operations?
-- Practises: NOT IN, ORDER BY two columns
-- Expected: 11 rows, grouped by category: Data, Engineering practice,
--           Governance, Language, Security
-- ---------------------------------------------------------------------
SELECT skill_id, skill_name, skill_category
FROM skills
WHERE skill_category NOT IN ('Architecture', 'Operations')
ORDER BY skill_category, skill_id;

-- ---------------------------------------------------------------------
-- RQ09. Which achievements give both a before and an after value?
-- Practises: IS NOT NULL
-- Expected: 10 rows: achievements 3, 5, 6, 7, 9, 10, 11, 12, 13, 14
-- ---------------------------------------------------------------------
SELECT achievement_id, measure, value_before, value_after, unit
FROM achievements
WHERE value_before IS NOT NULL
ORDER BY achievement_id;

-- ---------------------------------------------------------------------
-- RQ10. Summarise her team sizes.
-- Practises: COUNT(*), COUNT(column), MIN, MAX, AVG, column aliases (AS)
-- Expected: 1 row: roles 17, roles_with_size 12, smallest 5,
--           largest 1800, average 373.1667
-- Note: COUNT(team_size) and AVG ignore NULLs.
-- ---------------------------------------------------------------------
SELECT COUNT(*)         AS roles,
       COUNT(team_size) AS roles_with_size,
       MIN(team_size)   AS smallest,
       MAX(team_size)   AS largest,
       AVG(team_size)   AS average
FROM roles;

-- ---------------------------------------------------------------------
-- RQ11. How many roles did she hold in each employment period?
-- Practises: GROUP BY, COUNT, ORDER BY an alias
-- Expected: 7 rows: employment 4 has 4 roles; 1 and 3 have 3;
--           2, 5 and 6 have 2; 7 has 1
-- Note: the answer shows IDs, not company names. Names need a join (Module 6).
-- ---------------------------------------------------------------------
SELECT employment_id,
       COUNT(*) AS role_count
FROM roles
GROUP BY employment_id
ORDER BY role_count DESC, employment_id;

-- ---------------------------------------------------------------------
-- RQ12. How many awards are there in each category?
-- Practises: GROUP BY a text column
-- Expected: Company 9, Industry 7, Community 3
-- ---------------------------------------------------------------------
SELECT award_category,
       COUNT(*) AS awards
FROM awards
GROUP BY award_category
ORDER BY awards DESC;

-- ---------------------------------------------------------------------
-- RQ13. Which skills are used on at least two projects?
-- Practises: GROUP BY, HAVING (a filter on groups)
-- Expected: 11 rows: skill 6 (6 projects); skills 3 and 10 (3);
--           skills 1, 4, 5, 7, 8, 9, 11, 15 (2)
-- ---------------------------------------------------------------------
SELECT skill_id,
       COUNT(*) AS project_count
FROM project_skills
GROUP BY skill_id
HAVING COUNT(*) >= 2
ORDER BY project_count DESC, skill_id;

-- ---------------------------------------------------------------------
-- RQ14. Which was her longest employment period?
-- Practises: a calculated column (TIMESTAMPDIFF), ORDER BY, LIMIT
-- Expected: 1 row: employment 4 (CloudHarbor), 96 months
-- Note: +1 because end dates are the last day of the month,
--       so June 2001 to May 2009 counts as 96 whole months.
-- ---------------------------------------------------------------------
SELECT employment_id,
       start_date,
       end_date,
       TIMESTAMPDIFF(MONTH, start_date, end_date) + 1 AS months
FROM employment
ORDER BY months DESC
LIMIT 1;

-- ---------------------------------------------------------------------
-- RQ15. How long was her whole career, in years?
-- Practises: SUM over a calculated column
-- Expected: 1 row: 40.0000
-- ---------------------------------------------------------------------
SELECT SUM(TIMESTAMPDIFF(MONTH, start_date, end_date) + 1) / 12 AS career_years
FROM employment;

-- ---------------------------------------------------------------------
-- RQ16. Which are her five most recent achievements?
-- Practises: ORDER BY two columns, LIMIT
-- Expected: 5 rows: achievements 15, 14, 13 (role 17), 12 (role 16),
--           11 (role 15)
-- Note: achievements have no dates; role_id order follows the career
--       because roles were numbered oldest first. Ordering by the
--       role's real start date needs a join (Module 6).
-- ---------------------------------------------------------------------
SELECT achievement_id, role_id, measure
FROM achievements
ORDER BY role_id DESC, achievement_id DESC
LIMIT 5;
