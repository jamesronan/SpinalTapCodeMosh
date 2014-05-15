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
    expiry  INT(3)       DEFAULT 1,
    created TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- ) ENGINE = InnoDB CHARSET = 'utf8'; -- IF using MySQL

CREATE TABLE IF NOT EXISTS expiry (
    id   INT(3),
    name VARCHAR(25),
);
-- ) ENGINE = InnoDB CHARSET = 'utf8'; -- For MySQL

-- Default expiries.
INSERT INTO expiry VALUES (1, 'never');
INSERT INTO expiry VALUES (2, 'month');
INSERT INTO expiry VALUES (3, 'week');
INSERT INTO expiry VALUES (4, 'day');
INSERT INTO expiry VALUES (5, 'hour');


