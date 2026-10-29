-- =====================================================================
-- 03_crud_practice.sql
-- Course 4: Structured Databases | Module 4: CRUD Operations
-- Project: future_portfolio_db
--
-- Completes Ananya Rao's resume data and practises safe changes:
--   C  INSERT  the rest of the resume (projects, skills, links,
--              education, awards, community service, interests,
--              achievements)
--   R  SELECT  verification queries after each step
--   U  UPDATE  three recruiter-review corrections, each with a
--              SELECT before and after
--   D  DELETE  one temporary test row, added and then removed
--
-- Rebuild order:
--   01_schema.sql -> 02_seed_core.sql -> 02a_constraints.sql
--   -> 03_crud_practice.sql
--
-- Every UPDATE and DELETE uses the primary key in its WHERE clause,
-- so the file runs with Workbench's Safe Updates setting switched on.
--
-- Expected row counts at the end:
--   projects 16, role_projects 18, skills 17, project_skills 32,
--   education 4, awards 19, community_service 3, interests 5,
--   achievements 15 (people 1, companies 7, employment 7, roles 17)
-- =====================================================================

USE future_portfolio_db;

-- =====================================================================
-- C: CREATE
-- =====================================================================

-- ---------------------------------------------------------------------
-- C1. projects: the remaining 11 of the 16 agreed projects
-- ---------------------------------------------------------------------
INSERT INTO projects (project_id, project_name, description) VALUES
(1,  'Recovery improvement programme',
     'Improvements to transaction-log scanning, checkpoint handling and recovery diagnostics; restart-and-recovery time cut by 35%.'),
(2,  'Import pipeline rework',
     'Import pipeline reworked to process records in batches with restart checkpoints; throughput improved by 28%.'),
(3,  'Application-core migration',
     'Stable boundary between the legacy computational engine and the new graphical interface; three high-use workflows migrated incrementally.'),
(4,  'Order-processing engine',
     'C/C++ services for order validation, pricing and database access in the first commercial product.'),
(5,  'Browser-based B2B ordering platform',
     'Ordering platform integrating catalogues, inventory availability and order status with customer enterprise systems.'),
(6,  'Shared subscription administration service',
     'The company''s first shared subscription administration service, with engineering-support escalation procedures.'),
(8,  'Hosting environment consolidation',
     'Consolidated two hosting environments, lowering recurring infrastructure expense by 18% without breaching service levels.'),
(9,  'Release recovery programme',
     'Focused recovery roadmap after a difficult launch; aged critical-defect backlog reduced by 63% within nine months.'),
(11, 'Developer API programme',
     'Supported developer APIs with versioning, usage limits and migration notices; 120 certified customer and partner integrations.'),
(12, 'Services architecture modernisation',
     'Replaced a tightly coupled deployment architecture with independently deployable services where justified; avoided a wholesale rewrite.'),
(16, 'Enterprise assistant deployment',
     'Controlled deployment of an enterprise assistant to 300 design-partner customers before general release.');

-- ---------------------------------------------------------------------
-- C2. role_projects: the remaining 12 links
-- ---------------------------------------------------------------------
INSERT INTO role_projects (role_id, project_id, contribution) VALUES
(3,  1,  'Technical lead for the recovery programme; designed log-scanning and checkpoint improvements.'),
(2,  2,  'Reworked the import pipeline and added record-level rejection reports.'),
(4,  3,  'Mapped undocumented file-processing dependencies and wrote the migration guide.'),
(5,  3,  'Defined the application boundary and led the incremental workflow migration.'),
(6,  4,  'Designed the order-validation, pricing and database-access services.'),
(8,  5,  'Led delivery of the browser-based ordering platform.'),
(9,  6,  'Delivered the first shared subscription administration service.'),
(12, 8,  'Completed the consolidation of two hosting environments.'),
(13, 9,  'Ran the 60-day assessment and negotiated the recovery roadmap.'),
(14, 11, 'Established the supported developer API programme.'),
(15, 12, 'Replaced the tightly coupled deployment architecture.'),
(17, 16, 'Led the controlled deployment to 300 design-partner customers.');

