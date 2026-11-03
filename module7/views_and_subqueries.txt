-- =====================================================================
-- 06_views_and_subqueries.sql
-- Course 4: Structured Databases | Module 7: Subqueries and Reusable Views
-- Project: future_portfolio_db
--
-- Part A  Twelve labelled subquery questions (SQ01-SQ12). Read only.
-- Part B  Five views (V1-V5): saved queries the web page and later
--         modules reuse. CREATE OR REPLACE, so the file can be re-run.
-- Part C  Five queries that use the views (VQ1-VQ5). VQ4 changes a
--         value inside a transaction and rolls it back.
--
-- Rebuild order (views depend on the tables, so this file comes last):
--   01_schema.sql -> 02_seed_core.sql -> 02a_constraints.sql
--   -> 03_crud_practice.sql (provided) -> 06_views_and_subqueries.sql
-- 04_ and 05_ are query libraries: they read data and can run any time.
--
-- Aliases as in Module 6:
--   c companies   e employment   r roles   p projects   s skills
--   rp role_projects   ps project_skills   a awards   ach achievements
-- =====================================================================

USE future_portfolio_db;

-- =====================  A. SUBQUERIES  ================================

-- ---------------------------------------------------------------------
-- SQ01. Which roles led more people than the average role?
-- Practises: scalar subquery in WHERE
-- Expected: 4 rows: roles 14 (620), 15 (410), 16 (950), 17 (1800)
-- Note: the inner query returns one value, 373.1667 (Module 5, RQ10).
-- ---------------------------------------------------------------------
SELECT r.role_id, r.role_title, r.team_size
FROM roles AS r
WHERE r.team_size > (SELECT AVG(team_size) FROM roles)
ORDER BY r.team_size DESC;

-- ---------------------------------------------------------------------
-- SQ02. Which role had the largest team? (without LIMIT)
-- Practises: scalar subquery with MAX
-- Expected: 1 row: role 17, Chief Technology Officer, 1800
-- Note: unlike ORDER BY ... LIMIT 1, this returns every role on a tie.
-- ---------------------------------------------------------------------
SELECT r.role_id, r.role_title, r.team_size
FROM roles AS r
WHERE r.team_size = (SELECT MAX(team_size) FROM roles);

-- ---------------------------------------------------------------------
-- SQ03. Which roles did she hold at CloudHarbor Software?
-- Practises: nested subqueries: = (one value) inside IN (a list)
-- Expected: 4 rows: roles 9, 10, 11, 12
-- ---------------------------------------------------------------------
SELECT r.role_id, r.role_title
FROM roles AS r
WHERE r.employment_id IN (
        SELECT e.employment_id
        FROM employment AS e
        WHERE e.company_id = (
                SELECT c.company_id
                FROM companies AS c
                WHERE c.company_name = 'CloudHarbor Software'))
ORDER BY r.role_id;

-- ---------------------------------------------------------------------
-- SQ04. Which projects used Platform migration? (JQ07 as a subquery)
-- Practises: IN subquery instead of a join
-- Expected: 6 rows: projects 3, 7, 8, 12, 14, 15
-- ---------------------------------------------------------------------
SELECT p.project_id, p.project_name
FROM projects AS p
WHERE p.project_id IN (
        SELECT ps.project_id
        FROM project_skills AS ps
        WHERE ps.skill_id = (
                SELECT s.skill_id FROM skills AS s
                WHERE s.skill_name = 'Platform migration'))
ORDER BY p.project_id;

-- ---------------------------------------------------------------------
-- SQ05. Which skills have no project evidence? (JQ11 as a subquery)
-- Practises: NOT IN
-- Expected: 2 rows: skill 2 UNIX shell scripting,
--           skill 17 Technical due diligence
-- ---------------------------------------------------------------------
SELECT s.skill_id, s.skill_name
FROM skills AS s
WHERE s.skill_id NOT IN (SELECT ps.skill_id FROM project_skills AS ps);

-- ---------------------------------------------------------------------
-- SQ06. Which projects have no achievement? The NOT IN trap.
-- Practises: NOT IN with a NULL in the list
-- Expected: first query 0 rows (wrong!); second query 8 rows
-- Note: achievements.project_id is NULL for 7 achievements. "x NOT IN
--       (..., NULL)" is never true, so the first query returns nothing.
-- ---------------------------------------------------------------------
SELECT p.project_id, p.project_name
FROM projects AS p
WHERE p.project_id NOT IN (SELECT ach.project_id FROM achievements AS ach);

