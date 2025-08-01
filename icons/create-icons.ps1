# Simple PNG creation using .NET
Add-Type -AssemblyName System.Drawing

function Create-Icon($size, $filename) {
    $bitmap = New-Object System.Drawing.Bitmap($size, $size)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    
    # Fill background with green
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(76, 175, 80))
    $graphics.FillRectangle($brush, 0, 0, $size, $size)
    
    # Draw white text "ISL"
    $font = New-Object System.Drawing.Font("Arial", ($size * 0.2), [System.Drawing.FontStyle]::Bold)
    $whiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    $format = New-Object System.Drawing.StringFormat
    $format.Alignment = [System.Drawing.StringAlignment]::Center
    $format.LineAlignment = [System.Drawing.StringAlignment]::Center
    
    $graphics.DrawString("ISL", $font, $whiteBrush, ($size/2), ($size/2), $format)
    
    # Save the bitmap
    $bitmap.Save($filename, [System.Drawing.Imaging.ImageFormat]::Png)
    
    # Cleanup
    $graphics.Dispose()
    $bitmap.Dispose()
    $brush.Dispose()
    $whiteBrush.Dispose()
    $font.Dispose()
}

# Create icons
Create-Icon 16 "icon16.png"
Create-Icon 48 "icon48.png"
Create-Icon 128 "icon128.png"

Write-Host "Icons created successfully!"
