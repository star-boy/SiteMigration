
function FixImageFields($path){
    $items = get-ChildItem -Path $path -recurse -Language *
    foreach($item in $items)
    {
       foreach($field in $item.Fields)
       {
           $fieldname = $field.Name
           if(($fieldname -match "Image") -Or ($fieldname -match "Picture"))
           {
               $data = $field.Value
               $pattern2 = '\{(.*?)\}'
                filter Matches($pattern2)
                    {
                        $_ | Select-String -AllMatches $pattern2 | 
                        Select-Object -ExpandProperty Matches | 
                        Select-Object -ExpandProperty Value
                    } 
                foreach($i in $data | Matches $pattern2){
                    $oldItem = Get-Item master: -ID $i
                    $itempath = $oldItem.Paths.FullPath
                    #Write-Host $itempath
                    if($itempath -ne $null)
                        {
                            if(($itempath -match "$oldTenant\\") -Or ($itempath -match "$oldTenant ") -Or ($itempath -match "$oldTenant/"))
                                    {
                                        $itempath = $itempath -replace "$oldTenant\\","$newTenant\\"
                                        $itempath = $itempath -replace "$oldTenant ","$newTenant "
                                        $itempath = $itempath -replace "$oldTenant/","$newTenant/"
                                    }
                            #$itempath = $itempath -replace "Microsoft 14 14", "Microsoft 14" // redundant naming bug error
                            $newItem =  get-Item -Path $itempath
                            $itemIdValue = $newItem.ID
                            $data = $data -replace $i,$itemIdValue
                        }

                }
                $item.Editing.BeginEdit()
               $item[$fieldname] = $data
               $item.Editing.EndEdit()
           }
       }
    }
}
    
$oldTenant = "Microsoft" # Change this, To get Value from User
$newTenant = "Micro3"    # Change this, To get Value from User

FixImageFields("master:/content/Micro3") #Change to input path or the tenant root 