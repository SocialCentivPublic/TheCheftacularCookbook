name          "application_cron_jobs"
description   "The advanced role for an application node set to run cron_jobs for all applications installed on it"
run_list      "recipe[TheCheftacularCookbook::application_cron_jobs_setup]"
