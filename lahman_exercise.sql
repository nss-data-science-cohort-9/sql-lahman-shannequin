/*
## Lahman Baseball Database Exercise
- this data has been made available [online](http://www.seanlahman.com/baseball-archive/statistics/) by Sean Lahman
- you can find a data dictionary [here](http://www.seanlahman.com/files/database/readme2016.txt)
*/

-- 1. Find all players in the database who played at Vanderbilt University. 
-- Create a list showing each player's first and last names as well as the total salary they earned in the major leagues. 
-- Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?

WITH VANDY_PLAYERS AS (
	SELECT DISTINCT ON (P.PLAYERID)
		P.PLAYERID,
		P.NAMEFIRST,
		P.NAMELAST
	FROM PEOPLE P
		INNER JOIN COLLEGEPLAYING C USING (PLAYERID)
		INNER JOIN SCHOOLS S ON C.SCHOOLID = S.SCHOOLID
	WHERE S.SCHOOLNAME = 'Vanderbilt University'
)
SELECT 
	CONCAT(V.NAMEFIRST, ' ', V.NAMELAST) AS NAME,
	SUM(L.SALARY)::NUMERIC::MONEY AS TOTAL_EARNINGS
FROM VANDY_PLAYERS V
	INNER JOIN SALARIES L USING (PLAYERID)
GROUP BY V.PLAYERID, V.NAMEFIRST, V.NAMELAST
ORDER BY TOTAL_EARNINGS DESC NULLS LAST;

-- ALTERNATE SOLUTION

SELECT 
	P.NAMEFIRST || ' ' || P.NAMELAST AS NAME,
	SUM(S.SALARY)::NUMERIC::MONEY AS TOTAL_EARNINGS
FROM PEOPLE P
	INNER JOIN SALARIES S USING (PLAYERID)
WHERE P.PLAYERID IN (
	SELECT PLAYERID
	FROM COLLEGEPLAYING
	WHERE SCHOOLID = 'vandy'
)
GROUP BY P.NAMEFIRST, P.NAMELAST
ORDER BY TOTAL_EARNINGS DESC NULLS LAST;

-- ANSWER: DAVID PRICE ($81,851,296)


-- 2. Using the fielding table, group players into three groups based on their position: 
-- label players with position OF as "Outfield", 
-- those with position "SS", "1B", "2B", and "3B" as "Infield", 
-- and those with position "P" or "C" as "Battery". 
-- Determine the number of putouts made by each of these three groups in 2016.
SELECT
	CASE
		WHEN POS = 'OF' THEN 'Outfield'
		WHEN POS IN ('SS', '1B', '2B', '3B') THEN 'Infield'
		WHEN POS IN ('P', 'C') THEN 'Battery'
		ELSE NULL
	END AS POSITION,
	SUM(PO) AS TOTAL_PUTOUTS
FROM FIELDING 
WHERE YEARID = 2016
GROUP BY POSITION
ORDER BY TOTAL_PUTOUTS DESC;

-- ANSWER: 
-- Infield (58,934)
-- Battery (41,424)
-- Outfield (29,560)


