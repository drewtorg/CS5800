-- Andrew Torgeson
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
-- 38.368 sec

-- this view represents all players, their teams, and the year they played
CREATE OR REPLACE VIEW allPlayers AS (
	SELECT masterId, nameFirst, nameLast, teamID, yearId, name
	FROM master
		NATURAL JOIN appearances
        NATURAL JOIN teams
);

-- this view represents all players that played for the Brooklyn Dodgers and another team
CREATE OR REPLACE VIEW otherTeamsB AS (
	SELECT DISTINCT X.nameFirst, X.nameLast
    FROM allPlayers X INNER JOIN allPlayers Y ON X.masterID = Y.masterID
	WHERE X.name = "Brooklyn Dodgers" AND Y.name <> "Brooklyn Dodgers"
);

-- this view represents all players that played for the Brooklyn Dodgers
CREATE OR REPLACE VIEW BDodgers AS (
	SELECT DISTINCT nameFirst, nameLast
    FROM master
		NATURAL JOIN appearances
		NATURAL JOIN teams
	WHERE teams.name = "Brooklyn Dodgers"
);

-- Get people who have only played on Brooklyn Dodgers by taking away players
-- that have played on Brooklyn Dodgers and another team away from all the
-- players of the Brooklyn Dodgers
CREATE OR REPLACE VIEW onlyBDodgers AS (
	SELECT DISTINCT nameFirst, nameLast
    FROM BDodgers
    WHERE NOT EXISTS (SELECT nameFirst, nameLast
					  FROM otherTeamsB
                      WHERE BDodgers.nameFirst = otherTeamsB.nameFirst
						AND BDodgers.nameLast = otherTeamsB.nameLast)
);

-- thisis the same strategy as before, only with the LA Dodgers
CREATE OR REPLACE VIEW otherTeamsLA AS (
	SELECT DISTINCT X.nameFirst, X.nameLast
    FROM allPlayers X INNER JOIN allPlayers Y ON X.masterID = Y.masterID
	WHERE X.name = "Los Angeles Dodgers" AND Y.name <> "Los Angeles Dodgers"
);
CREATE OR REPLACE VIEW LADodgers AS (
	SELECT DISTINCT nameFirst, nameLast
    FROM master
		NATURAL JOIN appearances
		NATURAL JOIN teams
	WHERE teams.name = "Los Angeles Dodgers"
);
CREATE OR REPLACE VIEW onlyLADodgers AS (
	SELECT DISTINCT nameFirst, nameLast
    FROM LADodgers
    WHERE NOT EXISTS (SELECT nameFirst, nameLast
					  FROM otherTeamsLA
                      WHERE LADodgers.nameFirst = otherTeamsLA.nameFirst
						AND LADodgers.nameLast = otherTeamsLA.nameLast)
);

-- simply union the players who only have been on the Brooklyn Dodgers
-- with the players who only have been on the LA Dodgers
SELECT nameFirst, nameLast
FROM ((SELECT nameFirst, nameLast FROM onlyBDodgers)
	UNION (SELECT nameFirst, nameLast FROM onlyLADodgers)) unionList
ORDER BY nameLast;

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
-- .289 sec

-- this view represents all salaries for each team for every year
CREATE OR REPLACE VIEW teamsalaries AS (
	SELECT name, yearID, SUM(salaries.salary) salary FROM master
		NATURAL JOIN salaries
		NATURAL JOIN teams
	GROUP BY teams.name, teams.yearID
);

-- the general strategy here is to cross product the salaries list and then
-- check to see if the second salary is 150% or more than the other salary
SELECT X.name, X.yearID prevYear, X.salary prevSalary,
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

-- this view represents all the players that have batted for the red sox
CREATE OR REPLACE VIEW redsox AS (
	SELECT nameFirst, nameLast, AB, yearId
    FROM master
		NATURAL JOIN appearances
        NATURAL JOIN teams
	WHERE AB > 0 AND teams.name = "Boston Red Sox"
);

