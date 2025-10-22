# Microsoft MSSQL Tools with PowerShell

A Docker image that combines Microsoft SQL Server command-line tools with PowerShell, enabling you to run SQL operations and PowerShell scripts in a single containerized environment.

## Base Image

Built on top of `mcr.microsoft.com/mssql-tools:latest`, this image includes:
- **sqlcmd** - SQL Server command-line utility
- **bcp** - Bulk copy program utility
- **PowerShell 7+** - Cross-platform PowerShell

## Use Cases

- Execute SQL scripts using sqlcmd from PowerShell
- Run database migrations and deployments
- Automate database operations in CI/CD pipelines
- Perform bulk data operations with bcp
- Combine SQL operations with PowerShell scripting logic

## Prerequisites

- Docker Desktop installed on Windows
- Access to a SQL Server instance (local or remote)

## Quick Start

### Pull the Image

```powershell
docker pull cilerler/microsoft-mssql-tools:latest
```

### Basic Usage - Interactive PowerShell Session

```powershell
docker run -it --rm cilerler/microsoft-mssql-tools:latest pwsh
```

Once inside the container, you can use sqlcmd:

```powershell
sqlcmd -S your-server.database.windows.net -U your-username -P your-password -d your-database -Q "SELECT @@VERSION"
```

## Common Usage Patterns

### Execute a SQL Query from PowerShell

```powershell
docker run --rm cilerler/microsoft-mssql-tools:latest pwsh -Command `
    "sqlcmd -S 'your-server' -U 'your-username' -P 'your-password' -d 'your-database' -Q 'SELECT GETDATE()'"
```

### Run a SQL Script File

First, mount your local directory containing the SQL script:

```powershell
docker run --rm -v ${PWD}:/scripts cilerler/microsoft-mssql-tools:latest pwsh -Command `
    "sqlcmd -S 'your-server' -U 'your-username' -P 'your-password' -d 'your-database' -i /scripts/your-script.sql"
```

### Using Environment Variables for Connection

```powershell
docker run --rm `
    -e SQL_SERVER='your-server' `
    -e SQL_USER='your-username' `
    -e SQL_PASSWORD='your-password' `
    -e SQL_DATABASE='your-database' `
    cilerler/microsoft-mssql-tools:latest pwsh -Command `
    "sqlcmd -S `$env:SQL_SERVER -U `$env:SQL_USER -P `$env:SQL_PASSWORD -d `$env:SQL_DATABASE -Q 'SELECT DB_NAME()'"
```

### Execute a PowerShell Script with SQL Operations

Create a PowerShell script (`db-operations.ps1`):

```powershell
# db-operations.ps1
$server = $env:SQL_SERVER
$user = $env:SQL_USER
$password = $env:SQL_PASSWORD
$database = $env:SQL_DATABASE

Write-Host "Connecting to $server..."

$result = sqlcmd -S $server -U $user -P $password -d $database -Q "SELECT COUNT(*) FROM sys.tables" -h -1

Write-Host "Number of tables: $result"
```

Run it:

```powershell
docker run --rm `
    -v ${PWD}:/scripts `
    -e SQL_SERVER='your-server' `
    -e SQL_USER='your-username' `
    -e SQL_PASSWORD='your-password' `
    -e SQL_DATABASE='your-database' `
    cilerler/microsoft-mssql-tools:latest pwsh /scripts/db-operations.ps1
```

### Bulk Copy (bcp) Operations

Export data to a file:

```powershell
docker run --rm -v ${PWD}:/data cilerler/microsoft-mssql-tools:latest pwsh -Command `
    "bcp 'SELECT * FROM YourTable' queryout /data/output.dat -S 'your-server' -U 'your-username' -P 'your-password' -d 'your-database' -c"
```

Import data from a file:

```powershell
docker run --rm -v ${PWD}:/data cilerler/microsoft-mssql-tools:latest pwsh -Command `
    "bcp YourTable in /data/input.dat -S 'your-server' -U 'your-username' -P 'your-password' -d 'your-database' -c"
```

## Connecting to Local SQL Server

If you're running SQL Server locally on Windows and want to connect from the container:

```powershell
# Use host.docker.internal to reference the Windows host
docker run --rm cilerler/microsoft-mssql-tools:latest pwsh -Command `
    "sqlcmd -S 'host.docker.internal' -U 'sa' -P 'YourPassword' -Q 'SELECT @@SERVERNAME'"
```

## Connecting to SQL Server in Another Container

If SQL Server is running in a Docker container:

```powershell
# Create a network
docker network create sql-network

# Run SQL Server (example)
docker run -d --name sqlserver --network sql-network `
    -e "ACCEPT_EULA=Y" -e "SA_PASSWORD=YourStrong@Password" `
    mcr.microsoft.com/mssql/server:2022-latest

# Run mssql-tools container on the same network
docker run --rm --network sql-network cilerler/microsoft-mssql-tools:latest pwsh -Command `
    "sqlcmd -S 'sqlserver' -U 'sa' -P 'YourStrong@Password' -Q 'SELECT @@VERSION'"
```

## Using with Docker Compose

Create a `docker-compose.yml`:

```yaml
version: '3.8'

services:
  sqlserver:
    image: mcr.microsoft.com/mssql/server:2022-latest
    environment:
      ACCEPT_EULA: "Y"
      SA_PASSWORD: "YourStrong@Password"
    ports:
      - "1433:1433"

  sql-tools:
    image: cilerler/microsoft-mssql-tools:latest
    depends_on:
      - sqlserver
    environment:
      SQL_SERVER: sqlserver
      SQL_USER: sa
      SQL_PASSWORD: "YourStrong@Password"
      SQL_DATABASE: master
    volumes:
      - ./scripts:/scripts
    command: pwsh -Command "Start-Sleep -Seconds 10; sqlcmd -S $$env:SQL_SERVER -U $$env:SQL_USER -P $$env:SQL_PASSWORD -i /scripts/init.sql"
```

Run with:

```powershell
docker-compose up
```

## CI/CD Integration

### Azure DevOps Pipeline Example

```yaml
steps:
- task: Docker@2
  displayName: 'Run Database Migration'
  inputs:
    command: 'run'
    arguments: >
      --rm
      -v $(Build.SourcesDirectory)/database:/scripts
      -e SQL_SERVER=$(SqlServer)
      -e SQL_USER=$(SqlUser)
      -e SQL_PASSWORD=$(SqlPassword)
      -e SQL_DATABASE=$(SqlDatabase)
      cilerler/microsoft-mssql-tools:latest
      pwsh /scripts/migrate.ps1
```

### GitHub Actions Example

```yaml
- name: Run Database Scripts
  run: |
    docker run --rm `
      -v ${{ github.workspace }}/database:/scripts `
      -e SQL_SERVER=${{ secrets.SQL_SERVER }} `
      -e SQL_USER=${{ secrets.SQL_USER }} `
      -e SQL_PASSWORD=${{ secrets.SQL_PASSWORD }} `
      -e SQL_DATABASE=${{ secrets.SQL_DATABASE }} `
      cilerler/microsoft-mssql-tools:latest `
      pwsh /scripts/deploy.ps1
  shell: pwsh
```

## Advanced PowerShell Scenarios

### Using SqlServer PowerShell Module

You can extend this image or install the SqlServer module at runtime:

```powershell
docker run -it --rm cilerler/microsoft-mssql-tools:latest pwsh -Command `
    "Install-Module -Name SqlServer -Force -AllowClobber; Import-Module SqlServer; Invoke-Sqlcmd -ServerInstance 'your-server' -Username 'your-username' -Password 'your-password' -Query 'SELECT @@VERSION'"
```

### Error Handling in PowerShell Scripts

```powershell
# check-database.ps1
$ErrorActionPreference = "Stop"

try {
    $result = sqlcmd -S $env:SQL_SERVER -U $env:SQL_USER -P $env:SQL_PASSWORD -Q "SELECT 1" -h -1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Connection successful!"
        exit 0
    } else {
        Write-Error "Connection failed with exit code: $LASTEXITCODE"
        exit 1
    }
} catch {
    Write-Error "Error: $_"
    exit 1
}
```

## sqlcmd Common Options

- `-S` - Server name or IP address
- `-U` - Username (SQL Server authentication)
- `-P` - Password (SQL Server authentication)
- `-E` - Use Windows authentication (not applicable in Linux container)
- `-d` - Database name
- `-Q` - Execute query and exit
- `-i` - Input file (SQL script)
- `-o` - Output file
- `-h -1` - Remove headers from output
- `-s` - Column separator
- `-W` - Remove trailing spaces
- `-C` - Trust server certificate (for encrypted connections)

## Security Considerations

**Never hardcode passwords in scripts or command history.** Use environment variables or secure secret management:

```powershell
# Read from environment
$password = $env:SQL_PASSWORD

# Or use Docker secrets in Swarm mode
docker run --rm `
    --secret sql-password `
    cilerler/microsoft-mssql-tools:latest pwsh -Command `
    "sqlcmd -S 'your-server' -U 'your-username' -P (Get-Content /run/secrets/sql-password) -Q 'SELECT 1'"
```

## Troubleshooting

### Connection Issues

If you're having trouble connecting, verify the connection string:

```powershell
docker run --rm cilerler/microsoft-mssql-tools:latest pwsh -Command `
    "sqlcmd -S 'your-server' -U 'your-username' -P 'your-password' -Q 'SELECT 1' -C"
```

Add `-C` to trust the server certificate if using encrypted connections.

### Check Installed Versions

```powershell
docker run --rm cilerler/microsoft-mssql-tools:latest pwsh -Command `
    "sqlcmd -?; Write-Host '---'; pwsh --version"
```

## Building the Image Yourself

If you want to build this image locally:

```powershell
# Clone or create the Dockerfile
docker build -t cilerler/microsoft-mssql-tools:latest .
```

## License

This image is based on Microsoft's official SQL Server tools image. Please refer to Microsoft's licensing terms for sqlcmd and bcp utilities.

## Contributing

Issues and pull requests are welcome for improving this image and documentation.

## Links

- [Microsoft SQL Server Tools Documentation](https://learn.microsoft.com/en-us/sql/tools/overview-sql-tools)
- [sqlcmd Utility](https://learn.microsoft.com/en-us/sql/tools/sqlcmd-utility)
- [bcp Utility](https://learn.microsoft.com/en-us/sql/tools/bcp-utility)
- [PowerShell Documentation](https://learn.microsoft.com/en-us/powershell/)
