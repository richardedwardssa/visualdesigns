# Simple PowerShell HTTP Server for your portfolio
# This script creates a local web server to host your portfolio

$port = 3000
$path = Get-Location

Write-Host "Starting local server..." -ForegroundColor Green
Write-Host "Portfolio will be available at: http://localhost:$port" -ForegroundColor Cyan
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow
Write-Host ""

# Create HTTP listener
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")

try {
    $listener.Start()
    Write-Host "Server started successfully! Opening browser..." -ForegroundColor Green
    
    # Auto-open browser
    Start-Process "http://localhost:$port"
    
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        
        # Get the requested file path
        $requestedPath = $request.Url.LocalPath
        if ($requestedPath -eq "/") {
            $requestedPath = "/index.html"
        }
        
        $filePath = Join-Path $path $requestedPath.TrimStart('/')
        
        Write-Host "$(Get-Date -Format 'HH:mm:ss') - Request: $requestedPath" -ForegroundColor Gray
        
        if (Test-Path $filePath -PathType Leaf) {
            # File exists, serve it
            $content = Get-Content $filePath -Raw -Encoding UTF8
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($content)
            
            # Set content type based on file extension
            $extension = [System.IO.Path]::GetExtension($filePath).ToLower()
            switch ($extension) {
                ".html" { 
                    $response.ContentType = "text/html; charset=utf-8"
                    $content = Get-Content $filePath -Raw -Encoding UTF8
                    $buffer = [System.Text.Encoding]::UTF8.GetBytes($content)
                }
                ".css"  { $response.ContentType = "text/css" }
                ".js"   { $response.ContentType = "application/javascript" }
                ".png"  { 
                    $response.ContentType = "image/png"
                    $buffer = [System.IO.File]::ReadAllBytes($filePath)
                }
                ".jpg"  { 
                    $response.ContentType = "image/jpeg"
                    $buffer = [System.IO.File]::ReadAllBytes($filePath)
                }
                ".jpeg" { 
                    $response.ContentType = "image/jpeg"
                    $buffer = [System.IO.File]::ReadAllBytes($filePath)
                }
                ".gif"  { $response.ContentType = "image/gif" }
                ".svg"  { $response.ContentType = "image/svg+xml" }
                default { $response.ContentType = "text/plain" }
            }
            
            $response.ContentLength64 = $buffer.Length
            $response.StatusCode = 200
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        } else {
            # File not found
            $notFoundMessage = "<h1>404 - File Not Found</h1><p>The requested file '$requestedPath' was not found.</p>"
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($notFoundMessage)
            $response.ContentType = "text/html"
            $response.ContentLength64 = $buffer.Length
            $response.StatusCode = 404
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        }
        
        $response.Close()
    }
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
} finally {
    if ($listener.IsListening) {
        $listener.Stop()
    }
    Write-Host "Server stopped." -ForegroundColor Yellow
}