
# build all
dotnet build .\TestApp\Pluralsight.SfProd\Pluralsight.SfProd.sln --configuration release

# package Service Fabric app
msbuild .\TestApp\Pluralsight.SfProd\Pluralsight.SfProd\Pluralsight.SfProd.sfproj /p:Configuration=Release /t:Package

# compress existing SF package
Copy-ServiceFabricApplicationPackage -ApplicationPackagePath .\TestApp\Pluralsight.SfProd\Pluralsight.SfProd\pkg\Release -CompressPackage -SkipCopy

# copy to deployment destination
Copy-Item .\TestApp\Pluralsight.SfProd\Pluralsight.SfProd\pkg\ .\TestAppPkg\ -Recurse -Force

