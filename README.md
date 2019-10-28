# How do I enable Memory Utilization using custom CloudWatch Metrics for my Elastic Beanstalk Windows Environment


## Short Description

Configure custom CloudWatch metrics for the Elastic Beanstalk platform ".NET on Windows Server with IIS" using Elastic Beanstalk configuration files (.ebextensions).

By default, the CloudWatch agent is installed on all Elastic Beanstalk Windows Environments running Platform Versions 2.0.1 or newer.  We will use .ebextensions to deploy configuration files to enable  Custom CloudWatch Metrics to measure Memory utilization.

## Resolution:

You can create powershell scripts to configure the instance to start streaming memory metrics to CloudWatch . Please take note of the below:

Set up your .ebextensions directory

1. In the root of your application bundle, create a hidden directory named .ebextensions.

    Your application source bundle should look similar to the following example:

    ``` 
        ~/workspace/my-application/
        |-- Content
        |-- .ebextensions
        |  
        |-- archive.xml
        `-- systemInfo.xml
    ```        

2. Create and store the configuration files and PowerShell scripts in the .ebextensions directory.

    2.1  Create a file called "cw-memory-config.json" and paste the below content in the file. This file is the CloudWatch configuration file used to specify the metrics that the CloudWatch agent is to collect and push to CloudWatch. The configuration will collect the metrics for percentage(%) of memory used.

    ```        
        {
            "metrics": {
                "append_dimensions": {
                    "AutoScalingGroupName": "${aws:AutoScalingGroupName}",
                    "ImageId": "${aws:ImageId}",
                    "InstanceId": "${aws:InstanceId}",
                    "InstanceType": "${aws:InstanceType}"
                },
                "metrics_collected": {
                    "Memory": {
                        "measurement": [
                            "% Committed Bytes In Use"
                        ],
                        "metrics_collection_interval": 10
                    }
                }
            }
        }
    ```

      2.2 Create a file called "copy-cloud-watch-config-script.ps1" and paste the below content in the file . This file copies the CloudWatch agent configuration file to the CloudWatch directory.

    ```
        copy-item -path "C:\staging\.ebextensions\cw-memory-config.json" -destination "C:\Program Files\Amazon\AmazonCloudWatchAgent\cw-memory-config.json"
        exit
    ```

      2.3  Create a file called "cloud-watch-memory-script.ps1" and paste the below content in the file. This file will be used to execute the CloudWatch agent by using the settings in the CloudWatch configuration file and then start the agent

    ```
        cd "C:\\Program Files\\Amazon\\AmazonCloudWatchAgent"     
        ./amazon-cloudwatch-agent-ctl.ps1 -a -config -m ec2 -c file:cw-memory-config.json -s
        ./amazon-cloudwatch-agent-ctl.ps1 -a start
        exit
    ```

      2.4  Create a file called "01_cwmemory.config" and paste the below content in the file. This file will be used by elastic beanstalk to execute the scripts on the instance running in the environment.


        container_commands:
          01_copy_config_file_script:
            command: powershell.exe -ExecutionPolicy Bypass -File C:\\staging\\.ebextensions\\copy-cloud-watch-config-script.ps1
            ignoreErrors: false
            waitAfterCompletion: 10
          02_cw_excute_memory_script:
            command: powershell.exe -ExecutionPolicy Bypass -File C:\\staging\\.ebextensions\\cloud-watch-memory-script.ps1
       ignoreErrors: false
       waitAfterCompletion: 10


  At this point your application source bundle should look similar to the following example:
    ```
        ~/workspace/my-application/
        |-- Content
        |-- .ebextensions
        |   |--01_cwmemory.config
        |   |-- cloud-watch-memory-script.ps1
        |   |-- copy-cloud-watch-config-script.ps1
        |   `-- cw-memory-config.json
        |  
        |-- archive.xml
        `-- systemInfo.xml
    ```

3. Deploy your updated Elastic Beanstalk application. For more details in regards to Elastic Beanstalk Windows Environments. Please refer to documentation here:

4. After the deployment is successful, You should start seeing memory metrics on the CloudWatch Console under Metrics section with Custom Namespace "CWAgent". 

Please refer to full documentation here: https://github.com/aws-lmmakhu/aws-elastic-beanstalk-windows-memory-metrics
