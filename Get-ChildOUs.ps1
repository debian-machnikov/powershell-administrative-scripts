param (
    [Parameter(Mandatory= $true)]
    [string[]]$ParentOUs
)

$childOUList = @()

foreach($parentOUName in $ParentOUs) {
    # znajdz pelna nazwe DN jednostki-rodzica
    $currentParent = Get-ADOrganizationalUnit -Filter "Name -eq '$parentOUName'" -Properties DistinguishedName

    if(-not $currentParent) {
        Write-Warning "Nie znaleziono jednostki organizacyjnej '$parentOUName'"
        continue
    }

    foreach($parentOU in $currentParent) {
        # znajdz wszystkie jednostki-dzieci
        $childOUs = Get-ADOrganizationalUnit -SearchBase $parentOU.DistinguishedName -SearchScope Subtree -Filter * | Select-Object -ExpandProperty Name
        $childOUList += $childOUs
    }
}

# usun duplikaty, wyswietl wynik (mozna przekazac do drugiego skryptu)
$childOUList | Sort-Object -Unique