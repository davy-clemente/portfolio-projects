--Combining data sets for querying and setting datatypes into the format needed

DROP Table if exists Q1_TripData
Create Table Q1_TripData
(
ride_id nvarchar(255),
rideable_type nvarchar(255),
started_at datetime,
ended_at datetime,
start_station_name nvarchar(255),
start_station_id nvarchar(255),
end_station_name nvarchar(255),
end_station_id nvarchar(255),
start_lat float,
start_lang float,
end_lat float,
end_lang float,
member_casual nvarchar(255)
)
Insert into Q1_TripData
SELECT *
	FROM Cyclistic..['202401-divvy-tripdata']
	UNION
	SELECT *
	FROM Cyclistic..['202402-divvy-tripdata']
	UNION
	SELECT *
	FROM Cyclistic..['202403-divvy-tripdata']

--quick check
Select *
From Q1_TripData
Order by 1

--checking distinct counts for each column
Select COUNT(DISTINCT ride_id) as ride_id
, COUNT(DISTINCT rideable_type) as rideable_type
, COUNT(DISTINCT start_station_name) as start_station_name
, COUNT(DISTINCT start_station_id) as start_station_id
, COUNT(DISTINCT end_station_name) as end_station_name
, COUNT(DISTINCT end_station_id) as end_station_id
, COUNT(DISTINCT start_lat) as start_lat
, COUNT(DISTINCT start_lang) as start_lang
, COUNT(DISTINCT end_lat) as end_lat
, COUNT(DISTINCT end_lang) as end_lang
, COUNT(DISTINCT member_casual) as member_casual
From Q1_TripData

--check for null data
Select SUM(CASE WHEN ride_id is null THEN 1 ELSE 0 END) as null_ride_id
, SUM(CASE WHEN rideable_type is null THEN 1 ELSE 0 END) as null_rideable_type
, SUM(CASE WHEN start_station_name is null THEN 1 ELSE 0 END) as null_start_station_name
, SUM(CASE WHEN start_station_id is null THEN 1 ELSE 0 END) as null_start_station_id
, SUM(CASE WHEN end_station_name is null THEN 1 ELSE 0 END) as null_end_station_name
, SUM(CASE WHEN end_station_id is null THEN 1 ELSE 0 END) as null_end_station_id
, SUM(CASE WHEN start_lat is null THEN 1 ELSE 0 END) as null_start_lat
, SUM(CASE WHEN start_lang is null THEN 1 ELSE 0 END) as null_start_lang
, SUM(CASE WHEN end_lat is null THEN 1 ELSE 0 END) as null_end_lat
, SUM(CASE WHEN end_lang is null THEN 1 ELSE 0 END) as null_end_lang
, SUM(CASE WHEN member_casual is null THEN 1 ELSE 0 END) as null_member_casual
From Q1_TripData

-- filling in null station names

-- rounding down the latitude and longitude values to use for matching

ALTER TABLE Q1_TripData
ADD start_lat_r float,
start_lang_r float,
end_lat_r float,
end_lang_r float;

UPDATE Q1_TripData
SET start_lat_r = ROUND(start_lat, 2),
	start_lang_r = ROUND(start_lang, 2),
	end_lat_r = ROUND(end_lat, 2),
	end_lang_r = ROUND(end_lang, 2)

--self joining to compare values

Select a.start_station_name, a.start_lat_r, a.start_lang_r, b.start_station_name, b.start_lat_r, b.start_lang_r
From Q1_TripData a
Join Q1_TripData b
 on a.start_lat_r = b.start_lat_r
 AND a.start_lang_r = b.start_lang_r
Where a.start_station_name is null

--updating start_station_names

Update a
Set start_station_name = ISNULL(a.start_station_name, b.start_station_name)
From Q1_TripData a
Join Q1_TripData b
 on a.start_lat_r = b.start_lat_r
 AND a.start_lang_r = b.start_lang_r
Where a.start_station_name is null

--repeating for end station names

Update a
Set end_station_name = ISNULL(a.end_station_name, b.end_station_name)
From Q1_TripData a
Join Q1_TripData b
 on a.end_lat_r = b.end_lat_r
 AND a.end_lang_r = b.end_lang_r
Where a.end_station_name is null

-- starting station names that share the same start_station_id

Select COUNT(DISTINCT start_station_name), start_station_id
From Q1_TripData
Group by start_station_id
Having COUNT(DISTINCT start_station_name) > 1

Select Distinct start_station_name, start_station_id
From Q1_TripData
where start_station_id IN ('572','534','518','549','585','651','528','564','661','520','514','573','537','579','561','543','TA1305000030','594','559','517','604','331','569','536','562','586','639')
Order by start_station_id

-- end station names that share the same end_station_id

Select COUNT(DISTINCT end_station_name), end_station_id
From Q1_TripData
Group by end_station_id
Having COUNT(DISTINCT end_station_name) > 1
Order by end_station_id

Select Distinct end_station_name, end_station_id
From Q1_TripData
where end_station_id IN ('590','572','534','518','549','585','651','528','564','661','520','514','573','537','579','561','543','TA1305000030','594','559','517','604','331','569','536','562','586','639')
Order by end_station_id

--station names with the same station ID are distinct enough from each so i've decided to keep as is

--calculating ride length

ALTER TABLE Q1_TripData
ADD ride_length_s float;

UPDATE Q1_TripData
SET ride_length_s = Datediff(ss, started_at, ended_at)

--calculating day of the week ride started

ALTER TABLE Q1_TripData
ADD day_started nvarchar(10);

UPDATE Q1_TripData
SET day_started = DATENAME(dw, started_at)

--calculations for descriptive analysis

--(Excluding ride lengths < 0 which have end time < start time which are anomalous)
-- Calculate the mean of ride_length 
-- Calculate the max ride_length 

Select AVG(ride_length_s) as avg_ride_length
, MAX(ride_length_s) as max_ride_length
From Q1_TripData
Where ride_length_s > 0

-- average ride_length for members and casual riders.

Select member_casual, AVG(ride_length_s) as avg_ride_length
, MAX(ride_length_s) as max_ride_length
From Q1_TripData
Where ride_length_s > 0
Group by member_casual

Select member_casual, rideable_type, AVG(ride_length_s) as avg_ride_length
, MAX(ride_length_s) as max_ride_length
From Q1_TripData
Where ride_length_s > 0
Group by member_casual, rideable_type
Order by 1, 2

Select member_casual, day_started, AVG(ride_length_s) as avg_ride_length
, MAX(ride_length_s) as max_ride_length
From Q1_TripData
Where ride_length_s > 0
Group by member_casual, day_started
Order by 1, 2




