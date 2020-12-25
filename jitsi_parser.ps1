#Script that parses jitsi chat logs and prints in a nice format.
#Note <msg> section needs to be cleaned to only include <msg> MESSAGE </msg> before usnig the script
#This can be done using serach and replace in some text editor
#Promt for input and output file paths and username of the local and remote char accounts
$path = Read-Host "Enter path to source file: "
$outpath = Read-Host "Enter path, including filename, to output file: "
$local = Read-Host "Enter the local username: "
$remote = Read-Host "Enter remote username: "
Set-ExecutionPolicy unrestricted
get-executionpolicy

#Initiate arrays used later
$messages = @()
$messages_tidy = @()

#Import chat log content into a XML object, then select specific obejcts of interest
[xml]$chatlog = Get-Content $path
$chatlog.history.record | %{$messages += $_.dir + ";" + $_.msg + ";" +  $_.timestamp}

#Replace in and out keywords width actual usernames
foreach($index in $messages){
    if($index -like "out*"){

        [regex]$pattern = "out"
        $messages_tidy += $pattern.replace($index,$local, 1) 
        }
    elseif($index -like "in*"){
        [regex]$pattern = "in"
        $messages_tidy += $pattern.replace($index, $remote, 1)
        }
    }
#Ensure that no messages gets lost in the process...
if($messages.Length -ne $messages_tidy.Length){
    echo "Some message seems missing, exiting now......"
    break;
    }

#Write a headerrow and then output chat messaged to the outputfile.
$header = "Sender;Message;Timestamp"
Out-File -FilePath $outpath -InputObject $header

foreach($message in $messages_tidy){
    Out-File -FilePath $outpath -InputObject $message -Append
}


