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
    serialized LONGBLOB,
    data LONGBLOB,
    INDEX (id),
    PRIMARY KEY (id)
) ENGINE=INNODB;


CREATE TABLE lookup
(
    id INT NOT NULL AUTO_INCREMENT UNIQUE,
    type VARCHAR(64),
    field VARCHAR(64),
    value VARCHAR(64),
    object_id INT,
    FOREIGN KEY (object_id) REFERENCES datastore (id),
    INDEX (id),
    PRIMARY KEY (id)
) ENGINE=INNODB;




INSERT INTO datastore (serialized) VALUES ("serialized data for a group object named: group1");
INSERT INTO datastore (serialized) VALUES ("serialized data for a group object named: interactive");
INSERT INTO datastore (serialized) VALUES ("serialized data for a group object named: io");
INSERT INTO datastore (serialized) VALUES ("serialized data for a rack object named: rack1");
INSERT INTO datastore (serialized) VALUES ("serialized data for a rack object named: rack2");
INSERT INTO datastore (serialized) VALUES ("serialized data for a node object named: n0000");
INSERT INTO datastore (serialized) VALUES ("serialized data for a node object named: n0001");
INSERT INTO datastore (serialized) VALUES ("serialized data for a node object named: n0002");

INSERT INTO lookup (type, field, value, object_id) VALUES ("group",     "name",     "group1",       "1");
INSERT INTO lookup (type, field, value, object_id) VALUES ("group",     "name",     "interactive",  "2");
INSERT INTO lookup (type, field, value, object_id) VALUES ("group",     "name",     "io",           "3");
INSERT INTO lookup (type, field, value, object_id) VALUES ("rack",      "name",     "rack1",        "4");
INSERT INTO lookup (type, field, value, object_id) VALUES ("rack",      "name",     "rack2",        "5");

INSERT INTO lookup (type, field, value, object_id) VALUES ("node",      "name",     "n0000",        "6");
INSERT INTO lookup (type, field, value, object_id) VALUES ("node",      "group",    "group1",       "6");
INSERT INTO lookup (type, field, value, object_id) VALUES ("node",      "group",    "interactive",  "6");
INSERT INTO lookup (type, field, value, object_id) VALUES ("node",      "rack",     "rack1",        "6");

INSERT INTO lookup (type, field, value, object_id) VALUES ("node",      "name",     "n0001",        "7");
INSERT INTO lookup (type, field, value, object_id) VALUES ("node",      "group",    "group1",       "7");
INSERT INTO lookup (type, field, value, object_id) VALUES ("node",      "group",    "interactive",  "7");
INSERT INTO lookup (type, field, value, object_id) VALUES ("node",      "rack",     "rack1",        "7");

INSERT INTO lookup (type, field, value, object_id) VALUES ("node",      "name",     "n0002",        "8");
INSERT INTO lookup (type, field, value, object_id) VALUES ("node",      "group",    "group1",       "8");
INSERT INTO lookup (type, field, value, object_id) VALUES ("node",      "group",    "io",           "8");
INSERT INTO lookup (type, field, value, object_id) VALUES ("node",      "rack",     "rack2",        "8");







