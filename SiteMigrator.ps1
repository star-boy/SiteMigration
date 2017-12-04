#----------------------------------------------
#Fix Presentation Details
# This Script accepts "root path" of the Content tree and Iterates through all the fields.
# If it finds any Field Containing Renderigns it replaces the oldtentant files with the newtenant files
# It Replaces : Layout, Placeholder Settings and Renderings

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

#----------------------------------------------

#----------------------------------------------
#Fix Image Fields 
# This Script accepts "root path" of the Content tree and Iterates through all the fields.
# If it finds any Field Containing The Image or Picture it replaces the image with newtenant Image Location

function FixImageFields($path){
    Write-Host "Fixing Image fields for $path"
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
                            #$itempath = $itempath -replace "Microsoft 14 14", "Microsoft 14" // redundant naming bug error the above code fixes it
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
    Write-Host "Task Completed"
}
#----------------------------------------------


#----------------------------------------------
#Add Language and Version Call this Function Last

function FixLanguage($path){
    
    $items = Get-ChildItem -Path $path -recurse 
        foreach($item in $items){
            
        if(($item.Language -ne "") -or ($item.Language -ne $null))
        {
        Add-ItemLanguage -item $item -Language $oldLang -TargetLanguage $newLang -IfExist OverwriteLatest
        Remove-ItemLanguage -item $item -Language $oldLang
        }
    }
    }
#----------------------------------------------

#----------------------------------------------
#Copy Items
function CopyItems($oldPath,$newPath,$name)
{           
            $item = Get-Item -Path $oldPath
            if($item -ne $null)
            {
            Write-Host 'Copying '$name' from '$oldPath' to '$newPath

			#Remove all child items of target directory 
			Get-ChildItem -Path $newPath | remove-item -recurse
			#Copy all items from source directory to target directory
			Get-ChildItem -Path $oldPath | Copy-Item -Destination $newPath -Recurse -Container

			Write-Host 'Task Completed'
            }

			
}

#----------------------------------------------
#Rename Items
    function renameItems([String] $Path, [String] $Name)
    {
        cd $Path
        Write-Host 'Renaming '$Name
        foreach($item in Get-ChildItem -Language * -Recurse .) 
        { 
            $originalName = $item.Name
            $newName = $originalName -Replace "$oldTenant", "$newTenant"
        
            $item.Editing.BeginEdit()
            $item.Name = $newName;
            $item.Fields["__Display name"].Value = $newName;
            $item.Editing.EndEdit()
        }
        Write-Host 'Task Completed'
    }


#---------------------------------------------------------
#Change Templates
    function changeItemTemplates([String] $Path)
    {
        cd $Path
        Write-Host 'Change Item Templates'
            
        foreach($item in Get-ChildItem -Language * -Recurse .) 
        { 
            $oldItemTemplate = Get-ItemTemplate -Item $item
            $oldTemplateId = $oldItemTemplate.Id
            $oldItemTemplate = Get-Item $oldTemplateId
            
            $oldItemPath = $oldItemTemplate.Paths.FullPath
            $newPath = $oldItemPath -Replace $oldTenant, $newTenant
            $newItem = Get-Item -path $newPath
            Set-ItemTemplate -Item $item -TemplateItem $newItem
        }
        Write-Host 'Task Completed'

    }

#----------------------------------------------
#Update Allowed Controls in placeholder settings
    function updateAllowedControls([String] $Path)
    {
        cd $Path
        Write-Host 'Updating allowed controls of placeholder settings'                   
        foreach($item in Get-ChildItem -Language * -Recurse .) 
        { 
            $originalValue = $item.Fields["Allowed Controls"].Value
            if(![string]::IsNullOrEmpty($originalValue))
            {
                foreach($itemId in $originalValue.split("|"))
                {
                    $originalItem = Get-Item $itemId
                    $originalPath = $originalItem.Paths.FullPath
                    $newPath = $originalPath -Replace $oldTenant, $newTenant
                    $newItem = Get-Item -path $newPath
                    $newItemId = $newItem.Id
                    $newValue = $originalValue -Replace $itemId, $newItemId
                    $item.Editing.BeginEdit()
                    $item["Allowed Controls"] = $newValue
                    $item.Editing.EndEdit()
                }
            }
        }
        Write-Host 'Task Completed'
    }
    
