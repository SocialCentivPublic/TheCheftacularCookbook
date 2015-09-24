#the creation of this file in tmp will force the slave to start taking write requests

file "/tmp/postgresql.trigger.5432" do
  owner   "postgres"
  group   "postgres"
  mode    "0744"
  content "echo switch"
end
