# == definition mongodb::mongod
define mongodb::mongod (
    $mongod_instance = $name,
    $mongod_bind_ip = '',
    $mongod_port = 27017,
    $mongod_replSet = '',
    $mongod_enable = true,
    $mongod_running = true,
    $mongod_configsvr = false,
    $mongod_shardsvr = false,
    $mongod_logappend = true,
    $mongod_rest = true,
    $mongod_fork = true,
    $mongod_auth = false,
    $mongod_useauth = false,
    $mongod_monit = false,
    $mongod_add_options = '',
    $mongod_basedir = undef
) {

    # REVIEW: if not included specs won't get variables from the class, exp: $mongodb::params::homedir = null
    include mongodb::params

    if($mongod_basedir == undef) {
        $homedir = "${mongodb::params::homedir}/${mongod_instance}"
    } else {
        $homedir = "${mongd_basedir}/${mongod_instance}"
    }
    
    $datadir = "${homedir}/data"
    $logdir  = "${homedir}/log"

    $conf = {
        user        => $mongodb::params::run_as_user,
        homedir     => $homedir,
        datadir     => $dbdir,
        logdir      => $logdir,
        configfile  => "/etc/mongod_${mongod_instance}.conf"
    }

    anchor { "mongod::${mongod_instance}::files": }

    file {
        "/etc/mongod_${mongod_instance}.conf":
            content => template('mongodb/mongod.conf.erb'),
            mode    => '0644',
            # no auto restart of a db because of a config change
            #notify => Class['mongodb::service'],
            require => Anchor['mongodb::install::end'],
            before  => Anchor["mongod::${mongod_instance}::files"];

        "/etc/init/mongod_${mongod_instance}.conf":
            content => template('mongodb/mongod_upstart.conf.erb'),
            mode    => '0644',
            require => Anchor['mongodb::install::end'],
            before  => Anchor["mongod::${mongod_instance}::files"];

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
            before  => Anchor["mongod::${mongod_instance}::files"];

        "${logdir}":
            ensure  => directory,
            mode    => '0755',
            owner   => $mongodb::params::run_as_user,
            group   => $mongodb::params::run_as_group,
            require => File["${homedir}"],
            before  => Anchor["mongod::${mongod_instance}::files"];
    }

    mongodb::logrotate { "mongod_${mongod_instance}_logrotate":
        instance => $mongod_instance,
        logdir   => $logdir
    }

    service { "mongod_${mongod_instance}":
        ensure     => $mongod_running,
        enable     => $mongod_enable,
        hasstatus  => true,
        hasrestart => true,
        require    => Anchor["mongod::${mongod_instance}::files"],
        before     => Anchor['mongodb::end']
    }


    if ($mongod_monit != false){
        # ATTENTION: propably not working!!
        #notify { "mongod_monit is : ${mongod_monit}": }
        class { 'mongodb::monit':
            instance_name => $mongod_instance,
            instance_port => $mongod_port,
            require       => Anchor['mongodb::install::end'],
            before        => Anchor['mongodb::end'],
        }
    }

    if ($mongod_useauth != false){
        # ATTENTION: propably not working!!
        file { "/etc/mongod_${mongod_instance}.key":
            content => template('mongodb/mongod.key.erb'),
            mode    => '0700',
            owner   => $mongodb::params::run_as_user,
            require => Anchor['mongodb::install::end'],
            notify  => Service["mongod_${mongod_instance}"],
        }
    }


}
