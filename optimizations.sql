use baseball;
-- QUERY 1 --

CREATE INDEX pitchingWinsIndex ON pitching(w);
DROP INDEX pitchingWinsIndex on pitching;

EXPLAIN SELECT 
	DISTINCT m.nameFirst, m.nameLast
FROM
    master m,
    pitching a,
    teams t
WHERE
    m.masterId = a.masterId
        AND t.teamId = a.teamId
        AND t.lgID = a.lgID
        AND t.name like '%Montreal Expos%'
        AND t.yearID = a.yearId
        AND a.w > 20;



        
-- QUERY 2 --

EXPLAIN SELECT 
    h / ab AS Average,
    h AS 'Hits',
    ab AS 'At Bats',
    nameFirst AS 'First Name',
    nameLast AS 'Last Name',
    batting.yearID AS Year
FROM
    batting,
    schools,
    schoolsplayers,
    master
WHERE
    ab IS NOT NULL
        AND batting.masterID = master.masterID
        AND batting.masterID = schoolsplayers.masterID
        AND schools.schoolName LIKE '%Utah State%'
        AND schools.schoolId = schoolsplayers.schoolID
ORDER BY year;



-- QUERY 3 --

CREATE INDEX appearanceLeagueIndex ON appearances(lgId);
DROP INDEX appearanceLeagueIndex ON appearances;

EXPLAIN SELECT DISTINCT
    jeter.masterID,
    jeterT.masterID,
    jeterTY.masterID,
    jeterTT.masterID
FROM
    master m,
    appearances jeter,
    appearances jeterT,
    appearances jeterTY,
    appearances jeterTT
WHERE
    m.masterID = jeter.masterID
        AND m.nameLast = 'Jeter'
        AND m.nameFirst = 'Derek'
        AND jeter.teamID = jeterT.teamID
        AND jeter.yearID = jeterT.yearID
        AND jeter.lgID = jeterT.lgID
        AND jeter.masterID <> jeterT.masterID
        AND jeterT.masterID = jeterTY.masterID
        AND jeterTY.teamID = jeterTT.teamID
        AND jeterTY.yearID = jeterTT.yearID
        AND jeterTY.lgID = jeterTT.lgID
        AND jeterTY.masterID <> jeterTT.masterID
        AND jeterTT.masterID <> jeter.masterID
        AND jeter.teamID <> jeterTY.teamID;



-- QUERY 4 --

CREATE INDEX teamYearWinsIndex ON teams(yearID, W);
DROP INDEX teamYearWinsIndex on teams;
        
EXPLAIN SELECT
    T.name, T.yearId, T.W
FROM
    teams T INNER JOIN 
    (SELECT 
            z.yearID, MAX(W) as W
        FROM
            teams z
        GROUP BY z.yearID) y ON T.yearID = y.yearID AND T.W = y.W;
	


-- QUERY 5 --

CREATE INDEX battingMultiIndex ON batting(teamID, yearID, lgID);
CREATE INDEX battingABIndex ON batting(ab);

DROP INDEX battingMultiIndex on batting;
DROP INDEX battingABIndex on batting;

EXPLAIN SELECT 
    C.yearID AS year,
    name AS teamName,
    C.lgID AS league,
    D.cnt AS totalBatters,
    C.cnt AS aboveAverageBatters
FROM
    (SELECT 
        COUNT(masterID) AS cnt, A.yearID, A.teamID, A.lgID
    FROM
        (SELECT 
        masterID,
            teamID,
            yearID,
            lgID,
            SUM(AB),
            SUM(H),
            SUM(H) / SUM(AB) AS avg
    FROM
        batting
    GROUP BY teamID , yearID , lgID , masterID) B, (SELECT 
        teamID,
            yearID,
            lgID,
            SUM(AB),
            SUM(H),
            SUM(H) / SUM(AB) AS avg
    FROM
        batting
    WHERE
        ab IS NOT NULL
    GROUP BY teamID , yearID , lgID) A
    WHERE
        A.avg >= B.avg AND A.teamID = B.teamID
            AND A.yearID = B.yearID
            AND A.lgID = B.lgID
    GROUP BY teamID , yearID , lgID) C,
    (SELECT 
        COUNT(masterID) AS cnt, yearID, teamID, lgID
    FROM
        batting
    WHERE
        ab IS NOT NULL
    GROUP BY yearID , teamID , lgID) D,
    teams
