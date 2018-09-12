# clear up the target folder
Write-Host "deleting files in target folder..."
Remove-Item -Path .\TestAppPkg -Recurse -Force

# build all
Write-Host "Building code..."
dotnet build .\TestApp\Pluralsight.SfProd\Pluralsight.SfProd.sln -c release -v quiet

# package Service Fabric app
Write-Host "Packaging Service Fabric application..."
msbuild .\TestApp\Pluralsight.SfProd\Pluralsight.SfProd\Pluralsight.SfProd.sfproj /p:Configuration=Release /t:Package /nologo /verbosity:quiet

# compress existing SF package
Write-Host "Compressing package..."
Copy-ServiceFabricApplicationPackage -ApplicationPackagePath .\TestApp\Pluralsight.SfProd\Pluralsight.SfProd\pkg\Release -CompressPackage -SkipCopy -Verbose

# copy to deployment destination
Write-Host "Copying to TestAppPkg folder..."
Copy-Item .\TestApp\Pluralsight.SfProd\Pluralsight.SfProd\pkg\Release\ .\TestAppPkg\ -Recurse -Force

