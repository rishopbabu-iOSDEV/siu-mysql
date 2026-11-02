## Objective

Create a small company database, insert the supplied sample data, and
practise basic SQL queries and data modifications.
------------------------------------------------------------------------

## 1. Database Creation (2 minutes)

**Task 1:** Create a database named `company_db` and select it for the
following exercises.

## 2. Table Creation (5 minutes)

**Task 2: Create the `departments` table**

Use the following table structure:

  Column            Data type / requirement
  ----------------- ----------------------------------
  department_id     INT, Primary Key, Auto Increment
  department_name   VARCHAR(100)
  location          VARCHAR(100)

**Task 3: Create the `employees` table**

Use the following table structure:

  -----------------------------------------------------------------------
  Column                              Data type / requirement
  ----------------------------------- -----------------------------------
  employee_id                         INT, Primary Key, Auto Increment

  employee_name                       VARCHAR(100)

  email                               VARCHAR(100)

  salary                              DECIMAL(10,2)

  joining_date                        DATE

  department_id                       INT, Foreign Key referencing
                                      `departments.department_id`
  -----------------------------------------------------------------------

Create the `departments` table before creating the `employees` table
because of the foreign key relationship.

## 3. Insert Sample Records (5 minutes)

**Task 4:** Insert the following four records into the `departments`
table.

### Departments data

    department_id department_name   location
  --------------- ----------------- -----------
                1 DevOps            Chennai
                2 Development       Bangalore
                3 Testing           Hyderabad
                4 HR                Chennai

**Task 5:** Insert the following ten records into the `employees` table.

### Employees data

  ----------------------------------------------------------------------------------------------
    employee_id employee_name   email                      salary joining_date     department_id
  ------------- --------------- ------------------- ------------- -------------- ---------------
              1 Arun            arun@gmail.com              60000 2023-01-15                   1

              2 Bala            bala@gmail.com              45000 2022-05-20                   2

              3 Charles         charles@gmail.com           55000 2021-08-10                   1

              4 David           david@gmail.com             30000 2024-03-12                   3

              5 Edward          edward@gmail.com            75000 2020-11-01                   2

              6 Francis         francis@gmail.com           40000 2023-07-25                   4

              7 Gokul           gokul@gmail.com             65000 2022-02-18                   2

              8 Hari            hari@gmail.com              50000 2024-06-05                   1

              9 Karthik         karthik@gmail.com           35000 2023-09-10                   3

             10 Manoj           manoj@gmail.com             80000 2021-04-15                   1
  ----------------------------------------------------------------------------------------------

**Task 6:** Verify that all department and employee records have been
inserted correctly.

------------------------------------------------------------------------

## 4. SELECT and WHERE (5 minutes)

**Task 7:** Display all records from the employees table.

**Task 8:** Display only employee names and email addresses.

**Task 9:** Find employees whose salary is greater than 50,000.

**Task 10:** Find employees whose salary is less than 45,000.

**Task 11:** Find employees who belong to department IDs 1, 2, or 3
using the `IN` operator.

**Task 12:** Find employees whose salary is between 40,000 and 70,000
using the `BETWEEN` operator.

**Task 13:** Find employees whose salary is greater than 40,000 and who
belong to department ID 1.

**Task 14:** Find employees who belong to department ID 1 or whose
salary is greater than 70,000.

------------------------------------------------------------------------

## 5. ORDER BY and GROUP BY (5 minutes)

**Task 15:** Display all employees ordered by salary from highest to
lowest.

**Task 16:** Display employees ordered by joining date from oldest to
newest.

**Task 17:** Count the number of employees in each department using
`GROUP BY`.

**Task 18:** Calculate the average salary for each department.

**Task 19:** Calculate the total salary expenditure for each department.

------------------------------------------------------------------------

## 6. HAVING (3 minutes)

**Task 20:** Display departments that have more than two employees.

**Task 21:** Display departments whose average employee salary is
greater than 45,000.

------------------------------------------------------------------------

## 7. JOIN Operations (7 minutes)

Use the `employees` and `departments` tables for these tasks.

**Task 22:** Display employee names along with their department names
using `INNER JOIN`.

**Task 23:** Display all departments and their employees using
`LEFT JOIN`. Include departments that do not have employees.

**Task 24:** Display employee names, department names, and department
locations using a join.

------------------------------------------------------------------------

## 8. UPDATE and DELETE (5 minutes)

**Task 25:** Update one employee's salary to 65,000 using their employee
ID.

**Task 26:** Increase the salary of all employees in department ID 1 by
10%.

**Task 27:** Change the location of the HR department to Bangalore.

**Task 28:** Delete one employee using their employee ID.

**Task 29:** Delete employees whose salary is below 35,000.

**Caution:** Before executing an `UPDATE` or `DELETE`, check that your
condition identifies only the intended records. Do not run these
operations without a suitable `WHERE` condition.

------------------------------------------------------------------------

## 9. Completion Checklist

-   [ ] Create and select a database
-   [ ] Create tables with primary keys and auto-increment
-   [ ] Create a foreign key relationship
-   [ ] Insert and verify sample records
-   [ ] Use `SELECT` and `WHERE`
-   [ ] Use `IN`, `AND`, `OR`, and `BETWEEN`
-   [ ] Use `ORDER BY`
-   [ ] Use `GROUP BY`
-   [ ] Use `HAVING`
-   [ ] Perform `INNER JOIN` and `LEFT JOIN`
-   [ ] Perform `UPDATE` and `DELETE`

## Assignment Rules

1.  Complete the tasks independently.
2.  Write and execute each SQL statement yourself.
3.  Use the supplied sample data for all exercises.
4.  Verify the output of each query.
5.  Save your completed SQL statements in a file named
    `mysql_assignment.sql`.
6.  Be prepared to explain the purpose of each SQL command.

**Expected outcome:** By completing this assignment, you should be able
to create a relational database, manage records, filter and sort data,
generate grouped reports, join related tables, and perform basic data
updates and deletions.
