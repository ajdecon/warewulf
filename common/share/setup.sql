/****************************************************************************/
/* Drop Existing Tables */

DROP TABLE IF EXISTS module_node_group;
DROP TABLE IF EXISTS ethernet;


DROP TABLE IF EXISTS nodes_groups;
DROP TABLE IF EXISTS module_group;
DROP TABLE IF EXISTS vnfs_module;
DROP TABLE IF EXISTS groups;
DROP TABLE IF EXISTS nodeids;
DROP TABLE IF EXISTS modules;
DROP TABLE IF EXISTS sessions;
DROP TABLE IF EXISTS triggers;
DROP TABLE IF EXISTS ethernets;
DROP TABLE IF EXISTS nodes;
DROP TABLE IF EXISTS clusters;
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


CREATE TABLE IF NOT EXISTS ethernets
(
    id INT NOT NULL AUTO_INCREMENT UNIQUE,
    hwaddr VARCHAR(256),
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


CREATE TABLE IF NOT EXISTS module_group
(
    id INT NOT NULL AUTO_INCREMENT UNIQUE,
    group_id INT,
    module_id INT,
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



/****************************************************************************/
/* Example Data */

INSERT INTO vnfs (name, active) VALUES ("rhel-5.4-1.x86_64", "1");
INSERT INTO vnfs (name, active) VALUES ("centos-4.4-1.x86_64", "1");
INSERT INTO modules (name, script, active) VALUES ("statelite", "#!/bin/sh\necho 'this is a script'\n", "1");
INSERT INTO groups (name, active) VALUES ("compute-group1", "1");
INSERT INTO groups (name, active) VALUES ("interactive-group2", "1");
INSERT INTO clusters (name, active) VALUES ("geophys", "1");
INSERT INTO clusters (name, active) VALUES ("nano", "1");
INSERT INTO racks (name, active) VALUES ("A2", "1");
INSERT INTO racks (name, active) VALUES ("A3", "1");
INSERT INTO racks (name, active) VALUES ("A4", "1");
INSERT INTO nodes (name, cluster_id, rack_id, vnfs_id, active) VALUES ("n0000", "1", "2", "1", "1");
INSERT INTO nodes (name, cluster_id, rack_id, vnfs_id, active) VALUES ("n0001", "1", "2", "1", "1");
INSERT INTO nodes (name, cluster_id, rack_id, vnfs_id, active) VALUES ("n0002", "1", "2", "1", "1");
INSERT INTO nodes (name, cluster_id, rack_id, vnfs_id, active) VALUES ("n0003", "1", "2", "1", "1");
INSERT INTO nodes (name, cluster_id, rack_id, vnfs_id, active) VALUES ("n0004", "1", "2", "1", "1");
INSERT INTO nodes (name, cluster_id, rack_id, vnfs_id, active) VALUES ("n0005", "1", "2", "1", "1");
INSERT INTO nodes (name, cluster_id, rack_id, vnfs_id, active) VALUES ("n0006", "1", "2", "1", "1");
INSERT INTO nodes (name, cluster_id, rack_id, vnfs_id, active) VALUES ("n0007", "1", "2", "1", "1");
INSERT INTO nodes (name, cluster_id, rack_id, vnfs_id, active) VALUES ("n0000", "2", "3", "1", "1");
INSERT INTO nodes (name, cluster_id, rack_id, vnfs_id, active) VALUES ("n0001", "2", "3", "1", "1");
INSERT INTO nodes (name, cluster_id, rack_id, vnfs_id, active) VALUES ("n0002", "2", "3", "1", "1");
INSERT INTO nodes (name, cluster_id, rack_id, vnfs_id, active) VALUES ("n0003", "2", "3", "1", "1");
INSERT INTO nodes (name, cluster_id, rack_id, vnfs_id, active) VALUES ("n0004", "2", "3", "1", "1");
INSERT INTO nodes (name, cluster_id, rack_id, vnfs_id, active) VALUES ("n0005", "2", "3", "1", "1");
INSERT INTO ethernets (node_id, device, hwaddr, ipaddr, netmask, gateway) VALUES ("1", "eth0", "00:00:00:00:00:00", "11111110", "255.255.252.0", "10.0.0.20");
INSERT INTO ethernets (node_id, device, hwaddr, ipaddr, netmask) VALUES ("1", "eth1", "00:00:00:00:00:01", "11111112", "255.255.252.0");
INSERT INTO ethernets (node_id, device, hwaddr, ipaddr, netmask, gateway) VALUES ("2", "eth0", "00:00:00:00:01:00", "11111113", "255.255.252.0", "10.0.0.20");
INSERT INTO ethernets (node_id, device, hwaddr, ipaddr, netmask, gateway) VALUES ("3", "eth0", "00:00:00:00:02:00", "11111114", "255.255.252.0", "10.0.0.20");
INSERT INTO ethernets (node_id, device, hwaddr, ipaddr, netmask, gateway) VALUES ("4", "eth0", "00:00:00:00:03:00", "11111115", "255.255.252.0", "10.0.0.20");

INSERT INTO nodes_groups (node_id, group_id) VALUES ("1", "1");
INSERT INTO nodes_groups (node_id, group_id) VALUES ("1", "2");
INSERT INTO nodes_groups (node_id, group_id) VALUES ("2", "1");
INSERT INTO nodes_groups (node_id, group_id) VALUES ("3", "1");
INSERT INTO nodes_groups (node_id, group_id) VALUES ("4", "1");
INSERT INTO nodes_groups (node_id, group_id) VALUES ("5", "1");
INSERT INTO nodes_groups (node_id, group_id) VALUES ("6", "1");
INSERT INTO nodes_groups (node_id, group_id) VALUES ("7", "1");
INSERT INTO nodes_groups (node_id, group_id) VALUES ("8", "1");
INSERT INTO nodes_groups (node_id, group_id) VALUES ("9", "1");
INSERT INTO nodes_groups (node_id, group_id) VALUES ("9", "2");
INSERT INTO nodes_groups (node_id, group_id) VALUES ("10", "1");
INSERT INTO nodes_groups (node_id, group_id) VALUES ("11", "1");
INSERT INTO nodes_groups (node_id, group_id) VALUES ("12", "1");
INSERT INTO nodes_groups (node_id, group_id) VALUES ("13", "1");
INSERT INTO nodes_groups (node_id, group_id) VALUES ("14", "1");
INSERT INTO module_group (group_id, module_id) VALUES ("1", "1");
INSERT INTO module_group (group_id, module_id) VALUES ("2", "1");
