#
# Cookbook Name:: zabbix
# Recipe:: server
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

include_recipe "zabbix::default"

case node[:platform]
when "redhat", "centos", "fedora"
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

  cookbook_file "#{Chef::Config[:file_cache_path]}/ruby-2.1.1-1.el6.x86_64.rpm" do
    source "ruby-2.1.1-1.el6.x86_64.rpm"
  end

  rpm_package "ruby" do
    action :install
    source "#{Chef::Config[:file_cache_path]}/ruby-2.1.1-1.el6.x86_64.rpm"
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
  pgsql_path = "/var/lib/pgsql"
  httpd_conf_template = "httpd.conf.erb"
end

case node[:platform]
when "amazon"
  node['zabbix']['server']['packages'].each do |pkg|
    package pkg do
      if node['zabbix']['version']['full']
        version "#{node['zabbix']['version']['full']}.el6"
      end
      action :install
    end
  end

  package "ruby19-devel" do
    action :install
  end

  execute "alternatives-ruby" do
    command "/usr/sbin/alternatives --set ruby /usr/bin/ruby1.9"
  end

  pgsql_path = "/var/lib/pgsql9"
  httpd_conf_template = "httpd.conf.azn.erb"

end

node['zabbix']['other']['packages'].each do |pkg|
  package pkg do
    action :install
  end
end

node['zabbix']['server']['gems'].each do |pkg|
	gem_package "#{pkg}" do
		if pkg == "zbxapi" then
			version "0.3.5"
		end
    action :install
    options("--no-ri --no-rdoc")
  end
end




execute "/sbin/service postgresql initdb" do
  not_if { ::FileTest.exist?("#{pgsql_path}/data/postgresql.conf") }
end

template "#{pgsql_path}/data/pg_hba.conf" do
  source "pg_hba.conf.erb"
  owner "postgres"
  mode 0600
end

template "#{pgsql_path}/data/postgresql.conf" do
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
  source httpd_conf_template
  owner "root"
  notifies :restart, "service[httpd]"
  mode 0644
end

if node[:platform] == "amazon"
  template "/etc/httpd/conf.d/zabbix.conf" do
    source "zabbix.conf.erb"
    owner "root"
    notifies :restart, "service[httpd]"
    mode 0644
  end
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

git "#{Chef::Config[:file_cache_path]}/zabbix-api" do
	repository "https://github.com/taishin/zabbix-api.git"
	reference "master"
	action :checkout
end

bash "exec zbxapi" do
	cwd "#{Chef::Config[:file_cache_path]}/zabbix-api"
	code <<-EOC
	  find . -name "*.rb" -exec ruby {} \\;
	EOC
end
