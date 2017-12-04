#----------------------------------------------
#Copy Items
function CopyItems($oldPath,$newPath,$name)
{
			Write-Host 'Copying '$name' from '$oldPath' to '$newPath

			#Remove all child items of target directory 
			Get-ChildItem -Path $newPath | remove-item -recurse
			#Copy all items from source directory to target directory
			Get-ChildItem -Path $oldPath | Copy-Item -Destination $newPath -Recurse -Container

			Write-Host 'Task Completed'
}

#----------------------------------------------
#Rename Items
    function renameItems([String] $Path, [String] $Name)
    {
        cd $Path
        Write-Host 'Renaming '$Name
        foreach($item in Get-ChildItem -Recurse .) 
        { 
            $originalName = $item.Name
            $newName = $originalName -Replace "$SourceName", "$DestinationName"
        
            $item.Editing.BeginEdit()
            $item.Name = $newName;
            $item.Fields["__Display name"].Value = $newName;
            $item.Editing.EndEdit()
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
#$SublayoutsPath = "master:/sitecore/layout/Sublayouts"
#CopyItems -oldPath "$SublayoutsPath/$oldTenant" -newPath "$SublayoutsPath/$newTenant" -name "Sublayouts"

#Copy Media Library Tree
#$MediaPath = "master:/sitecore/media library"
#CopyItems -oldPath "$MediaPath/$oldTenant" -newPath "$MediaPath/$newTenant" -name "Media"

#Copy Media Files Library Tree
$MediaFilesPath = "master:/sitecore/media library/Files"
CopyItems -oldPath "$MediaFilesPath/$oldTenant" -newPath "$MediaFilesPath/$newTenant" -name "Media Files"

#Copy Media Images Library Tree
$MediaImagesPath = "master:/sitecore/media library/Images"
CopyItems -oldPath "$MediaImagesPath/$oldTenant" -newPath "$MediaImagesPath/$newTenant" -name "Media Images"

#Copy Templates Tree
$TemplatesPath = "master:/sitecore/templates"
CopyItems -oldPath "$TemplatesPath/$oldTenant" -newPath "$TemplatesPath/$newTenant" -name "Templates"

#Rename Content Items
$ContentPath = "$root"
renameItems -Path "$root/$newTenant" -Name 'content items'
