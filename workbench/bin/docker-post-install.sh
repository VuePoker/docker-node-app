#!/bin/sh
set -e

sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker