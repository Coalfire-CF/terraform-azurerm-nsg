# Catalog of predefined rules. Callers pick entries by name in var.predefined_rules.
# Source and destination addresses come from the caller, never from this catalog.
locals {
  rule_catalog = {

    #Nessus
    SSHfromBurp = { direction = "Inbound", access = "Allow", protocol = "Tcp", ports = ["22"], description = "SSHfromBurp" }
    WMIfromBurp = { direction = "Inbound", access = "Allow", protocol = "Tcp", ports = ["445", "139"], description = "WMIfromBurp" }

    #Tower
    TowerLinux   = { direction = "Inbound", access = "Allow", protocol = "Tcp", ports = ["22"], description = "TowerLinux" }
    TowerWindows = { direction = "Inbound", access = "Allow", protocol = "Tcp", ports = ["5985-5986"], description = "TowerWindows" }

    #ActiveDirectory
    ActiveDirectory-AllowADReplication          = { direction = "Inbound", access = "Allow", protocol = "*", ports = ["389"], description = "AllowADReplication" }
    ActiveDirectory-AllowADReplicationSSL       = { direction = "Inbound", access = "Allow", protocol = "*", ports = ["636"], description = "AllowADReplicationSSL" }
    ActiveDirectory-AllowADGCReplication        = { direction = "Inbound", access = "Allow", protocol = "Tcp", ports = ["3268"], description = "AllowADGCReplication" }
    ActiveDirectory-AllowADGCReplicationSSL     = { direction = "Inbound", access = "Allow", protocol = "Tcp", ports = ["3269"], description = "AllowADGCReplicationSSL" }
    ActiveDirectory-AllowDNS                    = { direction = "Inbound", access = "Allow", protocol = "*", ports = ["53"], description = "AllowDNS" }
    ActiveDirectory-AllowKerberosAuthentication = { direction = "Inbound", access = "Allow", protocol = "*", ports = ["88"], description = "AllowKerberosAuthentication" }
    ActiveDirectory-AllowADReplicationTrust     = { direction = "Inbound", access = "Allow", protocol = "*", ports = ["445"], description = "AllowADReplicationTrust" }
    ActiveDirectory-AllowSMTPReplication        = { direction = "Inbound", access = "Allow", protocol = "Tcp", ports = ["25"], description = "AllowSMTPReplication" }
    ActiveDirectory-AllowRPCReplication         = { direction = "Inbound", access = "Allow", protocol = "Tcp", ports = ["135"], description = "AllowRPCReplication" }
    ActiveDirectory-AllowFileReplication        = { direction = "Inbound", access = "Allow", protocol = "Tcp", ports = ["5722"], description = "AllowFileReplication" }
    ActiveDirectory-AllowWindowsTime            = { direction = "Inbound", access = "Allow", protocol = "Udp", ports = ["123"], description = "AllowWindowsTime" }
    ActiveDirectory-AllowPasswordChangeKerberes = { direction = "Inbound", access = "Allow", protocol = "*", ports = ["464"], description = "AllowPasswordChangeKerberes" }
    ActiveDirectory-AllowDFSGroupPolicy         = { direction = "Inbound", access = "Allow", protocol = "Udp", ports = ["138"], description = "AllowDFSGroupPolicy" }
    ActiveDirectory-AllowADDSWebServices        = { direction = "Inbound", access = "Allow", protocol = "Tcp", ports = ["9389"], description = "AllowADDSWebServices" }
    ActiveDirectory-AllowNETBIOSAuthentication  = { direction = "Inbound", access = "Allow", protocol = "Udp", ports = ["137"], description = "AllowNETBIOSAuthentication" }
    ActiveDirectory-AllowNETBIOSReplication     = { direction = "Inbound", access = "Allow", protocol = "Tcp", ports = ["139"], description = "AllowNETBIOSReplication" }

    #Cassandra
    Cassandra = { direction = "Inbound", access = "Allow", protocol = "Tcp", ports = ["9042"], description = "Cassandra" }

    #Cassandra-JMX
    Cassandra-JMX = { direction = "Inbound", access = "Allow", protocol = "Tcp", ports = ["7199"], description = "Cassandra-JMX" }

    #Cassandra-Thrift
    Cassandra-Thrift = { direction = "Inbound", access = "Allow", protocol = "Tcp", ports = ["9160"], description = "Cassandra-Thrift" }

    #CouchDB
    CouchDB = { direction = "Inbound", access = "Allow", protocol = "Tcp", ports = ["5984"], description = "CouchDB" }

    #CouchDB-HTTPS
    CouchDB-HTTPS = { direction = "Inbound", access = "Allow", protocol = "Tcp", ports = ["6984"], description = "CouchDB-HTTPS" }

    #DNS-TCP
    DNS-TCP = { direction = "Inbound", access = "Allow", protocol = "Tcp", ports = ["53"], description = "DNS-TCP" }

    #DNS-UDP
    DNS-UDP = { direction = "Inbound", access = "Allow", protocol = "Udp", ports = ["53"], description = "DNS-UDP" }

    #DynamicPorts
    DynamicPorts = { direction = "Inbound", access = "Allow", protocol = "Tcp", ports = ["49152-65535"], description = "DynamicPorts" }

    #ElasticSearch
    ElasticSearch = { direction = "Inbound", access = "Allow", protocol = "Tcp", ports = ["9200-9300"], description = "ElasticSearch" }

    #FTP
    FTP = { direction = "Inbound", access = "Allow", protocol = "Tcp", ports = ["21"], description = "FTP" }

    #HTTP
    HTTP = { direction = "Inbound", access = "Allow", protocol = "Tcp", ports = ["80"], description = "HTTP" }

    #HTTPS
    HTTPS = { direction = "Inbound", access = "Allow", protocol = "Tcp", ports = ["443"], description = "HTTPS" }

    #IMAP
    IMAP = { direction = "Inbound", access = "Allow", protocol = "Tcp", ports = ["143"], description = "IMAP" }

    #IMAPS
    IMAPS = { direction = "Inbound", access = "Allow", protocol = "Tcp", ports = ["993"], description = "IMAPS" }

    #Kestrel
    Kestrel = { direction = "Inbound", access = "Allow", protocol = "Tcp", ports = ["22133"], description = "Kestrel" }

    #LDAP
    LDAP = { direction = "Inbound", access = "Allow", protocol = "Tcp", ports = ["389"], description = "LDAP" }

    #MongoDB
    MongoDB = { direction = "Inbound", access = "Allow", protocol = "Tcp", ports = ["27017"], description = "MongoDB" }

    #Memcached
    Memcached = { direction = "Inbound", access = "Allow", protocol = "Tcp", ports = ["11211"], description = "Memcached" }

    #MSSQL
    MSSQL = { direction = "Inbound", access = "Allow", protocol = "Tcp", ports = ["1433"], description = "MSSQL" }

    #MySQL
    MySQL = { direction = "Inbound", access = "Allow", protocol = "Tcp", ports = ["3306"], description = "MySQL" }

    #Neo4J
    Neo4J = { direction = "Inbound", access = "Allow", protocol = "Tcp", ports = ["7474"], description = "Neo4J" }

    #POP3
    POP3 = { direction = "Inbound", access = "Allow", protocol = "Tcp", ports = ["110"], description = "POP3" }

    #POP3S
    POP3S = { direction = "Inbound", access = "Allow", protocol = "Tcp", ports = ["995"], description = "POP3S" }

    #PostgreSQL
    PostgreSQL = { direction = "Inbound", access = "Allow", protocol = "Tcp", ports = ["5432"], description = "PostgreSQL" }

    #RabbitMQ
    RabbitMQ = { direction = "Inbound", access = "Allow", protocol = "Tcp", ports = ["5672"], description = "RabbitMQ" }

    #RDP
    RDP = { direction = "Inbound", access = "Allow", protocol = "Tcp", ports = ["3389"], description = "RDP" }

    #Redis
    Redis = { direction = "Inbound", access = "Allow", protocol = "Tcp", ports = ["6379"], description = "Redis" }

    #Riak
    Riak = { direction = "Inbound", access = "Allow", protocol = "Tcp", ports = ["8093"], description = "Riak" }

    #Riak-JMX
    Riak-JMX = { direction = "Inbound", access = "Allow", protocol = "Tcp", ports = ["8985"], description = "Riak-JMX" }

    #SMTP
    SMTP = { direction = "Inbound", access = "Allow", protocol = "Tcp", ports = ["25"], description = "SMTP" }

    #SMTPS
    SMTPS = { direction = "Inbound", access = "Allow", protocol = "Tcp", ports = ["465"], description = "SMTPS" }

    #SSH
    SSH = { direction = "Inbound", access = "Allow", protocol = "Tcp", ports = ["22"], description = "SSH" }

    #WinRM
    WinRM = { direction = "Inbound", access = "Allow", protocol = "Tcp", ports = ["5986"], description = "WinRM" }
  }
}
