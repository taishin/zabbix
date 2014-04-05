#
# Cookbook Name:: zabbix
# Recipe:: default
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
case node[:platform]
when "redhat", "centos", "fedora"

	remote_file "#{Chef::Config[:file_cache_path]}/epel-release.noarch.rpm" do
  	source "http://dl.fedoraproject.org/pub/epel/#{node[:platform_version].to_i}/#{node[:kernel][:machine]}/epel-release-#{node[:platform_version].to_i}-8.noarch.rpm"
	end

	rpm_package "epel-release" do
  	action :install
  	source "#{Chef::Config[:file_cache_path]}/epel-release.noarch.rpm"
	end

  remote_file "#{Chef::Config[:file_cache_path]}/zabbix-release-#{node['zabbix']['version']['major']}-1.noarch.rpm" do
  	source "http://repo.zabbix.com/zabbix/#{node['zabbix']['version']['major']}/rhel/#{node[:platform_version].to_i}/#{node[:kernel][:machine]}/zabbix-release-#{node['zabbix']['version']['major']}-1.el#{node[:platform_version].to_i}.noarch.rpm"
	end

  rpm_package "zabbix-release" do
  	action :install
    source "#{Chef::Config[:file_cache_path]}/zabbix-release-#{node['zabbix']['version']['major']}-1.noarch.rpm"
  end
end

node['zabbix']['packages'].each do |pkg|
  package pkg do
    if node['zabbix']['version']['full']
      version "#{node['zabbix']['version']['full']}.el#{node[:platform_version].to_i}"
    end
    action :install
  end
end

template "/etc/zabbix/zabbix_agentd.conf" do
  source "zabbix_agentd.conf.erb"
  owner "root"
  notifies :restart, "service[zabbix-agent]"
  mode 0644
end

service "zabbix-agent" do
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
end