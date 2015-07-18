# scottsb-clustersync

## Overview

This module allows you to easily combine [lsyncd](https://code.google.com/p/lsyncd/) with
[csync2](http://oss.linbit.com/csync2/) to sync files across a set of servers. Lsyncd
watches the file system, triggering csync2 on a change, which then copies the files out
to the other machines. Csync2 supports multiple servers (not just a pair), intelligently
handling conflicts and file deletions.

This solution works well for any number of files (into
the [tens of millions](http://lists.linbit.com/pipermail/csync2/2014-October/001077.html)),
but it does not work well for files that change frequently. For this you need a
distributed filesystem like GlusterFS.

The core functionality is provided by [Matthias Saou's](http://matthias.saou.eu/) modules
thias-lsyncd and thias-csync2. This module simply serves as a convenience wrapper (which
Matthew left as an [exercise for the reader](http://thias.marmotte.net/2013/04/puppet-all-way-near-realtime-file-syncronization/)).
The primary benefits are:

* Streamlined syntax.
* No need to repeat sync directories for both lsyncd and csync2.


## Usage

There must be **one** `clustersync` declaration and **one or more**
`clustersync::serverset` declarations.

### clustersync

The `clustersync` class defines all directories that need to be synced as well as global
options for the csync2 and lsyncd daemons. Parameters:

* `sources`: hash where the key is a path to sync and the value is the name of a `serverset` declaration
* `logdir_owner`: lsyncd log file owner
* `logdir_group`: lsyncd log file group
* `logdir_mode`: lsyncd log file permissions
* `csync_port`: port csync2 will listen on
* `csync_only_from`: IPs csync2 will accept connections from (CIDR notation)
* `lsyncd_template`: override of lsyncd config template

**Note:** This module assumes that you have a `file` resource declared for each of the
`sources` keys. The `file` resource should have the same name as the path.

### clustersync::serverset

The `clustersync::serverset` resource matches up to one or more values from the `sources`
hash in the `clustersync` declaration. It specifies the servers that the indicated
directory will be synced to. Parameters:

* `servers`: array of hosts to sync with*
* `key_source`: path to the pre-shared key (mutually exclusive with `key_content`)**
* `key_content`: content of the pre-shared key (mutually exclusive with `key_source`)
* `csync2_template`: override of csync2 config template 

\* Hostnames must match the output of the `hostname` command. An IP address may
optionally be specified in addition using the syntax `hostname@ipaddress`.<br>
\** A pre-shared key can be generated with the command `csync2 -k filename`.


## Example

	# Set up source directories.
	file { [
	  '/var/uploads',
	  '/etc/serverd',
	]:
	  ensure => directory,
	}
	
	# Set up the automatic sync of dynamically uploaded files.
	class { 'clustersync':
	  sources         => {
	    '/var/uploads' => 'uploads',
	    '/etc/serverd' => 'serverd',
	  },
	  csync_only_from => '10.0.100.0/24 10.0.200.0/24'
	}
	clustersync::serverset { 'uploads':
	  servers => [
	    'foo.example.net@10.0.100.1',
	    'bar.example.net@10.0.100.2',
	    'baz.example.net@10.0.100.3',
	  ],
	  key_source => 'puppet:///mnt/csync2_uploads.key'
	}
	clustersync::serverset { 'serverd':
	  servers => [
	    'barium.example.net',
	    'sodium.example.net',
	  ],
	  key_source => 'puppet:///mnt/csync2_serverd.key'
	}


## Limitations

This module has only been tested with RHEL 6.5, though it should work on any Linux
distributions that include both csync2 and lsyncd in their package managers. Most
OS-specific support will fall to the underlying thias-lsyncd and thias-csync2 modules,
but if you experience distro-specific issues, raise them on GitHub.

## Adding Server to Existing Cluster

Because csync2 is push-only, when you add a new server to the cluster, it will not
automatically receive files from the existing servers since the original servers don't
consider them "dirty." You can force a sync by running the following commands from
one of the original servers (this assumes all original servers are in sync and that
the new servers are already successfully added to the cluster):

	csync2 -TUXI
	csync2 -u

See detailed discussion here:
http://lists.linbit.com/pipermail/csync2/2012-May/000873.html

## TODO

These are known areas that need to be improved:

* Add automated testing beyond just syntax check.
* Decouple from thias-xinetd so that any xinetd module can be used.
* Enforcement of option types and mutually exclusive options.
