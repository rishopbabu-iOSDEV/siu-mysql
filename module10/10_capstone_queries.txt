-- =====================================================================
-- 09_capstone_queries.sql
-- Course 4: Structured Databases | Module 10: Capstone Query Challenge and Demo Day
-- Project: future_portfolio_db
--
-- Part A  RB01        The clean rebuild, proved in one query
-- Part B  CQ01-CQ12   Capstone Query Challenge: 12 new recruiter questions
--                     Bronze (one table), Silver (joins and groups),
--                     Gold (subqueries, views, self-joins)
-- Part C  V6-V8       Three capstone views, so the whole resume can be
--                     produced from views; GRANT them to portfolio_web
-- Part D  RS01-RS07   The resume, section by section, run AS portfolio_web
--
-- FINAL REBUILD ORDER (from this module on):
--   01_schema.sql -> 02_seed_core.sql -> 02a_constraints.sql
--   -> 03_crud_practice.sql (provided) -> 06_views_and_subqueries.sql
--   -> 09_capstone_queries.sql (Part C: views and grants)
-- 04, 05, 07 and 08 are practice and query files: not part of the rebuild.
-- Part C's GRANTs need the users created in Module 9 (08, Part B).
-- =====================================================================

USE future_portfolio_db;

-- =====================  A. THE CLEAN REBUILD  =========================

-- ---------------------------------------------------------------------
-- RB01. Prove the rebuild: actual against expected, in one result
-- Expected: 14 rows, every ok = 1
-- ---------------------------------------------------------------------
SELECT 'people' AS item, COUNT(*) AS actual, 1 AS expected, COUNT(*) = 1 AS ok FROM people
UNION ALL SELECT 'companies',         COUNT(*), 7,  COUNT(*) = 7  FROM companies
UNION ALL SELECT 'employment',        COUNT(*), 7,  COUNT(*) = 7  FROM employment
UNION ALL SELECT 'roles',             COUNT(*), 17, COUNT(*) = 17 FROM roles
UNION ALL SELECT 'projects',          COUNT(*), 16, COUNT(*) = 16 FROM projects
UNION ALL SELECT 'role_projects',     COUNT(*), 18, COUNT(*) = 18 FROM role_projects
UNION ALL SELECT 'skills',            COUNT(*), 17, COUNT(*) = 17 FROM skills
UNION ALL SELECT 'project_skills',    COUNT(*), 32, COUNT(*) = 32 FROM project_skills
UNION ALL SELECT 'education',         COUNT(*), 4,  COUNT(*) = 4  FROM education
UNION ALL SELECT 'awards',            COUNT(*), 19, COUNT(*) = 19 FROM awards
UNION ALL SELECT 'community_service', COUNT(*), 3,  COUNT(*) = 3  FROM community_service
UNION ALL SELECT 'interests',         COUNT(*), 5,  COUNT(*) = 5  FROM interests
UNION ALL SELECT 'achievements',      COUNT(*), 15, COUNT(*) = 15 FROM achievements
UNION ALL SELECT 'views (06)',        COUNT(*), 5,  COUNT(*) = 5
          FROM information_schema.views
          WHERE table_schema = 'future_portfolio_db'
            AND table_name IN ('v_role_details', 'v_experience', 'v_skill_evidence',
                               'v_awards_section', 'v_career_summary');

-- =====================  B. CAPSTONE QUERY CHALLENGE  ==================
-- Bronze 1 point each, Silver 2, Gold 3: 24 points in all.
-- A query scores when its result matches the expected result.

-- ----------------------------- BRONZE --------------------------------

-- ---------------------------------------------------------------------
-- CQ01. How many awards did she receive in the 2010s?
-- Practises: BETWEEN, COUNT                                   [Bronze]
-- Expected: 7
-- ---------------------------------------------------------------------
SELECT COUNT(*) AS awards_2010s
FROM awards
WHERE award_year BETWEEN 2010 AND 2019;

-- ---------------------------------------------------------------------
-- CQ02. Which achievements more than doubled the starting value?
-- Practises: arithmetic in WHERE, IS NOT NULL (implied)       [Bronze]
-- Expected: 4 rows: achievements 5, 7, 10, 12
-- ---------------------------------------------------------------------
SELECT achievement_id, measure, value_before, value_after
FROM achievements
WHERE value_after > 2 * value_before
ORDER BY achievement_id;

-- ---------------------------------------------------------------------
-- CQ03. Which community service roles does she still hold?
-- Practises: IS NULL                                          [Bronze]
-- Expected: 2 rows: services 1 and 2
-- ---------------------------------------------------------------------
SELECT service_id, organisation, service_role, start_year
FROM community_service
WHERE end_year IS NULL
ORDER BY start_year;

-- ---------------------------------------------------------------------
-- CQ04. Which executive programmes has she completed, newest first?
-- Practises: WHERE on text, ORDER BY DESC                     [Bronze]
-- Expected: 3 rows: 2025, 2016, 2004
-- ---------------------------------------------------------------------
SELECT qualification, institution, end_year
FROM education
WHERE education_type = 'Executive programme'
ORDER BY end_year DESC;

