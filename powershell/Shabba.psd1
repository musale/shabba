@{
    RootModule = 'Shabba.psm1'
    ModuleVersion = '1.0.0'
    GUID = '77ebc245-e47f-4b64-ac1d-a71613163d20'
    Author = 'Musale Martin'
    Description = 'YouTube Music download and song-resolution commands for PowerShell.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'Invoke-ShabbaYtDlpAudio'
        'Save-ShabbaMp3'
        'Save-ShabbaM4a'
        'Save-ShabbaMp3List'
        'Get-ShabbaYtIds'
    )
    AliasesToExport = @('dmp3', 'dm4a', 'dmp3l', 'ytids')
    CmdletsToExport = @()
    VariablesToExport = @()
}
