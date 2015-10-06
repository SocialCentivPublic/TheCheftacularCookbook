name          "db_replication"
description   "The advanced role for a database node set to be a master and stream changes to slave nodes"
run_list      "recipe[TheCheftacularCookbook::db_setup_replication]"