use baseball;
-- Constraint 1
-- The default number of at bats is 20.
-- add the default constraint
ALTER TABLE batting
ALTER COLUMN AB SET DEFAULT 20;

-- insert a new batter with a default AB
INSERT INTO `batting` VALUES ('aardsda01',1900,1,'SFN','NL',11,11,DEFAULT,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,11);

-- like magic his AB is 20
SELECT * FROM
batting
WHERE masterID = 'aardsda01'
	AND yearID = 1900
    AND stint = 1
    AND teamID = 'SFN'
    AND lgID = 'NL';

-- Constraint 2
-- A player cannot have more H (hits) than AB (at bats).
-- add the check on hits and at bats
ALTER TABLE batting
ADD CONSTRAINT check_H_AB CHECK(H <= AB);

-- insert a new batter with 100 hits and 10 at bats
INSERT INTO `batting` VALUES ('aardsda01',1901,1,'SFN','NL',11,11,10,0,100,0,0,0,0,0,0,0,0,0,0,0,0,0,11);

-- Constraint 3
-- In the Teams table, the league can be only one of the values: NL or AL.
-- add the check on the lgID
ALTER TABLE teams
ADD CONSTRAINT check_league CHECK (lgID = 'NL' OR lgID = 'AL');

-- the first insert will fail, but the other two work just fine
INSERT INTO `teams` VALUES (1000,'NA','BS1','BNA',NULL,3,31,NULL,20,10,NULL,NULL,'N',NULL,401,1372,426,70,37,3,60,19,73,NULL,NULL,NULL,303,109,3.55,22,1,3,828,367,2,42,23,225,NULL,0.83,'Boston Red Stockings','South End Grounds I',NULL,103,98,'BOS','BS1','BS1');
INSERT INTO `teams` VALUES (1000,'NL','BS1','BNA',NULL,3,31,NULL,20,10,NULL,NULL,'N',NULL,401,1372,426,70,37,3,60,19,73,NULL,NULL,NULL,303,109,3.55,22,1,3,828,367,2,42,23,225,NULL,0.83,'Boston Red Stockings','South End Grounds I',NULL,103,98,'BOS','BS1','BS1');
INSERT INTO `teams` VALUES (1000,'AL','BS1','BNA',NULL,3,31,NULL,20,10,NULL,NULL,'N',NULL,401,1372,426,70,37,3,60,19,73,NULL,NULL,NULL,303,109,3.55,22,1,3,828,367,2,42,23,225,NULL,0.83,'Boston Red Stockings','South End Grounds I',NULL,103,98,'BOS','BS1','BS1');

-- Constraint 4
-- When a team loses more than 161 games in a season, the fans want to forget about the team forever, so all batting records for the team for that year should be deleted.
-- this proves that a team had batting data at first
SELECT *
FROM teams t,
	batting b,
    appearances a
WHERE t.yearID = b.yearID
	AND t.teamID = b.teamID
    AND t.lgID = b.lgID
    AND a.yearID = t.yearID
    AND a.masterID = b.masterID
    AND a.yearID = 1871
    AND t.name = 'Boston Red Stockings';

-- make an update trigger that deletes the batting data
DELIMITER $$
CREATE TRIGGER forgetTeamTrigger
AFTER UPDATE ON teams
FOR EACH ROW BEGIN 
	IF(NEW.L > 161) THEN
		DELETE FROM batting
        WHERE teamID = NEW.teamID
			AND yearID = NEW.yearID
            AND lgID = NEW.lgID;
	END IF;
END $$
DELIMITER ;

-- same as update, but for inserts
DELIMITER $$
CREATE TRIGGER forgetTeamInsertTrigger
AFTER INSERT ON teams
FOR EACH ROW BEGIN 
	IF(NEW.L > 161) THEN
		DELETE FROM batting
        WHERE teamID = NEW.teamID
			AND yearID = NEW.yearID
            AND lgID = NEW.lgID;
	END IF;
END $$
DELIMITER ;

-- update a team's losses to 162
UPDATE teams SET L = 162
WHERE yearID = 1871
	AND lgID = 'NA'
    AND teamID = 'BS1';

-- magically all their batting data is gone
SELECT *
FROM teams t,
	batting b,
    appearances a
WHERE t.yearID = b.yearID
	AND t.teamID = b.teamID
    AND t.lgID = b.lgID
    AND a.yearID = t.yearID
    AND a.masterID = b.masterID
    AND a.yearID = 1871
    AND t.name = 'Boston Red Stockings';
    
