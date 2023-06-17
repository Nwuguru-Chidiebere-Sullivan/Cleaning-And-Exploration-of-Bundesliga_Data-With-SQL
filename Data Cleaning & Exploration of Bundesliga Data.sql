--TITLE: DATA CLEANING AND EXPLORATION OF BUNDESLIGA DATA USING SQL

--Let's create our table
CREATE TABLE bundesliga_stats(
  MATCH_DATE date,
  SEASON integer,
  FINISHED boolean,
  LOCATION varchar(245),
  NUMBER_OF_VIEWERS numeric,
  MATCHDAY text,
  MATCHDAY_NR integer,
  HOME_TEAM_ID integer,
  HOME_TEAM_NAME varchar(245),
  HOME_TEAM_SHORT_NAME varchar(50),
  AWAY_TEAM_ID integer,
  AWAY_TEAM_NAME varchar(245),
  AWAY_TEAM_SHORT_NAME varchar(50),
  GOALS_HOME integer,
  GOALS_AWAY integer,
  DRAW integer,
  WIN_HOME integer,
  WIN_AWAY integer
)

--Let's copy the corresponding csv file into the table we created
COPY PUBLIC."bundesliga_stats"
FROM 'C:\Users\HP\Desktop\CSV Files\bulidata.csv'
DELIMITER ','
HEADER CSV

--Let's view and clean our table where necessary
SELECT *
FROM bundesliga_stats;
--cleaning the location column
UPDATE bundesliga_stats SET location = REPLACE(location, 'M?chen', 'München')
UPDATE bundesliga_stats SET location = REPLACE(location, 'K?n', 'Köln')
UPDATE bundesliga_stats SET location = REPLACE(location, 'N?rnberg', 'Nürnberg')
--cleaning the home_team_name column
UPDATE bundesliga_stats SET home_team_name = REPLACE(home_team_name , 'FC Bayern M?chen', 'FC Bayern München')
UPDATE bundesliga_stats SET home_team_name = REPLACE(home_team_name , '1. FC K?n', '1. FC Köln')
UPDATE bundesliga_stats SET home_team_name = REPLACE(home_team_name , 'Borussia M?chengladbach', 'Borussia Müchengladbach')
UPDATE bundesliga_stats SET home_team_name = REPLACE(home_team_name , '1. FC N?nberg', '1. FC Nürnberg')
--cleaning the away_team_name column
UPDATE bundesliga_stats SET away_team_name = REPLACE(away_team_name , 'FC Bayern M?chen', 'FC Bayern München')
UPDATE bundesliga_stats SET away_team_name = REPLACE(away_team_name , '1. FC K?n', '1. FC Köln')
UPDATE bundesliga_stats SET away_team_name = REPLACE(away_team_name , 'Borussia M?chengladbach', 'Borussia Müchengladbach')
UPDATE bundesliga_stats SET away_team_name = REPLACE(away_team_name , '1. FC N?nberg', '1. FC Nürnberg')

--Let's see each match played and won by FC Bayern
SELECT
  match_date,
  home_team_name,
  away_team_name,
  CASE WHEN home_team_id = 40
       AND goals_home > goals_away THEN 'Bayern wins!!'
	   WHEN away_team_id = 40
	   AND goals_home < goals_away THEN 'Bayern wins!!'
	   ELSE 'loss or tie' END AS outcome
FROM bundesliga_stats
WHERE home_team_id = 40
    OR away_team_id = 40;
	
--Let's query to return only columns where Dortmund won as a home or away_team without 
--keeping tie, loss or null values
SELECT
  match_date,
  season,
  CASE WHEN home_team_id = 7
           AND goals_home > goals_away THEN 'Dortmund home win!!'
		   WHEN away_team_id = 7
		   AND goals_home < goals_away THEN 'Dortmund away win'
		   END AS outcome
FROM bundesliga_stats
WHERE CASE WHEN home_team_id = 7
           AND goals_home > goals_away THEN 'Dortmund home win!!'
		   WHEN away_team_id = 7
		   AND goals_home < goals_away THEN 'Dortmund away win'
		   END IS NOT NULL;
		   
