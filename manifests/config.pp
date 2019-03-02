# == Class hitch::config
#
# This class is called from hitch for service config.
#
class hitch::config {

  validate_absolute_path($::hitch::config_root)
  validate_absolute_path($::hitch::config_file)
  validate_absolute_path($::hitch::dhparams_file)

  if $::hitch::dhparams_content {
    validate_re($::hitch::dhparams_content, 'BEGIN DH PARAMETERS')
  }

  file { $::hitch::config_root:
    ensure  => directory,
    recurse => true,
    purge   => $::hitch::purge_config_root,
    owner   => $::hitch::file_owner,
    group   => $::hitch::group,
    mode    => '0750',
  }

  concat { $::hitch::config_file:
    ensure => present,
  }

  if $::hitch::dhparams_content {
    file { $::hitch::dhparams_file:
      ensure  => present,
      owner   => $::hitch::file_owner,
      group   => $::hitch::group,
      mode    => '0640',
      content => $::hitch::dhparams_content,
    }
  }
  else {
    exec { "${title} generate dhparams":
      path    => '/usr/local/bin:/usr/bin:/bin',
      command => "openssl dhparam 2048 -out ${::hitch::dhparams_file}",
      creates => $::hitch::dhparams_file,
    }
    
    -> file { $::hitch::dhparams_file:
      ensure => present,
      owner  => $::hitch::file_owner,
      group  => $::hitch::group,
      mode   => '0640',
    }
  }

  concat::fragment { "${title} config":
    content => template('hitch/hitch.conf.erb'),
    target  => $::hitch::config_file,
  }

  create_resources('hitch::domain', $::hitch::domains)
}
