Select *
FROM PortfolioProject..CovidDeaths
ORDER BY 3,4

--Select *
--FROM PortfolioProject..CovidVaccinations
--ORDER BY 3,4

-- Select Data that we are going to be using

Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
Order by 1,2


-- Looking at Total Cases vs Total Deaths
Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage  --converts to percentage (Death percentage gives us the likelihood of death after contracting Covid)
From PortfolioProject..CovidDeaths
Where location like '%states%'   --extract only US
Order by 1,2

-- Looking at Total Cases vs Population
Select Location, date, population, total_cases, (total_cases/population)*100 as PercentPopulationInfected  --converts to percentage (What percentage of population got Covid)
From PortfolioProject..CovidDeaths
Where location like '%states%'   --extract only US
Order by 1,2

-- Looking at Countries with Highest Infection Rate compared to Population
Select Location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected  --converts to percentage (What percentage of population got Covid)
From PortfolioProject..CovidDeaths
Group by location, population    --group by needed since there is an aggregate function MAX
Order by PercentPopulationInfected desc  --descending order 

-- Need for next query since trouble with location showing world
Select *
From PortfolioProject..CovidDeaths
Where continent is not null
order by 3,4


-- Showing the countries with the Highest Death Count per Population
Select Location, MAX(cast(total_deaths as bigint)) as TotalDeathCount  -- since total_deaths data type is nvarchar we need to convert to integer 
From PortfolioProject..CovidDeaths
Where continent is not null
Group by location
Order by TotalDeathCount desc --descending order  


--LET'S BREAK THINGS DOWN BY CONTINENT  (These are continents with Highest Death Count per Population)
Select continent, MAX(cast(total_deaths as bigint)) as TotalDeathCount  -- since total_deaths data type is nvarchar we need to convert to integer 
From PortfolioProject..CovidDeaths
Where continent is not null
Group by continent
Order by TotalDeathCount desc --descending order 

-- Issues cause North America only shows US and doesn't include Canada so next query deals with that problem

-- Continents with the Highest Death Count per Population 
Select location, MAX(cast(total_deaths as bigint)) as TotalDeathCount  -- since total_deaths data type is nvarchar we need to convert to integer 
From PortfolioProject..CovidDeaths
Where continent is null
Group by location
Order by TotalDeathCount desc --descending order 



-- GLOBAL NUMBERS new_cases is float but new_deaths is nvarchar so cast first 
Select date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as bigint)) as total_deaths, SUM(cast(new_deaths as bigint))/SUM(new_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where continent is not null   
Group by date
Order by 1,2


-- Total cases across the world
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as bigint)) as total_deaths, SUM(cast(new_deaths as bigint))/SUM(new_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where continent is not null   
Order by 1,2





Select *
From PortfolioProject..CovidDeaths dea			--calling it dea
Join PortfolioProject..CovidVaccinations vac    --calling CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date

	
-- Looking at Total Population vs Vaccincations (what is the total amount of ppl in the world that have been vaccinated)
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
From PortfolioProject..CovidDeaths dea			--calling it dea
Join PortfolioProject..CovidVaccinations vac    --calling CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 1,2,3


-- Want to look at the same query but add up new_vaccinations
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations as bigint)) OVER (Partition by dea.Location Order by dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea			--calling it dea
Join PortfolioProject..CovidVaccinations vac    --calling CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3


--Want to use last data entry of rollinpeoplevaccinated for each country (since its the max) and divide it by number of ppl in that country to find percentage of ppl vaccinated using CTE
With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated) --must be same number as selected columns
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea			--calling it dea
Join PortfolioProject..CovidVaccinations vac    --calling CovidVaccinations vac
	On dea.location = vac.location   --joins columns that have the same name
	and dea.date = vac.date
where dea.continent is not null
)
Select *, (RollingPeopleVaccinated/Population) *100
From PopvsVac



--TEMP Table
DROP Table if exists #PercentPopulationVaccinated   --add when planning on making alterations so don't have to delete view or table every time your executing your code
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)
Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea			--calling it dea
Join PortfolioProject..CovidVaccinations vac    --calling CovidVaccinations vac
	On dea.location = vac.location   --joins columns that have the same name
	and dea.date = vac.date
--where dea.continent is not null

Select *, (RollingPeopleVaccinated/Population) *100
From #PercentPopulationVaccinated



DROP Table if exists #PercentPopulationVaccinated

-- Creating a view to store data for later visualizations
Create View PercentPopulationVaccinates as 
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea			--calling it dea
Join PortfolioProject..CovidVaccinations vac    --calling CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3

