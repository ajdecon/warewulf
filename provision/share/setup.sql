/****************************************************************************/
/* Drop Existing Tables */

DROP TABLE IF EXISTS nodes_groups;
DROP TABLE IF EXISTS module_node_group;
DROP TABLE IF EXISTS vnfs_module;
DROP TABLE IF EXISTS groups;
DROP TABLE IF EXISTS nodeids;
DROP TABLE IF EXISTS modules;
DROP TABLE IF EXISTS sessions;
DROP TABLE IF EXISTS triggers;
DROP TABLE IF EXISTS ethernet;
DROP TABLE IF EXISTS nodes;
DROP TABLE IF EXISTS cluster;
DROP TABLE IF EXISTS rack;
DROP TABLE IF EXISTS vnfs;


/****************************************************************************/
/* Create Base Tables */

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


CREATE TABLE IF NOT EXISTS clusters
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


CREATE TABLE IF NOT EXISTS racks
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
    cluster_id INT,
    rack_id INT,
    vnfs_id INT,
    FOREIGN KEY (vnfs_id) REFERENCES vnfs (id),
    FOREIGN KEY (cluster_id) REFERENCES clusters (id),
    FOREIGN KEY (rack_id) REFERENCES racks (id),
    PRIMARY KEY (id)
) ENGINE=INNODB;


CREATE TABLE IF NOT EXISTS ethernet
(
    id INT NOT NULL AUTO_INCREMENT UNIQUE,
    hwaddr VARCHAR(256) NOT NULL,
    device VARCHAR(8),
    ipaddr INT,
    netmask INT,
    gateway INT,
    node_id INT,
    FOREIGN KEY (node_id) REFERENCES nodes (id),
    PRIMARY KEY (id)
) ENGINE=INNODB;


CREATE TABLE IF NOT EXISTS triggers
(
    id INT NOT NULL AUTO_INCREMENT UNIQUE,
    name VARCHAR(256) NOT NULL,
    command VARCHAR(256) NOT NULL,
    PRIMARY KEY (id)
) ENGINE=INNODB;




/****************************************************************************/
/* Join groups follow */

CREATE TABLE IF NOT EXISTS nodes_groups
(
    id INT NOT NULL AUTO_INCREMENT UNIQUE,
    node_id INT,
    group_id INT,
    FOREIGN KEY (node_id) REFERENCES nodes (id),
    FOREIGN KEY (group_id) REFERENCES groups (id),
    PRIMARY KEY (id)
) ENGINE=INNODB;


CREATE TABLE IF NOT EXISTS module_node_group
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


CREATE TABLE IF NOT EXISTS vnfs_module
(
    id INT NOT NULL AUTO_INCREMENT UNIQUE,
    vnfs_id INT,
    module_id INT,
    FOREIGN KEY (vnfs_id) REFERENCES vnfs (id),
    FOREIGN KEY (module_id) REFERENCES modules (id),
    PRIMARY KEY (id)
) ENGINE=INNODB;