-- simply cross the redsox view 4 times and grab the rows that match
-- the same name and then that the years are consecutive
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

--this view represents the max homeruns in a year
CREATE OR REPLACE VIEW maxhr AS (
	SELECT yearID, MAX(batting.HR) homeRuns
    FROM master
		NATURAL JOIN batting
	GROUP BY yearID
);

-- just check all players to see if their home runs matches the max of the year
SELECT b.yearId, m.nameFirst, m.nameLast, hr.homeRuns
FROM master m
	NATURAL JOIN batting b
	INNER JOIN maxhr hr ON hr.homeRuns = b.HR AND b.yearID = hr.yearID
ORDER BY b.yearId;


-- Query 9 - Third best home runs each year - List the first name, last name,
-- year, and number of HRs of every player that has hit the third most home
-- runs in a single season. Order by the year.
-- ??? sec, times out but im sure it's right, but terribly inefficient

-- the sub-query counts the number of batters that are greater than the current
-- batter, this is then checked to see if it is two.  Two greater than you means
-- the current plaer is in 3rd place or tied for 3rd
SELECT nameFirst, nameLast, yearId, HR
FROM master
	NATURAL JOIN batting batters
WHERE ( 2 ) = (
	SELECT COUNT( batters2.HR)
	FROM batting batters2
	WHERE batters.yearID = batters2.yearID AND batters2.HR > batters.HR
)
ORDER BY yearId;

-- Query 10 - Triple happy team mates
-- List the team name, year, players' names, the number of triples hit
-- (column 'T' in the batting table), in which two or more players on the same
-- team hit 10 or more triples each.
-- 410.297 sec

-- These are the players that had 10 or more triples
CREATE OR REPLACE VIEW triples AS (
	SELECT nameFirst, nameLast, batting.3B as triples, teams.yearId, teams.name
	FROM master
		NATURAL JOIN batting
        INNER JOIN teams on teams.teamID = batting.teamID AND teams.yearID = batting.yearID
	WHERE batting.3B >= 10
    ORDER BY teams.name, yearID
);

-- Join triples with itself on the team name with different player names
-- and the same year, these will be teammates that have 10 or more triples
SELECT X.yearId, X.name AS teamName, X.nameFirst AS firstName, X.nameLast AS lastName, X.triples, Y.nameFirst AS teammateFirstName, Y.nameLast AS teammateLastName, Y.triples AS teammateTriples
FROM triples X
	INNER JOIN triples Y ON X.name = Y.name AND X.yearId = Y.yearID
WHERE X.nameFirst <> Y.nameFirst AND X.nameLast <> Y.nameLast
ORDER BY X.yearId;

-- Query 11 - Ranking the teams
-- Rank each team in terms of the winning percentage (wins divided by losses)
-- over its entire history. Consider a "team" to be a team with the same name,
-- so if the team changes name, it is consider two different teams.
-- Show the team name, win percentage, and the rank.
-- .032 sec

-- this view is a sum of the wins, losses, and winRate of every team over its history
CREATE OR REPLACE VIEW stats AS (
	SELECT teams.name, SUM(teams.W) wins, SUM(teams.L) losses, SUM(teams.W)/(SUM(teams.W) + SUM(teams.L)) winRate
	FROM teams
	GROUP BY name
);

-- cross stats with itself and count the number of teams that are greater than you
-- that is your rank
SELECT X.name, X.wins, X.losses, X.winRate, COUNT(*) AS rank
FROM stats X, stats Y
WHERE X.winRate <= Y.winRate
GROUP BY X.name, X.wins, X.losses, X.winRate
ORDER BY rank;

-- Query 12 - Casey Stengel's Pitchers
-- List the year, first name, and last name of each pitcher who was a on a team
--  managed by Casey Stengel (pitched in the same season on a team managed by Casey).
-- .406 sec

-- these are all the pitchers
CREATE OR REPLACE VIEW pitchers AS (
SELECT yearId, name AS teamName, nameFirst, nameLast
FROM master
	NATURAL JOIN appearances
	NATURAL JOIN teams
WHERE G_p > 0
);