SELECT p.project_id, p.project_name
FROM projects AS p
WHERE p.project_id NOT IN (SELECT ach.project_id FROM achievements AS ach
                           WHERE ach.project_id IS NOT NULL)
ORDER BY p.project_id;

-- ---------------------------------------------------------------------
-- SQ07. Which projects have no achievement? (the safe way)
-- Practises: NOT EXISTS with a correlated subquery
-- Expected: 8 rows: projects 4, 6, 9, 11, 12, 13, 15, 16
-- ---------------------------------------------------------------------
SELECT p.project_id, p.project_name
FROM projects AS p
WHERE NOT EXISTS (SELECT 1
                  FROM achievements AS ach
                  WHERE ach.project_id = p.project_id)
ORDER BY p.project_id;

-- ---------------------------------------------------------------------
-- SQ08. Which roles have at least one measurable achievement?
-- Practises: EXISTS
-- Expected: 10 rows: roles 2, 3, 5, 8, 11, 12, 14, 15, 16, 17
-- ---------------------------------------------------------------------
SELECT r.role_id, r.role_title
FROM roles AS r
WHERE EXISTS (SELECT 1
              FROM achievements AS ach
              WHERE ach.role_id = r.role_id)
ORDER BY r.role_id;

-- ---------------------------------------------------------------------
-- SQ09. How many achievements does each role have?
-- Practises: correlated scalar subquery in SELECT
-- Expected: 17 rows; role 17 -> 3; roles 3, 8, 14 -> 2; seven roles -> 0
-- ---------------------------------------------------------------------
SELECT r.role_id,
       r.role_title,
       (SELECT COUNT(*)
        FROM achievements AS ach
        WHERE ach.role_id = r.role_id) AS achievement_count
FROM roles AS r
ORDER BY r.role_id;

-- ---------------------------------------------------------------------
-- SQ10. On average, how many roles did she hold per company?
-- Practises: derived table (a subquery in FROM, with an alias)
-- Expected: 1 row: 2.4286 (17 roles / 7 companies)
-- ---------------------------------------------------------------------
SELECT AVG(per_company.role_count) AS avg_roles_per_company
FROM (SELECT e.company_id, COUNT(*) AS role_count
      FROM roles      AS r
      JOIN employment AS e ON r.employment_id = e.employment_id
      GROUP BY e.company_id) AS per_company;

-- ---------------------------------------------------------------------
-- SQ11. At which companies did she hold more roles than average?
-- Practises: subquery inside HAVING
-- Expected: 3 rows: CloudHarbor Software 4, MarketBridge Technologies 3,
--           Meridian Systems 3
-- ---------------------------------------------------------------------
SELECT c.company_name, COUNT(*) AS role_count
FROM roles      AS r
JOIN employment AS e ON r.employment_id = e.employment_id
JOIN companies  AS c ON e.company_id    = c.company_id
GROUP BY c.company_name
HAVING COUNT(*) > (SELECT AVG(per_company.role_count)
                   FROM (SELECT COUNT(*) AS role_count
                         FROM roles AS r2
                         GROUP BY r2.employment_id) AS per_company)
ORDER BY role_count DESC, c.company_name;

-- ---------------------------------------------------------------------
-- SQ12. What was her largest team in each employment period?
-- Practises: correlated subquery in WHERE (compare with the same group)
-- Expected: 7 rows: roles 3 (5), 5 (6), 8 (85), 11 (230), 14 (620),
--           16 (950), 17 (1800)
-- ---------------------------------------------------------------------
SELECT r.employment_id, r.role_id, r.role_title, r.team_size
FROM roles AS r
WHERE r.team_size = (SELECT MAX(r2.team_size)
                     FROM roles AS r2
                     WHERE r2.employment_id = r.employment_id)
ORDER BY r.employment_id;

-- =====================  B. VIEWS  =====================================
-- A view is a saved SELECT with a name. It stores no rows: every time
-- you select from it, MySQL runs its query against the current data.
-- Views have no ORDER BY: whoever selects from a view chooses the order.

-- ---------------------------------------------------------------------
-- V1. v_role_details: every role with its company and length in months
-- Expected: 17 rows
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW v_role_details AS
SELECT r.role_id,
       c.company_name,
       r.role_title,
       r.start_date,
       r.end_date,
       r.team_size,
       TIMESTAMPDIFF(MONTH, r.start_date, r.end_date) + 1 AS months
FROM roles      AS r
JOIN employment AS e ON r.employment_id = e.employment_id
JOIN companies  AS c ON e.company_id    = c.company_id;

