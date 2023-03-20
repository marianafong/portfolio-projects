-- COVID 19 PROJECT

-- Used tables

SELECT *
FROM PortfolioProject..CovidDeaths

SELECT *
FROM PortfolioProject..CovidVaccinations


-- Select data that I will use at the start

SELECT
	continent,
	location,
	date,
	total_cases,
	new_cases,
	total_deaths,
	population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, date


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid per country

SELECT
	continent,
	location,
	date,
	total_cases,
	total_deaths,
	(total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
--AND location = 'Portugal'
ORDER BY location, date


-- Looking at Total Cases vs Population
-- Shows what percentage of population was infected with covid

SELECT
	continent,
	location,
	date,
	population,
	total_cases,
	(total_cases/population)*100 AS PercentagePopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
--AND location = 'Portugal'
ORDER BY location, date


-- Countries with Highest Percentage of Population that was Infected

SELECT 
	continent,
	location,
	population,
	MAX(total_cases/population)*100 AS PercentagePopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent, location, population
ORDER BY MAX(total_cases/population) DESC


-- Countries with the Highest Death Count per Population

SELECT 
	continent,
	location,
	population,
	MAX(total_deaths) AS HighestDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent, location, population
ORDER BY MAX(total_deaths) DESC

SELECT 
	continent,
	location,
	population,
	MAX(total_deaths/population)*100 AS PercentagePopulationDeaths
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent, location, population
ORDER BY MAX(total_deaths/population) DESC


-- Breaking down data by Continents

-- Continents with the Highest Death Count

WITH CTE_CountryMax AS (
	SELECT
		continent,
		location,
		MAX(total_deaths) AS TotalDeaths
	FROM PortfolioProject..CovidDeaths
	WHERE continent IS NOT NULL
	GROUP BY continent, location
)
SELECT 
	continent,
	SUM(TotalDeaths) AS ContinentTotalDeaths
FROM CTE_CountryMax
GROUP BY continent
ORDER BY SUM(TotalDeaths) DESC


-- Or we can also do it like below, given the structure of the data
-- Although this outputs results other than continents

SELECT
	location,
	MAX(total_deaths) AS ContinentTotalDeaths
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY MAX(total_deaths) DESC


-- Global Numbers

SELECT
	SUM(new_cases) AS TotalCases,
	SUM(new_deaths) AS TotalDeaths,
	SUM(new_deaths)/SUM(new_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
--AND location = 'Portugal'


-- New Cases and New Deaths by Day

SELECT
	date,
	SUM(new_cases) AS NewCases,
	SUM(new_deaths) AS NewDeaths,
	CASE
		WHEN SUM(new_cases) = 0 THEN 0
		ELSE SUM(new_deaths)/SUM(new_cases)*100
	END AS DailyDeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date


-- Total Cases and Total Deaths by Day

SELECT
	date,
	SUM(total_cases) AS TotalCases,
	SUM(total_deaths) AS TotalDeaths,
	SUM(total_deaths)/SUM(total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date


-- Total Population vs Vaccinations

-- Using CTE (Common Table Expression)

WITH PopulationVsVaccination
AS
(
SELECT
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	(vac.new_vaccinations/dea.population)*100 AS PercentagePopulationVaccinatedToday,
	SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT
	*,
	(RollingPeopleVaccinated/population)*100 AS TotalPercentagePeopleVaccinated
FROM PopulationVsVaccination
ORDER BY location, date


-- Total Percentage of People Vaccinated by Country
-- Note: By analysing the results, it looks like 'new_vaccinations' can refer to the same person
-- A more trustworthy result would come from analysing 'people_vaccinated' and 'people_fully_vaccinated'

-- Using Temp Table

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated (
	Continent nvarchar(50),
	Location nvarchar(50),
	Date date,
	Population nvarchar(50),
	NewVaccinations nvarchar(50),
	PercentagePopulationVaccinatedToday nvarchar(50),
	RollingPeopleVaccinated nvarchar(50)
)

INSERT INTO #PercentPopulationVaccinated
SELECT
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	(vac.new_vaccinations/dea.population)*100 AS PercentagePopulationVaccinatedToday,
	SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT
	*,
	(CAST(RollingPeopleVaccinated as numeric)/CAST(Population as numeric))*100 AS TotalPercentagePeopleVaccinated
FROM #PercentPopulationVaccinated
ORDER BY Location


-- Creating Views (in PortfolioProject) to store data for visualisations

-- Rolling Percentage of Population Infected

CREATE VIEW V_PercentagePopulationInfected
AS
SELECT
	continent,
	location,
	date,
	population,
	total_cases,
	(total_cases/population)*100 AS PercentagePopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL

SELECT *
FROM V_PercentagePopulationInfected


-- Populations vs Vaccination

CREATE VIEW V_PopulationVsVaccination
AS
WITH PopulationVsVaccination
AS
(
SELECT
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	(vac.new_vaccinations/dea.population)*100 AS PercentagePopulationVaccinatedToday,
	SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT
	*,
	(RollingPeopleVaccinated/population)*100 AS TotalPercentagePeopleVaccinated
FROM PopulationVsVaccination

SELECT *
FROM V_PopulationVsVaccination