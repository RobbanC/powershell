################## METADATA #################### 
# NAME: Roberto Canovas
# USERNAME: b18robth
# COURSE: Script programming IT384G – Spring 2019 
# ASSIGNMENT: Assignment 1 - PowerShell
# DATE OF LAST CHANGE: 2019-05-22
################################################

cls
$IP = Get-DhcpServerv4Lease -ScopeID 192.168.1.0 -ComputerName "$env:COMPUTERNAME" -AllLeases | Sort-Object -Property LeaseExpiryTime
$IP
$ledigIP = Get-DhcpServerv4FreeIPAddress -ComputerName "$env:COMPUTERNAME" -ScopeId 192.168.1.0 -NumAddress 50
$ledigIP
$reservera = Get-DhcpServerv4Scope -ComputerName "$env:COMPUTERNAME" | Get-DhcpServerv4Reservation -ComputerName "$env:COMPUTERNAME"

$input = Read-Host "Gör en reservation, J/N!"
#För att göra en reservation måste först alla IP adresser i scopet listas ut och detta görs med hjälp av funktionen get-dhcpserv4lease.
#Sedan listas lediga ip-adresser. Och tillsist reserveras ip-adressen för den aktuella datorn med hjälp av variabeln $env:COMPUTERNAME
if($input -eq "J"){
    Write-Output $IP | Where-Object {$IP -like "Active"}
    $ledigIP = Read-Host "Skriv en IP från listan" 
try{
    Get-DhcpServerv4Lease -ComputerName  -IPAddress $ledigIP |Add-DhcpServerv4Reservation -ComputerName "$env:COMPUTERNAME"
    Write-Host "IP-adressen är nu reserverad"
    }
catch{
    n Write-Warning "Du måste skriva in en gilitig IP"
    }
}
# Här används en try and catch för att användaren måste skriva in en gilitig ip-adress.