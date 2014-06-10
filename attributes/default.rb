default['zabbix']['version']['major'] = "2.2"
# default['zabbix']['version']['full'] = "2.2.0-1"
default['zabbix']['packages'] = %w{
	zabbix
	zabbix-agent
	zabbix-sender
}

default['zabbix']['agent']['serverip'] = "127.0.0.1"



default['zabbix']['server']['packages'] = %w{
	zabbix-get
	zabbix-server-pgsql
	zabbix-web
	zabbix-web-japanese
	zabbix-web-pgsql
}


default['zabbix']['other']['packages']['rhel'] = %w{
  system-config-network-tui
}

default['zabbix']['other']['packages'] = %w{
	git
	crontabs
	ntp
	tcpdump
	telnet
	vim-enhanced
	bind-utils
	man
	postgresql-server
	mlocate
	zlib-devel
	gcc
	make
	zip
	libyaml
	libxslt-devel
	libxml2-devel
}

default['zabbix']['server']['gems'] = %w{
	zbxapi
	zipruby
}

default['zabbix']['snmp']['packages'] = %w{
        snmptt
        net-snmp-utils
        net-snmp-perl
}

default['zabbix']['snmp']['mibpath'] = "/usr/share/snmp/mibs"

default['zabbix']['java']['packages'] = %w{
        zabbix-java-gateway
}

default['zabbix']['proxy']['packages'] = %w{
	zabbix-get
        zabbix-proxy-pgsql
}

default['zabbix']['full']['packages'] = %w{
        monit
}

default['zabbix']['full']['gems'] = %w{
	nokogiri
	thinreports
	mail
}

default['ntp']['servers'] = %w{ntp.nict.jp}
case platform
  when "redhat", "centos", "fedora"
    default['ntp']['service'] = "ntpd"
  when "ubuntu"
    default['ntp']['service'] = "ntp"
end

default['monit']['mailserver'] = "localhost"
default['monit']['fromaddress'] = "from@example.com"
default['monit']['toaddress'] = %w{
	test1@example.com
	test2@example.com
}
