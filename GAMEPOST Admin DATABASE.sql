GAMEPOST WALA 1 HOR DATABASE
CREATE TABLE admin_gamepost.admin (
    game_post_id INT PRIMARY KEY,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    published_at TIMESTAMP,
    scheduled_at TIMESTAMP,

    saved_as_draft BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT fk_admin_game_post
        FOREIGN KEY (game_post_id)
        REFERENCES gamepost.game_posts(game_post_id)
        ON DELETE CASCADE
);