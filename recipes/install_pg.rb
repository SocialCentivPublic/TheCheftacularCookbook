
%w(postgresql-client libpq-dev).each do |r|
  package r #there is no simple way to test if the installation of libpq-dev has already been done. This executes very quickly regardless
end
