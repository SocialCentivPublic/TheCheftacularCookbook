name          "sensu_build_db"
description   "The intermediate role for a node set to become a sensu build server with local test database."
run_list      "recipe[TheCheftacularCookbook::sensu_build_db_setup]"
