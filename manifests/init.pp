class nginxpuppet (

$allow_from_ip_range = $::nginxpuppet::params::allow_from_ip_range,
$ssl_certs_dir = $::nginxpuppet::params::ssl_certs_dir,
$forward_proxy_port = $::nginxpuppet::params::forward_proxy_port,
$domain = $::nginxpuppet::params::domain,

) inherits ::nginxpuppet::params
{

include apt

host {$domain:
ensure => present,
ip => '127.0.0.1',
}

exec {'create_self_signed_sslcert':
  command => "openssl req -newkey rsa:2048 -nodes -keyout ${::fqdn}.key  -x509 -days 365 -out ${::fqdn}.crt -subj '/CN=${::fqdn}'",
  cwd     => $ssl_certs_dir,
  creates => [ "${ssl_certs_dir}/${::fqdn}.key", "${ssl_certs_dir}/${::fqdn}.crt", ],
  path    => ["/usr/bin", "/usr/sbin"]
}


package { 'dirmngr':
  ensure => installed,
}


class { 'apache':
  default_vhost => false,
}


apache::vhost { 'forward_proxy':
  port    => $forward_proxy_port,
  docroot => '/var/www/vhost',
  access_log_format => customlog,
  custom_fragment => 'LogFormat "{ \"time\":\"%t\", \"clientIP\":\"%a\", \"host\":\"%V\", \"remoteIP\":\"%h\" , \"request\":\"%U\", \"query\":\"%q\", \"method\":\"%m\", \"status\":\"%>s\", \"userAgent\":\"%{User-agent}i\", \"referer\":\"%{Referer}i\", \"processTime\":\"%D\" }" customlog
  ProxyRequests On
  ProxyVia On
  '
}

class { 'apache::mod::proxy':
proxy_requests => 'On',
allow_from => $allow_from_ip_range,
}
class { 'apache::mod::proxy_http': }
class { 'apache::mod::proxy_connect': }



class{'nginx': }

nginx::resource::server{$domain:
  ensure => present,
  www_root => '/opt/html/',
  ssl => true,
  listen_port => 443,
  ssl_port => 443,
  ssl_cert => "${ssl_certs_dir}/${::fqdn}.crt",
  ssl_key => "${ssl_certs_dir}/${::fqdn}.key",
  use_default_location => false,
}


nginx::resource::location{'/':
  proxy => 'https://20.20.20.20/' ,
  server => $domain,
  ssl => true,
  ssl_only => true,
}

nginx::resource::location{'/resources':
  proxy => 'https://10.10.10.10/' ,
  server => $domain,
  ssl => true,
  ssl_only => true,
}

}