-- Constraint 5
-- If a player wins the MVP, WS MVP, and a Gold Glove in the same season, they are automatically inducted into the Hall of Fame.
-- this proves this player isn't already in the hall of fame
SELECT *
FROM halloffame
WHERE masterID = 'aardsda01'
	AND yearID = 1871;

-- create an insert trigger on awardsplayers
-- basically creates a comman separated string containing a list of all the player's awards during that season
-- if they have all three awards, add them to the hall of fame, inducted by yours truly
DELIMITER $$
DROP TRIGGER IF EXISTS hallOfFameTrigger$$
CREATE TRIGGER hallOfFameTrigger
AFTER INSERT ON awardsplayers
FOR EACH ROW BEGIN 
    
    IF(FIND_IN_SET('MVP', (SELECT GROUP_CONCAT(awardID) as awards FROM awardsplayers a WHERE a.masterID = NEW.masterID AND a.yearID = NEW.yearID))
		AND FIND_IN_SET('WS MVP', (SELECT GROUP_CONCAT(awardID) as awards FROM awardsplayers a WHERE a.masterID = NEW.masterID AND a.yearID = NEW.yearID))
        AND FIND_IN_SET('Gold Glove', (SELECT GROUP_CONCAT(awardID) as awards FROM awardsplayers a WHERE a.masterID = NEW.masterID AND a.yearID = NEW.yearID))) THEN
			INSERT INTO halloffame VALUES (NEW.masterID, NEW.yearID, 'Andrew Torgeson', 0,0,0,'Y','Awesome','No');
	END IF;
    
END $$
DELIMITER ;

-- do the same but for updates as well
DELIMITER $$
DROP TRIGGER IF EXISTS hallOfFameUpdateTrigger$$
CREATE TRIGGER hallOfFameUpdateTrigger
AFTER UPDATE ON awardsplayers
FOR EACH ROW BEGIN 
    
    IF(FIND_IN_SET('MVP', (SELECT GROUP_CONCAT(awardID) as awards FROM awardsplayers a WHERE a.masterID = NEW.masterID AND a.yearID = NEW.yearID))
		AND FIND_IN_SET('WS MVP', (SELECT GROUP_CONCAT(awardID) as awards FROM awardsplayers a WHERE a.masterID = NEW.masterID AND a.yearID = NEW.yearID))
        AND FIND_IN_SET('Gold Glove', (SELECT GROUP_CONCAT(awardID) as awards FROM awardsplayers a WHERE a.masterID = NEW.masterID AND a.yearID = NEW.yearID))) THEN
			INSERT INTO halloffame VALUES (NEW.masterID, NEW.yearID, 'Andrew Torgeson', 0,0,0,'Y','Awesome','No');
	END IF;
    
END $$
DELIMITER ;

-- give this lucky player all three awards
INSERT INTO awardsplayers VALUES ('aardsda01', 'MVP', 1871, 'NL', 'N','');
INSERT INTO awardsplayers VALUES ('aardsda01', 'WS MVP', 1871, 'NL', 'N','');
INSERT INTO awardsplayers VALUES ('aardsda01', 'Gold Glove', 1871, 'NL', 'N','');

-- magically he is now a hall of famer
SELECT *
FROM halloffame
WHERE masterID = 'aardsda01'
	AND yearID = 1871;
    
-- Constraint 6
-- All teams must have some name, i.e., it cannot be null.
-- modify the column to include the NOT NULL
ALTER TABLE teams
MODIFY name varchar(50) NOT NULL;

-- insert fails because of NUll name
INSERT INTO `teams` VALUES (1001,'AL','BS1','BNA',NULL,3,31,NULL,20,10,NULL,NULL,'N',NULL,401,1372,426,70,37,3,60,19,73,NULL,NULL,NULL,303,109,3.55,22,1,3,828,367,2,42,23,225,NULL,0.83,NULL,'South End Grounds I',NULL,103,98,'BOS','BS1','BS1');

-- Constraint 7
-- Everybody has a unique name (combined first and last names).
-- add unique constraint to the master tables first and last names
ALTER TABLE master
ADD UNIQUE unique_name(nameFirst, nameLast);

-- fails because DAvid Aardsma's name is already taken
INSERT INTO `master` VALUES ('aardsda17',1981,12,27,'USA','CO','Denver',NULL,NULL,NULL,NULL,NULL,NULL,'David','Aardsma','David Allan',205,75,'R','R','2004-04-06 00:00:00','2013-09-28 00:00:00','aardd001','aardsda01')