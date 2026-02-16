GAMEPOST
Create schema gamepost;
CREATE TABLE gamepost.game_posts (
    game_post_id SERIAL PRIMARY KEY
);
CREATE TABLE gamepost.hero (
    game_post_id INT PRIMARY KEY,
    game_title TEXT NOT NULL,
    game_desc_short TEXT,
    background_img TEXT,
	
    FOREIGN KEY (game_post_id)
    REFERENCES gamepost.game_posts(game_post_id)
    ON DELETE CASCADE
);

CREATE TABLE gamepost.storyline (
    game_post_id INT PRIMARY KEY,
    paragraphs TEXT,

    FOREIGN KEY (game_post_id)
    REFERENCES gamepost.game_posts(game_post_id)
    ON DELETE CASCADE
);

CREATE TABLE gamepost.gameplay (
    game_post_id INT PRIMARY KEY,
    paragraph TEXT,
	gameplay_title TEXT,
	gameplay_title_desc TEXT,

    FOREIGN KEY (game_post_id)
    REFERENCES gamepost.game_posts(game_post_id)
    ON DELETE CASCADE
);

CREATE TABLE gamepost.quick_control_overview (
    game_post_id INT PRIMARY KEY,
    qco_title TEXT,
    qco_title_desc TEXT,

    FOREIGN KEY (game_post_id)
    REFERENCES gamepost.game_posts(game_post_id)
    ON DELETE CASCADE
);

CREATE TABLE gamepost.system_requirement (
    game_post_id INT PRIMARY KEY,

    os_min TEXT,
    os_rec TEXT,
    processor_min TEXT,
    processor_rec TEXT,
    memory_min TEXT,
    memory_rec TEXT,
    graphics_min TEXT,
    graphics_rec TEXT,
    storage_min TEXT,
    storage_rec TEXT,
    directx_min TEXT,
    directx_rec TEXT,

    FOREIGN KEY (game_post_id)
    REFERENCES gamepost.game_posts(game_post_id)
    ON DELETE CASCADE
);
CREATE TABLE gamepost.get_game (
    game_post_id INT not null,
    affiliate_links TEXT,
	get_game_id SERIAL primary key,

    FOREIGN KEY (game_post_id)
    REFERENCES gamepost.game_posts(game_post_id)
    ON DELETE CASCADE
);
CREATE TABLE gamepost.game_info (
    game_post_id INT PRIMARY KEY,
    developer TEXT,
    publisher TEXT,
    release_date DATE,
    genres TEXT,
    platforms TEXT,
    profile_size_photo TEXT,

    FOREIGN KEY (game_post_id)
    REFERENCES gamepost.game_posts(game_post_id)
    ON DELETE CASCADE
);
CREATE TABLE gamepost.carousel (
    carousel_id SERIAL PRIMARY KEY,
    game_post_id INT NOT NULL,
    yt_url_official TEXT,
    upload TEXT,

    FOREIGN KEY (game_post_id)
    REFERENCES gamepost.game_posts(game_post_id)
    ON DELETE CASCADE
);
CREATE TABLE gamepost.modes (
    modes_id SERIAL PRIMARY KEY,
    game_post_id INT NOT NULL,
    mode_title TEXT,
    mode_titledesc TEXT,

    FOREIGN KEY (game_post_id)
    REFERENCES gamepost.game_posts(game_post_id)
    ON DELETE CASCADE
);
CREATE TABLE gamepost.dlcs (
    dlc_id SERIAL PRIMARY KEY,
    game_post_id INT NOT NULL,
    dlc_pt TEXT,

    FOREIGN KEY (game_post_id)
    REFERENCES gamepost.game_posts(game_post_id)
    ON DELETE CASCADE
);
CREATE TABLE gamepost.awards_and_achievements (
    aa_id SERIAL PRIMARY KEY,
    game_post_id INT NOT NULL,
    aa_pt TEXT,

    FOREIGN KEY (game_post_id)
    REFERENCES gamepost.game_posts(game_post_id)
    ON DELETE CASCADE
);
CREATE TABLE gamepost.join_our_community (
    community_id SERIAL PRIMARY KEY,
    game_post_id INT NOT NULL,
    platform_name TEXT,
    platform_link TEXT,

    FOREIGN KEY (game_post_id)
    REFERENCES gamepost.game_posts(game_post_id)
    ON DELETE CASCADE
);