# How To Use This Cookbook

This cookbook is _very_ tightly coupled with the [Cheftacular Gem](https://github.com/SocialCentivPublic/cheftacular). It is recommended to look over the cheftacular gem before examining this cookbook as it is what closes the loop between Chef, this cookbook, and your infrastructure. Cheftacular utilizes a [cheftacular.yml file](https://github.com/SocialCentivPublic/cheftacular/blob/master/examples/thecheftacularcookbook.cheftacular.yml) that allows you to configure how it interacts with your infrastructure. The gem syncs changes to your cheftacular.yml onto your chef server so it can be utilized (ideally by this cookbook). This cookbook uses various keys in the cheftacular.yml file to configure your servers, in addition to the roles, nodes data, and business logic cookbook(s) you must define.

## Foreword: Business Logic

This cookbook contains no specific business logic and instead utilizes the configurations defined in the cheftacular.yml. However, this is not enough as you need a wrapper cookbook to bind some of your roles to specific business-oriented recipes. Due to this, it is **highly** recommended to create a wrapper cookbook that calls this cookbook and also defines your business logic (like what repos a role may load). An example of this can be found in the [example business logic cookbook](https://github.com/SocialCentivPublic/TheCheftacularCookbook/blob/master/examples/MyBusiness). An example of the roles you could use for this type of setup can be found [here](https://github.com/SocialCentivPublic/TheCheftacularCookbook/blob/master/examples/roles) and an example of the nodes_dir you can utilize can be found [within cheftacular](https://github.com/SocialCentivPublic/cheftacular/blob/master/examples/nodes_dir).

## Prologue & Rationalle

This repo was created in its entirety by Louis Alridge. While studying the source is preferred, he maintains a permanent email address at loualrid@gmail.com for correspondance.

This repo was created in 2014 and follows some chef best practices. At its most fundamental level its arranged with the concept of this cookbook being a wrapper cookbook for every other cookbook and the
wrapper cookbook controlled by roles set on the nodes from the nodes_dir. While you can set recipes directly via the nodes_dir, I used roles for both brevity and for situations where a many to one relationship for roles to recipes is desired.

## Utilizing this cookbook

This cookbook is designed to work directly with a chef-server and requires several data bags and roles to function properly. The cheftacular gem (and future iterations) explains how to utilize this cookbook to administrate and build an environment. This cookbook tells the environment how to behave and what it should do.

At its simplest, everything is managed via `chef-client` on a remote node.

## Data bags

The most important piece of this puzzle are the data bags. They provide the data that drives the top level functionality of this cookbook. Listed here are the required data bags along with conceptual contents and structure.

Note: The list is ENVIRONMENT -> bag, you can see the contents of any data bag with the command `knife data bag show <ENVIRONMENT> <BAG_NAME> -F json`. These data bag items are meant to be maintained via the cheftacular gem but manual manipulation may be required.

1.  default

    1.  authentication (encrypted)

        1. Stores the authorized keys for various developers to access the servers, also stores cloud_auth credentials and git credentials.

    1.  cheftacular

        1.  Stores the current state of the CHEF-REPO'S cheftacular.yml and attempts to merge in changes from various repositories utilizing the chef-server. This bag is used extensively by the cookbook.

    2.  chef_passwords (encrypted)

        1.  Stores useful password data like the default environment postgres password and the default mysql password.

    3.  environment_config

        1.  Stores the environments currently setup on the chef server and the databags each environment currently has available

2.  test / staging / production / etc

    1.  addresses

        1.  Stores key data for the node's domain names and some other info the chef-server doesn't automatically store (like the node's private ip-address)

    2.  config

        1.  The config bag holds the key building blocks for the environment. It holds the server's tld as well as default repo revision and special revisions set for individual codebases

    3.  logs

        1.  Stores logging data from various runs on the server so they can be fetched by a different user without checking the original user's computer manually. This bag will store the *entire* log output of a failed run on a node, but no data for successful runs.

    4.  server_passwords (encrypted)

        1.  Stores the initial root password, the deploy user sudo password, and the name for each server in the environment.

## Roles

Roles determine the meat of the functionality of the servers and various combinations of roles trigger different effects on servers. It is also worth noting that roles are executed from left to right and recipes set in multiple roles are only executed in the first role they are set in.

There are three different types of roles, basic roles, intermediate roles, and advanced roles, these types are purely conceptual but may assist in thinking about how the cookbook is structured.

Basic roles define critical functionality (is this a database, is this a rails app, is this a wordpress site, etc). 

Intermediate roles define what the basic role loads and how it behaves. For example a basic role of rails with an intermediate role of mybackendrepo tells a server it should install the repo mybackendrepo (which corresponds to an entry in the cheftacular.yml). This server would merely just have the codebase on it, no nginx, puma, or worker processes

Advanced roles define what the server should *do* with its basic and intermediate roles. There are many advanced roles but good examples include web, delayedjob, and db_slave. For a comprehensive list, check the roles folder in the root of the chef-repo.

1.  Special Advanced Roles (these are just a few of the examples)

    1.  `db_normal_pg_logging / db_verbose_pg_logging` will define how many logs postgres generates when one of the two is active. Verbose logging generates gigabytes of logs per day.

    2.  `db_replication` role should never be placed on a db role unless the db role has completed its run_list once (done a full deploy). Otherwise it won't setup slave / master replication correctly

    3.  `scalable` Tells monitoring clients (devs and monitoring server) that the other nodes in the group with this role are scalable via a command. This role should only be activated for node groups that can scale (web servers, workers)

        1.  You can't scalable a node group that doesn't have a load balancer

    6.  `worker` Doesn't trigger any unique functions on its own, but does help scope some other roles and in the deployment gem it can be used to tell what additional log files to fetch.

## Nodes (nodes_dir)

Nodes are the servers themselves. They form the building blocks for the infrastructure and are containers for the results of roles. Generally nodes can be destroyed and rebuilt easily as run-time is usually independent of the node's role itself (with the exception of nodes with role db_primary).

Node definition files and template files can be found in the nodes_dir and are parsed by the cheftacular gem to update the roles / recipes running on a node. Generally the formula is as follows: a node with a number in its name is scalable and belongs to a templating file that does not have its number. A node without a number in its name has a strict definition file that matches it's name and defines its run list.

Node template and definition files are usually fairly descriptive of the name of the node and a new node that does not have a name that matches either will never acquire a run_list.

## Cookbooks

If roles define the what, cookbooks define the how. Cookbooks (specifically this one) tell a node what it should become when a chef-client run is executed.

There are two types of cookbooks. Wrapper cookbooks (which is what this cookbook is) and component cookbooks (ruby, rvm, wordpress, etc).

Wrapper cookbooks define what the component cookbooks should do and what defaults they should install with. Component cookbooks generally do one thing and cover as many cases as possible for the installation of that one thing. A good example is the postgres cookbook which can be used to install postgres on (almost) any type of linux distro.

## TheCheftacularCookbook Basic Cookbook Flow

Most of the real magic of this setup happens in the TheCheftacularCookbook cookbook. This is a basic example of how it works for installing an api server with puma and nginx

1.  role[mybackendrepo]

    1.  Runs mybackendrepo_setup recipe. This recipe sets a setting to the node that it needs to load the "mybackendrepo" code. 

    2.  It also triggers a run of the default recipe which sets high level attributes like what ruby to use and other configs that are similar across almost all installations (like iptables)

2.  role[rails]

    1.  Runs the stack_setup recipe. This recipe triggers the `business_application` LWRP and attempts to install a repo based on configurations set in the cheftacular.yml. This recipe uses the application_ruby cookbook and several linux commands to perform this correctly.

3.  role[web]

    1.  This role does little by itself but triggers additional functionality on the rails_setup recipe. If specified, it will call the nginx and puma cookbooks to install these two processes and utilize them to bring up a fully functioning web server. This web server is automatically attached to the haproxy load balancer the next time a deploy is run (if there is one defined)

For a full idea of how this cookbook handles various configurations of roles, there really is nothing better than browsing the source code. Most combinations are fairly intuitive and combinations that don't seem like they'd work together most likely won't. Custom cases and new roles must be added to the cookbook (edge cases being particularly difficult).

Most of the recipes are fairly short and describe their intent. Following a role / node chain from start to finish would be the most instructional way of discovering how the system works.
