# == definition mongodb::mongos
define mongodb::mongos (
    $mongos_configServers,
    $mongos_instance = $name,
    $mongos_bind_ip = '',
    $mongos_port = 27017,
    $mongos_enable = true,
    $mongos_running = true,
    $mongos_logappend = true,
    $mongos_fork = true,
    $mongos_useauth = false,
    $mongos_add_options = '',
    $mongos_basedir = undef
) {
    
    if($mongos_basedir == undef) {
        $homedir = "${mongodb::params::homedir}/${mongos_instance}"
    } else {
        $homedir = "${mongos_basedir}/${mongos_instance}"
    }
    
    $datadir = "${homedir}/data"
    $logdir  = "${homedir}/log"

    $conf = {
        user        => $mongodb::params::run_as_user,
        homedir     => $homedir,
        datadir     => $datadir,
        logdir      => $logdir,
        configfile  => "/etc/mongos_${mongos_instance}.conf",
        instanceName => "${mongos_instance}"
    }

    anchor { "mongod::${mongos_instance}::files": }

    file {
        "/etc/mongos_${mongos_instance}.conf":
            content => template('mongodb/mongos.conf.erb'),
            mode    => '0644',
            # no auto restart of a db because of a config change
            #notify => Class['mongodb::service'],
            require => Anchor['mongodb::install::end'],
            before  => Anchor["mongod::${mongos_instance}::files"];

        "/etc/init/mongos_${mongos_instance}.conf":
            content => template('mongodb/mongos_upstart.conf.erb'),
            mode    => '0644',
            require => Anchor['mongodb::install::end'],
            before  => Anchor["mongod::${mongos_instance}::files"];

        "/etc/init.d/mongos_${mongos_instance}":
            ensure => 'link',
            target => "/etc/init/mongos_${mongos_instance}.conf",
            require => [ 
                File[ "/etc/init/mongos_${mongos_instance}.conf" ],
                Anchor['mongodb::install::end'],
                ],
            before  => Anchor["mongod::${mongos_instance}::files"];

        "${homedir}":
            ensure  => directory,
            mode    => '0755',
            owner   => $mongodb::params::run_as_user,
            group   => $mongodb::params::run_as_group,
            require => Anchor['mongodb::install::end'];

        "${datadir}":
            ensure  => directory,
            mode    => '0755',
            owner   => $mongodb::params::run_as_user,
            group   => $mongodb::params::run_as_group,
            require => File["${homedir}"],
            before  => Anchor["mongod::${mongos_instance}::files"];

        "${logdir}":
            ensure  => directory,
            mode    => '0755',
            owner   => $mongodb::params::run_as_user,
            group   => $mongodb::params::run_as_group,
            require => File["${homedir}"],
            before  => Anchor["mongod::${mongos_instance}::files"];
    }

    mongodb::logrotate { "mongos_${mongos_instance}_logrotate":
        instance => $mongos_instance,
        logdir   => $logdir,
        require    => Anchor["mongod::${mongos_instance}::files"]
    }

    service { "mongos_${mongos_instance}":
        ensure     => $mongos_running,
        enable     => $mongos_enable,
        hasstatus  => true,
        hasrestart => true,
        require    => Anchor["mongod::${mongos_instance}::files"],
        before     => Anchor['mongodb::end']
    }

    if ($mongos_useauth != false){
        # ATTENTION: propably not working!!
        file { "/etc/mongos_${mongos_instance}.key":
            content => template('mongodb/mongos.key.erb'),
            mode    => '0700',
            owner   => $mongodb::params::run_as_user,
            require => Anchor['mongodb::install::end'],
            notify  => Service["mongos_${mongos_instance}"],
        }
    }   
}

