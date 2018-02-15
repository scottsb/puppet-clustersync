class clustersync (
  $sources,
  $logdir_owner    = 'root',
  $logdir_group    = 'root',
  $logdir_mode     = '0644',
  $csync_port      = '30865',
  $csync_only_from = '10.0.0.0/8 172.16.0.0/12 192.168.0.0/16',
  $lsyncd_template = 'clustersync/lsyncd-csync2.conf.erb'
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
    config_content => template($lsyncd_template),
    logdir_owner   => $logdir_owner,
    logdir_group   => $logdir_group,
    logdir_mode    => $logdir_mode,
    require        => File[keys($sources)],
  }

  Csync2::Key <| |> -> Csync2::Cfg <| |> ~> Service['xinetd']
  Csync2::Cfg <| |> -> Class['lsyncd']

}
