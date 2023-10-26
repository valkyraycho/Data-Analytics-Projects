SELECT * 
FROM Project..CovidDeaths 
order by 3,4

--SELECT * 
--FROM PortfolioProject..CovidVaccinations 
--order by 3,4

-- Selec Data that we are going to be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM Project..CovidDeaths 
order by 1,2

-- total cases vs. total deaths (likelihood)

SELECT location, date, total_cases, total_deaths, total_deaths/total_cases*100 as DeathPercentage
FROM Project..CovidDeaths 
WHERE location LIKE '%states%'
order by 1,2

-- total cases vs. population

SELECT location, date, total_cases, population, total_cases/population*100 as PercentPopulationInfected
FROM Project..CovidDeaths 
-- WHERE location LIKE '%states%'
order by 1,2

-- countries with highest infection rate compared to population

SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX(total_cases/population)*100 as PercentPopulationInfected
FROM Project..CovidDeaths 
Group by location, population
order by PercentPopulationInfected desc

-- countries with highest death count per population

SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM Project..CovidDeaths 
WHERE continent is not null
Group by location
order by TotalDeathCount desc

-- continents with highest death count per population

SELECT continent, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM Project..CovidDeaths 
WHERE continent is not null
Group by continent
order by TotalDeathCount desc

-- Global numbers

SELECT date, SUM(new_cases) as total_cases, SUM(CAST(new_deaths AS INT)) as total_deaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 as DeathPercentage
FROM Project..CovidDeaths
WHERE continent is not NULL
GROUP BY date
ORDER BY 1


-- CTE

WITH PopvsVac(Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) as RollingPeopleVaccinated
FROM Project..CovidDeaths dea
JOIN Project..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
)
SELECT *, RollingPeopleVaccinated/Population*100 as PercentPopulationVaccinated
FROM PopvsVac

-- Temp table

DROP TABLE if exists #PercentPopulationVaccinated

CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) as RollingPeopleVaccinated
FROM Project..CovidDeaths dea
JOIN Project..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null

SELECT *, RollingPeopleVaccinated/Population*100
FROM #PercentPopulationVaccinated

-- Create View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) as RollingPeopleVaccinated
FROM Project..CovidDeaths dea
JOIN Project..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null

SELECT * FROM PercentPopulationVaccinated