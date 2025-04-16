# lista jednostek organizacyjnych do przetworzenia
param (
    [Parameter(Mandatory = $true)]
    [string[]]$OUs
)

# zapis do pliku csv w katalogu, w ktorym znajduje sie skrytp
$outputFile = Join-Path -Path $PSScriptRoot -ChildPath "ADUsers.csv"

$results = @()

foreach($ouName in $OUs) {
    # znajduje wszystkie sciezki jednostek organizacyjnych o podanej nazwie podstawowej
    $foundOUs = Get-ADOrganizationalUnit -Filter "Name -eq '$ouName'" -Properties DistinguishedName

    if(-not $foundOUs) {
        Write-Warning "Jednostka '$ouName' nie zosta³a znaleziona w domenie"
        continue
    }
    
    foreach($ou in $foundOUs) {
        Write-Host "Przetwarzanie OU: $($ou.DistinguishedName)"

        $users = Get-ADUser -Filter * -SearchBase $ou -Properties DisplayName, Enabled, CannotChangePassword, DistinguishedName, PasswordLastSet

        foreach($user in $users) {
            # wyciagnij bezposrednia nazwe jednostki
            $dnParts = $user.DistinguishedName -split ",", 2
            $parentOU = ($user.DistinguishedName -split ",") | Where-Object { $_ -like "OU=*" } | Select-Object -First 1
            $parentOU = $parentOU -replace "^OU=", ""

            # czy uzytkownik jest aktywny
            $user.Enabled = ([bool](-not ($user.UserAccountControl -band 2)))
            
            
            # czy uzytkownik moze zmienic swoje haslo
            $canChangePassword = -not $user.CannotChangePassword

            # ostatnia zmiana hasla
            $passwordLastSet = $null
            if ($user.PasswordLastSet -ne $null -and $user.PasswordLastSet -ne 0) {
                $passwordLastSet = $user.PasswordLastSet.ToString("yyyy-MM-dd HH:mm")
            } else {
                $passwordLastSet = "Nigdy"
            }

            # dodaj do wynikow
            $results += [PSCustomObject]@{
                "Jednostka Organizacyjna" = $parentOU
                "Nazwa wyœwietlana" = $user.DisplayName
                "Login" = $user.SamAccountName
                "Czy konto aktywne?" = if ($user.Enabled -eq "True") { "Tak" } else { "Nie" }
                "Czy mo¿e zmieniaæ has³o?" = if ($canChangePassword -eq "True") { "Tak" } else { "Nie" }
                "Ostatnia zmiana has³a" = $passwordLastSet
            }
        }
    }
}

#eksoprt do pliku csv
$results | Export-Csv -Path $outputFile -NoTypeInformation -Encoding UTF8

Write-Host "Done"