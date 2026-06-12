use bgg_mmly; 

DROP TABLE IF EXISTS game_ranking;
DROP TABLE IF EXISTS ranking_family;
DROP TABLE IF EXISTS game_platform;	
DROP TABLE IF EXISTS digital_platform;
DROP TABLE IF EXISTS game_review;
DROP TABLE IF EXISTS user_account;
    
ALTER TABLE game DROP COLUMN play_time; 
    
ALTER TABLE game 
	ADD min_playtime INT NOT NULL,
	ADD max_playtime INT NOT NULL; 
	
CREATE TABLE user_account (
	user_id INT AUTO_INCREMENT PRIMARY KEY, 
	username varchar(100) NOT NULL, 
	email VARCHAR (150) NOT NULL, 
	password_hash varchar(255) NOT NULL, 
	profile_picture LONGBLOB NULL, 
	city VARCHAR(150),
	state VARCHAR (150),
	country VARCHAR(150),	
	date_created DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
ALTER TABLE user_account 
	ADD CONSTRAINT user_username_uq UNIQUE (username); 
    
ALTER TABLE user_account 
	ADD CONSTRAINT user_email_uq UNIQUE (email);
    
CREATE TABLE game_review (
	review_id INT AUTO_INCREMENT PRIMARY KEY, 
    game_id INT NOT NULL,
    user_id INT NOT NULL,
    rating INT NOT NULL, 
    review_info TEXT NULL, 
    date_created DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, 
    date_updated DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
ALTER TABLE game_review
	ADD CONSTRAINT game_user_uq UNIQUE (game_id, user_id);
ALTER TABLE game_review 
	ADD CONSTRAINT game_review_fk
    FOREIGN KEY (game_id) REFERENCES game(game_id);
ALTER TABLE game_review 
	ADD CONSTRAINT game_review_user_fk
    FOREIGN KEY (user_id) REFERENCES user_account(user_id);

CREATE TABLE digital_platform (
	platform_id INT AUTO_INCREMENT PRIMARY KEY, 
	platform_name VARCHAR(200) NOT NULL
);
ALTER TABLE digital_platform
	ADD CONSTRAINT platform_name_uq UNIQUE (platform_name);
    
CREATE TABLE game_platform (
	game_id INT NOT NULL, 
    platform_id INT NOT NULL,
	PRIMARY KEY (game_id, platform_id)
);
ALTER TABLE game_platform 
	ADD CONSTRAINT game_platform_game_fk
    FOREIGN KEY (game_id) REFERENCES game(game_id);
ALTER TABLE game_platform 
	ADD CONSTRAINT game_platform_platform_fk
    FOREIGN KEY (platform_id) REFERENCES digital_platform(platform_id);
    
CREATE TABLE ranking_family (
    ranking_family_id INT AUTO_INCREMENT PRIMARY KEY, 
	family_name VARCHAR(200) NOT NULL
);
ALTER TABLE ranking_family 
	ADD CONSTRAINT ranking_family_name_uq UNIQUE (family_name);
    
CREATE TABLE game_ranking (
	game_id INT NOT NULL,
	ranking_family_id INT NOT NULL,
    rank_value INT NOT NULL,
    PRIMARY KEY (game_id, ranking_family_id)
);
ALTER TABLE game_ranking 
	ADD CONSTRAINT game_ranking_game_fk
    FOREIGN KEY (game_id) REFERENCES game(game_id);
ALTER TABLE game_ranking 
	ADD CONSTRAINT game_ranking_family_fk 
    FOREIGN KEY (ranking_family_id) REFERENCES ranking_family(ranking_family_id);