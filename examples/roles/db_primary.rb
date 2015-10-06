name          "db_primary"
description   "The advanced role for a database node set to be the primary db node (THERE SHOULD ONLY BE ONE NODE THAT HAS THIS ROLE PER ENVIRONMENT!)"
run_list      "recipe[TheCheftacularCookbook::db_primary_setup]"
