SELECT *
FROM coviddeaths
WHERE continent IS NOT NULL 
ORDER BY 3,4

SELECT "location" ,"date" ,total_cases ,new_cases ,total_deaths ,population 
FROM coviddeaths 
ORDER BY 1,2

--Looking at Total Cases vs Total Deaths
--Shows the likelyhood of dying when contracted COVID in your country
SELECT "location" ,"date" ,total_cases ,total_deaths, (total_deaths/total_cases)*100 AS PercentageOfDeaths
FROM coviddeaths 
WHERE "location" ILIKE '%states%'
ORDER BY "location" ,"date"


-- Looking at Total Cases vs. Population
SELECT "location" ,"date" ,total_cases ,population , (total_cases/population)*100 AS "PercentageOfCases"
FROM coviddeaths 
WHERE "location" ILIKE 'Cyprus'
ORDER BY "location" ,"date"


--Looking at countries with highest infection rate compared to population
SELECT "location",population,MAX(total_cases) AS "HighestInfectionCount" , MAX((total_cases/population))*100 AS "PercentageOfCases"
FROM coviddeaths 
GROUP BY "location" ,population 
ORDER BY "PercentageOfCases" DESC

--Showing countries with highest death rate 
SELECT "location",MAX(CAST(total_deaths AS int)) AS "TotalDeathCount"
FROM coviddeaths 
WHERE continent IS NOT NULL AND total_deaths IS NOT NULL
GROUP BY "location"
ORDER BY "TotalDeathCount" DESC

--Break down by continent
SELECT "location"  ,MAX(CAST(total_deaths AS int)) AS "TotalDeathCount"
FROM coviddeaths 
WHERE continent IS NULL AND "location" NOT ILIKE('%income%')
GROUP BY "location"  
ORDER BY "TotalDeathCount" DESC


-- Global Numbers
SELECT
	"date",
	SUM(new_cases) AS "CumulativeNewCases", 
	SUM(CAST(new_deaths AS INT)) AS "CumulativeDeathCount", 
	CASE 
		WHEN SUM(new_cases) = 0 THEN NULL 
		ELSE SUM(CAST(new_deaths AS REAL))/SUM(CAST(new_cases AS REAL)) * 100 
	END AS "PercentageOfDeath"
FROM 
	coviddeaths 
WHERE 
	continent IS NOT NULL
GROUP BY
	"date" 
ORDER BY 
	1,2;


--New version of the code above
SELECT 
    "date",
    SUM(new_cases) OVER (ORDER BY "date") AS "CumulativeNewCases"
FROM (
    SELECT 
        "date",
        COALESCE(SUM(new_cases), 0) AS new_cases
    FROM 
        coviddeaths
    GROUP BY 
        "date"
) AS subquery
ORDER BY 
    "date";
   
  
--Looking at Total Population vs Vaccinations
 
SELECT 
	d.continent,
	d."location",
	d."date",
	d.population,
	v.new_vaccinations,
	SUM(v.new_vaccinations) OVER(PARTITION BY d."location" ORDER BY d."location",d."date") AS "CumulativeSumOfVaccinations"
FROM 
	coviddeaths d
JOIN covidvaccinations v
ON	d."location"=v."location" AND d."date" =v."date" 
WHERE d.continent IS NOT NULL 
ORDER BY 2,3


 -- Using CTE to calculate d.population/CumulativeSumOfVaccinations

WITH PopVsVac AS
(
SELECT 
	d.continent,
	d."location",
	d."date",
	d.population,
	v.new_vaccinations,
	SUM(v.new_vaccinations) OVER(PARTITION BY d."location" ORDER BY d."location",d."date") AS "CumulativeSumOfVaccinations"
FROM 
	coviddeaths d
JOIN covidvaccinations v
ON	d."location"=v."location" AND d."date" =v."date" 
WHERE d.continent IS NOT NULL 
ORDER BY 2,3
)
SELECT *,("CumulativeSumOfVaccinations"/population)*100 AS "PercentageOfVaccinations"
FROM PopVsVac
WHERE LOCATION='Cyprus'


--Using TEMP table
DROP TABLE IF EXISTS PercentPopulationVaccinated
CREATE TEMPORARY TABLE PercentPopulationVaccinated
(
Continent varchar(255),
LOCATION varchar(255),
date DATE,
population NUMERIC,
new_vaccinations NUMERIC,
CumulativeSumOfVaccinations NUMERIC
)

INSERT INTO PercentPopulationVaccinated
(
SELECT 
	d.continent,
	d."location",
	d."date",
	d.population,
	v.new_vaccinations,
	SUM(v.new_vaccinations) OVER(PARTITION BY d."location" ORDER BY d."location",d."date") AS "CumulativeSumOfVaccinations"
FROM 
	coviddeaths d
JOIN covidvaccinations v
ON	d."location"=v."location" AND d."date" =v."date" 
WHERE d.continent IS NOT NULL 
ORDER BY 2,3
)

SELECT *,("CumulativeSumOfVaccinations"/population)*100 AS "PercentageOfVaccinations"
FROM PercentPopulationVaccinated
--WHERE LOCATION='Cyprus'


--Creating VIEW for later visualizations
CREATE VIEW PercentPopulationVaccinated AS
SELECT 
	d.continent,
	d."location",
	d."date",
	d.population,
	v.new_vaccinations,
	SUM(v.new_vaccinations) OVER(PARTITION BY d."location" ORDER BY d."location",d."date") AS "CumulativeSumOfVaccinations"
FROM 
	coviddeaths d
JOIN covidvaccinations v
ON	d."location"=v."location" AND d."date" =v."date" 
WHERE 
	d.continent IS NOT NULL 
ORDER BY 
	2,3

--Querying a view to see vaccinated population for 2023 and 2024.
SELECT *
FROM percentpopulationvaccinated
WHERE EXTRACT(YEAR FROM date) BETWEEN 2023 AND 2024
	

--VIEW: Break down by continent
CREATE VIEW TotalDeathByContinent AS
SELECT 
	"location",
	MAX(CAST(total_deaths AS int)) AS "TotalDeathCount"
FROM 
	coviddeaths 
WHERE 
	continent IS NULL AND "location" NOT ILIKE('%income%')
GROUP BY 
	"location"  
ORDER BY
	"TotalDeathCount" DESC

--Querying a TotalDeathCount view to see total amount of deaths associated with COVID-19 infection on each continent and the world
-- Selected continents only with total deaths registered above 1 million.
SELECT *
FROM totaldeathbycontinent
WHERE "TotalDeathCount">1000000