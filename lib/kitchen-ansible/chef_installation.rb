
def chef_installation_script(chef_url, omnibus_download_dir)
  <<-INSTALL
      if [ ! -d "/opt/chef" ]; then
        echo "-----> Installing Chef Omnibus needed by busser and serverspec"
        mkdir -p #{omnibus_download_dir}
        if [ ! -x #{omnibus_download_dir}/install.sh ]; then
          do_download #{chef_url} #{omnibus_download_dir}/install.sh
        fi
        sudo sh #{omnibus_download_dir}/install.sh -d #{omnibus_download_dir}
        echo "-----> End Installing Chef Omnibus"
      fi
  INSTALL
end
