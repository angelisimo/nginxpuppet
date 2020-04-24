# nginxproxy

#### Table of Contents

1. [Description](#description)
2. [Setup](#setup)
    * [Module dependencies](#dependencies)
3. [Usage](#usage)
4. [Development](#development)

## Description
Puppet Asset to devops position

* Create a proxy to redirect requests for https://domain.com to 10.10.10.10 and redirect requests for https://domain.com/resource to 20.20.20.20.
* Create a forward proxy to log HTTP requests going from the internal network to the Internet including: request protocol, remote IP and time take to serve the request.

## Setup

### Dependencies

* Puppet 4.6.1 or later.
* puppetlabs/apt module for debian systems
* puppetlabs/apache module
* puppet/nginx module

## Usage

Clone repository and set it in the modules directory of your puppet installation.
Then include the modude in the node you want to set up the configuration described in the description.
```puppet
node default {
include nginxpuppet
}
```

Modify nginxpuppet/params.pp with the parameters you need
```puppet
$allow_from_ip_range = '10.128.0'
$ssl_certs_dir = '/tmp/'
$forward_proxy_port = '8888'
$domain = 'domain.com'
```



## Development

I've decided to use nginx as a reverse proxy to fullfill the requeriments of "domain.com" redirected to IP and Apache as the forward proxy. The comments in the code section clarify each section,
```puppet
class nginxpuppet (
#parameters defined in params.pp
$allow_from_ip_range = $::nginxpuppet::params::allow_from_ip_range,
$ssl_certs_dir = $::nginxpuppet::params::ssl_certs_dir,
$forward_proxy_port = $::nginxpuppet::params::forward_proxy_port,
$domain = $::nginxpuppet::params::domain,

) inherits ::nginxpuppet::params
{
#for debian systems
include apt

package { 'dirmngr':
  ensure => installed,
}


#host poison for local testing 
host {$domain:
ensure => present,
ip => '127.0.0.1',
}

#create ss certificate
exec {'create_self_signed_sslcert':
  command => "openssl req -newkey rsa:2048 -nodes -keyout ${::fqdn}.key  -x509 -days 365 -out ${::fqdn}.crt -subj '/CN=${::fqdn}'",
  cwd     => $ssl_certs_dir,
  creates => [ "${ssl_certs_dir}/${::fqdn}.key", "${ssl_certs_dir}/${::fqdn}.crt", ],
  path    => ["/usr/bin", "/usr/sbin"]
}

#apache webserver
class { 'apache':
  default_vhost => false,
}

#Forward proxy, with custom logging format whcih will log in the access log with a json format
apache::vhost { 'forward_proxy':
  port    => $forward_proxy_port,
  docroot => '/var/www/vhost',
  access_log_format => customlog,
  custom_fragment => 'LogFormat "{ \"time\":\"%t\", \"clientIP\":\"%a\", \"host\":\"%V\", \"remoteIP\":\"%h\" , \"request\":\"%U\", \"query\":\"%q\", \"method\":\"%m\", \"status\":\"%>s\", \"userAgent\":\"%{User-agent}i\", \"referer\":\"%{Referer}i\", \"processTime\":\"%D\" }" customlog
  ProxyRequests On
  ProxyVia On
  '
}

#Apache plugins necessaries for proxy forwarding
class { 'apache::mod::proxy':
proxy_requests => 'On',
allow_from => $allow_from_ip_range,
}
class { 'apache::mod::proxy_http': }
class { 'apache::mod::proxy_connect': }


#Reverse Proxy
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

#locations for redirections
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

```