-- ---------------------------------------------------------------------
-- C3. skills: the remaining 11 of the 17 agreed skills
-- ---------------------------------------------------------------------
INSERT INTO skills (skill_id, skill_name, skill_category) VALUES
(1,  'C/C++',                             'Language'),
(2,  'UNIX shell scripting',              'Language'),
(3,  'Relational data access',            'Data'),
(4,  'Performance profiling',             'Engineering practice'),
(5,  'Transaction processing & recovery', 'Data'),
(8,  'Enterprise integration',            'Architecture'),
(9,  'Release engineering',               'Engineering practice'),
(11, 'Product security',                  'Security'),
(14, 'API design & versioning',           'Architecture'),
(16, 'AI product governance',             'Governance'),
(17, 'Technical due diligence',           'Governance');

-- Skills 2 and 17 deliberately get no project links: Module 6 finds them.

-- ---------------------------------------------------------------------
-- C4. project_skills: the remaining 23 links
-- ---------------------------------------------------------------------
INSERT INTO project_skills (project_id, skill_id) VALUES
(1, 3),  (1, 5),
(2, 3),  (2, 4),
(3, 1),  (3, 4),  (3, 6),
(4, 1),  (4, 3),  (4, 5),
(5, 8),
(6, 7),  (6, 9),
(8, 6),  (8, 15),
(9, 9),
(11, 8), (11, 14),
(12, 6), (12, 10),
(13, 11),
(16, 11), (16, 16);

-- ---------------------------------------------------------------------
-- C5. education (4 rows)
--     "Continuing executive learning" has no institution or year,
--     so it is left out (Module 1 Exercise 6).
-- ---------------------------------------------------------------------
INSERT INTO education (education_id, person_id, qualification, institution, education_type, start_year, end_year) VALUES
(1, 1, 'B.E., Computer Science & Engineering',
       'Deccan Institute of Technology, Bengaluru',     'Degree',              1983, 1987),
(2, 1, 'Executive Programme in Business Finance',
       'Western School of Management',                  'Executive programme', 2004, 2004),
(3, 1, 'Technology Strategy & Innovation Programme',
       'International School of Executive Studies',     'Executive programme', 2016, 2016),
(4, 1, 'Board Governance & Director Readiness Programme',
       'Centre for Corporate Stewardship',              'Executive programme', 2025, 2025);

-- ---------------------------------------------------------------------
-- C6. awards (19 rows: one row per award-year)
--     company_id is filled only for awards given by an employer.
-- ---------------------------------------------------------------------
INSERT INTO awards (award_id, person_id, award_name, awarding_body, award_year, award_category, company_id, citation) VALUES
(1,  1, 'Chairman''s Award for Enterprise Stewardship', 'Lumina Software',           2026, 'Company', 7,
     'Completion of platform renewal, stronger technology-risk reporting and a planned internal CTO succession.'),
(2,  1, 'Customer Trust Leadership Award',              'Lumina Software',           2024, 'Company', 7,
     'Cross-functional service-resilience and product-security programme.'),
(3,  1, 'CEO''s Transformation Award',                  'Aster Data Platforms',      2020, 'Company', 6,
     'Product-portfolio simplification, platform economics and enterprise-readiness improvements.'),
(4,  1, 'Global Leadership Award',                      'NexaCollab',                2014, 'Company', 5,
     'Cross-site engineering development, internal leadership appointments and improved delivery performance.'),
(5,  1, 'Founders'' Recognition for Commitment',        'CloudHarbor Software',      2009, 'Company', 4,
     'Completion of core-platform stabilisation following the financial-crisis restructuring.'),
(6,  1, 'Product Builder Award',                        'MarketBridge Technologies', 1998, 'Company', 3,
     'Reusable transaction services and more repeatable customer implementations.'),