-- ----------------------------- SILVER --------------------------------

-- ---------------------------------------------------------------------
-- CQ05. What was the largest team she led at each company?
-- Practises: three-table join, MAX, GROUP BY                  [Silver]
-- Expected: 7 rows: Lumina Software 1800, Aster Data Platforms 950,
--           NexaCollab 620, CloudHarbor Software 230, MarketBridge
--           Technologies 85, VectorWorks Software 6, Meridian Systems 5
-- ---------------------------------------------------------------------
SELECT c.company_name, MAX(r.team_size) AS largest_team
FROM roles      AS r
JOIN employment AS e ON r.employment_id = e.employment_id
JOIN companies  AS c ON e.company_id    = c.company_id
GROUP BY c.company_name
ORDER BY largest_team DESC;

-- ---------------------------------------------------------------------
-- CQ06. Which skills did she use at more than one company?
-- Practises: six-table chain, COUNT(DISTINCT), HAVING         [Silver]
-- Expected: 10 rows: Platform migration (4 companies); nine skills with 2
-- ---------------------------------------------------------------------
SELECT s.skill_name, COUNT(DISTINCT c.company_id) AS companies
FROM companies      AS c
JOIN employment     AS e  ON e.company_id    = c.company_id
JOIN roles          AS r  ON r.employment_id = e.employment_id
JOIN role_projects  AS rp ON rp.role_id      = r.role_id
JOIN project_skills AS ps ON ps.project_id   = rp.project_id
JOIN skills         AS s  ON ps.skill_id     = s.skill_id
GROUP BY s.skill_name
HAVING COUNT(DISTINCT c.company_id) > 1
ORDER BY companies DESC, s.skill_name;

-- ---------------------------------------------------------------------
-- CQ07. Which projects drew on three or more skills?
-- Practises: join through a junction table, GROUP BY, HAVING  [Silver]
-- Expected: 3 rows: Application-core migration, Lumina platform
--           renewal, Order-processing engine (3 skills each)
-- ---------------------------------------------------------------------
SELECT p.project_name, COUNT(*) AS skill_count
FROM projects       AS p
JOIN project_skills AS ps ON ps.project_id = p.project_id
GROUP BY p.project_id, p.project_name
HAVING COUNT(*) >= 3
ORDER BY skill_count DESC, p.project_name;

-- ---------------------------------------------------------------------
-- CQ08. How many measurable achievements per company, including none?
-- Practises: LEFT JOIN chain, COUNT(column)                   [Silver]
-- Expected: 7 rows: Lumina Software 3, Meridian Systems 3; four
--           companies with 2; VectorWorks Software 1 (none with 0
--           today, but the query would show them)
-- ---------------------------------------------------------------------
SELECT c.company_name, COUNT(ach.achievement_id) AS achievements
FROM companies         AS c
LEFT JOIN employment   AS e   ON e.company_id    = c.company_id
LEFT JOIN roles        AS r   ON r.employment_id = e.employment_id
LEFT JOIN achievements AS ach ON ach.role_id     = r.role_id
GROUP BY c.company_id, c.company_name
ORDER BY achievements DESC, c.company_name;

-- ------------------------------ GOLD ---------------------------------

-- ---------------------------------------------------------------------
-- CQ09. Which roles led a larger team than the average at the same company?
-- Practises: correlated subquery with a join                  [Gold]
-- Expected: 4 rows: roles 8 (85), 11 (230), 14 (620), 16 (950)
-- ---------------------------------------------------------------------
SELECT r.role_id, r.role_title, r.team_size
FROM roles      AS r
JOIN employment AS e ON r.employment_id = e.employment_id
WHERE r.team_size > (SELECT AVG(r2.team_size)
                     FROM roles      AS r2
                     JOIN employment AS e2 ON r2.employment_id = e2.employment_id
                     WHERE e2.company_id = e.company_id)
ORDER BY r.role_id;

-- ---------------------------------------------------------------------
-- CQ10. In the skill categories that contain an unevidenced skill, how
--       much evidence do the other skills have?
-- Practises: a view inside an IN subquery                     [Gold]
-- Expected: 4 rows: Governance: AI product governance 1, Technical due
--           diligence 0; Language: C/C++ 2, UNIX shell scripting 0
-- ---------------------------------------------------------------------
SELECT skill_category, skill_name, project_count
FROM v_skill_evidence
WHERE skill_category IN (SELECT skill_category
                         FROM v_skill_evidence
                         WHERE project_count = 0)
ORDER BY skill_category, project_count DESC;

-- ---------------------------------------------------------------------
-- CQ11. How many of her roles started in each decade?
-- Practises: GROUP BY a calculated value (FLOOR, YEAR)        [Gold]
-- Expected: 5 rows: 1980s 2, 1990s 6, 2000s 5, 2010s 3, 2020s 1
-- ---------------------------------------------------------------------
SELECT FLOOR(YEAR(start_date) / 10) * 10 AS decade,
       COUNT(*)                          AS roles_started
FROM roles
GROUP BY decade
ORDER BY decade;

