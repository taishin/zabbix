#
# Cookbook Name:: zabbix
# Recipe:: server
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

include_recipe "zabbix::default"
include_recipe "zabbix::server"
include_recipe "zabbix::snmp"
include_recipe "zabbix::java"

node['zabbix']['full']['packages'].each do |pkg|
  package "#{pkg}" do
    action :install
  end
end

case node[:platform]
when "redhat", "centos", "fedora"



  node['zabbix']['full']['gems'].each do |pkg|
    gem_package "#{pkg}" do
      action :install
      options("--no-ri --no-rdoc -- --use-system-libraries=ture")
    end
  end

  service "udev-post" do
    action [ :disable, :stop ]
  end

  service "avahi-daemon" do
    action [ :disable, :stop ]
  end

  template "/etc/ntp.conf" do
    source "ntp.conf.erb"
    notifies :restart, "service[#{node['ntp']['service']}]"
  end

  service node['ntp']['service'] do
    action [:enable, :start]
  end

when "amazon"
  package "libxml2-devel" do
    action :install
  end

  package "libxslt-devel" do
    action :install
  end

  node['zabbix']['full']['gems'].each do |pkg|
    gem_package "#{pkg}" do
      action :install
      options("--no-ri --no-rdoc -- --use-system-libraries=ture")
    end
  end
end





service "monit" do
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
end

template "/etc/monit.conf" do
  source "monit.conf.erb"
  mode "00600"
  owner "root"
  group "root"
  notifies :restart, "service[monit]"
end

template "/etc/monit.d/httpd" do
  source "monit-httpd.erb"
  mode "00644"
  owner "root"
  group "root"
  notifies :restart, "service[monit]"
end

template "/etc/monit.d/logging" do
  source "monit-logging.erb"
  mode "00644"
  owner "root"
  group "root"
  notifies :restart, "service[monit]"
end

template "/etc/monit.d/mail" do
  source "monit-mail.erb"
  mode "00644"
  owner "root"
  group "root"
  notifies :restart, "service[monit]"
end

template "/etc/monit.d/postgres" do
  source "monit-postgres.erb"
  mode "00644"
  owner "root"
  group "root"
  notifies :restart, "service[monit]"
end

template "/etc/monit.d/snmptrapd" do
  source "monit-snmptrapd.erb"
  mode "00644"
  owner "root"
  group "root"
  notifies :restart, "service[monit]"
end

template "/etc/monit.d/zabbix-server" do
  source "monit-zabbix-server.erb"
  mode "00644"
  owner "root"
  group "root"
  notifies :restart, "service[monit]"
end

template "/etc/monit.d/zabbix-agent" do
  source "monit-zabbix-agent.erb"
  mode "00644"
  owner "root"
  group "root"
  notifies :restart, "service[monit]"
end

