#
# Cookbook Name:: zabbix
# Recipe:: server
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
node['zabbix']['server']['packages'].each do |pkg|
  package pkg do
    if node['zabbix']['version']['full']
      version "#{node['zabbix']['version']['full']}.el#{node[:platform_version].to_i}"
    end
    action :install
  end
end

node['zabbix']['other']['packages'].each do |pkg|
  package pkg do
    action :install
  end
end


execute "selinux" do
  command "/usr/sbin/setenforce 0"
  only_if { `/usr/sbin/getenforce` =~ /Enforcing/ }
end

template "/etc/selinux/config" do
  source "config.erb"
  owner "root"
  mode 0644
end


execute "/sbin/service postgresql initdb" do
  not_if { ::FileTest.exist?("/var/lib/pgsql/data/postgresql.conf") }
end

template "/var/lib/pgsql/data/pg_hba.conf" do
  source "pg_hba.conf.erb"
  owner "postgres"
  mode 0600
end

template "/var/lib/pgsql/data/postgresql.conf" do
  source "postgresql.conf.erb"
  owner "postgres"
  mode 0600
end

service "postgresql" do
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
end

execute "create-database-user" do
  code = <<-EOH
psql -U postgres -c "select * from pg_user where usename='zabbix'" | grep -c zabbix
EOH
  command "createuser -U postgres zabbix -S -d -R"
  not_if code
end

execute "create-database-user" do
  exists = <<-EOH
psql -U postgres -c "select * from pg_database WHERE datname='zabbix'" | grep -c zabbix
EOH
  command "createdb -U zabbix zabbix"
  not_if exists
end

script "create_zabbix_table" do
  interpreter "bash"
  user "root"
  code <<-EOH
psql -f /usr/share/doc/`rpm -q zabbix-server-pgsql | sed -e s/-.\.el.\.x86_64//`/create/schema.sql -U zabbix zabbix
psql -f /usr/share/doc/`rpm -q zabbix-server-pgsql | sed -e s/-.\.el.\.x86_64//`/create/images.sql -U zabbix zabbix
psql -f /usr/share/doc/`rpm -q zabbix-server-pgsql | sed -e s/-.\.el.\.x86_64//`/create/data.sql -U zabbix zabbix
EOH
end

template "/etc/cron.d/postgresql_maintenance" do
  source "postgresql_maintenance.erb"
  owner "root"
  mode 0644
end

template "/etc/zabbix/zabbix_server.conf" do
  source "zabbix_server.conf-#{node['zabbix']['version']['major']}.erb"
  owner "root"
  notifies :restart, "service[zabbix-server]"
  mode 0640
end

template "/etc/zabbix/web/zabbix.conf.php" do
  source "zabbix.conf.php.erb"
  owner "root"
  notifies :restart, "service[zabbix-server]"
  mode 0644
end

template "/etc/php.ini" do
  source "php.ini.erb"
  owner "root"
  notifies :restart, "service[httpd]"
  mode 0644
end

template "/etc/httpd/conf/httpd.conf" do
  source "httpd.conf.erb"
  owner "root"
  notifies :restart, "service[httpd]"
  mode 0644
end

service "zabbix-server" do
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
end

service "httpd" do
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
end

service "iptables" do
  supports :status => true, :restart => true, :reload => true
  action [ :disable, :stop ]
end

service "ip6tables" do
  supports :status => true, :restart => true, :reload => true
  action [ :disable, :stop ]
end

