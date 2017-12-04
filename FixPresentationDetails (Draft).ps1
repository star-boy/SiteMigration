function FixPresentationDetails($path) {
    $Items = Get-ChildItem -Path $path -recurse -Language *
    foreach ($Item in $Items) {
        $Renderings = $Item["__Renderings"]
        if (($Renderings -ne "") -Or ($Renderings -ne $null)) {
            if (($Renderings -match "$oldTenant\\") -Or ($Renderings -match "$oldTenant ") -Or ($Renderings -match "$oldTenant/")) {
                $Renderings = $Renderings -replace "$oldTenant\\", "$newTenant\\"
                $Renderings = $Renderings -replace "$oldTenant ", "$newTenant "
                $Renderings = $Renderings -replace "$oldTenant/", "$newTenant/"


                $pattern2 = '\{(.*?)\}'
                filter Matches($pattern2) {
                    $_ | Select-String -AllMatches $pattern2 | 
                        Select-Object -ExpandProperty Matches | 
                        Select-Object -ExpandProperty Value
                }
                
                $data = $Renderings
                foreach ($i in $data | Matches $pattern2) {
                    $oldItem = Get-Item master: -ID $i
                    $itempath = $oldItem.Paths.FullPath
                    #Write-Host $itempath
                    if ($itempath -ne $null) {
                        if (($itempath -match "$oldTenant\\") -Or ($itempath -match "$oldTenant ") -Or ($itempath -match "$oldTenant/")) {
                            $itempath = $itempath -replace "$oldTenant\\", "$newTenant\\"
                            $itempath = $itempath -replace "$oldTenant ", "$newTenant "
                            $itempath = $itempath -replace "$oldTenant/", "$newTenant/"
                        }
                        #$itempath = $itempath -replace "Microsoft 14 14", "Microsoft 14" // redundant naming bug error
                        $newItem = get-Item -Path $itempath
                        $itemIdValue = $newItem.ID
                        $data = $data -replace $i, $itemIdValue
                    }
            
                }
            
               $newdata = $data
            }
            $Item.Editing.BeginEdit()
            $Item["__Renderings"] = $newdata
            $Item.Editing.EndEdit()
        }
    }

}
    
$oldTenant = "Microsoft" # Change this, To get Value from User
$newTenant = "Micro3"    # Change this, To get Value from User

FixPresentationDetails("master:/content/Micro3")