-- ---------------------------------------------------------------------
-- CQ12. Data-quality check: is there any gap between one employment
--       period and the next?
-- Practises: self-join, MIN, HAVING, DATE_ADD                 [Gold]
-- Expected: 0 rows: every period starts the day after the previous ends
-- ---------------------------------------------------------------------
SELECT e1.employment_id, e1.end_date, MIN(e2.start_date) AS next_start
FROM employment AS e1
JOIN employment AS e2 ON e2.start_date > e1.end_date
GROUP BY e1.employment_id, e1.end_date
HAVING MIN(e2.start_date) <> DATE_ADD(e1.end_date, INTERVAL 1 DAY);

-- =====================  C. CAPSTONE VIEWS  ============================
-- Together with Module 7's views, these produce every resume section.

-- ---------------------------------------------------------------------
-- V6. v_profile_header: the top of the resume. Deliberately NO email.
-- Expected: 1 row
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW v_profile_header AS
SELECT full_name, headline, location, professional_summary
FROM people
WHERE person_id = 1;

-- ---------------------------------------------------------------------
-- V7. v_projects_section: each project with its role, company and skills
--     GROUP_CONCAT turns the linked skill rows back into one readable
--     list: stored separately, shown together.
-- Expected: 18 rows (one per role-project link)
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW v_projects_section AS
SELECT p.project_name AS project,
       r.role_title   AS role,
       c.company_name AS company,
       GROUP_CONCAT(s.skill_name ORDER BY s.skill_name SEPARATOR ', ') AS skills,
       r.start_date
FROM role_projects       AS rp
JOIN projects            AS p  ON rp.project_id   = p.project_id
JOIN roles               AS r  ON rp.role_id      = r.role_id
JOIN employment          AS e  ON r.employment_id = e.employment_id
JOIN companies           AS c  ON e.company_id    = c.company_id
LEFT JOIN project_skills AS ps ON ps.project_id   = p.project_id
LEFT JOIN skills         AS s  ON ps.skill_id     = s.skill_id
GROUP BY rp.role_id, rp.project_id, p.project_name, r.role_title, c.company_name, r.start_date;

-- ---------------------------------------------------------------------
-- V8. v_education_section: qualifications with readable years
--     CASE chooses between two ways of writing the years.
-- Expected: 4 rows; years '1983 - 1987', '2004', '2016', '2025'
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW v_education_section AS
SELECT qualification,
       institution,
       CASE WHEN start_year = end_year THEN CAST(end_year AS CHAR)
            ELSE CONCAT(start_year, ' - ', end_year)
       END AS years,
       end_year
FROM education;

-- ---------------------------------------------------------------------
-- Grants: the web user may read the new views too (users from Module 9)
-- Expected: SHOW GRANTS lists 7 SELECT grants on views
-- ---------------------------------------------------------------------
GRANT SELECT ON future_portfolio_db.v_profile_header    TO 'portfolio_web'@'localhost';
GRANT SELECT ON future_portfolio_db.v_projects_section  TO 'portfolio_web'@'localhost';
GRANT SELECT ON future_portfolio_db.v_education_section TO 'portfolio_web'@'localhost';
-- Re-grant Module 9's four (safe to repeat; needed after a rebuild):
GRANT SELECT ON future_portfolio_db.v_experience        TO 'portfolio_web'@'localhost';
GRANT SELECT ON future_portfolio_db.v_awards_section    TO 'portfolio_web'@'localhost';
GRANT SELECT ON future_portfolio_db.v_skill_evidence    TO 'portfolio_web'@'localhost';
GRANT SELECT ON future_portfolio_db.v_career_summary    TO 'portfolio_web'@'localhost';
SHOW GRANTS FOR 'portfolio_web'@'localhost';

-- =====================  D. THE RESUME, FROM TABLES  ===================
-- Run these in a connection logged in AS portfolio_web.
-- Seven queries, no PDF: Day 1's promise, kept.

-- RS01. Header                     -- 1 row: Ananya Rao | headline | Bengaluru, India | summary
SELECT full_name, headline, location, professional_summary
FROM future_portfolio_db.v_profile_header;

-- RS02. Career at a glance         -- 7 | 17 | 16 | 17 | 19 | 40.0000
SELECT * FROM future_portfolio_db.v_career_summary;

-- RS03. Experience                 -- 17 rows, newest first
SELECT company, role, dates, team
FROM future_portfolio_db.v_experience
ORDER BY start_date DESC;

-- RS04. Selected projects          -- 18 rows, newest first
SELECT project, role, company, skills
FROM future_portfolio_db.v_projects_section
ORDER BY start_date DESC, project;

-- RS05. Skills with evidence       -- 15 rows, most-used first
SELECT skill_name, skill_category, project_count
FROM future_portfolio_db.v_skill_evidence
WHERE project_count > 0
ORDER BY project_count DESC, skill_name;

-- RS06. Education                  -- 4 rows, newest first
SELECT qualification, institution, years
FROM future_portfolio_db.v_education_section
ORDER BY end_year DESC;

-- RS07. Awards and recognition     -- 19 rows, newest first
SELECT year, award, awarded_by
FROM future_portfolio_db.v_awards_section
ORDER BY year DESC, award_id;
