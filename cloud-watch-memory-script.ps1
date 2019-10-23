Set-Location -Path "C:\\Program Files\\Amazon\\AmazonCloudWatchAgent"     
./amazon-cloudwatch-agent-ctl.ps1 -a -config -m ec2 -c file:cw-memory-config.json -s
./amazon-cloudwatch-agent-ctl.ps1 -a start
exit