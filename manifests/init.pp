class nginxpuppet {

include apt

file {'/tmp/server.crt':
  ensure => present,
  mode => '0644',
  source => 'puppet:///modules/nginxpuppet/server.crt',
}


file {'/tmp/server.pem':
  ensure => present,
  mode => '0644',
  source => 'puppet:///modules/nginxpuppet/server.pem',
}


package { 'dirmngr':
  ensure => installed,
}

package { 'tinyproxy':
  ensure => absent,
  
}


class { 'apache':
  default_vhost => false,
}




apache::vhost { 'forward_proxy':
  port    => '8888',
  docroot => '/var/www/vhost',
  access_log_format => customlog,
  custom_fragment => 'LogFormat "{ \"time\":\"%t\", \"remoteIP\":\"%a\", \"host\":\"%V\", \"request\":\"%U\", \"query\":\"%q\", \"method\":\"%m\", \"status\":\"%>s\", \"userAgent\":\"%{User-agent}i\", \"referer\":\"%{Referer}i\" }" customlog
  ProxyRequests On
  ProxyVia On
  '
}

class { 'apache::mod::proxy':
proxy_requests => 'On',
allow_from => '10.128.0.54',
}
class { 'apache::mod::proxy_http': }
class { 'apache::mod::proxy_connect': }



class{'nginx': }

nginx::resource::server{'www.domain.com':
  ensure => present,
  www_root => '/opt/html/',
  ssl => true,
  listen_port => 443,
  ssl_port => 443,
  ssl_cert => '/tmp/server.crt',
  ssl_key => '/tmp/server.pem',
  use_default_location => false,
}


nginx::resource::location{'/':
  proxy => 'https://20.20.20.20/' ,
  server => 'www.domain.com',
  ssl => true,
  ssl_only => true,
}

nginx::resource::location{'/resources':
  proxy => 'https://10.10.10.10/' ,
  server => 'www.domain.com',
  ssl => true,
  ssl_only => true,
}

}

