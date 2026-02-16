ADMIN KA DATABASE
CREATE TABLE admin_data.admin_users (
    admin_id SERIAL PRIMARY KEY,
    email_id TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    username TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE admin_data.sign_up (
    user_id SERIAL PRIMARY KEY,

    email_id TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    username TEXT NOT NULL,
    phone_no TEXT,
    profile_pic TEXT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    login_at TIMESTAMP,

    device_info TEXT,
    geo_location TEXT
);
CREATE TABLE admin_data.login (
    login_id SERIAL PRIMARY KEY,

    user_id INT NOT NULL,
    logged_in TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    session_time INTERVAL,

    CONSTRAINT fk_login_user
        FOREIGN KEY (user_id)
        REFERENCES admin_data.sign_up(user_id)
        ON DELETE CASCADE

);
