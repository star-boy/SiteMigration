#function to fix renderings of items
function FixRenderings($data){
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
            #$itempath = $itempath -replace "Microsoft 14 14", "Microsoft 14" // redundancy naming bug error
            $newItem =  get-Item -Path $itempath
            $itemIdValue = $newItem.ID
            $data = $data -replace $i,$itemIdValue
 }

}

return $data
}

function FixTemplate($path){
    $items = get-ChildItem -Path $path -recurse
    foreach($item in $items)
    {
      $templateRoot = '/sitecore/templates'
      $template = Get-ItemTemplate -Item $item
      $templatePath = $template.FullName
      $templatePath = $templatePath -replace $oldTenant,$newTenant
      $master = [Sitecore.Configuration.Factory]::GetDatabase("master");
      $templateItem = $master.Templates[$templatePath];
      $item.ChangeTemplate($templateItem)
    }
}
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

function FixImageFields($path){
    $items = get-ChildItem -Path $path -recurse
    foreach($item in $items)
    {
       foreach($field in $item.Fields)
       {
           if($field -match "Image")
           {
              if($field -match "mediaid")
              {
                #Write-Host $item.Paths.FullPath
               $fieldname = $field.Name
               #Write-Host $fieldname
               Write-Host $field.Value
               $text =  $field -replace "^.*{", ""
               $text =  $text -replace "}.*$", ""
              #Write-Host $text
               $newImageItem = Get-Item master: -ID $text
               $itempath = $newImageItem.Paths.FullPath
               $itempath = $itempath -replace $oldTenant, $newTenant
               $newTenItem =  get-Item -Path $itempath
               $itemIdValue = $newTenItem.ID
               $ImageValue = "<image mediaid=`"$itemIdValue`" />"
               #Write-Host $ImageValue
               #Write-Host $newTenItem.ID
               $item.Editing.BeginEdit()
               $item[$fieldname] = $ImageValue
               $item.Editing.EndEdit()
              }
           }
           elseif ($field -match "Picture")
           {
               if($field -match "<img mediaid=")
              {
                #Write-Host $item.Paths.FullPath
               $fieldname = $field.Name
               #Write-Host $fieldname
               Write-Host $field.Value
               $text =  $field -replace "^.*{", ""
               $text =  $text -replace "}.*$", ""
              #Write-Host $text
               $newImageItem = Get-Item master: -ID $text
               $itempath = $newImageItem.Paths.FullPath
               $itempath = $itempath -replace $oldTenant, $newTenant
               $newTenItem =  get-Item -Path $itempath
               $itemIdValue = $newTenItem.ID
               $ImageValue = "<image mediaid=`"$itemIdValue`" />"
               #Write-Host $ImageValue
               #Write-Host $newTenItem.ID
               $item.Editing.BeginEdit()
               $item[$fieldname] = $ImageValue
               $item.Editing.EndEdit()
              }

           }
           }
       }
    }
    
$result = Read-Variable -Parameters `
    @{ Name = "root"; Value="master:/content"; Title="Root"}, `
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
#$root = "master:/content/"
#$oldTenant = "SKII-JP"
#$newTenant = "SKII-RU"
$oldTenantPath = "$root/$oldTenant"
$newTenantPath = "$root/$newTenant"
#$newLang = "en-ca"
#$oldLang = "ja-JP"
Write-Host "Copying Items"
Write-Host "Copying Content Tree"
# Content Tree
New-Item -Path $root -Name "$newTenant" -ItemType "/sitecore/templates/Score/Base/Website Root" | Out-Null
copy-item "$oldTenantPath/*" "$newTenantPath/" -recurse 
get-childItem -Path $newTenantPath -recurse | rename-item -newname { $_.name -replace $oldTenant,$newTenant }
FixLanguage($newTenantPath) 

Write-Host "Copying Layouts Folder"
#Layouts Folder
$layoutsRootPath = "master:/layout/Layouts"
New-Item -Path $layoutsRootPath -Name "$newTenant" -ItemType "/sitecore/templates/System/Layout/Layout Folder" | Out-Null
copy-item "$layoutsRootPath/$oldTenant/*" "$layoutsRootPath/$newTenant/" -recurse
FixLanguage("$layoutsRootPath/$newTenant")


Write-Host "Copying Models Folder"
#Models Folder
$modelsRootPath = "master:/layout/Models"
New-Item -Path $modelsRootPath -Name "$newTenant" -ItemType "/sitecore/templates/Common/Folder" | Out-Null
copy-item "$modelsRootPath/$oldTenant/*" "$modelsRootPath/$newTenant/" -recurse
FixLanguage("$modelsRootPath/$newTenant")


