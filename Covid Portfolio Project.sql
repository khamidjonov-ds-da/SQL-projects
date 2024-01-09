--Select data we use
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM Portfolio_Project..CovidDeaths
ORDER BY 1, 2

-- Dying percentage by infection cases
SELECT location, date, population, total_deaths, (cast(total_deaths as float)/total_cases)*100 as deaths_percentage
FROM Portfolio_Project..CovidDeaths
ORDER BY 1, 2

-- Dying percentage by population
SELECT location, date, population, total_deaths, (total_deaths/population)*100 as deaths_percentage
FROM Portfolio_Project..CovidDeaths
ORDER BY 1, 2

--Countries with highest Infection Rate
SELECT Location, Population, MAX(total_cases) as HighestInfectionLCount, MAX((total_cases/population)*100) as PercentPopulationInfected
FROM Portfolio_Project..CovidDeaths
GROUP BY Location, Population
ORDER BY PercentPopulationInfected desc

--Countries with most deaths
SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM Portfolio_Project..CovidDeaths
WHERE continent is not null
GROUP BY Location
ORDER BY TotalDeathCount desc

--BREAK THINGS BY CONTINENT

--Continents with most deaths
SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM Portfolio_Project..CovidDeaths
WHERE continent is null
GROUP BY Location
ORDER BY TotalDeathCount desc

--GlOBAL NUMBERS

SELECT SUM(new_cases) as total_cases_eachday, SUM(cast(new_deaths as int)) as total_deaths_eachday, SUM(cast(new_deaths as int))/SUM(new_cases) * 100 as DeathPercentage
FROM Portfolio_Project..CovidDeaths
WHERE continent is not null AND new_cases > 0
ORDER BY 1, 2


-- Total population vs Vaccinations

--Use CTE
WITH PopVsVac (Continent, Location, Date, Population, New_vaccinations, RollingPeopleVaccinated)
as
(SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as float))
	OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM Portfolio_Project..CovidDeaths dea
JOIN Portfolio_Project..CovidVaccination vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)

SELECT *, (RollingPeopleVaccinated/population)*100 as VaccinatedPeoplePercentage
FROM PopVsVac

--TEMP Table
DROP TABLE IF EXISTS #PercentPopulationVaccinated

CREATE TABLE #PercentPopulationVaccinated
(
Continent varchar(255),
Location varchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as float)) 
	OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM Portfolio_Project..CovidDeaths dea
JOIN Portfolio_Project..CovidVaccination vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3

SELECT *, RollingPeopleVaccinated/Population * 100
FROM #PercentPopulationVaccinated

-- Creating View to store data for later visualisation
Create View PercentPopVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as float)) 
	OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM Portfolio_Project..CovidDeaths dea
JOIN Portfolio_Project..CovidVaccination vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

Select *
FROM PercentPopVaccinated