addpath('workflow\matlab\')
addpath('workflow\templates\')
addpath('C:\Windows\System32\OpenSSH')

run_native_xcp_workflow(".......", ...      % Compile with your own data
    "RaspberryHost",".......", ...          % Compile with your own data
    "RaspberryUser","........", ...         % Compile with your own data
    "SSHPassword","......", ...             % Compile with your own data
    "SSHHostKey",".....", ...               % Compile with your own data
    "UseSudo",false, ...
    "EnableCalibrationDebug",false, ...
    "XcpCore",3, ...
    "ModelCores",[1 2]);
