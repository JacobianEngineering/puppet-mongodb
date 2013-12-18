

define mongodb::logrotate($instance, $logdir) {

  if ! defined(Package['logrotate']) {
    package { 'logrotate':
      ensure => installed;
    }
  }

  file { "/etc/logrotate.d/mongodb_${instance}":
    content    => template('mongodb/logrotate.conf.erb'),
    require    => [Package['logrotate']],
  }

}
