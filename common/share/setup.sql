/****************************************************************************/
/* Drop Existing Tables */

DROP TABLE IF EXISTS lookup;
DROP TABLE IF EXISTS datastore;


/****************************************************************************/
/* Create Base Tables */


CREATE TABLE datastore
(
    id INT NOT NULL AUTO_INCREMENT UNIQUE,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    serialized LONGTEXT,
    data LONGBLOB,
    INDEX (id),
    PRIMARY KEY (id)
) ENGINE=INNODB;


CREATE TABLE lookup
(
    id INT NOT NULL AUTO_INCREMENT UNIQUE,
    type VARCHAR(64),
    string VARCHAR(64),
    parent_id INT,
    object_id INT,
    active BOOL,
    FOREIGN KEY (parent_id) REFERENCES datastore (id),
    FOREIGN KEY (object_id) REFERENCES datastore (id),
    INDEX (id),
    PRIMARY KEY (id)
) ENGINE=INNODB;




