## 1.1.6

* Fixed issue in libraries/helpers.rb, if environments_to_backup was not set, it would error.

## 1.1.5

* Added check-url.rb sensu plugin check

## 1.1.4

* Fixed runtime error where the database hash for minibackup generation is wrong

## 1.1.3

* Fixed errors in database creation on new servers

## 1.1.2

* Fixed errors that could arise with the new backups

## 1.1.1

* Improved the backup templates and increased the integration with the *backup_gem_backups* key

## 1.1.0

* Added new backup templates for automatically storing data from MySQL and mongo nodes locally and on the backupmaster. This is triggered by the cheftacular.yml key *backup_gem_backups* in your repo config hash.

## 1.0.10

* Fix runtime error in https haproxy instances

## 1.0.9

* Fixed syntax error in sensu_gems.rb

## 1.0.8

* Fixed bug in sensu_gems.rb that made gem installs occur on all runs

* Fixed bug with database creation that would cause the default application user to not be able to access

## 1.0.7

* Fixed bug in db_prepare_backups_setup.rb where clients that were not in the main server's environment would not get sent backups.

## 1.0.6

* Added new sensu check cleanup-processes.rb

## 1.0.5

* Major fix to database volumes not configuring sub directories correctly

* Major fix to helper calls not configuring repo_hashes correctly

* Fix to database user not always being inserted into a rails application database.yml

* Fix to backup server not getting loaded on backup_gem calls

## 1.0.4

* Minor tweaks to wordpress installations

## 1.0.3

* Fix to graphite workers not starting successfully

* Fix to wordpress applications not creating their uploads directory correctly

* Fix to HAproxy servers using an outdated version that doesn't support the latest SSL termination protocols (changes will safely update to the latest)

## 1.0.2

* Update to application_defaults to use new cheftacular key for a repo: **use_other_repo_database**

## 1.0.1

* Large numbers of fixes for invalid syntax and code.

## 1.0.0

* Too many changes to list here, please see README and the [cheftacular_gem](https://github.com/SocialCentivPublic/cheftacular)