(7,  1, 'Engineering Excellence Award',                 'VectorWorks Software',      1993, 'Company', 2,
     'File-processing performance and compatibility improvements.'),
(8,  1, 'Technical Contribution Award',                 'Meridian Systems',          1991, 'Company', 1,
     'Recovery testing and diagnostic improvements.'),
(9,  1, 'Quality Improvement Award',                    'Meridian Systems',          1989, 'Company', 1,
     'Import reliability.'),
(10, 1, 'Technology Stewardship Honour',                'Enterprise Software Leadership Forum', 2025, 'Industry', NULL,
     'Transparent technology governance and responsible enterprise AI introduction.'),
(11, 1, 'Distinguished Engineering Leader',             'Product Engineering Council of India',  2022, 'Industry', NULL,
     'Sustained contributions to product engineering and technical leadership development.'),
(12, 1, 'Leadership Catalyst Award',                    'Women in Product Technology Network',  2018, 'Industry', NULL,
     'Sponsorship of women progressing into senior technical and management roles.'),
(13, 1, 'Invited Industry Fellow',                      'Global SaaS Practitioners Forum',      2016, 'Industry', NULL,
     'Practitioner perspectives on platform reliability and engineering scale.'),
(14, 1, 'Invited keynote speaker',                      'Enterprise Product Summit',            2013, 'Industry', NULL,
     'Keynote on distributed engineering.'),
(15, 1, 'Invited keynote speaker',                      'Enterprise Product Summit',            2019, 'Industry', NULL,
     'Keynote on platform investment.'),
(16, 1, 'Invited keynote speaker',                      'Enterprise Product Summit',            2024, 'Industry', NULL,
     'Keynote on technology stewardship.'),
(17, 1, 'Community Leadership Recognition',             'Open Pathways Education Trust',        2023, 'Community', NULL,
     'A structured mentoring and scholarship programme for first-generation women engineering students.'),
(18, 1, 'Volunteer Mentor Distinction',                 'City Learning Partnership',            2017, 'Community', NULL,
     'Sustained career mentoring and employer-supported student project reviews.'),
(19, 1, 'Mentor Service Recognition',                   'Women in Product Technology Network',  2011, 'Community', NULL,
     'Long-term support to early-career engineers returning after family-related career breaks.');

-- ---------------------------------------------------------------------
-- C7. community_service (3 rows); end_year NULL = still serving
-- ---------------------------------------------------------------------
INSERT INTO community_service (service_id, person_id, organisation, service_role, start_year, end_year, description) VALUES
(1, 1, 'Open Pathways Education Trust',       'Volunteer advisory council member',      2016, NULL,
    'Helped establish mentor selection, scholarship review and internship-readiness programmes; 240 students across eight cohorts by 2026.'),
(2, 1, 'Women in Product Technology Network', 'Volunteer mentor',                       2008, NULL,
    'Career-transition mentoring; sponsors senior women for visible technical leadership assignments.'),
(3, 1, 'Product Engineering Council of India', 'Practitioner working group contributor', 2019, 2025,
    'Contributed to guidance on engineering career frameworks and responsible product operations.');

-- ---------------------------------------------------------------------
-- C8. interests (5 rows)
-- ---------------------------------------------------------------------
INSERT INTO interests (interest_id, person_id, interest_category, description) VALUES
(1, 1, 'Sports & outdoors',
    'Recreational distance runner and regular swimmer; completed four half-marathons between 2012 and 2024.'),
(2, 1, 'Sports & outdoors',
    'Doubles badminton, weekend cycling and annual guided trekking trips.'),
(3, 1, 'Arts & culture',
    'Student and listener of Hindustani classical music, with a particular interest in raga interpretation.'),
(4, 1, 'Arts & culture',
    'Theatre, architectural walks, museum visits and sketching historic buildings; keeps a travel journal.'),
