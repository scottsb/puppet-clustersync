define clustersync::serverset (
  $servers,
  $key_source   = undef,
  $key_content  = undef,
  $csync2_template = 'clustersync/csync2_serverset.cfg.erb'
) {

  $source_paths = keys($clustersync::sources)

  csync2::cfg { $title :
    content => template($csync2_template),
  }

  csync2::key { $title :
    source  => $key_source,
    content => $key_content,
  }

}
