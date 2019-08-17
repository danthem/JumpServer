**This repo is a WIP... The jumpserver, setup and cpanel scripts work but are still being improved. Instructions in this README may not be fully up to date.

# JumpServer
A simple 'jump server' bash script reading available devices from a sqlite3 database. For this reason you'll obviously need sqlite3 on your machine.

It's set up to fit my needs, modify the DB etc as needed to fit your needs.

## Syntax
./jump.sh should be enough. But an alternative is to create users and set their shell to be the script (just make sure to check their permissions), this way as a user connects they will be directly presented with the list of available devices. Good if you're allowing other people access. Before running the script you have to set the database + logfile locations. You will also need to create devices in the database, you can do it manually in the database (tables described further down) or by using cpanel.sh. 

## Setup
Setup is fairly straight forward. You just need the script, a database with devices (more on this later) and a logfile destination. Database location is specified in the "dbase" variable in the script, log location in the "logfile" variable. **You must update these variables to reflect actual location on your system**. 

I've included a template database here in the report (database/jumpdb.sq3), the database consists of three tables, covered in more detail further down.

## cpanel.sh
I've written a quick script for managing the jumpserver database called cpanel.sh. This script can be used to interactively add users/devices, enable/disable devices, delete users, change servermode without having to manually edit the sqlite3 database. Note that there's very little input validation here, it's just a 'quality of life' improvement and assumes that you're entering correct values. Similar to jump.db you must set the log and database locations prior to running this.

### Database
##### devices
```CREATE TABLE devices(id INTEGER PRIMARY KEY, ip TEXT NOT NULL UNIQUE, os TEXT NOT NULL, hostname TEXT NOT NULL UNIQUE, user TEXT NOT NULL, comment TEXT, admin_only INTEGER NOT NULL DEFAULT 0, enabled INTEGER NOT NULL DEFAULT 1);```

This is the table we use to get which devices we can connect to, fields should be self explanatory. "user" is the username that will be used to SSH to this device (ssh $user@$ip)

*Example 'devices' entry:* ```INSERT INTO devices VALUES(1,'192.168.10.235','OneFS 8.1.2.0','Eight-One-Two','Daniel','hosted on HE-ESXI-01',0,1);``` 

##### users
```CREATE TABLE users(username TEXT NOT NULL UNIQUE, comment TEXT, admin INTEGER NOT NULL DEFAULT 0, enabled INTEGER NOT NULL DEFAULT 1);```

This table holds users that are allowed to run the jump script, if a user is not in here they will never be presented a list of devices - instead the script will end. This table also has a field indicating if a user is an "admin", if this is set to "1" the user will be able to see devices with "admin_only" set to 1.

*Example 'users' entry:* ```INSERT INTO users VALUES("tester", "testeruser", 0, 1);```

##### serverstatus
```CREATE TABLE serverstatus(id INTEGER PRIMARY KEY, mode TEXT NOT NULL, reason TEXT, who TEXT NOT NULL, time TEXT NOT NULL);```

This table holds the current server mode ('maintenance' or 'normal', the script only looks at 1 entry (the entry with id=1). If server mode is set to "normal" users can connect as usual but if set to "maintenance" the user will be presented with a screen informing that server is in maintenance mode and prints the given reason. It's a way to temporarily disable user access, some people may never need to use/change this. Personally I have scripts rebooting all devices and rolling them back to an initial setup state on a regular basis, while this is happening the jumpserver is set to maintenance mode to avoid uneccessary logging of failed connection attempts.

The server mode can be changed interactively through cpanel.sh.

*Example 'serverstatus' entry:* ```INSERT INTO serverstatus VALUES(1,'normal','','Daniel','2019-05-16');```

### Logging
The script does log various events to the "logfile" variable (by default set to /var/log/jumpserver.log). The user(s) will need to have write access to this file. The sript will log connections, disconnections and/or connection failures/errors along with username, IP and a timestamp. cpanel access and server mode changes are also logged to this logfile.

### SSH authentication
The script will use whatever username is specified for a device in the sqlite3 database. You can either leave it at that and manually enter the password whenever you try to connect but I'd recommend setting up SSH keys to be used instead.

### A note on ICMP
The script does rely on performing a ping check before attempting to SSH to a device, if your network blocks ICMP traffic you might want to get rid of that if statement. The ping timeout is set to 2 seconds, if you expect longer ping times than that you will need to increase it as well. If the ping test fails it will not attempt SSH'ing.

### Final note
This project is mostly a 'skeleton project' that should be built upon and adjusted to fit your requirements. For me it's run in a pure non-prod lab environment where there's no concern about unauthorized access or so.

