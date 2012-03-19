
/****************************************************************************/
/* Create Base Tables */


CREATE TABLE IF NOT EXISTS datastore
(
    id INT UNSIGNED NOT NULL AUTO_INCREMENT UNIQUE,
    type VARCHAR(64),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    serialized BLOB,
    data BLOB,
    INDEX (id),
    PRIMARY KEY (id)
) ENGINE=INNODB;


CREATE TABLE IF NOT EXISTS binstore
(
    id INT UNSIGNED NOT NULL AUTO_INCREMENT UNIQUE,
    object_id INT UNSIGNED,
    chunk LONGBLOB,
    FOREIGN KEY (object_id) REFERENCES datastore (id),
    INDEX (id),
    PRIMARY KEY (id)
) ENGINE=INNODB;


CREATE TABLE IF NOT EXISTS lookup
(
    id INT UNSIGNED NOT NULL AUTO_INCREMENT UNIQUE,
    object_id INT UNSIGNED,
    field VARCHAR(64) BINARY,
    value VARCHAR(64) BINARY,
    FOREIGN KEY (object_id) REFERENCES datastore (id),
    INDEX (id),
    UNIQUE KEY (object_id, field, value),
    PRIMARY KEY (id)
) ENGINE=INNODB;


