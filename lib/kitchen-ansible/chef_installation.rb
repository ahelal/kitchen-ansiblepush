
def chef_installation_script_linux(chef_url, omnibus_download_dir)
    <<-INSTALL
        if [ ! -d "/opt/chef" ]
        then
          echo "-----> Installing Chef Omnibus needed by busser and serverspec"
          mkdir -p #{omnibus_download_dir}
          if [ ! -x #{omnibus_download_dir}/install.sh ]
          then
            do_download #{chef_url} #{omnibus_download_dir}/install.sh
          fi
          sudo sh #{omnibus_download_dir}/install.sh -d #{omnibus_download_dir}
          echo "-----> End Installing Chef Omnibus"
        fi
    INSTALL
end

def chef_installation_script_windows(chef_url)
    <<-INSTALL
    if((Test-Path "c:\\opscode\\chef\\bin") -eq 0)
    {
      echo "-----> Installing Chef Omnibus needed by busser and serverspec"
      . { iwr -useb #{chef_url} } | iex; install -channel current -project chef
      echo "-----> End Installing Chef Omnibus"
    }
    else
    {
      echo "-----> Chef Omnibus needed by busser and serverspec is already installed"
    }
    INSTALL
end
