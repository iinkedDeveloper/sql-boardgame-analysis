/*Request #1
Provide a list of all games that meet each of the following criteria:
• The title contains the word “castle”.
• The game has no parent game (i.e. it is not a spin-off of another game)
List games with the highest number of owners first.
Below is a sample of the output for a different set of board games. Your column headers and data
formats must be identical to the example below.
• Display the number of game owners in thousands
• Play time should be converted from minutes as in the example
• “Quality” is determined using the average rating of each game.
o “Excellent” games have a rating of 8.0 or higher.
o Games with ratings of at 7.2 that are not “Excellent” are “Very Good”
o “Good” games have ratings of at least 6.7
o “OK” games are rated 6.0 and above but not considered “Good”
o Games with average ratings below 6.0 are “Poor”
Game Title Play Time Quality First Reviewed # Owners (thousands)
CATAN 2hr 0min Good September 1, 2000 226.3
Pandemic 0hr 45min Very Good February 26, 2009 217.1
SQL Database Programming */

use bgg;
SELECT g.title AS 'Game title', 
	CONCAT(g.play_time DIV 60, 'hr', ' ', MOD(g.play_time, 60), 'min') AS `Play Time`, 
CASE 
	WHEN g.avg_rating >= 8.0 THEN 'Excellent'
	WHEN g.avg_rating >= 7.2 THEN 'Very Good'
    WHEN g.avg_rating >= 6.7 THEN 'Good'
    WHEN g.avg_rating >= 6.0 THEN 'OK'
    ELSE 'Poor'
END AS `Quality`, 
DATE_FORMAT(g.first_reviewed, '%M %e, %Y') AS `First Reviewed`, 
ROUND(g.owners / 1000, 1) AS `# Owners (thousands)`
FROM game AS g 
WHERE g.title LIKE '%castle%'
	AND g.parent_game_id IS NULL
ORDER BY g.owners DESC;

/* Request #2
Pull the title and the publish year of all individual games which have a category that begins with
“war”, and which includes at least one of the following mechanic types.
• Area Majority / Influence
• Force Commitment
• Secret Unit Deployment
Order the games with the most recently published games first, in alphabetical order by year. */

SELECT DISTINCT g.title AS `Game Title`, 
	g.year_published AS `Publish Year`
FROM game AS g
INNER JOIN game_category AS gc
	ON gc.game_id = g.game_id
INNER JOIN category AS c
	ON c.category_id = gc.category_id
INNER JOIN game_mechanic AS gm
	ON gm.game_id = g.game_id
INNER JOIN mechanic AS m
	ON m.mechanic_id = gm.mechanic_id
WHERE g.parent_game_id IS NULL
	AND c.category_name LIKE 'war%'
    AND m.mechanic_type IN ('Area Majority / Influence',
    'Force Commitment', 'Secret Unit Deployment')
ORDER BY g.year_published DESC, g.title ASC;

/* Request #3
Identify all games that have a minimum age of at least 14 years old and an average rating above 8.2.
Provide the title, the average rating (to two decimal places) and the minimum age.
Also include in your output the source of crowdfunding for each game, if it exists. If one does not
exist, display “Self-funded”.
List results by the funding source, then alphabetically. */

SELECT g.title AS `Game Title`, 
	ROUND(g.avg_rating, 2) AS `Average Rating`,
g.min_age AS `Minimum Age`,
COALESCE(cf.funding_source, 'Self-funded') AS `Funding Source`
FROM game AS g
LEFT OUTER JOIN crowdfund AS cf
	ON cf.crowdfund_id = g.crowdfund_id
WHERE g.min_age >= 14
	AND g.avg_rating > 8.2
ORDER BY 
COALESCE(cf.funding_source, 'Self-funded') ASC, 
g.title ASC; 

/* Request #4
Show all fields from the game table for each game whose parent game is CATAN. List games in order
by the date they were first reviewed, oldest first.
Bonus: Include the parent game (CATAN) in the result set, maintaining the order by review date. */ 

SELECT g.*
FROM game AS parent 
LEFT OUTER JOIN game AS g 
	ON g.parent_game_id = parent.game_id
WHERE parent.title = 'CATAN'
ORDER BY g.first_reviewed; 