-- this view is all the teams Casey Stengel has managed
CREATE OR REPLACE VIEW stengel AS (
SELECT yearId, nameFirst, nameLast, name AS teamName
FROM master
	NATURAL JOIN teams
	NATURAL JOIN managers
WHERE nameFirst = "Casey"
	AND nameLast = "Stengel"
);

-- join every pitcher on the teams and years that Casey Stengel was over them
SELECT manager.teamName, manager.yearId, pitchers.nameFirst, pitchers.nameLast, manager.nameFirst AS managerNameFirst, manager.nameLast AS managerNameFirst
FROM pitchers INNER JOIN stengel AS manager ON pitchers.yearID = manager.yearId AND manager.teamName = pitchers.teamName;

-- Query 13 - Two degrees from Yogi Berra
-- List the name of each player who appeared on a team with a player that
-- was at one time was a teamate of Yogi Berra. So suppose player A was a
-- teamate of Yogi Berra. Then player A is one-degree of separation from
-- Yogi Berra. Let player B be related to player A because A played on a
-- team in the same year with player A. Then player B is two-degrees of
-- separation from Yogi Berra.

-- get every team Yogi Berra was on
CREATE OR REPLACE VIEW yogiTeams AS (
	SELECT yearID, teamID, masterId
    FROM master
		NATURAL JOIN appearances
	WHERE nameFirst = "Yogi" AND nameLast = "Berra"
);

-- get all the players that were on Yogi Berra's teams
CREATE OR REPLACE VIEW yogiTeamMembers AS (
	SELECT allPlayers.masterId
    FROM yogiTeams
		INNER JOIN allPlayers ON allPlayers.teamID = yogiTeams.teamID
							  AND allPlayers.yearId = yogiTeams.yearID
	WHERE allPlayers.masterId <> yogiTeams.masterID
);

-- get all the teams played on by Yogi's teammates
CREATE OR REPLACE VIEW yogiTMTeams AS (
	SELECT DISTINCT yearID, teamID, master.masterId
    FROM master
		NATURAL JOIN appearances
        INNER JOIN yogiTeamMembers ON master.masterID = yogiTeamMembers.masterID
);

-- select all the players that were on the teams played on by Yogi's teammates
SELECT DISTINCT allPlayers.nameFirst, allPlayers.nameLast
FROM yogiTMTeams
	INNER JOIN allPlayers ON allPlayers.teamID = yogiTMTeams.teamID
						  AND allPlayers.yearId = yogiTMTeams.yearID
WHERE allPlayers.masterId <> yogiTMTeams.masterID
ORDER BY allPlayers.nameLast;

-- Query 14 - Rickey's travels
-- List all of the teams for which Rickey Henderson did not play. Note that
-- because teams come and go, limit your answer to only the teams that were
-- in existence while Rickey Henderson was a player. List each such team once.
-- .968 sec

-- get the years that Ricket played baseball
CREATE OR REPLACE VIEW rickeyYears AS (
	SELECT yearID
    FROM master NATURAL JOIN appearances
	WHERE nameFirst = "Rickey" AND nameLast = "Henderson"
);

-- get all the teams Rickey played on
CREATE OR REPLACE VIEW rickeyTeams AS (
	SELECT DISTINCT name
    FROM master NATURAL JOIN appearances NATURAL JOIN teams
	WHERE nameFirst = "Rickey" AND nameLast = "Henderson"
);

-- get all the teams that existed while Rickey was playing
CREATE OR REPLACE VIEW teamsDuringRickeyYears AS (
	SELECT DISTINCT name
    FROM teams
		NATURAL JOIN appearances
    WHERE teams.yearID IN (SELECT yearID FROM rickeyYears)
);

-- get all the teams that were around while Rickey played and subtract the teams
-- that he played on
SELECT name
FROM teamsDuringRickeyYears teams
WHERE NOT EXISTS ( 	SELECT name
					FROM rickeyTeams
                    WHERE teams.name = rickeyTeams.name
)
ORDER BY name;
