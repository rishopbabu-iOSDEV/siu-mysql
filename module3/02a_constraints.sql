
--    Policy: RESTRICT. A person or company with employment rows
--    cannot be deleted; career history is never removed by accident.
-- ---------------------------------------------------------------------
ALTER TABLE employment DROP FOREIGN KEY fk_employment_person;
ALTER TABLE employment DROP FOREIGN KEY fk_employment_company;

ALTER TABLE employment
    MODIFY person_id  INT  NOT NULL,
    MODIFY company_id INT  NOT NULL,
    MODIFY start_date DATE NOT NULL,
    ADD CONSTRAINT chk_employment_dates
        CHECK (end_date IS NULL OR end_date >= start_date);

ALTER TABLE employment
    ADD CONSTRAINT fk_employment_person
        FOREIGN KEY (person_id) REFERENCES people (person_id)
        ON DELETE RESTRICT,
    ADD CONSTRAINT fk_employment_company
        FOREIGN KEY (company_id) REFERENCES companies (company_id)
        ON DELETE RESTRICT;

-- ---------------------------------------------------------------------
-- 4. roles
--    Policy: RESTRICT. An employment period with roles cannot be deleted.
-- ---------------------------------------------------------------------
ALTER TABLE roles DROP FOREIGN KEY fk_roles_employment;

ALTER TABLE roles
    MODIFY employment_id INT          NOT NULL,
    MODIFY role_title    VARCHAR(100) NOT NULL,
    MODIFY start_date    DATE         NOT NULL,
    ADD CONSTRAINT chk_roles_dates
        CHECK (end_date IS NULL OR end_date >= start_date),
    ADD CONSTRAINT chk_roles_team_size
        CHECK (team_size IS NULL OR team_size > 0);

ALTER TABLE roles
    ADD CONSTRAINT fk_roles_employment
        FOREIGN KEY (employment_id) REFERENCES employment (employment_id)
        ON DELETE RESTRICT;

-- ---------------------------------------------------------------------
-- 5. projects: a name is required and unique
-- ---------------------------------------------------------------------
ALTER TABLE projects
    MODIFY project_name VARCHAR(150) NOT NULL,
    ADD CONSTRAINT uq_projects_name UNIQUE (project_name);

-- ---------------------------------------------------------------------
-- 6. role_projects (junction)
--    Policy: CASCADE. A link row means nothing without both ends, so
--    deleting a role or a project deletes its link rows too.
--    (Primary-key columns are already NOT NULL.)
-- ---------------------------------------------------------------------
ALTER TABLE role_projects DROP FOREIGN KEY fk_role_projects_role;
ALTER TABLE role_projects DROP FOREIGN KEY fk_role_projects_project;

ALTER TABLE role_projects
    ADD CONSTRAINT fk_role_projects_role
        FOREIGN KEY (role_id) REFERENCES roles (role_id)
        ON DELETE CASCADE,
    ADD CONSTRAINT fk_role_projects_project
        FOREIGN KEY (project_id) REFERENCES projects (project_id)
        ON DELETE CASCADE;

-- ---------------------------------------------------------------------
-- 7. skills: name required and unique; category defaults to 'General'
-- ---------------------------------------------------------------------
ALTER TABLE skills
    MODIFY skill_name     VARCHAR(100) NOT NULL,
    MODIFY skill_category VARCHAR(50)  NOT NULL DEFAULT 'General',
    ADD CONSTRAINT uq_skills_name UNIQUE (skill_name);

-- ---------------------------------------------------------------------
-- 8. project_skills (junction): CASCADE, as for role_projects
-- ---------------------------------------------------------------------
ALTER TABLE project_skills DROP FOREIGN KEY fk_project_skills_project;
ALTER TABLE project_skills DROP FOREIGN KEY fk_project_skills_skill;

ALTER TABLE project_skills
    ADD CONSTRAINT fk_project_skills_project
        FOREIGN KEY (project_id) REFERENCES projects (project_id)
        ON DELETE CASCADE,
    ADD CONSTRAINT fk_project_skills_skill
        FOREIGN KEY (skill_id) REFERENCES skills (skill_id)
        ON DELETE CASCADE;

-- ---------------------------------------------------------------------
-- 9. education
-- ---------------------------------------------------------------------
ALTER TABLE education DROP FOREIGN KEY fk_education_person;

