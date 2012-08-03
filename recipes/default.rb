#
# Cookbook Name:: rbenv
# Recipe:: default
#
# Copyright 2012, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

# traverse users in data bag and see if they set a ruby attribute and install rubies
search(:users, "ruby:*") do |u|
  rbenv_user = u['id']
  rbenv_user_dir = "/home/#{rbenv_user}"
  rubies = u['ruby']
  rbenv_dir = "#{rbenv_user_dir}/.rbenv"
  
  # directory rbenv_dir do
  #     owner rbenv_user
  #     action :create
  #   end
  
  git rbenv_dir do
    user rbenv_user
    repository "git://github.com/sstephenson/rbenv.git"
    action :sync
  end
 
  # setup bash profile add ons
  # TODO move to it's own provider maybe
  cookbook_file "#{rbenv_user_dir}/.profile" do
    owner rbenv_user
    mode '0700'
    source "profile"
    action :create
  end
  
  # directory "#{rbenv_user_dir}/profile.d" do
  #     owner rbenv_user
  #     action :create
  #   end
  #   
  #   cookbook_file "#{rbenv_user_dir}/profile.d/rbenv" do
  #     owner rbenv_user
  #     mode '0700'
  #     source "rbenv"
  #     action :create
  #   end
  
  directory "#{rbenv_user_dir}/.rbenv/plugins" do
    owner rbenv_user
    action :create
  end
  
  git "#{rbenv_user_dir}/.rbenv/plugins/ruby-build" do
    user rbenv_user
    repository "git://github.com/sstephenson/ruby-build.git"
    action :sync
  end
  
  rubies.each do |ruby|
    bash "install rubies" do
      user rbenv_user
      cwd rbenv_user_dir
      code <<-EOH
      source .profile
      export HOME=#{rbenv_user_dir}
      export TMPDIR=#{rbenv_user_dir}
      export PREFIX=#{rbenv_user_dir}/.rbenv/versions/#{ruby}
      # ruby compile flags to link correctly for smartos
      export LDFLAGS="-R/opt/local/lib -L/opt/local/lib -L/opt/local/lib/"
      # first check /modpkg/ruby if version exists
      # if true, copy ruby from NFS
      # else install
      # then copy new install to NFS
      source .profile
      if [ "`rbenv versions | grep #{ruby}`" ];
        then echo "#{ruby} already installed";
      elif [ -f /modpkg/ruby/smartos-base64-1.7.1/#{rbenv_user}/#{ruby}.tar.gz ];
        then echo "copying ruby from modpkg..." && mkdir -p  $HOME/.rbenv/versions &&  \
        tar -xzf /modpkg/ruby/smartos-base64-1.7.1/#{rbenv_user}/#{ruby}.tar.gz -C $HOME/.rbenv/versions
      else
        # make sure to create os/version folder for ruby
        [  -d /modpkg/ruby/smartos-base64-1.7.1/#{rbenv_user} ] || echo "creating pkg directory on nfs share..." && mkdir -p /modpkg/ruby/smartos-base64-1.7.1/#{rbenv_user}
        source .profile
        echo "installing ruby from source..." && \
        rbenv install #{ruby} && echo "creating tar file" && cd .rbenv/versions/ && \
        mkdir -p /modpkg/ruby/smartos-base64-1.7.1/#{rbenv_user} && \
        tar -czf /modpkg/ruby/smartos-base64-1.7.1/#{rbenv_user}/1.9.3-p194.tar.gz 1.9.3-p194;
      fi
      rbenv rehash
      rbenv global #{ruby}
      if  rbenv which bundle; then
        echo 'bundler already installed'
      else
        gem install bundler
      fi
      rbenv rehash
      EOH
    end
  end
end
