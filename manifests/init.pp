# @summary
#   Installs the gitlab service as a omnibus installation with backup assistance
#
class omnibus (
  $primary_domain,
  $ensure = present,
) {

  [$ensure_ssl, $privkey, $fullchain ] = baseline::get_server_certificate($primary_domain)
  $external_url = $ensure_ssl ? {
    present => "https://${primary_domain}",
    default => "http://${primary_domain}",
  }

  # Make sure we get the same system uid for the 'git' user to
  group { 'git':
    gid => 995,
  }
  -> user { 'git':
    uid    => 995,
    gid    => 995,
    home   => '/var/opt/gitlab',
    system => true,
    shell  => '/usr/sbin/nologin',
  }
  -> class {'gitlab':
    external_url => $external_url,
    nginx        => {
      redirect_http_to_https => ($ensure_ssl == present),
    },
  }

  # add a backup helper script to list the latest backup
  file { "/usr/local/bin/${baseline::scriptprefix}-gitlab-backup-list":
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0700',
    content => template("omnibus/gitlab-backup-list.bash.erb"),
  }
}