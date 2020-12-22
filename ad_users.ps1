
################## METADATA #################### 
# NAME: Roberto Canovas
################################################


cls
import-module ActiveDirectory
#Här importeras modulen ActiveDirectory in.
If ($args) {
    $filepath = $args
}
Else {
    $filepath = Read-Host "Enter a file path please!"
}
$users = import-CSV $filepath -Encoding UTF7 -Delimiter ";"
#Med hjälp av if-satsen kommer användaren att få skriva in sökvägen för filen som ska importeras. 
#If-satsen kollar om argumentet är sant och ifall det är sant kommer inte användaren behöva skriva in sökvägen till csv filen.
#
ForEach ($user in $users) {
    $name = $user.Name
    $firstname = $name.split(" ")[0]
    $lastname = $name.split(" ")[1] 
    $accname = $firstname.substring(0,2).ToLower()
    $accname = $accname + $lastname.substring(0,2).ToLower()
    $faccname = $accname
    #Här används en foreach iteration för att splita, replace namnet och åäö för varje användare i filen. 
    #Den ändrar inte värderna i filen men när de läggs in i variabeln.
   #För att få ut användarnamnet måste förnamn och efternamn splitas och sedan tas första 2bokstäverna från för och efternamn
    If ($accname -like '*ä*') {$accname = $accname.Replace('ä','a')}
    If ($accname -like '*ö*') {$accname = $accname.Replace('ö','o')}
    If ($accname -like '*å*') {$accname = $accname.Replace('å','a')}
    #Eftersom skriptet ska vara unviersalt måste åäö bytas ut mot ao, detta görs med funktionen replace.
    $depart = $user.Department
    $Email = $user.Email
    $descr = $user.Description
    $card = $user.PassCardNumber
    $OU = "OU=$depart,DC=script,DC=local"
    $DistinguishedName = 'CN='+$name+','+$OU
    $pass1 = ([char[]]([char]33..[char]47) | sort {Get-Random})[0..2] -join ''
    $pass2 = ([char[]]([char]65..[char]90) | sort {Get-Random})[0..2] -join ''
    $pass3 = ([char[]]([char]48..[char]57) | sort {Get-Random})[0..2] -join ''
    $pass4 = ([char[]]([char]97..[char]122) | sort {Get-Random})[0..2] -join ''
    $pass = $pass1 + $pass2 + $pass3 + $pass4
    #Det ska slumpas ett lösenord som är såpass starkt att det används olika versaler, små och stora bokstäver.
    #Det görs med hjälp av funktionen char och sedan sorteras och randomizas detta för varje användare.

    try {$COU = Get-ADOrganizationalUnit -Filter "Name -eq '$depart'"}
    catch{$COU = $null}
    if ($COU -eq $null) {
        New-ADOrganizationalUnit -Name $depart -Path "DC=script,DC=local"
    }
    #En try och catch används för att se om OU finns och om det inte finns skapas det med hjälp av en if-sats där variabeln null används.
    #OU läggs in i denna path "DC=script,DC=local".
    try {$Cgroup = Get-ADGroup -Filter "Name -eq '$depart'"}
    catch{$Cgroup = $null}
    if ($Cgroup -eq $null) {
        New-ADGroup -Name $depart -Path "OU=RoleGroups,DC=script,DC=local" -GroupScope Global
    }
    # En till try and catch finns med för att kolla om användaren finns i OU och finns det inte används en if-sats. 
    #Användarna läggs in i de specifika Rolegrupperna som finns definierat i csv filen.
    #Groupscope är globalt och detta har en stor betydelse för användare som delar samma nätverksresurser. 
    #Det finns många egenskaper global gör och här tas inte de egenskaper upp.
    If (Get-ADUser -Filter "comment -eq '$card'") {
        Get-ADUser -Identity $accname -Properties MemberOf | ForEach-Object {
            $_.MemberOf | Remove-ADGroupMember -Members $_.DistinguishedName -Confirm:$false
        }
    
        $UDN = (Get-ADUser -Identity $faccname).DistinguishedName
        If (!($UDN -eq $DistinguishedName)) {
            Move-ADObject -Identity $UDN -TargetPath $OU
        }

        Add-ADGroupMember -Identity $depart -Members $accname
    }   
      
    else {
        $n = 2
        While (Get-ADUser -Filter "SamAccountName -eq '$faccname'") {
            $faccname = $accname+$n
            $name = $name+$n
            $n++
        }

        $useraccounts = @('Username:', $faccname, "| Password:", $pass)
        New-Item -path 'C:\Users\Administrator\Desktop\User accounts' -Name $faccname'.txt' -Value "$useraccounts" -ItemType file -force
        #Här läggs informationen och lösenord för de aktuella användare i en fil. Filen har samma namn som användarens användarnamn.
        New-ADUser -Name $name -GivenName $firstname -Surname $lastname -DisplayName $name -Department $depart -SamAccountName $faccname -EmailAddress $Email -Description $descr -Path $OU `
        -AccountPassword (ConvertTo-SecureString -AsPlainText $pass -Force) -UserPrincipalName $faccname"@script.local" -Enabled $true -ChangePasswordAtLogon True
        #Här skapas nya användare med informationen från deras för, efternamn.
        #Här skapas användare och konverterar lösenordet till en säkersträng. Här måste användaren byta lösenord så fort den loggar in första gången.
        Set-ADUser -Identity $faccname -Add @{Comment=$card} -Confirm:$false

        Add-ADGroupMember -Identity $depart -Members $faccname
        
    }

}