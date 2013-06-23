--
-- SpinalTapCodeMosh DB Structure.
--

-- DB if used in MySQL... Currently works on SQLite.
-- CREATE DATABASE IF NOT EXISTS `spinaltapcodemosh`;
-- USE `spinaltapcodemosh`;

CREATE TABLE IF NOT EXISTS moshes (
    id      VARCHAR(40),
    syntax  VARCHAR(40)  DEFAULT 'plain',
    poster  VARCHAR(100) DEFAULT 'Guest',
    subject VARCHAR(255),
    data    TEXT,
    created TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- ) ENGINE = InnoDB CHARSET = 'utf8'; -- IF using MySQL


