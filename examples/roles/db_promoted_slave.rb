name          "db_promoted_slave"
description   "A promoted slave should be given the db_primary role and the db_primary should have its db_primary role taken away"
run_list      "recipe[TheCheftacularCookbook::db_promoted_slave]"