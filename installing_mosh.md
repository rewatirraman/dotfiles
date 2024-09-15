Client side (Mac):
- Install homebrew

    ```
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
    ```

- Install mosh
    ```
    brew install mosh
    ```

Server side:

- Get the mosh installataion script:
    ```
    mkdir ~/mosh
    cd ~/mosh
    # Get the mosh install script
    wget https://gist.github.com/eminence/85961d47244a140fde89314837d0db0a/archive/084cc67c5c68a3b73ac958582e6a93ccadfe9f9b.zip
    unzip 084cc67c5c68a3b73ac958582e6a93ccadfe9f9b.zip
    mv 85961d47244a140fde89314837d0db0a-084cc67c5c68a3b73ac958582e6a93ccadfe9f9b/build-mosh-and-tmux.sh .
    rm -rf 85961d47244a140fde89314837d0db0a-084cc67c5c68a3b73ac958582e6a93ccadfe9f9b/
    ```

- Update the Install directory in the script,
    - Open build-mosh-and-tmux.sh
    - Update `INSTALL_DIR` to `/homes/<username>/mosh/`

- Change file permission
    ```
    chmod 755 build-mosh-and-tmux.sh
    ```
- Run the install script
    ```
    ./build-mosh-and-tmux.sh
    ```
- Finally, binary will be available in the `/homes/<username>/mosh/bin/`
- Create a script to run the mosh-server
    - create a file `~/run_server`
    - Copy paste below contents in the file `~/run_server`
    ```
    #!/bin/sh
    LANG="en_US.UTF-8"
    export LANG
    /homes/<username>/mosh/bin/mosh-server
    ```

Client side (Mac):
- Run the mosh server using below command:

    ```
    mosh --server=/homes/<username_of_server>/run_server <server_ip>
    ```
