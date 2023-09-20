/*
Data Exploration with Covid 19 cases

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

SELECT *
FROM PortfolioProject..CovidDeaths
where continent is not null
ORDER BY 3,4

--SELECT *
--FROM PortfolioProject..CovidVaccinations
--ORDER BY 3,4

SELECT location, date, total_cases,new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
order by 1,2

	
-- LOOKING AT THE TOTAL CASES VS TOTAL DEATHS
-- Shows the chance of dying if you contract covid in a country

SELECT location, date, total_cases, total_deaths, 
(total_deaths/total_cases)*100 AS DeathPercent
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%INDIA%'
order by 1,2

	
-- Total cases vs Population
-- Shows the percentage of population that got covid

SELECT location, date, total_cases, population, 
(total_cases/population)*100 AS CasePercent
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%INDIA%'
order by 1,2

	
--Countries with highest Infection 
--The Percentage of people that got the virus compared to Popuation

SELECT location, population,
MAX(total_cases) as HighestInfected, 
MAX((total_cases/population))*100 AS InfectRate
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%INDIA%'
group by location, population
order by InfectRate desc

	
--Showing the countries with highest deathcount per population

SELECT location,
MAX(cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%INDIA%'
where continent is not null
group by location
order by TotalDeathCount desc

	
-- Showing the Continents with highest deathcount

SELECT continent,
MAX(cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
where continent is not null
group by continent
order by TotalDeathCount desc

	
--Global numbers of deaths each day

SELECT date, SUM(new_cases) as NewCases, SUM(cast(new_deaths as int)) as NewDeaths, 
SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathRate
FROM PortfolioProject..CovidDeaths
where continent is not null
GROUP BY date
order by 1,2

	
-- Population VS Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT DEA.continent, DEA.location, DEA.date, 
DEA.population, VAC.new_vaccinations, 
SUM(CAST(VAC.new_vaccinations AS INT)) OVER 
(PARTITION BY DEA.LOCATION ORDER BY DEA.LOCATION,DEA.DATE) AS TotalVacc,
DEA.new_deaths, SUM(CAST(DEA.new_deaths AS INT)) OVER 
(PARTITION BY DEA.LOCATION ORDER BY DEA.LOCATION,DEA.DATE) AS TotalDeath
FROM PortfolioProject..CovidDeaths DEA
JOIN PortfolioProject..CovidVaccinations VAC
	ON DEA.location = VAC.location
	AND DEA.date = VAC.date
WHERE DEA.continent IS NOT NULL
ORDER BY 2,3

	
-- Using CTE to perform Calculation on Partition By in previous query

with VaccvsDeath (continent, location, date, population, new_vaccinations, TotalVacc, new_deaths, TotalDeath)
as
(
SELECT DEA.continent, DEA.location, DEA.date, 
DEA.population, VAC.new_vaccinations, 
SUM(CAST(VAC.new_vaccinations AS INT)) OVER 
(PARTITION BY DEA.LOCATION ORDER BY DEA.LOCATION,DEA.DATE) AS TotalVacc,
DEA.new_deaths, SUM(CAST(DEA.new_deaths AS INT)) OVER 
(PARTITION BY DEA.LOCATION ORDER BY DEA.LOCATION,DEA.DATE) AS TotalDeath
FROM PortfolioProject..CovidDeaths DEA
JOIN PortfolioProject..CovidVaccinations VAC
	ON DEA.location = VAC.location
	AND DEA.date = VAC.date
WHERE DEA.continent IS NOT NULL
)
SELECT *, (TotalDeath/population)*100 AS DailyDeathRate,
(TotalVacc/population)*100 AS DailyVaxRate
FROM VaccvsDeath
order by 1,2,3

	
-- Using Temp table to perform the calculation of the Total Vaccinated and Total Death rate of Population
	
drop table if exists #PercentVacc
CREATE TABLE #PercentVacc
(
continent nvarchar(255),
location Nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
TotalVacc numeric
)

insert into #PercentVacc
SELECT DEA.continent, DEA.location, DEA.date, 
DEA.population, VAC.new_vaccinations, 
SUM(CAST(VAC.new_vaccinations AS INT)) OVER 
(PARTITION BY DEA.LOCATION ORDER BY DEA.LOCATION,DEA.DATE) AS TotalVacc,
DEA.new_deaths, SUM(CAST(DEA.new_deaths AS INT)) OVER 
(PARTITION BY DEA.LOCATION ORDER BY DEA.LOCATION,DEA.DATE) AS TotalDeath
FROM PortfolioProject..CovidDeaths DEA
JOIN PortfolioProject..CovidVaccinations VAC
	ON DEA.location = VAC.location
	AND DEA.date = VAC.date
WHERE DEA.continent IS NOT NULL
ORDER BY 2,3

SELECT *,
(TotalVacc/population)*100 AS DailyVaxRate
FROM #PercentVacc
order by 1,3

	
-- Creating view to store data for later visualisations

Create view PercentVacc as
SELECT DEA.continent, DEA.location, DEA.date, 
DEA.population, VAC.new_vaccinations, 
SUM(CAST(VAC.new_vaccinations AS INT)) OVER 
(PARTITION BY DEA.LOCATION ORDER BY DEA.LOCATION,DEA.DATE) AS TotalVacc,
DEA.new_deaths, SUM(CAST(DEA.new_deaths AS INT)) OVER 
(PARTITION BY DEA.LOCATION ORDER BY DEA.LOCATION,DEA.DATE) AS TotalDeath
FROM PortfolioProject..CovidDeaths DEA
JOIN PortfolioProject..CovidVaccinations VAC
	ON DEA.location = VAC.location
	AND DEA.date = VAC.date
WHERE DEA.continent IS NOT NULL
--ORDER BY 2,3

SELECT * 
FROM PercentVacc