(5, 1, 'History of knowledge',
    'Studies how societies preserve, organise and transmit knowledge; monthly reading circle and community digitisation projects.');

-- ---------------------------------------------------------------------
-- C9. achievements (15 rows): the Module 1 Exercise 5 answer key
--     value_before is NULL where the resume gives only the change.
-- ---------------------------------------------------------------------
INSERT INTO achievements (achievement_id, role_id, project_id, measure, value_before, value_after, unit) VALUES
(1,  2,  2,    'Import throughput improvement',        NULL,     28,      '%'),
(2,  3,  1,    'Restart-and-recovery time reduction',  NULL,     35,      '%'),
(3,  3,  NULL, 'Developer escalations per quarter',    18,       11,      'count'),
(4,  5,  3,    'Large-file opening time reduction',    NULL,     31,      '%'),
(5,  8,  5,    'Paying customers',                     28,       110,     'count'),
(6,  8,  NULL, 'Median deployment duration',           16,       10,      'weeks'),
(7,  11, 7,    'Subscription customers',               420,      1300,    'count'),
(8,  12, 8,    'Infrastructure expense reduction',     NULL,     18,      '%'),
(9,  14, NULL, 'Milestones delivered on schedule',     58,       86,      '%'),
(10, 14, 10,   'Monthly active mobile users',          90000,    1400000, 'count'),
(11, 15, NULL, 'Emergency rollback frequency',         14,       5,       '% of major releases'),
(12, 16, NULL, 'Annual recurring revenue',             180,      620,     'USD million'),
(13, 17, NULL, 'Flagship availability',                99.93,    99.98,   '%'),
(14, 17, NULL, 'Director roles filled internally',     32,       57,      '%'),
(15, 17, 14,   'Cloud cost per active user reduction', NULL,     24,      '%');

-- =====================================================================
-- R: READ (verification after the inserts)
-- =====================================================================
SELECT * FROM projects;        -- 16 rows
SELECT * FROM skills;          -- 17 rows
SELECT * FROM education;       -- 4 rows
SELECT * FROM awards;          -- 19 rows
SELECT * FROM community_service; -- 3 rows
SELECT * FROM interests;       -- 5 rows
SELECT * FROM achievements;    -- 15 rows

-- =====================================================================
-- U: UPDATE (recruiter-review corrections)
-- The safe habit: SELECT the row, UPDATE by primary key, SELECT again.
-- The Output panel should say "1 row(s) affected" for each UPDATE.
-- =====================================================================

-- U1. "Platform renewal" is too vague on a public profile.
SELECT project_id, project_name FROM projects WHERE project_id = 14;

UPDATE projects
SET project_name = 'Lumina platform renewal'
WHERE project_id = 14;

SELECT project_id, project_name FROM projects WHERE project_id = 14;

-- U2. Use the full name of the skill.
SELECT skill_id, skill_name FROM skills WHERE skill_id = 10;

UPDATE skills
SET skill_name = 'Site reliability engineering'
WHERE skill_id = 10;

SELECT skill_id, skill_name FROM skills WHERE skill_id = 10;

-- U3. The headline should reflect the board-candidate profile.
SELECT person_id, headline FROM people WHERE person_id = 1;

UPDATE people
SET headline = 'Former Chief Technology Officer | Candidate for non-executive board roles'
WHERE person_id = 1;

SELECT person_id, headline FROM people WHERE person_id = 1;

-- =====================================================================
-- D: DELETE (a temporary test row only)
-- =====================================================================

-- D1. Add a test row, check it, delete it by primary key, check again.
INSERT INTO interests (interest_id, person_id, interest_category, description)
VALUES (99, 1, 'Test', 'Temporary row for delete practice');

SELECT * FROM interests WHERE interest_id = 99;   -- 1 row

DELETE FROM interests
WHERE interest_id = 99;

SELECT * FROM interests WHERE interest_id = 99;   -- 0 rows
