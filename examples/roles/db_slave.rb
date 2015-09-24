name          "db_slave"
description   "The advanced role for a database node set to be a slave db node"
run_list      "recipe[TheCheftacularCookbook::db_slave_setup]"