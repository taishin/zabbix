#
# Cookbook Name:: zabbix
# Recipe:: server
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
node['zabbix']['java']['packages'].each do |pkg|
  package pkg do
    if node['zabbix']['version']['full']
      version "#{node['zabbix']['version']['full']}.el#{node[:platform_version].to_i}"
    end
    action :install
  end
end

template "/etc/zabbix/zabbix_java_gateway.conf" do
  source "zabbix_java_gateway.conf.erb"
  owner "root"
  notifies :restart, "service[zabbix-java-gateway]"
  mode 0644
end

service "zabbix-java-gateway" do
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
end


