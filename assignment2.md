# SQL Practice Tasks

## Subqueries

### Task 1: Employees Above Overall Average Salary
Find employees whose salary is greater than the overall average salary of the company.

### Task 2: Highest Salary in the Company
Find the employee or employees who receive the highest salary in the company.

**Requirement:**
- Use a subquery.
- Do not use ORDER BY and LIMIT.

### Task 3: Employees Above Their Department Average
Find employees who earn more than the average salary of their own department.

### Task 4: Departments With Employees Earning More Than 60,000
Find departments that have at least one employee earning more than 60,000.

**Requirements:**
- Use IN or EXISTS.
- Use a subquery.

### Task 5: Employees in the Department With the Highest Average Salary
Find employees who belong to the department with the highest average salary.

### Task 6: Second-Highest Distinct Salary
Find the second-highest distinct salary using a subquery.

**Requirement:**
- Handle duplicate salaries correctly.

---

## Reusable Views

### Task 7: Create Employee Department View

Create a view named `employee_department_view` displaying:

- Employee ID
- Employee name
- Email
- Salary
- Department name
- Department location

### Task 8: Retrieve Employee Department View

Retrieve all records from `employee_department_view`.

### Task 9: Create Department Salary Summary View

Create a view named `department_salary_summary` displaying:

- Department name
- Total employee count
- Average salary
- Total salary expenditure

### Task 10: Filter Departments From Summary View

Retrieve departments from `department_salary_summary` whose average salary is greater than 45,000.

### Task 11: Modify Employee Department View

Modify the definition of `employee_department_view` to include department ID.

### Task 12: Drop a View

Drop one view without deleting the original tables or their records.

---

## Advanced SQL Challenges

### Task 13: Department Salary Comparison

Find departments whose total salary expenditure is greater than the average department-level salary expenditure.

**Requirements:**
- Use GROUP BY.
- Use HAVING.
- Use a subquery.

### Task 14: Employees Above Department Average

Display employees who earn more than their own department's average salary.

**Display:**
- Employee name
- Employee salary
- Department name
- Department average salary

### Task 15: Departments Without Employees

Find departments that currently have no employees.

**Requirements:**
- Use LEFT JOIN or NOT EXISTS.
- Your query should work even when new departments are added later.

### Task 16: Salary Distribution

Classify employees into salary bands:

| Salary | Category |
|---|---|
| 60,000 and above | High |
| 40,000–59,999 | Medium |
| Below 40,000 | Low |

**Display:**
- Department name
- Salary category
- Number of employees in each category

**Requirements:**
- Use CASE.
- Use GROUP BY.

### Task 17: JOIN and Subquery Challenge

Find employees who earn more than at least one employee in the Development department but do not belong to the Development department.

**Requirements:**
- Use JOIN.
- Use a subquery.
- Use appropriate filtering conditions.

### Task 18: Foreign Key and Data Integrity

Attempt to delete a department that still has employees assigned to it.

**Tasks:**

1. Observe the database error.
2. Explain why the database prevents the deletion.
3. Find the employees assigned to that department.
4. Explain two safe approaches to deleting the department.