/* Request #5
Which crowdfunding sources did not provide funding for a game published in the decade of the
2010s? Write a query to list those funding sources, if there are any. */

SELECT cf.funding_source AS `Crowdfunding Source`
FROM crowdfund AS cf 
LEFT OUTER JOIN game AS g 
	ON cf.crowdfund_id = g.crowdfund_id
		AND g.year_published BETWEEN 2010 AND 2019
WHERE g.game_id IS NULL 
ORDER BY cf.funding_source;


/* Request #6
Show all of the game categories that contain no games fitting the following criteria.
• Minimum recommended age of 8 or under
• Uses a Dice Rolling mechanic
SQL Database Programming */

SELECT category_name 
FROM category
EXCEPT ALL
SELECT DISTINCT c.category_name
FROM category AS c 
INNER JOIN 	game_category AS gc 
	ON gc.category_id = c.category_id
INNER JOIN game AS g  
	ON g.game_id = gc.game_id
INNER JOIN game_mechanic AS gm
	ON gm.game_id = g.game_id
INNER JOIN mechanic AS m 
	ON m.mechanic_id = gm.mechanic_id
WHERE g.min_age <= 8
	AND m.mechanic_type = 'Dice Rolling'
ORDER BY category_name;

/* Request #7
Create a report containing all games that are:
• in either the “Movies / TV / Radio theme” or the “Comic Book / Strip” category
and, also
• in either the “Party Game” or “Humor” category
Bingo is (surprisingly) one example of such a game, categorized as both a Movies / TV / Radio theme
game and a Party game. Checkers, on the other hand, does not meet the criteria.
Your report format (labels and number formats) should match the example below.
Game Average Rating # Users Rated
Bingo 3.04974 2,866 */

SELECT DISTINCT g.title AS `Game`,
	g.avg_rating AS `Average Rating`,
	FORMAT(g.users_rated, 0) AS `# Users Rated`
FROM game AS g,
	game_category AS gc1,
    category AS c1,
    game_category AS gc2,
    category AS c2
WHERE g.game_id = gc1.game_id
	AND gc1.category_id = c1.category_id
    AND g.game_id = gc2.game_id
    AND gc2.category_id = c2.category_id
    AND c1.category_name IN ('Movies / TV / Radio Theme', 'Comic Book / Strip')
    AND c2.category_name IN ('Party Game', 'Humor')
ORDER BY g.title;

/* Request #8
List all games that are classified as “Ownership”, and which have at least 20000 owners. Display
games by number of owners in decreasing order.
For each game, show the title, the year published, and the number of owners. Also include a field
that displays “Yes” if the game was funded by a Kickstarter campaign and “No” otherwise. */

SELECT DISTINCT g.title AS `Game Title`,
    g.year_published AS `Year Published`,
    g.owners AS `Owners`,
	CASE 
		WHEN cf.funding_source = 'Kickstarter' THEN 'Yes'
		ELSE 'No'
    END AS `Kickstarter Funded`
FROM game AS g
INNER JOIN game_mechanic AS gm
	ON gm.game_id = g.game_id
INNER JOIN mechanic AS m
	ON m.mechanic_id = gm.mechanic_id
LEFT OUTER JOIN crowdfund AS cf
	ON cf.crowdfund_id = g.crowdfund_id
WHERE m.mechanic_type = 'Ownership'
	AND g.owners >= 20000
ORDER BY g.owners DESC;


/* Request #9
Choose one of the following questions. Write a query that helps answer the question. Include a
comment in your script with both the question and your answer.
Question 1
Are there any games in which the year the game was published appears in the title of the game?
Question 2
Are there any games where both the number of owners and the number of users who rated the
game are evenly divisible by 25?
Question 3
What are the categories, if any, that are also mechanic types? */ 

-- I choose Question 3 . ANSWER: the query is below, it shows both the category table and the mechanic_type table overlapping to look for the same category names as mechanic type names.
SELECT c.category_name AS `Category`,
    m.mechanic_type AS `Mechanic`
FROM category AS c
INNER JOIN mechanic AS m
	ON c.category_name = m.mechanic_type
ORDER BY c.category_name;