-- 3. Find the average number of strikeouts per game by decade since 1920. 
-- Round the numbers you report to 2 decimal places. 
-- Do the same for home runs per game. 
-- Do you see any trends?
-- (Hint: For this question, you might find it helpful to look at the **generate_series** function (https://www.postgresql.org/docs/9.1/functions-srf.html). 
-- If you want to see an example of this in action, check out this DataCamp video: https://campus.datacamp.com/courses/exploratory-data-analysis-in-sql/summarizing-and-aggregating-numeric-data?ex=6)
WITH BINS AS (
	SELECT GENERATE_SERIES(1920, 2026, 10) AS LOWER,
		GENERATE_SERIES(1929, 2026, 10) AS UPPER
),
SO_GAMES_YEAR AS (
	SELECT YEARID,
		SUM(SO) AS SUM_SO,
		SUM(G) AS SUM_G
	FROM TEAMS
	GROUP BY YEARID
),
TOTAL_SO_G_YEAR AS (
	SELECT B.LOWER,
		B.UPPER,
		SUM(S.SUM_SO) AS TOTAL_SO,
		SUM(S.SUM_G) / 2 AS TOTAL_G
	FROM BINS B
		LEFT JOIN SO_GAMES_YEAR S ON B.LOWER <= S.YEARID
			AND B.UPPER >= S.YEARID
	GROUP BY B.LOWER, B.UPPER
	ORDER BY B.LOWER, B.UPPER
)
SELECT CONCAT(LOWER, ' - ', UPPER) AS DECADE,
	ROUND(TOTAL_SO / TOTAL_G, 2) AS AVG_SO
FROM TOTAL_SO_G_YEAR;

-- ALTERNATE TO GET DECADES: (YEAR / 10) * 10

-- ANSWER:
-- "1920 - 1929"	5.63
-- "1930 - 1939"	6.63
-- "1940 - 1949"	7.10
-- "1950 - 1959"	8.80
-- "1960 - 1969"	11.43
-- "1970 - 1979"	10.29
-- "1980 - 1989"	10.73
-- "1990 - 1999"	12.30
-- "2000 - 2009"	13.12
-- "2010 - 2019"	15.04
-- "2020 - "	

WITH BINS AS (
	SELECT GENERATE_SERIES(1920, 2026, 10) AS LOWER,
		GENERATE_SERIES(1929, 2026, 10) AS UPPER
),
HR_GAMES_YEAR AS (
	SELECT YEARID,
		SUM(HR) AS SUM_HR,
		SUM(G) AS SUM_G
	FROM TEAMS
	GROUP BY YEARID
),
TOTAL_HR_G_YEAR AS (
	SELECT B.LOWER,
		B.UPPER,
		SUM(S.SUM_HR) AS TOTAL_HR,
		SUM(S.SUM_G) / 2 AS TOTAL_G
	FROM BINS B
		LEFT JOIN HR_GAMES_YEAR S ON B.LOWER <= S.YEARID
			AND B.UPPER >= S.YEARID
	GROUP BY B.LOWER, B.UPPER
	ORDER BY B.LOWER, B.UPPER
)
SELECT CONCAT(LOWER, ' - ', UPPER) AS DECADE,
	ROUND(TOTAL_HR / TOTAL_G, 2) AS AVG_HR
FROM TOTAL_HR_G_YEAR;

-- ANSWER:
-- "1920 - 1929"	0.80
-- "1930 - 1939"	1.09
-- "1940 - 1949"	1.05
-- "1950 - 1959"	1.69
-- "1960 - 1969"	1.64
-- "1970 - 1979"	1.49
-- "1980 - 1989"	1.62
-- "1990 - 1999"	1.91
-- "2000 - 2009"	2.15
-- "2010 - 2019"	1.97
-- "2020 - "	

-- THERE IS A POSITIVE CORRELATION BETWEEN THE DECADE, SO, AND HR.

-- ALTERNATE SOLUTION

WITH DECADES AS (
	SELECT *
	FROM GENERATE_SERIES(1920, 2016, 10) AS DECADE_START
)
SELECT
	DECADE_START || 's' AS DECADE,
	ROUND(SUM(SO) * 1.0 / (SUM(G) / 2.0), 2) AS SO_PER_GAME,
	ROUND(SUM(HR) * 1.0 / (SUM(G) / 2.0), 2) AS HR_PER_GAME
FROM TEAMS T
	INNER JOIN DECADES D ON T.YEARID BETWEEN D.DECADE_START AND D.DECADE_START + 9
WHERE YEARID >= 1920
GROUP BY DECADE
ORDER BY DECADE;


-- 4. Find the player who had the most success stealing bases in 2016, 
-- where __success__ is measured as the percentage of stolen base attempts which are successful. 
-- (A stolen base attempt results either in a stolen base or being caught stealing.) 
-- Consider only players who attempted _at least_ 20 stolen bases. 
-- Report the players' names, number of stolen bases, number of attempts, and stolen base percentage.

WITH STEALING_TOTALS AS (
	SELECT
		PLAYERID,
		SUM(SB) AS TOTAL_SB,
		SUM(CS) AS TOTAL_CS,
		SUM(SB) + SUM(CS) AS TOTAL_ATTEMPTS
	FROM BATTING
	WHERE YEARID = 2016
	GROUP BY PLAYERID
	-- ALTERNATE INSTEAD OF MAIN QUERY WHERE STATEMENT: HAVING SUM(SB) + SUM(CS) >= 20
)
SELECT CONCAT(P.NAMEFIRST, ' ', P.NAMELAST) AS NAME,
	B.TOTAL_SB,
	B.TOTAL_ATTEMPTS,
	ROUND(B.TOTAL_SB::DECIMAL / B.TOTAL_ATTEMPTS, 3) AS PERCENT_STOLEN
FROM STEALING_TOTALS B
	INNER JOIN PEOPLE P USING (PLAYERID)
WHERE B.TOTAL_ATTEMPTS >= 20
ORDER BY PERCENT_STOLEN DESC
LIMIT 1;

-- ANSWER: Chris Owings	(21	23	0.913)

-- ALTERNATE SOLUTION

SELECT
	P.NAMEFIRST || ' ' || P.NAMELAST AS NAME,
	SUM(SB) AS TOTAL_SB,
	SUM(SB) + SUM(CS) AS TOTAL_ATTEMPTS,
	ROUND(SUM(SB)::DECIMAL / (SUM(SB) + SUM(CS)), 3) AS PERCENT_STOLEN
FROM BATTING B
	INNER JOIN PEOPLE P USING (PLAYERID)
WHERE YEARID = 2016
GROUP BY NAME
HAVING SUM(SB) + SUM(CS) >= 20
ORDER BY PERCENT_STOLEN DESC
LIMIT 1;


-- 5. From 1970 to 2016, what is the largest number of wins for a team that did not win the world series? 
SELECT
	YEARID,
	TEAMID,
	W
FROM TEAMS
WHERE WSWIN = 'N'
	AND YEARID BETWEEN 1970 AND 2016
ORDER BY W DESC
LIMIT 1;

-- ANSWER: SEA (116)


-- What is the smallest number of wins for a team that did win the world series? 
SELECT
	YEARID,
	TEAMID,
	W
FROM TEAMS
WHERE WSWIN = 'Y'
	AND YEARID BETWEEN 1970 AND 2016
ORDER BY W
LIMIT 1;

-- ANSWER: LAN (63)


-- Doing this will probably result in an unusually small number of wins for a world series champion; determine why this is the case. 
SELECT DISTINCT YEARID, SUM(G) / 2 AS SUM_G
FROM TEAMS
WHERE YEARID >= 1970
GROUP BY YEARID
ORDER BY SUM_G;

-- ANSWER: THERE WAS A PLAYER STRIKE IN 1981 AND 1994


-- Then redo your query, excluding the problem year. 
SELECT
	YEARID,
	TEAMID,
	W
FROM TEAMS
WHERE YEARID BETWEEN 1970 AND 2016
	AND YEARID <> 1981
	AND WSWIN = 'Y'
ORDER BY W
LIMIT 1;

-- ANSWER: SLN (83)


-- How often from 1970 to 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?
-- (TEAMS COULD BE TIED FOR MOST WINS)
WITH MOST_GAMES_WON AS (
	SELECT DISTINCT ON (YEARID)
		YEARID,
		TEAMID,
		W,
		WSWIN
	FROM TEAMS
	WHERE YEARID BETWEEN 1970 AND 2016
	ORDER BY YEARID, W DESC, WSWIN DESC
),
WS_WINNERS AS (
	SELECT TEAMID
	FROM MOST_GAMES_WON
	WHERE WSWIN = 'Y'
)
SELECT ROUND(
	(
		SELECT COUNT(*)
		FROM WS_WINNERS
	) / COUNT(*)::DECIMAL,
	3
) AS PERCENT_WS_MOST_WINS
FROM MOST_GAMES_WON;

-- ALTERNATE SOLUTION

WITH WS_WINNERS AS (
	SELECT
		TEAMID,
		YEARID,
		W,
		WSWIN
	FROM TEAMS
	WHERE YEARID BETWEEN 1970 AND 2016
		AND WSWIN = 'Y'
),
MOST_WINS AS (
	SELECT
		YEARID,
		MAX(W) AS MAX_WINS
	FROM TEAMS
	WHERE YEARID BETWEEN 1970 AND 2016
	GROUP BY YEARID
),
WINNERS_WITH_MOST_WINS AS (
	SELECT
		W.YEARID,
		TEAMID,
		W
	FROM WS_WINNERS W
		INNER JOIN MOST_WINS M ON W.YEARID = M.YEARID
		AND W = MAX_WINS
)
SELECT ROUND(
	100.0 * (
		SELECT COUNT(*)
		FROM WINNERS_WITH_MOST_WINS
	) / (
		SELECT COUNT(*)
		FROM WS_WINNERS
	),
	1
);


-- 6. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? 
-- Give their full name and the teams that they were managing when they won the award.

SELECT
	NAMEFIRST || ' ' || NAMELAST AS FULL_NAME,
	A.YEARID AS YEAR,
	A.LGID AS LEAGUE,
	NAME AS TEAM_NAME
FROM AWARDSMANAGERS A
	INNER JOIN PEOPLE P ON A.PLAYERID = P.PLAYERID
	INNER JOIN MANAGERS M ON A.PLAYERID = M.PLAYERID
		AND A.YEARID = M.YEARID
	INNER JOIN TEAMS T ON M.TEAMID = T.TEAMID
		AND M.YEARID = T.YEARID
WHERE
	A.PLAYERID IN (
		SELECT *
		FROM (
			(
				SELECT PLAYERID
				FROM AWARDSMANAGERS
				WHERE AWARDID = 'TSN Manager of the Year'
					AND LGID = 'AL'
			)
			INTERSECT
			(
				SELECT PLAYERID
				FROM AWARDSMANAGERS
				WHERE
					AWARDID = 'TSN Manager of the Year'
					AND LGID = 'NL'
			)
		)
	)
	AND AWARDID = 'TSN Manager of the Year'
ORDER BY FULL_NAME,	A.YEARID;

-- ALTERNATE SOLUTION

WITH BOTH_LEAGUE_WINNERS AS (
	(
		SELECT PLAYERID
		FROM AWARDSMANAGERS
		WHERE
			AWARDID = 'TSN Manager of the Year'
			AND LGID = 'AL'
	)
	INTERSECT
	(
		SELECT PLAYERID
		FROM AWARDSMANAGERS
		WHERE
			AWARDID = 'TSN Manager of the Year'
			AND LGID = 'NL'
	)
)
SELECT
	NAMEFIRST || ' ' || NAMELAST AS FULL_NAME,
	A.YEARID,
	A.LGID,
	NAME
FROM
	AWARDSMANAGERS A
	INNER JOIN PEOPLE P ON A.PLAYERID = P.PLAYERID
	INNER JOIN MANAGERS M ON A.PLAYERID = M.PLAYERID
	AND A.YEARID = M.YEARID
	INNER JOIN TEAMS T ON M.TEAMID = T.TEAMID
	AND M.YEARID = T.YEARID
WHERE
	A.PLAYERID IN (
		SELECT *
		FROM BOTH_LEAGUE_WINNERS
	)
	AND AWARDID = 'TSN Manager of the Year'
ORDER BY
	FULL_NAME,
	YEARID;

-- ANSWER:
-- "Davey Johnson"	1997	"AL"	"Baltimore Orioles"
-- "Davey Johnson"	2012	"NL"	"Washington Nationals"
-- "Jim Leyland"	1988	"NL"	"Pittsburgh Pirates"
-- "Jim Leyland"	1990	"NL"	"Pittsburgh Pirates"
-- "Jim Leyland"	1992	"NL"	"Pittsburgh Pirates"
-- "Jim Leyland"	2006	"AL"	"Detroit Tigers"


-- 7. Which pitcher was the least efficient in 2016 in terms of salary / strikeouts?
-- Only consider pitchers who started at least 10 games (across all teams). 
-- Note that pitchers often play for more than one team in a season, so be sure that you are counting all stats for each player.

SELECT
	NAMEFIRST || ' ' || NAMELAST AS FULL_NAME,
	ROUND(SALARY::NUMERIC / SO, 2)::MONEY AS SALARY_PER_STRIKEOUT,
	SALARY::NUMERIC::MONEY,
	SO
FROM (
	SELECT
		PLAYERID,
		SUM(SO) AS SO,
		SUM(GS) AS GS
	FROM PITCHING
	WHERE YEARID = 2016
	GROUP BY PLAYERID
	HAVING SUM(GS) >= 10
) P
	INNER JOIN (
		SELECT
			PLAYERID,
			SUM(SALARY) AS SALARY
		FROM SALARIES
		WHERE YEARID = 2016
		GROUP BY PLAYERID
	) S ON P.PLAYERID = S.PLAYERID
	INNER JOIN PEOPLE PE ON P.PLAYERID = PE.PLAYERID
ORDER BY SALARY_PER_STRIKEOUT DESC;

-- ALTERNATE SOLUTION

WITH
	FULL_PITCHING AS (
		SELECT
			PLAYERID,
			SUM(SO) AS SO,
			SUM(GS) AS GS
		FROM PITCHING
		WHERE YEARID = 2016
		GROUP BY PLAYERID
		HAVING SUM(GS) >= 10
	),
	FULL_SALARIES AS (
		SELECT
			PLAYERID,
			SUM(SALARY) AS SALARY
		FROM SALARIES
		WHERE YEARID = 2016
		GROUP BY PLAYERID
	)
SELECT
	NAMEFIRST || ' ' || NAMELAST AS FULL_NAME,
	ROUND(SALARY::NUMERIC / SO, 2)::MONEY AS SALARY_PER_STRIKEOUT,
	SALARY::NUMERIC::MONEY,
	SO
FROM FULL_PITCHING P
	INNER JOIN FULL_SALARIES S ON P.PLAYERID = S.PLAYERID
	INNER JOIN PEOPLE PE ON P.PLAYERID = PE.PLAYERID
ORDER BY SALARY_PER_STRIKEOUT DESC;

-- ANSWER: Matt Cain ($20,833,333.00 / 72 = $289,351.85)


-- 8. Find all players who have had at least 3000 career hits. 
-- Report those players' names, total number of hits, and the year they were inducted into the hall of fame 
-- (If they were not inducted into the hall of fame, put a null in that column.) 
-- Note that a player being inducted into the hall of fame is indicated by a 'Y' in the **inducted** column of the halloffame table.

WITH
	HITS AS (
		SELECT PLAYERID,
			SUM(H) AS CAREER_HITS
		FROM BATTING
		GROUP BY PLAYERID
		HAVING SUM(H) >= 3000
	),
	HALL_OF_FAME AS (
		SELECT DISTINCT ON (H.PLAYERID)
			H.PLAYERID,
			CASE
				WHEN F.INDUCTED = 'Y' THEN F.YEARID
				ELSE NULL
			END AS HALL_OF_FAME_YEAR,
			H.CAREER_HITS
		FROM HALLOFFAME F
			RIGHT JOIN HITS H USING (PLAYERID)
		ORDER BY PLAYERID, HALL_OF_FAME_YEAR
	)
SELECT
	P.NAMEFIRST || ' ' || NAMELAST AS PLAYER_NAME,
	F.CAREER_HITS,
	F.HALL_OF_FAME_YEAR
FROM PEOPLE P
	RIGHT JOIN HALL_OF_FAME F ON P.PLAYERID = F.PLAYERID
ORDER BY HALL_OF_FAME_YEAR, CAREER_HITS DESC;

-- ANSWER: (30 ROWS)


-- 9. Find all players who had at least 1,000 hits for two different teams. Report those players' full names.

WITH
	HITS AS (
		SELECT
			PLAYERID,
			TEAMID,
			SUM(H) AS HITS
		FROM BATTING
		GROUP BY PLAYERID, TEAMID
		HAVING SUM(H) >= 1000
	),
	TEAMS AS (
		SELECT
			PLAYERID,
			COUNT(TEAMID) AS TEAMS
		FROM HITS
		GROUP BY PLAYERID
		HAVING COUNT(TEAMID) > 1
	)
SELECT
	P.NAMEFIRST || ' ' || P.NAMELAST AS PLAYER_NAME,
	H.TEAMID,
	H.HITS
FROM PEOPLE P
	INNER JOIN HITS H ON P.PLAYERID = H.PLAYERID
	RIGHT JOIN TEAMS T ON P.PLAYERID = T.PLAYERID
ORDER BY PLAYER_NAME, HITS;

-- ANSWER: (14 PLAYERS)


-- 10. Find all players who hit their career highest number of home runs in 2016. 
-- Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. 
-- Report the players' first and last names and the number of home runs they hit in 2016.
WITH
	PLAYERS_TEN_YR AS (
		SELECT
			PLAYERID,
			COUNT(YEARID) AS YEARS
		FROM BATTING
		WHERE YEARID <= 2016
		GROUP BY PLAYERID
		HAVING COUNT(YEARID) >= 10
	)
SELECT
	PL.NAMEFIRST || ' ' || PL.NAMELAST AS PLAYER_NAME,
	B.YEARID,
	MAX(B.HR) AS MAX_HR
FROM BATTING B
	INNER JOIN PLAYERS_TEN_YR P USING (PLAYERID)
	INNER JOIN PEOPLE PL USING (PLAYERID)
WHERE B.YEARID <= 2016
	AND B.HR > 0
GROUP BY P.PLAYERID, PLAYER_NAME, B.YEARID
HAVING B.YEARID = 2016
ORDER BY MAX_HR DESC;

-- ANSWER: (115 ROWS)

-- After finishing the above questions, here are some open-ended questions to consider.

-- **Open-ended questions**

-- 11. Is there any correlation between number of wins and team salary? Use data from 2000 and later to answer this question. As you do this analysis, keep in mind that salaries across the whole league tend to increase together, so you may want to look on a year-by-year basis.

-- 12. In this question, you will explore the connection between number of wins and attendance.

--     a. Does there appear to be any correlation between attendance at home games and number of wins?  
--     b. Do teams that win the world series see a boost in attendance the following year? What about teams that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.


-- 13. It is thought that since left-handed pitchers are more rare, causing batters to face them less often, that they are more effective. Investigate this claim and present evidence to either support or dispute this claim. First, determine just how rare left-handed pitchers are compared with right-handed pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to make it into the hall of fame?