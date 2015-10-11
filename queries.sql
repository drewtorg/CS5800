use baseball;
-- Query 1 - LA Dodgers
-- List the first name and last name of every player that has 
-- played at any time in their career for the Los Angeles Dodgers. 
-- List each player only once 
-- .016 sec
SELECT DISTINCT master.nameFirst, master.nameLast
FROM master 
	NATURAL JOIN appearances 
    NATURAL JOIN teams
WHERE teams.name = "Los Angeles Dodgers"
ORDER BY nameLast;

-- Query 2 - Brooklyn AND LA Dodgers Only
-- List the first name and last name of every player that has played
-- only for the Los Angeles AND Brooklyn Dodgers (i.e., they did not 
-- play for any other team). List each player only once. 
-- VERIFY RESULTS
SELECT DISTINCT X.nameFirst, X.nameLast
FROM (SELECT DISTINCT m.nameFirst, m.nameLast
    FROM master m 
		NATURAL JOIN appearances a
		NATURAL JOIN teams t
	WHERE t.name = "Brooklyn Dodgers"
	) X
		INNER JOIN
    (SELECT DISTINCT m.nameFirst, m.nameLast
    FROM master m 
		NATURAL JOIN appearances a
		NATURAL JOIN teams t
	WHERE t.name = "Los Angeles Dodgers"
	) Y
		ON X.nameFirst = Y.nameFirst
			AND X.nameLast = Y.nameLast
ORDER BY X.nameLast;

-- Query 3 - Gold Glove Dodgers
-- For each Los Angeles Dodger that has won a "Gold Glove" award, 
-- list their first name, last name, position (this is the 'notes' 
-- field in the 'awardsplayers' table), and year in which the award 
-- was won. Note that a player may win such an award several times.
-- .063 sec
SELECT master.nameFirst, master.nameLast, yearId, awardsplayers.notes
FROM awardsplayers
	NATURAL JOIN master
	NATURAL JOIN appearances
    NATURAL JOIN teams
WHERE awardID = "Gold Glove" AND teams.name = "Los Angeles Dodgers"
ORDER BY yearId, nameLast;

-- Query 4 - World Series Winners
-- List the name of each team that has won the world series and number 
-- of world series that it has won (the column WSWin in the Teams table 
-- has a 'Y' value if the team won the world series in that season). 
-- Each winner should be listed just once.
-- .031 sec
SELECT teams.name, COUNT(*) count
FROM teams
WHERE teams.WSWin = "Y"
GROUP BY teams.name
ORDER BY count;

-- Query 5 - USU batters
-- List the first name, last name, year played, and batting average (h/ab) 
-- of every player from the school named "Utah State University".
-- .046 sec
SELECT batting.H/batting.AB avg, batting.H, batting.AB, nameFirst, nameLast, yearID
FROM master
	NATURAL JOIN appearances
	NATURAL JOIN batting
	NATURAL JOIN schoolsplayers
    NATURAL JOIN schools
WHERE schools.schoolName = "Utah State University" AND batting.G_batting > 0
ORDER BY yearID;

-- Query 6 - Bumper Salary Teams
-- List the total salary for two consecutive years, team name, and year 
-- for every team that had a total salary which was 1.5 times as much 
-- as for the previous year.
-- VERIFY RESULTS
-- 1.094 sec
CREATE OR REPLACE VIEW teamsalaries AS (
	SELECT name, lgID, yearID, SUM(salaries.salary) salary FROM master 
		NATURAL JOIN salaries
		NATURAL JOIN teams
		NATURAL JOIN appearances
	GROUP BY teams.name, teams.yearID
);
SELECT X.name, X.lgID, X.yearID prevYear, X.salary prevSalary, 
	Y.yearID currYear, Y.salary currSalary, TRUNCATE(Y.salary / X.salary * 100, 0) percentIncrease
FROM teamsalaries X, teamsalaries Y
WHERE X.name = Y.name
	AND TRUNCATE(Y.salary / X.salary * 100, 0) >= 150
	AND X.yearID = Y.yearID - 1
ORDER BY prevYear, X.name;