--Let's retrieve from the matches played between Bayern and Dortmund, which of the teams
--were away or home
SELECT
  match_date,
  season,
  --identify the home_team as Bayern or Dortmund
  CASE WHEN home_team_id = 40 THEN 'FC Bayern'
       ELSE 'Dortmond' END AS home,
  --identify the away_team as Bayern or Dortmund
  CASE WHEN away_team_id = 40 THEN 'FC Bayern'
       ELSE 'Dortmund' END AS away
FROM bundesliga_stats
WHERE (home_team_id = 40 OR away_team_id = 40)
    AND (home_team_id = 7 OR away_team_id = 7);
	
--Let's query to count the home_wins of FC Schalke 04 in each of the seasons
SELECT
  season,
  COUNT(CASE WHEN home_team_name = 'FC Schalke 04'
	         AND goals_home > goals_away 
		     THEN home_team_id END) AS home_wins
FROM bundesliga_stats
WHERE home_team_name = 'FC Schalke 04'
GROUP BY season
ORDER BY season DESC;

--Let's sum the home and away goals scored by FC Köln across each season
SELECT
  season,
  SUM(CASE WHEN home_team_id = 65
	       THEN goals_home END) AS home_goals,
  SUM(CASE WHEN away_team_id = 65
	       THEN goals_away END) AS away_goals
FROM bundesliga_stats
GROUP BY season
ORDER BY season DESC;

--Let's check for what percentage of Eintracht Frankfurt's matches that they won in each season
SELECT
  season,
  ROUND(AVG(CASE WHEN home_team_id = 91
	       AND goals_home > goals_away THEN 1
	       WHEN home_team_id = 91
	       AND goals_home < goals_away THEN 0 END),2)*100 AS pct_home_wins,
  ROUND(AVG(CASE WHEN away_team_id = 91
	       AND goals_home < goals_away THEN 1
	       WHEN goals_home > goals_away THEN 0 END),2)*100 AS pct_home_wins
FROM bundesliga_stats
GROUP BY season
ORDER BY season DESC;

--Let's query to retrieve those matches where home_goal is greater than the avg-goal
-- in 2022 season
SELECT
  match_date,
  season,
  home_team_name,
  away_team_name,
  goals_home
FROM bundesliga_stats
WHERE goals_home > (SELECT 
					  AVG(goals_home + goals_away) 
				    FROM bundesliga_stats)
      AND season = 2022;

--How many goals were scored in each match in 2005 and how did that compare to the 
--season's average
SELECT
  match_date,
  season,
  home_team_name,
  away_team_name,
  (goals_home + goals_away) AS match_goals,
     (SELECT ROUND(AVG(goals_home + goals_away),2)
		   FROM bundesliga_stats
		   WHERE season = 2005) AS season_avg
FROM bundesliga_stats
WHERE season = 2005;

--Let's write a query to retrieve matches where the number of viewers is greater
--than the average number of viewers in each month across the 2017 season
SELECT
  DISTINCT match_date,
  season,
  home_team_name,
  away_team_name,
  number_of_viewers,
  ROUND(AVG(number_of_viewers) OVER(PARTITION BY 
							 EXTRACT(MONTH FROM match_date)),2) AS months_avg
FROM bundesliga_stats
WHERE season = 2017
ORDER BY match_date ASC, number_of_viewers DESC;

--Let's rank matches in 2017 based on the number of viewers that attended each of the matches
SELECT
  match_date,
  season,
  home_team_name,
  away_team_name,
  number_of_viewers,
  DENSE_RANK() OVER(ORDER BY number_of_viewers DESC) AS viewers_dense_rank
FROM bundesliga_stats
WHERE season = 2017;

--Let's calculate the sum of FC Bayerns home_goals in each current and the preceding match 
--across the 2022 season
SELECT
  match_date,
  season,
  goals_home,
  SUM(goals_home) OVER(ORDER BY match_date
					  ROWS BETWEEN 1 PRECEDING AND CURRENT ROW) AS sum_of_last_2_games
FROM bundesliga_stats
WHERE season = 2022
  AND home_team_id = 40;
  
--The end. Thank you!!!