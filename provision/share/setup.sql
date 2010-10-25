
DROP TABLE IF EXISTS nodes_groups_join;
DROP TABLE IF EXISTS modules_node_group_join;
DROP TABLE IF EXISTS vnfs_modules_join;
DROP TABLE IF EXISTS groups;
DROP TABLE IF EXISTS nodes;
DROP TABLE IF EXISTS vnfs;
DROP TABLE IF EXISTS nodeids;
DROP TABLE IF EXISTS modules;
DROP TABLE IF EXISTS sessions;
DROP TABLE IF EXISTS triggers;


CREATE TABLE IF NOT EXISTS sessions
(
    sid INT NOT NULL AUTO_INCREMENT UNIQUE,
    cookie varchar(64) NOT NULL UNIQUE,
    last_access BIGINT,
    ipaddr BIGINT,
    user_agent VARCHAR(256),
    INDEX (sid,cookie),
    PRIMARY KEY (sid)
) ENGINE=INNODB;


CREATE TABLE IF NOT EXISTS vnfs
(
    id INT NOT NULL AUTO_INCREMENT UNIQUE,
    name VARCHAR(256) NOT NULL,
    create_time BIGINT,
    update_time BIGINT,
    lastcontact_time BIGINT,
    description TEXT,
    notes TEXT,
    image LONGBLOB,
    active BOOLEAN,
    PRIMARY KEY (id)
) ENGINE=INNODB;


CREATE TABLE IF NOT EXISTS modules
(
    id INT NOT NULL AUTO_INCREMENT UNIQUE,
    name VARCHAR(256) NOT NULL,
    create_time BIGINT,
    update_time BIGINT,
    lastcontact_time BIGINT,
    description TEXT,
    notes TEXT,
    script LONGBLOB,
    active BOOLEAN,
    PRIMARY KEY (id)
) ENGINE=INNODB;


CREATE TABLE IF NOT EXISTS groups
(
    id INT NOT NULL AUTO_INCREMENT UNIQUE,
    name VARCHAR(256) NOT NULL,
    create_time BIGINT,
    update_time BIGINT,
    lastcontact_time BIGINT,
    description TEXT,
    notes TEXT,
    active BOOLEAN,
    PRIMARY KEY (id)
) ENGINE=INNODB;


CREATE TABLE IF NOT EXISTS nodeids
(
    id INT NOT NULL AUTO_INCREMENT UNIQUE,
    string VARCHAR(256) NOT NULL,
    node_id INT,
    FOREIGN KEY (node_id) REFERENCES nodes (id),
    PRIMARY KEY (id)
) ENGINE=INNODB;


CREATE TABLE IF NOT EXISTS nodes_groups_join
(
    id INT NOT NULL AUTO_INCREMENT UNIQUE,
    node_id INT,
    group_id INT,
    FOREIGN KEY (node_id) REFERENCES nodes (id),
    FOREIGN KEY (group_id) REFERENCES groups (id),
    PRIMARY KEY (id)
) ENGINE=INNODB;


CREATE TABLE IF NOT EXISTS modules_node_group_join
(
    id INT NOT NULL AUTO_INCREMENT UNIQUE,
    node_id INT,
    group_id INT,
    module_id INT,
    FOREIGN KEY (node_id) REFERENCES nodes (id),
    FOREIGN KEY (group_id) REFERENCES groups (id),
    FOREIGN KEY (module_id) REFERENCES modules (id),
    PRIMARY KEY (id)
) ENGINE=INNODB;


CREATE TABLE IF NOT EXISTS vnfs_modules_join
(
    id INT NOT NULL AUTO_INCREMENT UNIQUE,
    vnfs_id INT,
    module_id INT,
    FOREIGN KEY (vnfs_id) REFERENCES vnfs (id),
    FOREIGN KEY (module_id) REFERENCES modules (id),
    PRIMARY KEY (id)
) ENGINE=INNODB;


CREATE TABLE IF NOT EXISTS nodes
(
    id INT NOT NULL AUTO_INCREMENT UNIQUE,
    name VARCHAR(256) NOT NULL,
    create_time BIGINT,
    update_time BIGINT,
    lastcontact_time BIGINT,
    description TEXT,
    notes TEXT,
    debug BOOLEAN,
    active BOOLEAN,
    vnfs_id INT,
    FOREIGN KEY (vnfs_id) REFERENCES vnfs (id),
    PRIMARY KEY (id)
) ENGINE=INNODB;


