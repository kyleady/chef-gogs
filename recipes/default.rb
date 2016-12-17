#
# Cookbook Name:: gogs
# Recipe:: default
#
# Copyright 2015 Eddie Hurtig
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

include_recipe 'apt'

include_recipe 'chef-sugar'

package 'unzip'
package 'git'

user node['gogs']['config']['global']['RUN_USER'] do
  action :create
  comment 'Gogs User'
  home "/home/#{node['gogs']['config']['global']['RUN_USER']}"
  shell '/bin/bash'
  supports manage_home: true
end

[
  node['gogs']['install_dir'],
  "#{node['gogs']['install_dir']}/gogs/custom/conf",
  node['gogs']['config']['repository']['ROOT']
].each do |dir|
  directory dir do
    owner node['gogs']['config']['global']['RUN_USER']
    group node['gogs']['config']['global']['RUN_USER']
    mode '0755'
    action :create
    recursive true
  end
end

ark 'gogs' do
  path node['gogs']['install_dir']
  url "https://github.com/gogits/gogs/releases/download/v#{node['gogs']['version']}/linux_amd64.zip"
  owner node['gogs']['config']['global']['RUN_USER']
  group node['gogs']['config']['global']['RUN_USER']
  action :put
end

template "#{node['gogs']['install_dir']}/gogs/custom/conf/app.ini" do
  source 'app.ini.erb'
  owner node['gogs']['config']['global']['RUN_USER']
  mode '0644'
  variables config: JSON.parse(node['gogs']['config'].to_json)
end

systemd_service 'gogs' do
  description 'Go Git Service'
  after 'syslog.target'
  after 'network.target'
  service do
    exec_start "#{node['gogs']['install_dir']}/gogs/gogs web"
    user node['gogs']['config']['global']['RUN_USER']
    group node['gogs']['config']['global']['RUN_USER']
    restart 'always'
    type 'simple'
    working_directory "#{node['gogs']['install_dir']}/gogs"
  end
  install do
    wanted_by 'multi-user.target'
  end
end

service 'gogs' do
  action [:enable, :start]
end
