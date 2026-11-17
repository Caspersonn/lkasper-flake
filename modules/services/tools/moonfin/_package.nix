{ lib, buildDotnetModule, fetchFromGitHub, dotnetCorePackages }:
buildDotnetModule {
  pname = "moonbase-holyarrs";
  version = "3.1.0-c6aad40";
  src = fetchFromGitHub {
    owner = "Moonfin-Client";
    repo = "Plugin";
    rev = "c6aad40f61a89be84a272329731b5b688eac8567";
    sha256 = "0bh5pqc00wmipizh282il0ckh110904zag4n4j2ifsdg6qdn6ypb";
  };
  patches = [ ./moonbase.patch ];
  postPatch = ''
    cp ${./HolyArrsBackend.cs} Jellyfin/backend/Services/HolyArrsBackend.cs
    cp ${./HolyArrsIntegration.cs} Jellyfin/backend/Services/HolyArrsIntegration.cs
  '';
  projectFile = "Jellyfin/backend/Moonfin.Server.csproj";
  nugetDeps = ./_deps.nix;
  dotnet-sdk = dotnetCorePackages.sdk_8_0;
  dotnet-runtime = dotnetCorePackages.aspnetcore_8_0;
  executables = [ ];
  dontPublish = true;
  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    cp Jellyfin/backend/bin/Release/net8.0/*/Moonfin.Server.dll "$out/"
    cp Jellyfin/backend/bin/Release/net8.0/*/SharpCompress.dll "$out/"
    runHook postInstall
  '';
  meta = {
    description = "Moonbase Jellyfin plugin with native HolyArrs requests";
    license = lib.licenses.gpl3Plus;
    platforms = [ "x86_64-linux" "aarch64-linux" ];
  };
}