-- Query 7 - Red Sox Four
-- List the first name and last name of every player that has batted for 
-- the Boston Red Sox in at least four consecutive years. 
-- List each player only once.
-- 15.547 sec
CREATE OR REPLACE VIEW redsox AS (
	SELECT nameFirst, nameLast, AB, yearId
    FROM master
		NATURAL JOIN appearances
        NATURAL JOIN teams
	WHERE AB > 0 AND teams.name = "Boston Red Sox"
);
SELECT DISTINCT r1.nameFirst, r1.nameLast
FROM redsox r1, redsox r2, redsox r3, redsox r4
WHERE r1.yearId = r2.yearId + 1
	AND r2.yearId = r3.yearId + 1
    AND r3.yearId = r4.yearId + 1
    AND r1.nameLast = r2.nameLast
	AND r2.nameLast = r3.nameLast
    AND r3.nameLast = r4.nameLast
    AND r1.nameFirst = r2.nameFirst
	AND r2.nameFirst = r3.nameFirst
    AND r3.nameFirst = r4.nameFirst
ORDER BY r1.nameLast;

-- Query 8 - Home Run Kings
-- List the first name, last name, year, and number of HRs of every player
--  that has hit the most home runs in a single season. Order by the year. 
-- Note that the 'batting' table has a column 'HR' with the number of home 
-- runs hit by a player in that year.
-- 1.281 sec
CREATE OR REPLACE VIEW maxhr AS (
	SELECT yearID, MAX(batting.HR) homeRuns
    FROM master
		NATURAL JOIN batting
	GROUP BY yearID
);
SELECT b.yearId, m.nameFirst, m.nameLast, hr.homeRuns
FROM master m
	NATURAL JOIN batting b
	INNER JOIN maxhr hr ON hr.homeRuns = b.HR AND b.yearID = hr.yearID
ORDER BY b.yearId;


-- Query 9 - Third best home runs each year - List the first name, last name,
-- year, and number of HRs of every player that has hit the third most home 
-- runs in a single season. Order by the year.

-- Query 10 - Triple happy team mates
-- List the team name, year, players' names, the number of triples hit 
-- (column 'T' in the batting table), in which two or more players on the same 
-- team hit 10 or more triples each.

-- Query 11 - Ranking the teams
-- Rank each National League (NL) team in terms of the winning percentage (wins divided by losses) 
-- over its entire history. Consider a "team" to be a team with the same name, 
-- so if the team changes name, it is consider two different teams. 
-- Show the team name, win percentage, and the rank.
CREATE OR REPLACE VIEW nl AS (
	SELECT teams.name, SUM(teams.W) wins, SUM(teams.L) losses, SUM(teams.W)/(SUM(teams.W) + SUM(teams.L)) winRate
	FROM teams
	WHERE lgID = "NL"
    GROUP BY name
    ORDER BY winRate DESC
);
    
SELECT t0.winRate
FROM nl AS t0
	LEFT JOIN nl AS t1 
		ON t0.name=t1.name AND t1.winRate>t0.winRate
WHERE t1.name IS NULL;
    
SELECT a.*, count(*) as rank 
FROM nl a
	JOIN nl b 
    ON a.name = b.name AND a.winRate >= b.winRate
GROUP BY a.name, a.winRate;

-- Query 12 - Casey Stengel's Pitchers
-- List the year, first name, and last name of each pitcher who was a on a team
--  managed by Casey Stengel (pitched in the same season on a team managed by Casey).
-- .406 sec
CREATE OR REPLACE VIEW pitchers AS (
SELECT yearId, name AS teamName, nameFirst, nameLast
FROM master 
	NATURAL JOIN appearances
	NATURAL JOIN teams
WHERE G_p > 0
);
SELECT manager.teamName, manager.yearId, pitchers.nameFirst, pitchers.nameLast, manager.nameFirst, manager.nameLast
FROM pitchers INNER JOIN
    (SELECT yearId, nameFirst, nameLast, name AS teamName
		FROM master 
			NATURAL JOIN teams
			NATURAL JOIN managers
		WHERE nameFirst = "Casey"
			AND nameLast = "Stengel") manager
            ON pitchers.yearID = manager.yearId
				AND manager.teamName = pitchers.teamName;

-- Query 13 - Two degrees from Casey
-- List the name of each manager, who managed a pitcher that at one time was a 
-- teamate of a pitcher on a team managed by Casey Stengel.

-- Query 14 - Rickey's travels
-- List all of the teams for which Rickey Henderson did not play. Note that
-- because teams come and go, limit your answer to only the teams that were 
-- in existence while Rickey Henderson was a player. List each such team once.