CREATE TABLE RawData (
    ID VARCHAR(255) PRIMARY KEY,
    Source VARCHAR(255),
    Severity INT,
    Start_Time TIMESTAMP,
    End_Time TIMESTAMP,
    Start_Lat FLOAT8,
    Start_Lng FLOAT8,
    End_Lat FLOAT8,
    End_Lng FLOAT8,
    Distance FLOAT8,
    Description TEXT,
    Street VARCHAR(255),
    City VARCHAR(255),
    County VARCHAR(255),
    State VARCHAR(255),
    Zipcode VARCHAR(255),
    Country VARCHAR(255),
    Timezone VARCHAR(255),
    Airport_Code VARCHAR(255),
    Weather_Timestamp TIMESTAMP,
    Temperature_F FLOAT8,
    Wind_Chill_F FLOAT8,
    Humidity_Percent FLOAT8,
    Pressure_in FLOAT8,
    Visibility_mi FLOAT8,
    Wind_Direction VARCHAR(255),
    Wind_Speed_mph FLOAT8,
    Precipitation_in FLOAT8,
    Weather_Condition VARCHAR(255),
    Amenity BOOLEAN,
    Bump BOOLEAN,
    Crossing BOOLEAN,
    Give_Way BOOLEAN,
    Junction BOOLEAN,
    No_Exit BOOLEAN,
    Railway BOOLEAN,
    Roundabout BOOLEAN,
    Station BOOLEAN,
    Stop BOOLEAN,
    Traffic_Calming BOOLEAN,
    Traffic_Signal BOOLEAN,
    Turning_Loop BOOLEAN,
    Sunrise_Sunset VARCHAR(255),
    Civil_Twilight VARCHAR(255),
    Nautical_Twilight VARCHAR(255),
    Astronomical_Twilight VARCHAR(255)
);



-- Filter the RawData table and create new table
CREATE TABLE FilteredRawData AS
	SELECT
		ID,
		Start_Time,
		Severity,
		Start_Lat,
		Description,
		Street,
		City,
		County,
		State,
		Temperature_F,
		Crossing,
		Junction,
		Roundabout,
		Traffic_Signal
	FROM RawData
	WHERE
		EXTRACT(YEAR FROM Start_Time) BETWEEN 2017 AND 2022;
		


-- ANALYSIS

-- 1. Temporal Impact
--- 1-1. Hour of the Day
WITH HourCount AS (
    SELECT 
        EXTRACT(HOUR FROM Start_Time) AS hour_of_day,
        COUNT(DISTINCT DATE(Start_Time)::TEXT || '-' || EXTRACT(HOUR FROM Start_Time)::TEXT) AS total_hours
    FROM FilteredRawData
    GROUP BY hour_of_day
)

SELECT 
    h.hour_of_day,
    ROUND(COUNT(r.ID) * 1.0 / h.total_hours, 2) AS avg_accidents_per_hour
FROM FilteredRawData r
JOIN HourCount h ON EXTRACT(HOUR FROM r.Start_Time) = h.hour_of_day
GROUP BY h.hour_of_day, h.total_hours
ORDER BY avg_accidents_per_hour DESC;


--- 1-2. Day of Week
WITH DayCount AS (
    SELECT 
        EXTRACT(DOW FROM Start_Time) AS day_of_week_num,
        TO_CHAR(Start_Time, 'Day') AS day_of_week_text,
        COUNT(DISTINCT DATE(Start_Time)) AS total_days
    FROM FilteredRawData
    GROUP BY day_of_week_num, day_of_week_text
)

SELECT 
    d.day_of_week_text AS day_of_week,
    ROUND(COUNT(r.ID) * 1.0 / d.total_days, 2) AS avg_accidents_per_day
FROM FilteredRawData r
JOIN DayCount d ON EXTRACT(DOW FROM r.Start_Time) = d.day_of_week_num
GROUP BY d.day_of_week_text, d.total_days
ORDER BY avg_accidents_per_day DESC;



--- 1-3. Month
WITH MonthCount AS (
    SELECT 
        EXTRACT(MONTH FROM Start_Time) AS month,
        COUNT(DISTINCT DATE_TRUNC('MONTH', Start_Time)) AS total_months
    FROM FilteredRawData
    GROUP BY month
)

SELECT 
    m.month,
    ROUND(COUNT(r.ID) * 1.0 / m.total_months, 2) AS avg_accidents_per_month
FROM RawData r
JOIN MonthCount m ON EXTRACT(MONTH FROM r.Start_Time) = m.month
GROUP BY m.month, m.total_months
ORDER BY avg_accidents_per_month DESC;



-- 2. Location Impact
--- 2-1. Cities with highest number of accidents
SELECT 
    City,
    COUNT(*) AS accident_count
FROM FilteredRawData
GROUP BY City
ORDER BY accident_count DESC
LIMIT 10;



--- 2-2. Streets with the highest number of accidents
SELECT 
    Street,
    City,
    COUNT(*) AS accident_count
FROM FilteredRawData
GROUP BY Street, City
ORDER BY accident_count DESC
LIMIT 10;



-- 3. Weather Impact
--- 3-1. Accidents by weather condition
SELECT 
    Weather_Condition,
    COUNT(*) AS accident_count
FROM FilteredRawData
WHERE Weather_Condition IS NOT NULL
GROUP BY Weather_Condition
ORDER BY accident_count DESC;



--- 3-2. Severity of accidents in different weather conditions
SELECT 
    Weather_Condition,
    ROUND(AVG(Severity), 2) AS avg_severity
FROM FilteredRawData
WHERE Weather_Condition IS NOT NULL
GROUP BY Weather_Condition
ORDER BY avg_severity DESC;



-- 4. Traffic Features Impact
--- 4-1. Accidents related to specific traffic features
SELECT 
    Crossing, Junction, Roundabout, Traffic_Signal,
    COUNT(*) AS accident_count
FROM FilteredRawData
GROUP BY Crossing, Junction, Roundabout, Traffic_Signal
ORDER BY accident_count DESC;


WITH FeatureCounts AS (
    SELECT 
        'Crossing' AS feature,
        Crossing AS value,
        COUNT(*) AS accident_count
    FROM FilteredRawData
    GROUP BY Crossing
    UNION ALL
    SELECT 
        'Junction' AS feature,
        Junction AS value,
        COUNT(*) AS accident_count
    FROM FilteredRawData
    GROUP BY Junction
    UNION ALL
	    SELECT 
        'Roundabout' AS feature,
        Roundabout AS value,
        COUNT(*) AS accident_count
    FROM FilteredRawData
    GROUP BY Roundabout
	UNION ALL
    SELECT 
        'Traffic_Signal' AS feature,
        Traffic_Signal AS value,
        COUNT(*) AS accident_count
    FROM FilteredRawData
    GROUP BY Traffic_Signal
)

SELECT 
    feature,
    COALESCE(SUM(CASE WHEN value THEN accident_count END), 0) AS "True",
    COALESCE(SUM(CASE WHEN NOT value THEN accident_count END), 0) AS "False"
FROM FeatureCounts
GROUP BY feature
ORDER BY feature;

