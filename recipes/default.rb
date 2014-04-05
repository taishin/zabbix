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
#  include_recipe 'yum-epel'

  remote_file "#{Chef::Config[:file_cache_path]}/zabbix-release-#{node['zabbix']['version']['major']}-1.noarch.rpm" do
  	source "http://repo.zabbix.com/zabbix/#{node['zabbix']['version']['major']}/rhel/#{node[:platform_version].to_i}/#{node[:kernel][:machine]}/zabbix-release-#{node['zabbix']['version']['major']}-1.el#{node[:platform_version].to_i}.noarch.rpm"
	end

  rpm_package "zabbix-release" do
  	action :install
    source "#{Chef::Config[:file_cache_path]}/zabbix-release-#{node['zabbix']['version']['major']}-1.noarch.rpm"
  end

end
