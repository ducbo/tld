PRAGMA foreign_keys=OFF;
BEGIN TRANSACTION;
CREATE TABLE cyberman (
	id integer primary key,
	dbrev integer not null,
	intserial integer not null default 1,
	lastserial integer not null default 0,
	zonecheckstatus integer not null default 0
);
INSERT INTO cyberman VALUES(1,10,1,0,0);
CREATE TABLE user (
	id integer primary key,
	email text not null,
	password text not null,
	salt text not null,
	active integer not null default 0,
	conftoken text not null,
	newemail text,
	recoverytoken text,
	stylesheet text,
	admin integer not null default 0,
	email_pub integer not null default 0,
	whois_name text
);
INSERT INTO user VALUES(1,'ducbo@yahoo.com','6nL9pmkzIaBMfnUjQ6MJQvJ7.SoUpEC','pwStjUVTS40scZ2q',1,'AS2K1we64TtOWiET',NULL,NULL,NULL,1,1,NULL);
CREATE TABLE session (
	id integer primary key,
	uid integer not null,
	since integer not null,
	token text not null
);
CREATE TABLE domain (
	id integer primary key,
	name string not null,
	ownerid integer not null,
	lastsid integer not null default 0,
	since integer not null default 1503187200
);
CREATE TABLE record (
	id integer primary key,
	sid integer not null,
	domainid integer not null,
	type string not null,
	name string not null,
	value string not null
);
COMMIT;
