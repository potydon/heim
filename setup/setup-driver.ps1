#!/usr/bin/env pwsh

# copy script ini ke directory yang sama dengan dimana lu extract driver nya,
# intinya di folder yang sama dimana ada folder Drivers\

# pnputil /add-driver '.\Drivers\*.inf' /subdirs /install

get-childitem '.\Drivers' -recurse -filter *.inf | foreach-object {
    write-host "[driver] $($_.Directory.Name)" -foregroundcolor cyan
    pnputil /add-driver $_.FullName /install | out-null
    if ($LASTEXITCODE -notin 0, 3010) { 
        write-host "  failed: $LASTEXITCODE" -foregroundcolor red
    }
}
