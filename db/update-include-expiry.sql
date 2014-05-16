-- SQL to update existing mosh DBs to work with release 1.0.

ALTER TABLE moshes ADD COLUMN expiry INT(3) DEFAULT 1;

CREATE TABLE IF NOT EXISTS expiry (
    id   INT(3),
    name VARCHAR(25),
);

INSERT INTO expiry VALUES (1, 'never');
INSERT INTO expiry VALUES (2, 'month');
INSERT INTO expiry VALUES (3, 'week');
INSERT INTO expiry VALUES (4, 'day');
INSERT INTO expiry VALUES (5, 'hour');