-- ---------------------------------------------------------------------
-- V2. v_experience: the resume's Experience section (JQ16 as a view)
-- Expected: 17 rows; start_date is kept so callers can sort by it
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW v_experience AS
SELECT c.company_name AS company,
       r.role_title   AS role,
       CONCAT(DATE_FORMAT(r.start_date, '%b %Y'), ' - ',
              DATE_FORMAT(r.end_date,   '%b %Y')) AS dates,
       r.team_size    AS team,
       r.start_date
FROM roles      AS r
JOIN employment AS e ON r.employment_id = e.employment_id
JOIN companies  AS c ON e.company_id    = c.company_id;

-- ---------------------------------------------------------------------
-- V3. v_skill_evidence: every skill with the number of projects using it
-- Expected: 17 rows; skills 2 and 17 have project_count 0
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW v_skill_evidence AS
SELECT s.skill_id,
       s.skill_name,
       s.skill_category,
       COUNT(ps.project_id) AS project_count
FROM skills              AS s
LEFT JOIN project_skills AS ps ON ps.skill_id = s.skill_id
GROUP BY s.skill_id, s.skill_name, s.skill_category;

-- ---------------------------------------------------------------------
-- V4. v_awards_section: the resume's Awards section (JQ17 as a view)
-- Expected: 19 rows; awarded_by never NULL
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW v_awards_section AS
SELECT a.award_id,
       a.award_year     AS year,
       a.award_name     AS award,
       COALESCE(c.company_name, a.awarding_body) AS awarded_by,
       a.award_category AS category
FROM awards         AS a
LEFT JOIN companies AS c ON a.company_id = c.company_id;

-- ---------------------------------------------------------------------
-- V5. v_career_summary: one row of headline numbers for a profile page
-- Expected: 1 row: companies 7, roles 17, projects 16, skills 17,
--           awards 19, career_years 40.0000
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW v_career_summary AS
SELECT (SELECT COUNT(*) FROM companies) AS companies,
       (SELECT COUNT(*) FROM roles)     AS roles,
       (SELECT COUNT(*) FROM projects)  AS projects,
       (SELECT COUNT(*) FROM skills)    AS skills,
       (SELECT COUNT(*) FROM awards)    AS awards,
       (SELECT SUM(TIMESTAMPDIFF(MONTH, e.start_date, e.end_date) + 1) / 12
        FROM employment AS e)           AS career_years;

-- =====================  C. USING THE VIEWS  ===========================

-- ---------------------------------------------------------------------
-- VQ1. The Experience section, newest first: one short query
-- Expected: 17 rows; first: Lumina Software | Chief Technology Officer |
--           Jun 2021 - May 2026 | 1800
-- ---------------------------------------------------------------------
SELECT company, role, dates, team
FROM v_experience
ORDER BY start_date DESC;

-- ---------------------------------------------------------------------
-- VQ2. Skills with no project evidence, from the view
-- Expected: 2 rows: UNIX shell scripting, Technical due diligence
-- ---------------------------------------------------------------------
SELECT skill_id, skill_name
FROM v_skill_evidence
WHERE project_count = 0;

-- ---------------------------------------------------------------------
-- VQ3. Total months in roles at each company, longest first
-- Practises: GROUP BY on a view
-- Expected: 7 rows: CloudHarbor Software 96, MarketBridge Technologies 84,
--           then three companies on 72, Lumina Software 60,
--           VectorWorks Software 24. Total 480 months = 40 years.
-- ---------------------------------------------------------------------
SELECT company_name, SUM(months) AS months_in_roles
FROM v_role_details
GROUP BY company_name
ORDER BY months_in_roles DESC, company_name;

-- ---------------------------------------------------------------------
-- VQ4. A view stores no data: change a table, the view changes too.
-- Practises: transaction + ROLLBACK (Module 4) with a view
-- Expected: team 2000 inside the transaction; 1800 after ROLLBACK
-- ---------------------------------------------------------------------
START TRANSACTION;
UPDATE roles SET team_size = 2000 WHERE role_id = 17;
SELECT role, team FROM v_experience WHERE role = 'Chief Technology Officer';
ROLLBACK;
SELECT role, team FROM v_experience WHERE role = 'Chief Technology Officer';

-- ---------------------------------------------------------------------
-- VQ5. The profile page's headline numbers
-- Expected: 1 row: 7 | 17 | 16 | 17 | 19 | 40.0000
-- ---------------------------------------------------------------------
SELECT * FROM v_career_summary;

-- List the views in this database (Workbench: refresh the Views folder)
SHOW FULL TABLES WHERE Table_type = 'VIEW';     -- 5 views
