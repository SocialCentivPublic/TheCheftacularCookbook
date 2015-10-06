name          "db_prepare_backups"
description   "An advanced role to prepare backups each day"
run_list      "recipe[TheCheftacularCookbook::db_prepare_backups_setup]"
