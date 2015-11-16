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