Write-Host "Copying PlaceHolder Settings Folder"
#PlaceHolder Settings Folder
$placeholderSettingsRootPath = "master:/layout/Placeholder Settings"
New-Item -Path $placeholderSettingsRootPath -Name "$newTenant" -ItemType "/sitecore/templates/System/Layout/Placeholder Settings Folder" | Out-Null
copy-item "$placeholderSettingsRootPath/$oldTenant/*" "$placeholderSettingsRootPath/$newTenant/" -recurse
get-childItem -Path "$placeholderSettingsRootPath/$newTenant" -recurse | rename-item -newname { $_.name -replace $oldTenant,$newTenant }
FixLanguage("$placeholderSettingsRootPath/$newTenant")


Write-Host "Copying Renderings Folder"
#Renderings Folder
$renderingsRootPath = "master:/layout/Renderings"
New-Item -Path $renderingsRootPath -Name "$newTenant" -ItemType "/sitecore/templates/Score/Renderings/Rendering Folder with Area" | Out-Null
copy-item "$renderingsRootPath/$oldTenant/*" "$renderingsRootPath/$newTenant/" -recurse
get-childItem -Path "$renderingsRootPath/$newTenant" -recurse | rename-item -newname { $_.name -replace $oldTenant,$newTenant }
FixLanguage("$renderingsRootPath/$newTenant")


Write-Host "Copying Media Library Folder"
#media Library Folder
$mediaLibraryPath = "master:/Media Library";
New-Item -Path $mediaLibraryPath -Name "$newTenant" -ItemType "/sitecore/templates/System/Media/Media folder" | Out-Null
copy-item "$mediaLibraryPath/$oldTenant/*" "$mediaLibraryPath/$newTenant/" -recurse
get-childItem -Path "$mediaLibraryPath/$newTenant" -recurse | rename-item -newname { $_.name -replace $oldTenant,$newTenant }
FixLanguage("$mediaLibraryPath/$newTenant")


Write-Host "Copying Media Library Images Folder"
$mediaLibraryImagesPath = "master:/Media Library/Images";
New-Item -Path $mediaLibraryImagesPath -Name "$newTenant" -ItemType "/sitecore/templates/System/Media/Media folder" | Out-Null
copy-item "$mediaLibraryImagesPath/$oldTenant/*" "$mediaLibraryImagesPath/$newTenant/" -recurse
get-childItem -Path "$mediaLibraryImagesPath/$newTenant" -recurse | rename-item -newname { $_.name -replace $oldTenant,$newTenant }
FixLanguage("$mediaLibraryImagesPath/$newTenant")


Write-Host "Copying Media Library Files Folder"
$mediaLibraryFilesPath = "master:/Media Library/Files";
New-Item -Path $mediaLibraryFilesPath -Name "$newTenant" -ItemType "/sitecore/templates/System/Media/Media folder" | Out-Null
copy-item "$mediaLibraryFilesPath/$oldTenant/*" "$mediaLibraryFilesPath/$newTenant/" -recurse
get-childItem -Path "$mediaLibraryFilesPath/$newTenant" -recurse | rename-item -newname { $_.name -replace $oldTenant,$newTenant }
FixLanguage("$mediaLibraryFilesPath/$newTenant")


Write-Host "Copying Templates Folder"
#Templates Folder
$TemplatesPath = "master:/templates";
New-Item -Path $TemplatesPath -Name "$newTenant" -ItemType "/sitecore/templates/System/Templates/Template Folder" | Out-Null
copy-item "$TemplatesPath/$oldTenant/*" "$TemplatesPath/$newTenant/" -recurse
get-childItem -Path "$TemplatesPath/$newTenant" -recurse | rename-item -newname { $_.name -replace $oldTenant,$newTenant }
FixLanguage("$TemplatesPath/$newTenant")


Write-Host "Fixing Image Fields"
# Fix Image Fields
FixImageFields($newTenantPath)

Write-Host "Fixing Template Fields"
# Fix Template Fields
FixTemplate($newTenantPath)

Write-Host "Fixing Renderings"
#Fix Renderings
$Items = Get-ChildItem -Path $newTenantPath -recurse
    foreach($Item in $Items)
    {
        $Renderings = $Item["__Renderings"]
        if($Renderings -ne "")
        {
            if(($Renderings -match "$oldTenant\\") -Or ($Renderings -match "$oldTenant ") -Or ($Renderings -match "$oldTenant/"))
                {
                    $Renderings = $Renderings -replace "$oldTenant\\","$newTenant\\"
                    $Renderings = $Renderings -replace "$oldTenant ","$newTenant "
                    $Renderings = $Renderings -replace "$oldTenant/","$newTenant/"
                }
            $newdata = FixRenderings($Renderings)
            $Item.Editing.BeginEdit()
            $Item["__Renderings"] = $newdata
            $Item.Editing.EndEdit()
        }
    }
#Fix Language for Tenant    
FixLanguage($newTenantPath)    