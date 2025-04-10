# IIS Application Pool Manager

This extension provides a task for Azure DevOps pipelines to remotely manage IIS Application Pools on Windows servers. You can start, stop, recycle, or force stop application pools as part of your deployment or maintenance processes.

## Features

- **Start Application Pools**: Ensure your application pools are running after deployment
- **Stop Application Pools**: Gracefully stop application pools before maintenance
- **Recycle Application Pools**: Reset application pools without downtime
- **Force Stop Application Pools**: Forcefully terminate stubborn worker processes

## Getting Started

### Prerequisites

- Windows target server with IIS installed
- PowerShell remoting enabled on the target server
- Credentials with sufficient permissions to manage IIS

### Adding the Task to Your Pipeline

```yaml
steps:
- task: IISAppPoolManagerTask@1
  displayName: 'Recycle IIS Application Pool'
  env:
    iisPoolName: 'YourAppPoolName'
    serverName: 'your-server.example.com'
    username: '$(serverUsername)'
    password: '$(serverPassword)'
    action: 'Recycle'
```

## Task Parameters

| Parameter | Description |
|-----------|-------------|
| **iisPoolName** | Name of the IIS Application Pool to manage |
| **serverName** | Target server name or IP address |
| **username** | Username for remote server authentication |
| **password** | Password for remote server authentication |
| **action** | Action to perform: Start, Stop, Recycle, or ForceStop |

## Action Details

- **Start**: Starts the specified application pool if it exists
- **Stop**: Gracefully stops the specified application pool
- **Recycle**: Restarts the specified application pool
- **ForceStop**: Stops the application pool and forcibly terminates any remaining worker processes

## Example Scenarios

### Integration in Release Pipeline

```yaml
steps:
# Stop the application pool before deployment
- task: IISAppPoolManagerTask@1
  displayName: 'Stop Application Pool'
  env:
    iisPoolName: 'ProductionSite'
    serverName: 'web-server-01'
    username: '$(adminUsername)'
    password: '$(adminPassword)'
    action: 'Stop'

# Deploy your application...
- task: YourDeploymentTask@1
  # ...deployment configuration

# Start the application pool after deployment
- task: IISAppPoolManagerTask@1
  displayName: 'Start Application Pool'
  env:
    iisPoolName: 'ProductionSite'
    serverName: 'web-server-01'
    username: '$(adminUsername)'
    password: '$(adminPassword)'
    action: 'Start'
```

### Automated IIS Maintenance

```yaml
# Schedule this pipeline to run during maintenance windows
steps:
- task: IISAppPoolManagerTask@1
  displayName: 'Recycle All Application Pools'
  env:
    iisPoolName: 'MainWebsite'
    serverName: 'web-server-01'
    username: '$(adminUsername)'
    password: '$(adminPassword)'
    action: 'Recycle'

- task: IISAppPoolManagerTask@1
  displayName: 'Recycle API Application Pool'
  env:
    iisPoolName: 'APIServices'
    serverName: 'web-server-01'
    username: '$(adminUsername)'
    password: '$(adminPassword)'
    action: 'Recycle'
```

## Troubleshooting

- Ensure the target server is accessible from your Azure DevOps agent
- Verify that PowerShell remoting is enabled on the target server
- Check that the provided credentials have appropriate permissions on the target server
- Review the task logs for detailed error messages

## Security Notes

- It's recommended to store credentials as secret pipeline variables
- Consider using a service account with limited permissions specifically for this purpose
- The task uses PowerShell remoting which requires HTTPS or proper WinRM security configuration

## Support

For questions and support, please create an issue in the repository or contact your system administrator.