#----------------------------------------------
#Update path
    function updatePath([String] $Path, [String] $Name)
    {
        cd $Path
        Write-Host 'Updating path of '$Name                    
        foreach($item in Get-ChildItem -Language * -Recurse .) 
        { 
            $itemFieldList = Get-ItemField -Item $item
            foreach($itemField in $itemFieldList)
            {
                $originalValue = $item.Fields[$itemField].Value
                if(![string]::IsNullOrEmpty($originalValue))
                {
                    $newValue = $originalValue -Replace $oldTenant, $newTenant
                    $item.Editing.BeginEdit()
                    $item[$itemField] = $newValue
                    $item.Editing.EndEdit()
                }
                
            }			
        }
        Write-Host 'Task Completed'
    }
	
#-------------------------------UI---------------------------------------------------
#------------------------------------------------------------------------------------
$result = Read-Variable -Parameters `
    @{ Name = "root"; Value="master:/sitecore/content"; Title="Root"}, `
    @{ Name = "oldTenant"; Value="Old Tenant Name"; Title="Orignal Tenant Name"}, `
    @{ Name = "oldLang"; Value="en-ca"; Title="Original Tenant Language"}, `
    @{ Name = "newTenant"; Value="New Tenant Name"; Title="New Tenant Name"}, `
    @{ Name = "newLang"; Value="en-uk"; Title="New Tenant Language"} `
    -Description "Copy Tenant Very Quickly." `
    -Title "Copy tenant" -Width 500 -Height 500 `
    -OkButtonName "Proceed" -CancelButtonName "Abort" 
    
If ($result -ne "ok")
{
    Exit
}
#------------------------------------------------------------------------------------

#Copy Content tree
$ContentPath = "$root"
CopyItems -oldPath "$root/$oldTenant" -newPath "$root/$newTenant" -name "Content"

#Copy Layout Tree
$layoutPath = "master:/sitecore/layout/Layouts"
CopyItems -oldPath "$layoutPath/$oldTenant" -newPath "$layoutPath/$newTenant" -name "Layout"

#Copy Models Tree
$modelsPath = "master:/sitecore/layout/Models"
CopyItems -oldPath "$modelsPath/$oldTenant" -newPath "$modelsPath/$newTenant" -name "Models"

#Copy Placeholder Settings Tree
$PlaceholderPath = "master:/sitecore/layout/Placeholder Settings"
CopyItems -oldPath "$PlaceholderPath/$oldTenant" -newPath "$PlaceholderPath/$newTenant" -name "Placeholder Settings"

#Copy Renderings Tree
$RenderingsPath = "master:/sitecore/layout/Renderings"
CopyItems -oldPath "$RenderingsPath/$oldTenant" -newPath "$RenderingsPath/$newTenant" -name "Renderings"

#Copy Sublayouts Tree
$SublayoutsPath = "master:/sitecore/layout/Sublayouts"
CopyItems -oldPath "$SublayoutsPath/$oldTenant" -newPath "$SublayoutsPath/$newTenant" -name "Sublayouts"

#Copy Media Library Tree
$MediaPath = "master:/sitecore/media library"
CopyItems -oldPath "$MediaPath/$oldTenant" -newPath "$MediaPath/$newTenant" -name "Media"

#Copy Media Files Library Tree
$MediaFilesPath = "master:/sitecore/media library/Files"
CopyItems -oldPath "$MediaFilesPath/$oldTenant" -newPath "$MediaFilesPath/$newTenant" -name "Media Files"

#Copy Media Images Library Tree
$MediaImagesPath = "master:/sitecore/media library/Images"
CopyItems -oldPath "$MediaImagesPath/$oldTenant" -newPath "$MediaImagesPath/$newTenant" -name "Media Images"

#Copy Templates Tree
$TemplatesPath = "master:/sitecore/templates"
CopyItems -oldPath "$TemplatesPath/$oldTenant" -newPath "$TemplatesPath/$newTenant" -name "Templates"

#Copy Score Templates Tree
$TemplatesPath = "master:/sitecore/templates/Branches"
CopyItems -oldPath "$TemplatesPath/$oldTenant" -newPath "$TemplatesPath/$newTenant" -name "Score Templates"

#Rename Content Items
$ContentPath = "$root"
renameItems -Path "$root/$newTenant" -Name 'Content Items'

#Rename Layout Tree
$layoutPath = "master:/sitecore/layout/Layouts"
renameItems -Path "$layoutPath/$newTenant" -Name 'Layout'

#Rename Models Tree
$modelsPath = "master:/sitecore/layout/Models"
renameItems -Path "$modelsPath/$newTenant" -Name 'Models'

#Rename Placeholder Settings Tree
$PlaceholderPath = "master:/sitecore/layout/Placeholder Settings"
renameItems -Path "$PlaceholderPath/$newTenant" -Name 'Placeholder Settings'

#Rename Renderings Tree
$RenderingsPath = "master:/sitecore/layout/Renderings"
renameItems -Path "$RenderingsPath/$newTenant" -Name 'Renderings'

#Rename Sublayouts Tree
#$SublayoutsPath = "master:/sitecore/layout/Sublayouts"
#renameItems -Path "$SublayoutsPath/$newTenant" -Name 'Sublayouts'

#Rename Media Library Tree
#$MediaPath = "master:/sitecore/media library"
#renameItems -Path "$MediaPath/$newTenant" -Name 'Media Library'

#Rename Media Files Library Tree
$MediaFilesPath = "master:/sitecore/media library/Files"
renameItems -Path "$MediaFilesPath/$newTenant" -Name 'Media Files'

#Rename Media Images Library Tree
$MediaImagesPath = "master:/sitecore/media library/Images"
renameItems -Path "$MediaImagesPath/$newTenant" -Name 'Media Images'

#Rename Templates Tree
$TemplatesPath = "master:/sitecore/templates"
renameItems -Path "$TemplatesPath/$newTenant" -Name 'Templates'

#Rename Score Templates Tree
$TemplatesPath = "master:/sitecore/templates/Branches"
renameItems -Path "$TemplatesPath/$newTenant" -Name 'Score Templates'

#Change item templates
$ContentPath = "$root"
changeItemTemplates -Path "$root/$newTenant"

#Update path of Layouts
$layoutPath = "master:/sitecore/layout/Layouts"
updatePath -Path "$layoutPath/$newTenant" -Name 'Layouts'

#Update path of Models
$modelsPath = "master:/sitecore/layout/Models"
updatePath -Path "$modelsPath/$newTenant" -Name 'Models'

#Update path of Renderings
$RenderingsPath = "master:/sitecore/layout/Renderings"
updatePath -Path "$RenderingsPath/$newTenant" -Name 'Renderings'

#Update path of Sublayouts
#$SublayoutsPath = "master:/sitecore/layout/Sublayouts"
#updatePath -Path "$SublayoutsPath/$newTenant" -Name 'Sublayouts'

#Update allowed controls in Placeholder Settings
$PlaceholderPath = "master:/sitecore/layout/Placeholder Settings"
updateAllowedControls -Path "$PlaceholderPath/$newTenant"

#Fixing Image Fields
$ContentPath = "$root"
FixImageFields("$root/$newTenant")

#Fixing Presentation Details.
$ContentPath = "$root"
FixPresentationDetails("$root/$newTenant")


#Fixing Presentation Details of Templates.
$TemplatesPath = "master:/sitecore/templates"
FixPresentationDetails("$TemplatesPath/$newTenant")


###############***** Please Call this Function LAST, ADD ANY ADDTIONAL CODE ABOVE THIS.
#Fix Languages ***** Please Call this Function LAST, ADD ANY ADDTIONAL CODE ABOVE THIS.

#Fix Language for Content 
FixLanguage("$root/$newTenant")
#Fix Language for Content 
FixLanguage("$layoutPath/$newTenant")
#Fix Language for Content 
FixLanguage("$modelsPath/$newTenant")
#Fix Language for Content 
FixLanguage("$PlaceholderPath/$newTenant")
#Fix Language for Content 
FixLanguage("$RenderingsPath/$newTenant")
#Fix Language for Content 
FixLanguage("$SublayoutsPath/$newTenant")
#Fix Language for Content 
FixLanguage("$MediaPath/$newTenant")
#Fix Language for Content 
FixLanguage("$MediaFilesPath/$newTenant")
#Fix Language for Content 
FixLanguage("$MediaImagesPath/$newTenant")
#Fix Language for Content 
FixLanguage("$TemplatesPath/$newTenant")
