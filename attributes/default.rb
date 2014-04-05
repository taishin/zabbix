default['zabbix']['version']['major'] = "2.2"
default['zabbix']['version']['full'] = "2.2.0-1"
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

default['zabbix']['other']['packages'] = %w{
	git
	snmptt
	crontabs
	net-snmp-utils
	net-snmp-perl
	ntp
	tcpdump
	telnet
	vim-enhanced
	bind-utils
	man
	postgresql-server
}


