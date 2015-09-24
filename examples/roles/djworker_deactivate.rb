name          "djworker_deactivate"
description   "The advanced role for systems that will be deactivating their delayed job workers"
run_list      "recipe[TheCheftacularCookbook::generic_service_deactivate]"
