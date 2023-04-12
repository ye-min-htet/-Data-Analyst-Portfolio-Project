Covid 19 Data Exploration (Google Sheet + BigQuery)

- import CSV file from https://ourworldindata.org/ into Google Sheets and update the data every day automatically:
- used App Script Editor	
function importData() {
  var url = "https://github.com/owid/covid-19-data/raw/master/public/data/vaccinations/vaccinations.csv"; // Replace with the URL of your CSV file
  var file = UrlFetchApp.fetch(url).getBlob();
  var sheet = SpreadsheetApp.getActiveSheet();
  var csvData = Utilities.parseCsv(file.getDataAsString());
  sheet.clearContents();
  sheet.getRange(1, 1, csvData.length, csvData[0].length).setValues(csvData);
}
- run SQL in BigQuery.


Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types


Select *
From Covid_19_SQL_Portfolio_Project.CovidDeaths
Where continent is not null 
order by 3,4


-- Select Data that we are going to be starting with

Select Location, date, total_cases, new_cases, total_deaths, population
From Covid_19_SQL_Portfolio_Project.CovidDeaths
Where continent is not null 
order by 1,2


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From Covid_19_SQL_Portfolio_Project.CovidDeaths
Where location like '%states%'
and continent is not null 
order by 1,2


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From Covid_19_SQL_Portfolio_Project.CovidDeaths
--Where location like '%states%'
order by 1,2


-- Countries with Highest Infection Rate compared to Population

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From Covid_19_SQL_Portfolio_Project.CovidDeaths
--Where location like '%states%'
Group by Location, Population
order by PercentPopulationInfected desc


-- Countries with Highest Death Count per Population

Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From Covid_19_SQL_Portfolio_Project.CovidDeaths
--Where location like '%states%'
Where continent is not null 
Group by Location
order by TotalDeathCount desc


-- BREAKING THINGS DOWN BY CONTINENT
-- Showing contintents with the highest death count per population

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From Covid_19_SQL_Portfolio_Project.CovidDeaths
--Where location like '%states%'
Where continent is not null 
Group by continent
order by TotalDeathCount desc


-- GLOBAL NUMBERS

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From Covid_19_SQL_Portfolio_Project.CovidDeaths
--Where location like '%states%'
where continent is not null 
--Group By date
order by 1,2


-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT CovidDeaths.continent, CovidDeaths.location, CovidDeaths.date, CovidDeaths.population, IFNULL(CovidVaccinations.daily_vaccinations, 0) AS new_vaccinations,
  SUM(IFNULL(CAST(CovidVaccinations.daily_vaccinations AS INT64), 0)) OVER (PARTITION BY CovidDeaths.location ORDER BY CovidDeaths.location, CovidDeaths.date) AS RollingPeopleVaccinated
FROM `Covid_19_SQL_Portfolio_Project.CovidDeaths` AS CovidDeaths
LEFT JOIN `Covid_19_SQL_Portfolio_Project.CovidVaccinations` AS CovidVaccinations
  ON CovidDeaths.location = CovidVaccinations.location
  AND CovidDeaths.date = CovidVaccinations.date
WHERE CovidDeaths.continent IS NOT NULL 
ORDER BY 2,3


-- Using CTE to perform Calculation on Partition By in previous query

WITH PopvsVac AS (
  SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.daily_vaccinations,
    SUM(CAST(vac.daily_vaccinations AS INT64)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
  FROM 
    Covid_19_SQL_Portfolio_Project.CovidDeaths AS dea
  JOIN 
    Covid_19_SQL_Portfolio_Project.CovidVaccinations AS vac
    ON dea.location = vac.location
    AND dea.date = vac.date
  WHERE 
    dea.continent IS NOT NULL 
)
SELECT 
  *,
  (RollingPeopleVaccinated / Population) * 100 AS VaccinationPercentage
FROM 
  PopvsVac


-- Using Temp Table to perform Calculation on Partition By in previous query

WITH PopvsVac AS (
  SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.daily_vaccinations,
    SUM(CAST(vac.daily_vaccinations AS INT64)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
  FROM 
    `Covid_19_SQL_Portfolio_Project.CovidDeaths` dea
  JOIN 
    `Covid_19_SQL_Portfolio_Project.CovidVaccinations` vac
  ON 
    dea.location = vac.location
    AND dea.date = vac.date
  WHERE 
    dea.continent IS NOT NULL 
)
SELECT 
  PopvsVac.*, 
  (RollingPeopleVaccinated / Population) * 100 AS PercentPopulationVaccinated
FROM 
  PopvsVac


-- Creating View to store data for later visualizations

CREATE VIEW Covid_19_SQL_Portfolio_Project.PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.daily_vaccinations,
  SUM(CAST(vac.daily_vaccinations AS INT64)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM `Covid_19_SQL_Portfolio_Project.CovidDeaths` dea
JOIN `Covid_19_SQL_Portfolio_Project.CovidVaccinations` vac
  ON dea.location = vac.location
  AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

