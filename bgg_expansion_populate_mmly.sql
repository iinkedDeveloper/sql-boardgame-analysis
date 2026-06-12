USE bgg_mmly; 

SET FOREIGN_KEY_CHECKS = 0;
SET SQL_SAFE_UPDATES = 0;

DROP TABLE IF EXISTS staging_bgg_expansion;

CREATE TABLE staging_bgg_expansion (
	title VARCHAR(300),
    bgg_id INT,
    min_playtime INT, 
    max_playtime INT, 
    digital_platforms VARCHAR(250),
    overall_rank INT, 
    rank_1_family VARCHAR(200),
    rank_1 INT, 
    rank_2_family VARCHAR(200),
    rank_2 INT
);

LOAD DATA LOCAL INFILE 'C:/Users/mmoll/Desktop/SQL Database Prog 26/BGG Expansion Data.csv'
INTO TABLE staging_bgg_expansion
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

UPDATE staging_bgg_expansion 
SET title = TRIM(title),
	digital_platforms = TRIM(digital_platforms),
    rank_1_family = TRIM(rank_1_family),
    rank_2_family = TRIM(rank_2_family);
    
UPDATE staging_bgg_expansion  
SET digital_platforms = NULL
WHERE digital_platforms = '';

UPDATE staging_bgg_expansion
SET rank_1_family = NULL
WHERE rank_1_family = '';

UPDATE staging_bgg_expansion
SET rank_2_family = NULL
WHERE rank_2_family = '';


DELETE FROM game_platform;
DELETE FROM game_ranking;
DELETE FROM digital_platform;
DELETE FROM ranking_family;
    
INSERT INTO ranking_family (family_name)
VALUES ('Overall');

INSERT INTO ranking_family (family_name)
SELECT DISTINCT rank_1_family 
FROM staging_bgg_expansion
WHERE rank_1_family IS NOT NULL;

INSERT INTO ranking_family (family_name)
SELECT DISTINCT rank_2_family
FROM staging_bgg_expansion AS s
LEFT OUTER JOIN ranking_family AS rf
	ON rf.family_name = s.rank_2_family
WHERE s.rank_2_family IS NOT NULL
AND rf.family_name IS NULL;

INSERT INTO digital_platform (platform_name)
SELECT DISTINCT TRIM(SUBSTRING_INDEX(s.digital_platforms, ',', 1))
FROM staging_bgg_expansion AS s
LEFT OUTER JOIN digital_platform AS dp 
	ON dp.platform_name = TRIM(SUBSTRING_INDEX(s.digital_platforms, ',', 1))
WHERE s.digital_platforms IS NOT NULL
	AND dp.platform_name IS NULL; 

INSERT INTO digital_platform (platform_name)
SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(s.digital_platforms, ',', 2), ',', -1))
FROM staging_bgg_expansion AS s
LEFT OUTER JOIN digital_platform AS dp
	ON dp.platform_name = TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(s.digital_platforms, ',', 2), ',', -1))
WHERE s.digital_platforms LIKE '%,%,%'
	AND dp.platform_name IS NULL; 

INSERT INTO digital_platform (platform_name)
SELECT DISTINCT TRIM(SUBSTRING_INDEX(s.digital_platforms, ',', -1))
FROM staging_bgg_expansion AS s
LEFT OUTER JOIN digital_platform AS dp 
	ON dp.platform_name = TRIM(SUBSTRING_INDEX(s.digital_platforms, ',', -1))
WHERE s.digital_platforms IS NOT NULL
AND s.digital_platforms LIKE '%,%' 
AND dp.platform_name IS NULL;

INSERT INTO game_ranking (game_id, ranking_family_id, rank_value)
SELECT g.game_id, 
	rf.ranking_family_id,
    s.overall_rank
FROM staging_bgg_expansion AS s
INNER JOIN game AS g
	ON g.bgg_source_id = s.bgg_id
INNER JOIN ranking_family AS rf	
	ON rf.family_name = 'Overall'
WHERE s.overall_rank IS NOT NULL; 

INSERT INTO game_ranking (game_id, ranking_family_id, rank_value)
SELECT g.game_id,
	rf.ranking_family_id, 
    s.rank_1
FROM staging_bgg_expansion AS s
INNER JOIN game AS g
	ON g.bgg_source_id = s.bgg_id
INNER JOIN ranking_family AS rf
	ON rf.family_name = s.rank_1_family
WHERE s.rank_1_family IS NOT NULL
	AND s.rank_1 IS NOT NULL;
    
