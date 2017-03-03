# Class: gcloudsdk
#
# This module manages gcloudsdk
#
# Parameters: https://github.com/RanjthKumar45/puppet-gcloudsdk#usage
#
# Actions: Download and Install Google Cloud Sdk.
#
# Requires: puppetlabs/stdlib,camptocamp/archive
#
# Sample Usage: https://github.com/RanjthKumar45/puppet-gcloudsdk#usage
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

  #Validate Tools Installation Set up
  validate_bool($is_install_gcloud)
  validate_bool($is_install_gsutil)
  validate_bool($is_install_core)
  validate_bool($is_install_bq)
  validate_bool($is_install_kubectl)
  validate_bool($is_install_app_engine_python)
  validate_bool($is_install_app_engine_java)
  validate_bool($is_install_beta)
  validate_bool($is_install_alpha)
  validate_bool($is_install_pubsub_emulator)
  validate_bool($is_install_gcd_emulator)

  # Validates if the installation directory path exists
  validate_absolute_path($install_dir)

  # Check the Architecture of Node to form the download URL
  if $::architecture == 'amd64' or $::architecture == 'x86_64' {
    $arch = 'x86_64'
  } else {
    $arch = 'x86'
  }

  # GCloud SDK File Name
  if $version == 'LATEST' {
    $download_file_name = "google-cloud-sdk-108.0.0-linux-${arch}"
  } else {
    $download_file_name = "google-cloud-sdk-${version}-linux-${arch}"
  }


  # GCloud SDK Download URL
  $download_source = "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/${download_file_name}.tar.gz"



  notice($download_source)

  archive { "/tmp/${download_file_name}.tar.gz":
    ensure       => present,
    provider     => 'wget',
    extract      => true,
    extract_path => $install_dir,
    source       => $download_source,
    creates      => "${install_dir}/google-cloud-sdk",
  }


  # The below block of code installs the google-cloud-sdk archive file.
  $install_path = "${install_dir}/google-cloud-sdk"
  exec { 'install Google Cloud SDK':
    path    => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
    creates => "${install_path}/bin/gcloud",
    cwd     => "${install_dir}/google-cloud-sdk",
    command => '/bin/echo "" | ./install.sh --usage-reporting false --disable-installation-options --bash-completion false',
#    require => Archive["/tmp/${download_file_name}.tar.gz"],
  }



  # The below code will set the google-cloud-sdk path inside the PATH env variable.
  file { '/etc/profile.d/gcloud_path.sh':
    ensure  => file,
    mode    => '0755',
    content => template('gcloudsdk/gcloud_path.sh.erb'),
    require => Archive::Extract[$download_file_name],
  }-> exec { 'set gcloud':
    provider  => shell,
    command   => 'sh /etc/profile.d/gcloud_path.sh',
    logoutput => on_failure,
  }

  # The below code will install the selected addtional components. (only if any additional components is set to true)
  file { '/tmp/sdk_add_components.sh':
    ensure  => file,
    mode    => '0755',
    content => template('gcloudsdk/sdk_add_components.sh.erb'),
    require => Exec['set gcloud'],
  }-> exec { 'Add Components':
    provider  => shell,
    command   => 'sh /tmp/sdk_add_components.sh',
    logoutput => on_failure,
  }

  # The below code will Update the components to latest version. (only if version is set to LATEST)
  file { '/tmp/sdk_update_components.sh':
    ensure  => file,
    mode    => '0755',
    content => template('gcloudsdk/sdk_update_components.sh.erb'),
    require => Exec['Add Components'],
  }-> exec { 'Update Components':
    provider  => shell,
    command   => 'sh /tmp/sdk_update_components.sh',
    logoutput => on_failure,
  }

  # The below code will uninstall the selected default components. (only if default components installation is set to false)
  file { '/tmp/sdk_remove_components.sh':
    ensure  => file,
    mode    => '0755',
    content => template('gcloudsdk/sdk_remove_components.sh.erb'),
    require => Exec['Update Components'],
  }-> exec { 'Remove Components':
    provider  => shell,
    command   => 'sh /tmp/sdk_remove_components.sh',
    logoutput => on_failure,
  }


  $ua_module_name = 'RanjithKumar45/gcloudsdk'
  $ua_module_version = "${ua_module_name}/1.2.0"

  file { '/tmp/agent.sh':
    ensure  => file,
    mode    => '0755',
    content => template('gcloudsdk/agent.sh.erb'),
    require => Exec['Remove Components'],
  }-> exec { 'Agent':
    provider  => shell,
    command   => 'sh /tmp/agent.sh',
    logoutput => on_failure,
  }

}
