Select *
From Covid.dbo.CovidData

--getting the total cases, total deaths, %death percentage for the global summary

With max_data ( max_total_cases, max_total_deaths )
as (
	Select MAX(total_cases), MAX(total_deaths)
	From Covid.dbo.CovidData
	Where continent is not null
	Group by location
	)
Select SUM(max_total_cases) as total_cases
, SUM(max_total_deaths) as total_deaths
, (SUM(max_total_deaths)/SUM(max_total_cases))*100 as percent_death
From max_data

--getting the total deaths per country

Select continent, location, MAX(total_deaths) as death_count
From Covid.dbo.CovidData
Where continent is not null
Group by location, continent
Order by continent

--getting total cases and percent of the population infected per country

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From Covid.dbo.CovidData
Where continent is not null
Group by Location, Population
order by PercentPopulationInfected desc

--getting the 7-day rolling average for total_cases and total_cases per million for each country

Select continent, location, date,
		new_cases,
       avg(new_cases) over(partition by location order by location, date rows between 6 preceding and current row) as rolling_ncase_avg,
		new_cases_per_million,
	   avg(new_cases_per_million) over(partition by location order by location, date rows between 6 preceding and current row) as rolling_ncase_per_mil_avg,
	   new_deaths,
       avg(new_deaths) over(partition by location order by location, date rows between 6 preceding and current row) as rolling_ndeath_avg,
		new_deaths_per_million,
	   avg(new_deaths_per_million) over(partition by location order by location, date rows between 6 preceding and current row) as rolling_ndeath_per_mil_avg,
	   avg(total_cases) over(partition by location order by location, date rows between 6 preceding and current row) as rolling_case_avg,
	   avg(total_cases_per_million) over(partition by location order by location, date rows between 6 preceding and current row) as rolling_case_per_mil_avg
From Covid.dbo.CovidData
Where continent is not null
Order by location

Select continent, location, date, population
, total_cases, new_cases
, total_deaths, new_deaths
, total_vaccinations, people_vaccinated, new_vaccinations
From Covid.dbo.CovidData
Where continent is not null
Order by 1, 2, 3

--continent version

Select location, date, population
, (total_cases/population)*100 AS infection_rate
, (people_vaccinated/population)*100 AS vaccination_rate
, (total_deaths/total_cases)*100 AS infection_fatality_rate --IFR % of total cases that result in death, some cases have death>cases
, (total_deaths/population)*100 AS crude_mortality_rate --CMR % of total population that died due to Covid
From Covid.dbo.CovidData
Where location in ('Africa','Asia','Europe','North America','South America','Oceania')
Order by 1, 2, 3
