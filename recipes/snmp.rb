#
# Cookbook Name:: zabbix
# Recipe:: server
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
node['zabbix']['snmp']['packages'].each do |pkg|
  package pkg do
    action :install
    options "--enablerepo=epel"
  end
end

if node[:platform] != 'amazon' then
  package "snmptt" do
    action :install
  end
end
  

git "#{node['zabbix']['snmp']['mibpath']}/vendor_mibs" do
	repository "https://github.com/taishin/vendor_mibs.git"
	reference "master"
	action :checkout
end


bash "create snmptt.conf for vendor mibs" do
	code <<-EOC
	  CONF=/etc/snmp/snmptt.conf.vendors
	  TMPFILE=#{Chef::Config[:file_cache_path]}/snmptt.conf.vendors.tmp
	  MIBDIR=#{node['zabbix']['snmp']['mibpath']}/vendor_mibs
	  for file in $( ls $MIBDIR ); do
	    /usr/bin/snmpttconvertmib --in=$MIBDIR\/$file \
	    --out=$TMPFILE \
	    --net_snmp_perl
	  done
	  sed -e "s/^FORMAT\s/FORMAT ZBXTRAP \\$aA /g" $TMPFILE > $CONF
	  rm $TMPFILE
	EOC
  not_if { ::FileTest.exist?("/etc/snmp/snmptt.conf.vendors") }
  notifies :restart, "service[snmptt]"
end

template "/etc/snmp/snmptrapd.conf" do
  source "snmptrapd.conf.erb"
  owner "root"
  notifies :restart, "service[snmptrapd]"
  mode 0644
end

template "/etc/sysconfig/snmptrapd" do
  source "snmptrapd.erb"
  owner "root"
  notifies :restart, "service[snmptrapd]"
  mode 0644
end

template "/etc/snmp/snmptt.conf" do
  source "snmptt.conf.erb"
  owner "root"
  notifies :restart, "service[snmptt]"
  mode 0644
end

template "/etc/snmp/snmptt.ini" do
  source "snmptt.ini.erb"
  owner "root"
  notifies :restart, "service[snmptt]"
  mode 0644
end

template "/etc/snmp/snmp.conf" do
  source "snmp.conf.erb"
  owner "root"
  mode 0644
end

service "snmptrapd" do
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
end

service "snmptt" do
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
end