ALTER TABLE education
    MODIFY person_id      INT          NOT NULL,
    MODIFY qualification  VARCHAR(150) NOT NULL,
    MODIFY institution    VARCHAR(150) NOT NULL,
    MODIFY education_type VARCHAR(30)  NOT NULL DEFAULT 'Executive programme',
    ADD CONSTRAINT chk_education_type
        CHECK (education_type IN ('Degree', 'Executive programme', 'Certificate')),
    ADD CONSTRAINT chk_education_years
        CHECK (end_year IS NULL OR start_year IS NULL OR end_year >= start_year);

ALTER TABLE education
    ADD CONSTRAINT fk_education_person
        FOREIGN KEY (person_id) REFERENCES people (person_id)
        ON DELETE RESTRICT;

-- ---------------------------------------------------------------------
-- 10. awards
--     company_id stays optional (industry and community awards).
--     Policy for company_id: SET NULL. If an employer row were ever
--     deleted, the award stays and simply stops pointing to it.
-- ---------------------------------------------------------------------
ALTER TABLE awards DROP FOREIGN KEY fk_awards_person;
ALTER TABLE awards DROP FOREIGN KEY fk_awards_company;

ALTER TABLE awards
    MODIFY person_id      INT          NOT NULL,
    MODIFY award_name     VARCHAR(150) NOT NULL,
    MODIFY awarding_body  VARCHAR(150) NOT NULL,
    MODIFY award_year     YEAR         NOT NULL,
    MODIFY award_category VARCHAR(20)  NOT NULL,
    ADD CONSTRAINT chk_awards_category
        CHECK (award_category IN ('Company', 'Industry', 'Community'));

ALTER TABLE awards
    ADD CONSTRAINT fk_awards_person
        FOREIGN KEY (person_id) REFERENCES people (person_id)
        ON DELETE RESTRICT,
    ADD CONSTRAINT fk_awards_company
        FOREIGN KEY (company_id) REFERENCES companies (company_id)
        ON DELETE SET NULL;

-- ---------------------------------------------------------------------
-- 11. community_service: end_year NULL means "still serving"
-- ---------------------------------------------------------------------
ALTER TABLE community_service DROP FOREIGN KEY fk_community_service_person;

ALTER TABLE community_service
    MODIFY person_id    INT          NOT NULL,
    MODIFY organisation VARCHAR(150) NOT NULL,
    MODIFY service_role VARCHAR(100) NOT NULL,
    MODIFY start_year   YEAR         NOT NULL,
    ADD CONSTRAINT chk_service_years
        CHECK (end_year IS NULL OR end_year >= start_year);

ALTER TABLE community_service
    ADD CONSTRAINT fk_community_service_person
        FOREIGN KEY (person_id) REFERENCES people (person_id)
        ON DELETE RESTRICT;

-- ---------------------------------------------------------------------
-- 12. interests
-- ---------------------------------------------------------------------
ALTER TABLE interests DROP FOREIGN KEY fk_interests_person;

ALTER TABLE interests
    MODIFY person_id         INT         NOT NULL,
    MODIFY interest_category VARCHAR(50) NOT NULL,
    MODIFY description       TEXT        NOT NULL;

ALTER TABLE interests
    ADD CONSTRAINT fk_interests_person
        FOREIGN KEY (person_id) REFERENCES people (person_id)
        ON DELETE RESTRICT;

-- ---------------------------------------------------------------------
-- 13. achievements
--     role_id required (RESTRICT); project_id optional (SET NULL)
-- ---------------------------------------------------------------------
ALTER TABLE achievements DROP FOREIGN KEY fk_achievements_role;
ALTER TABLE achievements DROP FOREIGN KEY fk_achievements_project;

ALTER TABLE achievements
    MODIFY role_id     INT           NOT NULL,
    MODIFY measure     VARCHAR(150)  NOT NULL,
    MODIFY value_after DECIMAL(14,2) NOT NULL,
    MODIFY unit        VARCHAR(30)   NOT NULL;

ALTER TABLE achievements
    ADD CONSTRAINT fk_achievements_role
        FOREIGN KEY (role_id) REFERENCES roles (role_id)
        ON DELETE RESTRICT,
    ADD CONSTRAINT fk_achievements_project
        FOREIGN KEY (project_id) REFERENCES projects (project_id)
        ON DELETE SET NULL;

-- ---------------------------------------------------------------------
-- Check the result
-- ---------------------------------------------------------------------
DESCRIBE roles;          -- Null = NO for employment_id, role_title, start_date
SHOW CREATE TABLE roles; -- shows both CHECK rules and ON DELETE RESTRICT
