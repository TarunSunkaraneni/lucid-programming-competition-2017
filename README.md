# Lucid Programming Competition 2017

## Generate descriptions

```sh
wget -O /tmp/wkhtmltox.deb https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.2.1/wkhtmltox-0.12.2.1_linux-trusty-amd64.deb
sudo apt-get remove --purge wkhtmltopdf
sudo dpkg -i /tmp/wkhtmltox.deb
sudo apt-get install -f ruby
```

```sh
make
```