#
# Cookbook:: web
# Recipe:: default
#
# Copyright:: 2018, The Authors, All Rights Reserved.

yum_package "yum-fastestmirror" do
  action :install
end

execute "yum-update" do
  user "root"
  command "yum -y update"
  action :run
end

package "httpd"

service 'httpd' do
  action [:enable, :start]
end

# epel
package 'epel-release.noarch' do
  action :install
end

# remi-release-7
remote_file "#{Chef::Config[:file_cache_path]}/remi-release-7.rpm" do
    source "http://rpms.famillecollet.com/enterprise/remi-release-7.rpm"
    # not_if "rpm -qa | grep -q '^remi-release'"
    action :create
    # notifies :install, "rpm_package[remi-release]", :immediately
end

# remi-release-7
rpm_package 'remi-release-7' do
  not_if "rpm -qa | grep -q '^remi-release'"
  source "#{Chef::Config[:file_cache_path]}/remi-release-7.rpm"
  action :install # defaults to :install if not specified
end

# php7
package 'php' do
  flush_cache [:before]
  action :install
  options "--enablerepo=remi --enablerepo=remi-php72"
end

%w(php-openssl php-common php-mbstring php-xml).each do |pkg|
  package pkg do
    action :install
    options "--enablerepo=remi --enablerepo=remi-php72"
  end
end

# composer
bash 'install_composer' do
  not_if { File.exists?("/usr/local/bin/composer") }
  user 'root'
  cwd '/tmp'
  code <<-EOH
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/tmp
    mv /tmp/composer.phar /usr/local/bin/composer
  EOH
end
