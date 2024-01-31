/* TITLE: Microsoft SQL Server Management Studio
------------------------------

Up to 43827 cells of data may have been dropped during insert from the following columns:
median_age
gdp_per_capita
handwashing_facilities
hospital_beds_per_thousand
life_expectancy 

------------------------------
BUTTONS:

OK
------------------------------

NOTE: 43827 cells 
*/

-- SELECT *
-- FROM PortfolioProject_C19..CovidVaccinations
-- order by 3, 4


SELECT 
	*
FROM 
	PortfolioProject_C19..CovidDeaths
WHERE 
	continent IS NOT NULL
ORDER BY 
	3, 4

-- Select Data that we are going to use


SELECT 
	location, 
	date, 
	total_cases, 
	new_cases, 
	total_deaths, 
	population
FROM 
	PortfolioProject_C19..CovidDeaths
WHERE 
	continent IS NOT NULL
ORDER BY 
	1, 2

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in a country

SELECT 
	location, 
	date, 
	total_cases, 
	total_deaths, 
	(CAST(total_deaths AS FLOAT) / total_cases)*100 AS death_percentage
FROM 
	PortfolioProject_C19..CovidDeaths
WHERE
	location LIKE '%states%' AND 
	continent IS NOT NULL
ORDER BY 
	1, 2

-- Looking at Total Cases vs Population
-- Shows what percentage of population got Covid

SELECT 
	location, 
	date,
	total_cases, 
	population,
	(CAST(total_cases AS FLOAT)/population)*100 AS infection_rate
FROM 
	PortfolioProject_C19..CovidDeaths
WHERE
	location LIKE '%%' -- Insert location name between %% to zoom into a specific country/location
	AND continent IS NOT NULL
ORDER BY 
	1, 2

-- Looking at Countries with Highest Infection rates compared to Population

SELECT
	location,
	population,
	MAX(total_cases) AS highest_infection_count,
	MAX((CAST(total_cases AS FLOAT)/population))*100 AS infection_rate
FROM 
	PortfolioProject_C19..CovidDeaths
WHERE 
	continent IS NOT NULL
GROUP BY
	location,
	population
ORDER BY
	infection_rate DESC

-- Showing Countries with Highest Death Count 

SELECT
	location,
	MAX(total_deaths) AS total_death_count
FROM 
	PortfolioProject_C19..CovidDeaths
WHERE 
	continent IS NOT NULL
GROUP BY
	location
ORDER BY
	total_death_count DESC

-- Break down by Continent
-- Showing the continents with the highest death count

SELECT
	continent,
	MAX(total_deaths) AS total_death_count
FROM 
	PortfolioProject_C19..CovidDeaths
WHERE 
	continent IS NOT NULL
GROUP BY
	continent
ORDER BY
	total_death_count DESC


-- Global Numbers
-- Total daily new cases, new deaths and death percentage since 2020-01-01

SELECT  
	date, 
	SUM(new_cases) AS daily_global_new_cases,
	SUM(new_deaths) AS daily_global_new_deaths,
	CAST(SUM(new_deaths) AS FLOAT)/SUM(new_cases)*100 AS death_percentage
FROM 
	PortfolioProject_C19..CovidDeaths
WHERE
	continent IS NOT NULL
GROUP BY 
	date
ORDER BY
	date
	
-- Total global covid19 cases, deaths and death ratio from 2020-01-01

SELECT  
	SUM(new_cases) AS daily_global_new_cases,
	SUM(new_deaths) AS daily_global_new_deaths,
	CAST(SUM(new_deaths) AS FLOAT)/SUM(new_cases)*100 AS death_percentage
FROM 
	PortfolioProject_C19..CovidDeaths
WHERE
	continent IS NOT NULL


-- Joining two tables together (JOIN ON location AND date)

SELECT 
	*
FROM 
	PortfolioProject_C19..CovidDeaths AS dea
JOIN 
	PortfolioProject_C19..CovidVaccinations AS vac
ON 
	dea.location = vac.location
	AND dea.date = vac.date

-- Looking at Global Population vs Vaccinations - Rolling Count

SELECT 
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM 
	PortfolioProject_C19..CovidDeaths AS dea
JOIN 
	PortfolioProject_C19..CovidVaccinations AS vac
ON 
	dea.location = vac.location
	AND dea.date = vac.date
WHERE
	dea.continent IS NOT NULL
ORDER BY
	2, 3

-- Use a CTE

-- Looking at Total Population vs Vaccinations

WITH pop_vs_vac (continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
AS (
SELECT 
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM 
	PortfolioProject_C19..CovidDeaths AS dea
JOIN 
	PortfolioProject_C19..CovidVaccinations AS vac
ON 
	dea.location = vac.location
	AND dea.date = vac.date
WHERE
	dea.continent IS NOT NULL
	)
SELECT
	*, (rolling_people_vaccinated/CAST(population AS FLOAT))*100 AS vaccination_percentage
FROM pop_vs_vac


-- Use a TEMP TABLE

DROP TABLE IF EXISTS #percent_population_vaccinated

CREATE TABLE #percent_population_vaccinated 
(
	continent NVARCHAR(255),
	location NVARCHAR(255),
	date DATE,
	population NUMERIC,
	new_vaccinations NUMERIC,
	rolling_people_vaccinated NUMERIC
	)

INSERT INTO 
	#percent_population_vaccinated 

SELECT 
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM 
	PortfolioProject_C19..CovidDeaths AS dea
JOIN 
	PortfolioProject_C19..CovidVaccinations AS vac
ON 
	dea.location = vac.location
	AND dea.date = vac.date
WHERE
	dea.continent IS NOT NULL

SELECT
	*, (rolling_people_vaccinated/CAST(population AS FLOAT))*100 AS vaccination_percentage
FROM #percent_population_vaccinated 

-- Creating View to store data for later visualizations

-- (Total global covid19 cases, deaths and death ratio from 2020-01-01)


CREATE VIEW TotalCasesDeathsRatio 
AS
SELECT  
	SUM(new_cases) AS daily_global_new_cases,
	SUM(new_deaths) AS daily_global_new_deaths,
	CAST(SUM(new_deaths) AS FLOAT)/SUM(new_cases)*100 AS death_percentage
FROM 
	PortfolioProject_C19..CovidDeaths
WHERE
	continent IS NOT NULL

-- Select View

SELECT 
	*
FROM 
	TotalCasesDeathsRatio