WHERE
    C.cnt / D.cnt >= 0.75
        AND C.yearID = D.yearID
        AND C.teamID = D.teamID
        AND C.lgID = D.lgID
        AND teams.yearID = C.yearID
        AND teams.lgID = C.lgID
        AND teams.teamID = C.teamID;
       


-- QUERY 6 --

CREATE INDEX battingMultiIndex ON batting(teamID, yearID, lgID);
DROP INDEX battingMultiIndex on batting;

EXPLAIN SELECT DISTINCT
    master.nameFirst AS 'First Name',
    master.nameLast AS 'Last Name'
FROM
    (SELECT 
        b.masterID AS ID, b.yearID AS year
    FROM
        batting b, teams t
    WHERE
        name LIKE '%New York Yankees%'
            AND b.teamID = t.teamID
            AND b.yearID = t.yearID
            AND t.lgID = b.lgID) y1,
    (SELECT 
        b.masterID AS ID, b.yearID AS year
    FROM
        batting b, teams t
    WHERE
        name LIKE '%New York Yankees%'
            AND b.teamID = t.teamID
            AND b.yearID = t.yearID
            AND t.lgID = b.lgID) y2,
    (SELECT 
        b.masterID AS ID, b.yearID AS year
    FROM
        batting b, teams t
    WHERE
        name LIKE '%New York Yankees%'
            AND b.teamID = t.teamID
            AND b.yearID = t.yearID
            AND t.lgID = b.lgID) y3,
    (SELECT 
        b.masterID AS ID, b.yearID AS year
    FROM
        batting b, teams t
    WHERE
        name LIKE '%New York Yankees%'
            AND b.teamID = t.teamID
            AND b.yearID = t.yearID
            AND t.lgID = b.lgID) y4,
    master
WHERE
    y1.id = y2.id AND y2.id = y3.id
        AND y3.id = y4.id
        AND y1.year + 1 = y2.year
        AND y2.year + 1 = y3.year
        AND y3.year + 1 = y4.year
        AND y4.id = master.masterID
ORDER BY master.nameLast , master.nameFirst;



-- QUERY 7 --

EXPLAIN SELECT 
    name,
    A.lgID,
    A.S AS TotalSalary,
    A.yearID AS Year,
    B.S AS PreviousYearSalary,
    B.yearID AS PreviousYear
FROM
    (SELECT 
        SUM(salary) AS S, yearID, teamID, lgID
    FROM
        salaries
    GROUP BY yearID , teamID , lgID) A,
    (SELECT 
        SUM(salary) AS S, yearID, teamID, lgID
    FROM
        salaries
    GROUP BY yearID , teamID , lgID) B,
    teams
WHERE
    A.yearID = B.yearID + 1
        AND (A.S * 2) <= (B.S)
        AND A.teamID = B.teamID
        AND A.lgID = B.lgID
        AND teams.yearID = A.yearID
        AND teams.lgID = A.lgID
        AND teams.teamID = A.teamID;
        
EXPLAIN SELECT 
    name,
    A.lgID,
    A.S AS TotalSalary,
    A.yearID AS Year,
    B.yearID AS PreviousYear,
    B.S AS PreviousSalary
FROM
    (SELECT 
        SUM(salary) AS S, s.yearID, s.teamID, s.lgID
    FROM
        salaries s
    GROUP BY s.yearID , s.teamID , s.lgID
    HAVING S*2 <= (	SELECT SUM(salary)
						FROM salaries z
                        WHERE s.yearID = z.yearID + 1 AND s.teamID = z.teamID AND s.lgID = z.lgID
                        GROUP BY z.yearID, z.teamID, z.lgID )
	) A,
    (SELECT 
        SUM(salary) AS S, yearID, teamID, lgID
    FROM
        salaries
    GROUP BY yearID , teamID , lgID) B,
    teams
WHERE
     teams.yearID = A.yearID
        AND teams.lgID = A.lgID
        AND teams.teamID = A.teamID
        AND B.yearID = A.yearID - 1
        AND B.teamID = A.teamID
        AND B.lgID = A.lgID;