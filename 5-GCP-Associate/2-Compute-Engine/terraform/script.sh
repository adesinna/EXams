#!/bin/bash
# Update packages
apt-get update -y

# Install Apache
apt-get install -y apache2

# Enable and start Apache
systemctl enable apache2
systemctl start apache2

# Create a beautiful HTML page
cat <<HTML > /var/www/html/index.html
<!DOCTYPE html>
<html>
<head>
 <title>Welcome</title>
 <style>
   body { font-family: Arial; background-color: #f0f0f0; text-align: center; }
   h1 { color: #333; margin-top: 50px; }
   p { font-size: 1.2em; color: #666; }
 </style>
</head>
<body>
 <h1>Hello from Terraform VM!</h1>
 <p>This is a beautiful web page served by Apache.</p>
</body>
</html>
HTML