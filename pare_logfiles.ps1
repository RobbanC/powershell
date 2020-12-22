################## METADATA #################### 
# NAME: Roberto Canovas
# USERNAME: b18robth
# COURSE: Script programming IT384G – Spring 2019 
# ASSIGNMENT: Assignment 1 - PowerShell
# DATE OF LAST CHANGE: 2019-05-22
################################################

cls

$users = @()
Get-ADOrganizationalUnit -Filter * | Where {$_.Name -ne "Domain Controllers"} | ForEach-Object {Get-ADUser -Filter * -SearchBase $_.DistinguishedName} | ForEach-Object {$users += $_.SamAccountName}
 # För att filtrera ut alla systemandvändare används strängen ovanför. Detta är för att systemanvändare inte ska listas i listan med lyckade/misslyckade inloggnignar.
 # Först
"---------------------"
"Lyckade inloggningar"
"---------------------"
$lyckad = Get-Eventlog -Logname Security -InstanceId 4768 | select @{n="Username";e={$_.ReplacementStrings[0]}},TimeGenerated
$misslyckad = Get-EventLog -LogName Security -InstanceId 4771 | select @{n="Username";e={$_.ReplacementStrings[0]}}, TimeGenerated
#För att få ut användarnamnen i logfilen används strängen ovanför där select @{n="Username";e={$_.ReplacementStrings[0]}}
#används för att byta ut och lägga till användarnamnet istället för id på användaren. Detta gör det lättare att senae filtrera ut på anv namn.

$lyckad | Where {$users -contains $_.Username} | Group-Object -Property Username
"--------------------------------"
"Misslyckade inloggningar per dag"
"--------------------------------"


$misslyckad.TimeGenerated | Group-Object -Property day | Sort-Object count -Descending
$användare = ($lyckad | Group-Object -Property Username)
$användarfel = ($misslyckad | Group-Object -Property Username)
#Här listas alla misslyckade inloggningar med hjälp av timegenerated och grupperar efter dag och sedan sorteras på största värdet först
"---------------------"
"Användare per procent"
"---------------------"
$tal = 0
Foreach ($line in $användare)
{
    $user = $line.name
    $summa = $line
    if ($user -in (Get-ADUser -Filter * | Select-Object -ExpandProperty SamAccountName) -and (Get-ADUser -Filter {SamAccountName -like $user} -Properties * | Select isCriticalSystemObject | Select-Object -ExpandProperty isCriticalSystemObject) -ne "True")
    #För att sortera ut alla användare används strängen ovanför. en select funktion finns med för att välja alla systemanvändare och sedan expenadera denna och se om dessa användare är false.
    #Detta gör att systemanvändare sorteras bort och OU användare listas bara.
    
    {
    if ($användarfel[$tal].count -eq 0)
    
 {
        write-host $line.Name, "vart exkluderad"
 }
 else{

    $summa = ($användarfel[$tal].count / ($line.count + $användarfel[$tal].count))
    write-host ("användaren" , $line.name, "misslyckade inloggningar per", ($summa * 100), "%")
    $tal = ($tal + 1)
 }
    }
    else
    {
    
    }
}

#Här sorteras varje ut systemanvändare och sedan används en matematiskformel där det hela värdet delas med delen för att få ut procenten.
#Sedan multipliceras summan med 100 för att få ut procenten. 
  