INSERT INTO game_ranking (game_id, ranking_family_id, rank_value)
SELECT g.game_id,
	rf.ranking_family_id,
    s.rank_2
FROM staging_bgg_expansion AS s 
INNER JOIN game AS g
	ON g.bgg_source_id = s.bgg_id 
INNER JOIN ranking_family AS rf
	ON rf.family_name = s.rank_2_family
WHERE s.rank_2_family IS NOT NULL
	AND s.rank_2 IS NOT NULL;


INSERT INTO game_platform (game_id, platform_id)
SELECT DISTINCT g.game_id,
	dp.platform_id
FROM staging_bgg_expansion AS s
INNER JOIN game AS g
	ON g.bgg_source_id = s.bgg_id
INNER JOIN digital_platform AS dp 
	ON dp.platform_name = TRIM(SUBSTRING_INDEX(s.digital_platforms, ',', 1))
LEFT OUTER JOIN game_platform AS gp
	ON gp.game_id = g.game_id
    AND gp.platform_id = dp.platform_id
WHERE s.digital_platforms IS NOT NULL
	AND gp.game_id IS NULL; 

INSERT INTO game_platform (game_id, platform_id)
SELECT DISTINCT g.game_id,
		dp.platform_id
FROM staging_bgg_expansion AS s 
INNER JOIN game AS g
	ON g.bgg_source_id = s.bgg_id
INNER JOIN digital_platform AS dp 
	ON dp.platform_name = TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(s.digital_platforms, ',', 2), ',', -1))
LEFT OUTER JOIN game_platform AS gp
	ON gp.game_id = g.game_id
    AND gp.platform_id = dp.platform_id
WHERE s.digital_platforms LIKE '%,%,%'
	AND gp.platform_id IS NULL; 


    
INSERT INTO game_platform (game_id, platform_id)
SELECT DISTINCT g.game_id,
	dp.platform_id
FROM staging_bgg_expansion AS s
INNER JOIN game AS g 
	ON g.bgg_source_id = s.bgg_id
INNER JOIN digital_platform AS dp
	ON dp.platform_name = TRIM(SUBSTRING_INDEX(s.digital_platforms, ',', -1))
LEFT OUTER JOIN game_platform AS gp
	ON gp.game_id = g.game_id
    AND gp.platform_id = dp.platform_id
WHERE s.digital_platforms IS NOT NULL
	AND s.digital_platforms LIKE '%,%'
    	AND gp.platform_id IS NULL; 

UPDATE game AS g 
INNER JOIN staging_bgg_expansion AS s
	ON g.bgg_source_id = s.bgg_id
SET g.min_playtime = s.min_playtime,
	g.max_playtime = s.max_playtime;

SELECT COUNT(*) AS staging_count
FROM staging_bgg_expansion;

SELECT COUNT(*) AS ranking_family_count
FROM ranking_family;

SELECT COUNT(*) AS digital_platform_count
FROM digital_platform;

SELECT COUNT(*) AS game_ranking_count
FROM game_ranking;

SELECT COUNT(*) AS game_platform_count
FROM game_platform;

SELECT COUNT(*) AS games_with_playtimes
FROM game
WHERE min_playtime IS NOT NULL
	AND max_playtime IS NOT NULL;
    

SELECT g.title, rf.family_name, gr.rank_value
FROM game_ranking AS gr
INNER JOIN game AS g
	ON gr.game_id = g.game_id
INNER JOIN ranking_family AS rf 
	ON gr.ranking_family_id = rf.ranking_family_id
ORDER BY g.title;

SELECT g.title, dp.platform_name
FROM game_platform AS gp
INNER JOIN game AS g
	ON gp.game_id = g.game_id
INNER JOIN digital_platform AS dp
	ON gp.platform_id = dp.platform_id
ORDER BY g.title;

SELECT COUNT(*) AS staging_overall 
FROM staging_bgg_expansion
WHERE overall_rank IS NOT NULL;

SELECT COUNT(*) AS inserted_overall
FROM game_ranking AS gr
INNER JOIN ranking_family AS rf
	ON gr.ranking_family_id = rf.ranking_family_id
WHERE rf.family_name = 'Overall';

SELECT platform_name
FROM digital_platform
GROUP BY platform_name
HAVING COUNT(*) > 1;

SELECT title, min_playtime, max_playtime
FROM game
WHERE max_playtime > 1000 OR min_playtime < 0;

SET FOREIGN_KEY_CHECKS = 1;
