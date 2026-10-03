%% ============================================================
% HV ISOLATOR PROJECT - DEMONSTRATION CONFIGURATION
% MATLAB R2026a
%
% IMPORTANT:
% These are temporary development values, NOT OEM isolator data.
% ============================================================

%% -------------------------
% Sampling
% --------------------------
Ts = 0.001;             % s
Fs = 1/Ts;              % Hz = 1000 Hz

%% -------------------------
% Mechanical model
% --------------------------
Bshaft = 2000;          % N*m*s/rad
% OLD STARTER DEMO VALUE ONLY

theta_limit = pi/2;     % rad
% = 90 deg

ThetaOpen_deg   = 0;
ThetaClosed_deg = 90;

ThetaTolerance_deg = 2;

%% -------------------------
% Motor command scaling
% --------------------------
Vscale = 1.0;

% IMPORTANT:
% This only scales your existing motor command.
% It does NOT define the motor voltage itself.

%% -------------------------
% Torque signal conditioning
% --------------------------
TorqueFullScaleNm = 10000;   % +/-10000 N*m
% DEMO VALUE ONLY

%% -------------------------
% Timing
% --------------------------
NominalOperatingTime_s = 3;  % demo only
OperationTimeout_s     = 5;  % demo only

SimulationStopTime_s   = 6;

%% -------------------------
% State definitions
% --------------------------
STATE_OPEN    = 0;
STATE_CLOSING = 1;
STATE_CLOSED  = 2;
STATE_OPENING = 3;
STATE_FAULT   = 4;

%% -------------------------
% Command definitions
% --------------------------
CMD_OPEN  = -1;
CMD_IDLE  = 0;
CMD_CLOSE = 1;

%% -------------------------
% Position / motion validity
% --------------------------
OmegaMoveThreshold_deg_s = 1;

%% -------------------------
% ANN dimensions
% --------------------------
NumFeatures = 18;

%% -------------------------
% Display configuration
% --------------------------
fprintf('\n============================================\n');
fprintf('HV ISOLATOR DEMO CONFIGURATION LOADED\n');
fprintf('============================================\n');

fprintf('Sampling time        = %.4f s\n',Ts);
fprintf('Sampling frequency   = %.0f Hz\n',Fs);
fprintf('Mechanical travel    = %.1f deg\n',rad2deg(theta_limit));
fprintf('Open position        = %.1f deg\n',ThetaOpen_deg);
fprintf('Closed position      = %.1f deg\n',ThetaClosed_deg);
fprintf('Position tolerance   = +/- %.1f deg\n',ThetaTolerance_deg);
fprintf('Torque full scale    = +/- %.0f N*m\n',TorqueFullScaleNm);
fprintf('Operation timeout    = %.1f s\n',OperationTimeout_s);

fprintf('\nWARNING:\n');
fprintf('Bshaft and TorqueFullScaleNm are temporary demo values.\n');
fprintf('Inspect actual simulation signals before ANN dataset generation.\n\n');