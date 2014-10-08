class clustersync (
  $sources         = {},
  $logdir_owner    = undef,
  $logdir_group    = undef,
  $logdir_mode     = undef,
  $csync_port      = undef,
  $csync_only_from = undef
) {

  # Make sure csync2 is set up.
  class { 'csync2':
    xinetd    => true,
    port      => $csync_port,
    only_from => $csync_only_from,
  }

  # Set up lsyncd daemon to watch the uploaded files for modification. When a change
  # is detected, it will trigger csync2 to transfer the changes to the other nodes.
  class { 'lsyncd':
    config_content => template('clustersync/lsyncd-csync2.conf.erb'),
    logdir_owner   => $logdir_owner,
    logdir_group   => $logdir_group,
    logdir_mode    => $logdir_mode,
    require        => File[keys($sources)],
  }

  Csync2::Key <| |> -> Csync2::Cfg <| |> ~> Service['xinetd']
  Csync2::Cfg <| |> -> Class['lsyncd']

}
