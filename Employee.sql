# ANALYZING EMPLOYEE RETENTION DATA SET

# The dataset contains the following columns:

-- 1. Education: Level of education (e.g., Bachelors, Masters).
-- 2. JoiningYear: Year of joining the organization.
-- 3. City: Location of the employee.
-- 4. PaymentTier: Salary tier (1, 2, or 3).
-- 5. Age: Age of the employee.
-- 6. Gender: Gender of the employee (Male/Female).
-- 7. EverBenched: Whether the employee was ever benched (Yes/No).
-- 8. ExperienceInCurrentDomain: Experience in the current domain (years).
-- 9. LeaveOrNot: Whether the employee has left the organization (1 for Yes, 0 for No).

-- How many employees are in each payment tier?
select paymenttier, count(*) as employee_count
from employee
group by paymenttier
order by paymenttier;

-- Calculate the average age of employees for each gender
select gender, avg(age) as avg_age
from employee
group by gender;

-- Retrieve the count of employees in each city.
select city, count(*) as count_employee
from employee
group by city;

-- List all distinct education levels available in the dataset.
select distinct Education
from employee;

-- Count the number of employees who have left the organization.
select count(*) count_left_org
from employee
where leaveornot = 1;

-- Retrieve the average experience of employees in each payment tier.
select 
	paymenttier,	
    avg(experienceincurrentdomain) avg_experience
from employee
group by paymenttier
order by paymenttier;

-- Find the top 2 cities with the highest percentage of employees who have been benched at least once
with benched_atleast_once as (
	select city, 
		count(*) as total_employees,
		sum(case when everbenched = 'yes' then 1 else 0 end) as benched
	from employee
	group by city
)

select city, 
	(benched/total_employees)*100 as percentage_benched
from benched_atleast_once
order by percentage_benched desc
limit 2;

-- For each education level, calculate the average experience in the current domain for employees who joined before 2015 and those who joined in 2015 or later
select 
	education,
	avg(case when joiningyear < '2015' then experienceincurrentdomain else 0 end) as before_2015_avgdomex,
	avg(case when joiningyear >= '2015' then experienceincurrentdomain else 0 end) as after_2015_avgdomex
from employee
group by education;

-- Find the percentage of employees who were benched (EverBenched = 'Yes') and still left the organization.
select (a.count_benched/a.left_org)* 100 as PercentageLeftAfterBenching
from (
	select 
		sum(case when everbenched = 'yes' then 1 else 0 end) as count_benched,
		count(leaveornot) as left_org 
	from employee
	where leaveornot = 1
	) a;

-- Calculate the average age of employees who joined in each year.
select JoiningYear, avg(age) Avg_Age
from employee
group by joiningyear
order by 1;

-- Identify the top 2 cities with the highest employee attrition rate (LeaveOrNot = 1), and include the percentage of employees who left in those cities.
with attrition_per_city as (
	select 
		city,
		count(city) as total_emp,
		sum(case when LeaveOrNot = 1 then 1 else 0 end) as num_emp_left
	from employee
	group by city
)

select 
	city, 
    (num_emp_left/total_emp) * 100 as attrition_rate
from attrition_per_city
order by attrition_rate desc
limit 2;

-- Calculate the correlation between payment tier and the average experience in the current domain for each city.
select 
	city,
	paymenttier,
	avg(experienceincurrentdomain) as avg_experience
from employee
group by city, paymenttier
order by 2;

-- For each education level, find the gender with the highest attrition rate and include the number of employees who left.
with gender_attrition as (
	select 
		education,
		gender,
        sum(case when leaveornot = 1 then 1 else 0 end) as employees_left,
        count(case when leaveornot = 1 then 1 else 0 end) as total_emloyees
	from employee
	group by education, gender
)

select 
	education, gender, employees_left,
    (employees_left/total_emloyees)*100 as percentage_attrition
from gender_attrition;

-- Analyze the trend of employee retention for each joining year by calculating the percentage of employees who stayed (LeaveOrNot = 0) for each year and ordering it chronologically.
with retained as (
	select 
		joiningyear,
		count(case when leaveornot = 0 then 1 end) as employees_retained
	from employee
	group by joiningyear
	order by joiningyear
),

total_emp as (
	select 
		joiningyear,
        count(*) as total
	from employee
    group by joiningyear
)

select 
	r.joiningyear,
    (employees_retained/total)*100 as Retention_Rate
from total_emp te
join retained r
on te.joiningyear = r.joiningyear
order by joiningyear;

-- Calculate the employees likely hood to lease based on their payment tier, experince in current domain, and the average leave rate in their city
with avg_leave_rate as (
	select city, avg(case when leaveornot = 'yes' then 1 else 0 end) as avg_rate
    from employee
    group by city
)

select e.city, 
		e.paymenttier, 
        case 
			when e.experienceincurrentdomain <= '3' then 'low'
            when e.experienceincurrentdomain <= '7' then 'medium'
            else 'high'
		end as experiencelevel,
        alr.avg_rate
from employee e
left join avg_leave_rate alr
on e.city = alr.city
where avg_rate > 0.65
group by e.paymenttier, experiencelevel, e.city, alr.avg_rate;

-- Impact of Benching on Attrition
select 
	b.leaveornot,
	(b.benched/b.stayed_left) *100 as perc_benched,
    (b.not_benched/b.stayed_left) *100 as perc_not_benched
from (
select
	leaveornot,
	count(leaveornot) as stayed_left,
	count(case when everbenched = 'No' then 1 end) as not_benched,
    count(case when everbenched = 'Yes' then 1 end) as benched
from employee
group by leaveornot) as b;




