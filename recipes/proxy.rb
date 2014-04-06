#
# Cookbook Name:: zabbix
# Recipe:: proxy
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

include_recipe "zabbix::default"

node['zabbix']['proxy']['packages'].each do |pkg|
  package pkg do
    if node['zabbix']['version']['full']
      version "#{node['zabbix']['version']['full']}.el#{node[:platform_version].to_i}"
    end
    action :install
  end
end

case node[:platform]
when "redhat", "centos", "fedora"
  node['zabbix']['other']['packages'].each do |pkg|
    package pkg do
      action :install
    end
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

execute "create-database" do
  exists = <<-EOH
  psql -U postgres -c "select * from pg_database WHERE datname='zabbix_proxy'" | grep -c zabbix
  EOH
  command "createdb -U zabbix zabbix_proxy"
  not_if exists
end

script "create_zabbix_table" do
 interpreter "bash"
 user "root"
 code <<-EOH
 psql -f /usr/share/doc/`rpm -q zabbix-proxy-pgsql | sed -e s/-.\.el.\.x86_64//`/create/schema.sql -U zabbix zabbix_proxy
 EOH
end
 
template "/etc/cron.d/postgresql_maintenance" do
  source "postgresql_maintenance.erb"
  owner "root"
  mode 0644
end

template "/etc/zabbix/zabbix_proxy.conf" do
  source "zabbix_proxy.conf-#{node['zabbix']['version']['major']}.erb"
  owner "root"
  notifies :restart, 'service[zabbix-proxy]'
  mode 0640
end

service "zabbix-proxy" do
  supports :status => true, :restart => true
  action [ :enable, :start]
end

service "iptables" do
  supports :status => true, :restart => true, :reload => true
  action [ :disable, :stop ]
end

service "ip6tables" do
  supports :status => true, :restart => true, :reload => true
  action [ :disable, :stop ]
end
