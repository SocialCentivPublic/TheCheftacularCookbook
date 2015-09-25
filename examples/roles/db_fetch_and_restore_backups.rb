name          "db_fetch_and_restore_backups"
description   "An advanced role to fetch backups from the production primary each day and drop them onto a prepared disk. If a flag in the config data bag is set, the latest backup will be restored into the database"
run_list      "recipe[TheCheftacularCookbook::db_fetch_and_restore_backups_setup]"
