--Viewing the Two Data Sources ('CovidDeaths' and 'CovidVaccinations')
Select *
From PortfolioProject..CovidDeaths
Where continent is not null
order by 3,4

Select *
From PortfolioProject..CovidVaccinations
order by 3,4


--EXPLORING THE DATA

--Select Data that we are going to be using

Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
Where continent is not null
order by 1,2


--Looking at Total Cases vs Total Deaths (for United States)

--Shows the likelihood of death if you contract covid in your country:
Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as Death_Percentage
From PortfolioProject..CovidDeaths
Where Location = 'United States'
and continent is not null
order by 1,2


--Looking at Total Cases vs Population

--Shows what percentage of poupulation got Covid:
Select Location, date, Population, total_cases, (total_cases/population)*100 as percent_population_infected
From PortfolioProject..CovidDeaths
--Where Location = 'United States'
Where continent is not null
order by 1,2


--Looking at Countires with the Highest Infection Rates compared to Population

Select Location, Population, Max(total_cases) as highest_infection_count, Max((total_cases/population))*100 as percent_population_infected
From PortfolioProject..CovidDeaths
--Where Location = 'United States'
Where continent is not null
Group by Location, Population
order by percent_population_infected desc


--Showing Counties with the Highest Death Count per Population

--Casting/converting the 'total_deaths' datatype to an Integer due to an issue with the 'total_deaths' being improperly stored as a 'nvarchar(255)' data type.
Select Location, Max(cast(total_deaths as int)) as total_death_count
From PortfolioProject..CovidDeaths
--Where Location = 'United States'
Where continent is not null
Group by Location
order by total_death_count desc


--LET'S BREAK THINGS DOWN BY CONTINENT
--Showing Continents with the Highest Death Count per Population
Select continent, Max(cast(total_deaths as int)) as total_death_count
From PortfolioProject..CovidDeaths
Where continent is not null
Group by continent
order by total_death_count desc


--Global Covid Numbers by Day

--casting 'new_deaths' as integer because its nvarchar data type is invalid for SUM operator
Select date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as Death_Percentage
From PortfolioProject..CovidDeaths
Where continent is not null
Group by date
order by 1,2


--Global Covid Numbers - Total

Select  'Global' as continent, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as Death_Percentage
From PortfolioProject..CovidDeaths
Where continent is not null
order by 1,2


--Looking at Total Population vs Vaccinations

--Giving the aliases 'dea' and 'vac' for CovidDeaths and CovidVaccinations tables
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.location Order by dea.location, dea.date) as rolling_vaccination_count
, (rolling_vaccination_count/population)*100
From PortfolioProject..CovidDeaths dea 
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
order by 2,3

--This (above) doesn't work because we cannot add the 'rolling_vaccination_count/population*100' calculation into the same table right after it is created.
--So to fix this issue we create a CTE below that holds the 'rolling_vaccination_count' values to allow for the 'rolling_vaccination_count/population*100' calculation to be made.


-- USE CTE (a temporary table to hold calculations for futher evaluation)

With PopulationvsVaccination (Continent, Location, Date, Population, New_Vaccinations, Rolling_Vaccinated_Count)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.location Order by dea.location, dea.date) as rolling_vaccination_count
--, (rolling_vaccination_count/population)*100
From PortfolioProject..CovidDeaths dea 
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
)

Select *, (Rolling_Vaccinated_Count/Population)*100 as Percent_Vaccinated
From PopulationvsVaccination

--Another way to fix this issue (to hold the 'rolling_vaccination_count' values to allow for the 'rolling_vaccination_count/population*100' calculation to be made) is to Create a TEMP TABLE like below.


--Creating a TEMP TABLE

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Locaton nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
Rolling_Vaccinated_Count numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.location Order by dea.location, dea.date) as rolling_vaccination_count
--, (rolling_vaccination_count/population)*100
From PortfolioProject..CovidDeaths dea 
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null

Select *, (Rolling_Vaccinated_Count/Population)*100 as Percent_Vaccinated
From #PercentPopulationVaccinated



--Creating a View to Store Data for Later Visualizations

Create View PercentPopulationVaccinatedView as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as rolling_vaccination_count
--, (rolling_vaccination_count/population)*100
From PortfolioProject..CovidDeaths dea 
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
