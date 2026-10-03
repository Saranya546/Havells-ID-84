%% ============================================================
% HV ISOLATOR - TEMPORARY DEMONSTRATION CONFIGURATION
% MATLAB R2026a
% ============================================================

%% Sampling
Ts = 0.001;          % s
Fs = 1/Ts;           % Hz

%% Mechanical model
Bshaft = 2000;       % N*m*s/rad
% OLD STARTER DEMONSTRATION VALUE

theta_limit = pi/2;  % rad = 90 deg

%% Motor command scaling
Vscale = 1.0;        % multiplier only

%% Torque measurement conditioning
TorqueFullScaleNm = 10000;   % +/- N*m
% OLD STARTER DEMO VALUE

%% Position definitions
ThetaOpen_deg = 0;
ThetaClosed_deg = 90;

ThetaTolerance_deg = 2;

%% Operation timing
NominalOperatingTime_s = 3;   % demonstration only
OperationTimeout_s = 5;       % demonstration only

%% Controller states
STATE_OPEN    = 0;
STATE_CLOSING = 1;
STATE_CLOSED  = 2;
STATE_OPENING = 3;
STATE_FAULT   = 4;

%% Display
fprintf("\nHV isolator temporary configuration loaded.\n");
fprintf("Sampling frequency : %.0f Hz\n",Fs);
fprintf("Sampling time      : %.4f s\n",Ts);
fprintf("Travel limit       : %.1f deg\n",rad2deg(theta_limit));
fprintf("Torque full scale  : +/- %.0f N*m\n",TorqueFullScaleNm);
fprintf("Timeout            : %.1f s\n\n",OperationTimeout_s);

fprintf("WARNING: Bshaft and torque range are old demo values.\n");
fprintf("Verify them before generating ANN training data.\n");