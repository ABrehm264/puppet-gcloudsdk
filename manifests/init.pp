# Class: gcloudsdk
#
# This module manages gcloudsdk
#
# Parameters: none
#
# Actions:
#
# Requires: see Modulefile
#
# Sample Usage:
#
class gcloudsdk (
  $version = $::gcloudsdk::params::version, 
  $install_dir = $::gcloudsdk::params::install_dir,
  $is_install_gcloud = $::gcloudsdk::params::is_install_gcloud,
  $is_install_gsutil = $::gcloudsdk::params::is_install_gsutil,
  $is_install_core = $::gcloudsdk::params::is_install_core,
  $is_install_bq = $::gcloudsdk::params::is_install_bq,
  $is_install_kubectl = $::gcloudsdk::params::is_install_kubectl,
  $is_install_app_engine_python = $::gcloudsdk::params::is_install_app_engine_python,
  $is_install_app_engine_java = $::gcloudsdk::params::is_install_app_engine_java,
  $is_install_beta = $::gcloudsdk::params::is_install_beta,
  $is_install_alpha = $::gcloudsdk::params::is_install_alpha,
  $is_install_pubsub_emulator = $::gcloudsdk::params::is_install_pubsub_emulator,
  $is_install_gcd_emulator = $::gcloudsdk::params::is_install_gcd_emulator,
  ) inherits ::gcloudsdk::params {
    
  # Check the Architecture of Node to form the download URL
  if $::architecture == 'amd64' or $::architecture == 'x86_64' {
    $arch = 'x86_64'
  } else {
    $arch = 'x86'
  }

  # GCloud SDK File Name
  $download_file_name = "google-cloud-sdk-${version}-linux-${arch}"

  # GCloud SDK Download URL
  $download_source = "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/${download_file_name}.tar.gz"

  # Validates if the installation directory path exists
  validate_absolute_path($install_dir)

  notice($download_source)

  # The below block of code downloads the google-cloud-sdk archive file.
  archive::download{ "${download_file_name}.tar.gz":
    url => $download_source,
    src_target => '/tmp',
    checksum => false,
  }
  
  # The below block of code extracts the google-cloud-sdk archive file.
  archive::extract { $download_file_name:
    target  => $install_dir,
    src_target => "/tmp",
    require => Archive::Download["${download_file_name}.tar.gz"],
  }
  
  # The below block of code installs the google-cloud-sdk archive file.
  $install_path = "${install_dir}/google-cloud-sdk"
  exec { 'install Google Cloud SDK':
    path => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
    creates => "${install_path}/bin/gcloud",
    cwd => "${install_dir}/google-cloud-sdk",
    command => '/bin/echo "" | ./install.sh --usage-reporting false --disable-installation-options --bash-completion false',
    require => Archive::Extract[$download_file_name],
  }
  
  
  
  # The below code will set the google-cloud-sdk path inside the PATH env variable.
  file { "/etc/profile.d/gcloud_path.sh":
    ensure  => file,
    mode => '0755',
    content => template('gcloudsdk/gcloud_path.sh.erb'),
    require => Archive::Extract["${download_file_name}"],
  }-> exec { 'set gcloud':
    provider  => shell,
    command   => "sh /etc/profile.d/gcloud_path.sh",
    logoutput => on_failure,
  }  
  
  # The below code will install the selected addtional components.
  file { "/tmp/sdk_add_components.sh":
    ensure  => file,
    mode => '0755',
    content => template('gcloudsdk/sdk_add_components.sh.erb'),
    require => Exec['set gcloud'],
  }-> exec { 'Add Components':
    provider  => shell,
    command   => "sh /tmp/sdk_add_components.sh",
    logoutput => on_failure,
  } 
  
  # The below code will uninstall the selected default components.
  file { "/tmp/sdk_remove_components.sh":
    ensure  => file,
    mode => '0755',
    content => template('gcloudsdk/sdk_remove_components.sh.erb'),
    require => Exec['Add Components'],
  }-> exec { 'Remove Components':
    provider  => shell,
    command   => "sh /tmp/sdk_remove_components.sh",
    logoutput => on_failure,
  } 
    
}


