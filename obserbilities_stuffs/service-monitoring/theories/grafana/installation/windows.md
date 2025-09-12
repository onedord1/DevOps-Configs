## Installing Grafana on Windows

### Steps:

- Go to [Grafana Download Page for Windows](https://grafana.com/grafana/download?edition=oss&pg=get&platform=windows&plcmt=selfmanaged-box1-cta1) and download the latest version of Grafana for Windows.

- You can either choose `installer` or `zip` file based on your requirement. Once you have downloaded the file, you can install Grafana on your Windows machine by following the below steps.
    - For Installer, you can just double click on the installer and follow the instructions to install Grafana.
    - For Zip file, you can extract the zip file to a location where you want to install Grafana.

- If you have downloaded the `zip `file, you can extract the zip file to a location you want to install Grafana. If you choosen installer, please note the installation path because we need it later.

- Navigate to the installation directory and open the `conf` directory. There you can find the `defaults.ini` file. This file contains the default configuration of Grafana. If we want to change the configuration our Grafana instance, we can change here.

- Now, We can access Grafana using the URL `http://localhost:3000`. The default username and password is `admin`. We can change password after login.

Date of notes: 04/07/2024