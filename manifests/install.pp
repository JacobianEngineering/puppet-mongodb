# == Class: mongodb::install
#
#
class mongodb::install {

    $repo_class = $::osfamily ? {
        debian => mongodb::repos::apt,
        redhat => mongodb::repos::yum,
    }

    include $repo_class

    anchor { 'mongodb::install::begin': }
    anchor { 'mongodb::install::end': }

    package { 'mongodb-stable':
        ensure  => absent,
        name    => $::mongodb::params::old_server_pkg_name,
        require => Anchor['mongodb::install::begin'],
        before  => Anchor['mongodb::install::end']
    }

    user { "${mongodb::params::run_as_user}":
        comment  => "MongoDB user",
        ensure   => present,
        require  => Anchor['mongodb::install::begin'],
        before  => Anchor['mongodb::install::end']
    }

    group { "${mongodb::params::run_as_group}":
        ensure   => present,
        require  => Anchor['mongodb::install::begin'],
        before  => Anchor['mongodb::install::end']
    }

    file { '/etc/default/mongodb':
        content => 'ENABLE_MONGODB=NO',
        ensure  => present,
        require => Anchor['mongodb::install::begin']
    }

    file { "${mongodb::params::homedir}":
        ensure  => directory,
        mode    => 755,
        owner   => $mongodb::params::run_as_user,
        group   => $mongodb::params::run_as_group,
        require => Anchor['mongodb::install::begin'],
        before  => Anchor['mongodb::install::end']
    }

    package { 'mongodb-10gen':
        ensure => $mongodb::params::version,
        require => [File['/etc/default/mongodb'], Package['mongodb-stable'], Class[$repo_class]],
        before => Anchor['mongodb::install::end']
    }
}
