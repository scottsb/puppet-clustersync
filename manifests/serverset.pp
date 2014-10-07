define clustersync::serverset (
  $servers      = {},
  $cfg_template = 'clustersync/csync2_serverset.cfg.erb',
  $key_source   = undef,
  $key_content  = undef
) {

  $source_paths = values($clustersync::sources)

  csync2::cfg { $title :
    content => template($cfg_template),
  }

  csync2::key { $title :
    source  => $key_source,
    content => $key_content,
  }

}
