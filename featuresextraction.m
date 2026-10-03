%% ============================================================
%  HV ISOLATOR - COMPLETE FEATURE EXTRACTION
%  Model: coremodel
%
%  Logged signals required:
%       Vm         - Motor voltage [V]
%       Im         - Motor current [A]
%       tauNm      - Shaft/mechanism torque [N*m]
%       theta_deg  - Angular position [degree]
%
%  Output:
%       F = 32 x 1 feature vector
%
% =============================================================

clc;

mdl = "coremodel";

%% ============================================================
% 1. RUN SIMULATION
% =============================================================

out = sim(mdl,"StopTime","12");

logs = out.logsout;

%% ============================================================
% 2. GET LOGGED SIGNALS
% =============================================================

Vm_sig    = logs.get("Vm");
Im_sig    = logs.get("Im");
tau_sig   = logs.get("tauNm");
theta_sig = logs.get("theta_deg");

%% Check signals exist

if isempty(Vm_sig)
    error("Signal 'Vm' was not found in logsout.");
end

if isempty(Im_sig)
    error("Signal 'Im' was not found in logsout.");
end

if isempty(tau_sig)
    error("Signal 'tauNm' was not found in logsout.");
end

if isempty(theta_sig)
    error("Signal 'theta_deg' was not found in logsout.");
end

%% ============================================================
% 3. EXTRACT DATA + TIME
% =============================================================

Vm = squeeze(Vm_sig.Values.Data);
tV = Vm_sig.Values.Time;

Im = squeeze(Im_sig.Values.Data);
tI = Im_sig.Values.Time;

tauNm = squeeze(tau_sig.Values.Data);
tTau  = tau_sig.Values.Time;

theta_deg = squeeze(theta_sig.Values.Data);
tTheta    = theta_sig.Values.Time;

%% Force everything to column vectors

Vm        = Vm(:);
tV        = tV(:);

Im        = Im(:);
tI        = tI(:);

tauNm     = tauNm(:);
tTau      = tTau(:);

theta_deg = theta_deg(:);
tTheta    = tTheta(:);

%% ============================================================
% 4. REMOVE DUPLICATE TIME POINTS IF PRESENT
% =============================================================

[tV,idx] = unique(tV,"stable");
Vm = Vm(idx);

[tI,idx] = unique(tI,"stable");
Im = Im(idx);

[tTau,idx] = unique(tTau,"stable");
tauNm = tauNm(idx);

[tTheta,idx] = unique(tTheta,"stable");
theta_deg = theta_deg(idx);

%% ============================================================
% 5. BASIC DATA VALIDATION
% =============================================================

if length(Vm) < 2
    error("Voltage signal contains insufficient samples.");
end

if length(Im) < 2
    error("Current signal contains insufficient samples.");
end

if length(tauNm) < 2
    error("Torque signal contains insufficient samples.");
end

if length(theta_deg) < 2
    error("Angular-position signal contains insufficient samples.");
end

if any(~isfinite(Vm))
    error("Vm contains NaN or Inf.");
end

if any(~isfinite(Im))
    error("Im contains NaN or Inf.");
end

if any(~isfinite(tauNm))
    error("tauNm contains NaN or Inf.");
end

if any(~isfinite(theta_deg))
    error("theta_deg contains NaN or Inf.");
end

%% ============================================================
% 6. CURRENT FEATURES
% =============================================================

% RMS current
I_rms = sqrt(mean(Im.^2));

% Largest current magnitude
I_peak_abs = max(abs(Im));

% Mean current magnitude
I_mean_abs = mean(abs(Im));

%% ============================================================
% 7. VOLTAGE FEATURES
% =============================================================

V_mean = mean(Vm);

V_min = min(Vm);

V_max = max(Vm);

% Complete range of voltage experienced during operation
V_span = V_max - V_min;

%% ============================================================
% 8. CURRENT RATE OF CHANGE dI/dt
% =============================================================

dI_dt = gradient(Im,tI);

% Most-negative current rate
dI_dt_min = min(dI_dt);

% Most-positive current rate
dI_dt_max = max(dI_dt);

% Largest rate independent of direction
max_abs_dIdt = max(abs(dI_dt));

% Average rate magnitude
mean_abs_dIdt = mean(abs(dI_dt));

%% ============================================================
% 9. VOLTAGE RATE OF CHANGE dV/dt
% =============================================================

dV_dt = gradient(Vm,tV);

dV_dt_min = min(dV_dt);

dV_dt_max = max(dV_dt);

max_abs_dVdt = max(abs(dV_dt));

mean_abs_dVdt = mean(abs(dV_dt));

%% ============================================================
% 10. ELECTRICAL POWER
%
% Voltage and current may have different Simulink time vectors.
% Therefore current is interpolated onto voltage time.
% =============================================================

Im_on_Vtime = interp1( ...
    tI, ...
    Im, ...
    tV, ...
    "linear", ...
    "extrap");

% Instantaneous electrical power
Pe = Vm .* Im_on_Vtime;

% Peak magnitude of electrical power
Pe_peak_abs = max(abs(Pe));

% Electrical energy
%
% Signed value:
% positive = net energy supplied
% negative portions can occur depending on system convention
%
ElectricalEnergy = trapz(tV,Pe);

%% ============================================================
% 11. BASIC TORQUE FEATURES
% =============================================================

% Most-negative signed torque
Tau_min = min(tauNm);

% Maximum positive signed torque
Tau_max = max(tauNm);

% Average signed torque
Tau_mean = mean(tauNm);

% Average torque magnitude
Tau_mean_abs = mean(abs(tauNm));

% Largest torque magnitude
Tau_peak_abs = max(abs(tauNm));

% Torque fluctuation
Tau_std = std(tauNm);

%% ============================================================
% 12. TORQUE RATE OF CHANGE dTau/dt
% =============================================================

dTau_dt = gradient(tauNm,tTau);

% Fastest negative torque change
dTau_dt_min = min(dTau_dt);

% Fastest positive torque change
dTau_dt_max = max(dTau_dt);

% Largest torque-rate magnitude
max_abs_dTaudt = max(abs(dTau_dt));

% Mean torque-rate magnitude
mean_abs_dTaudt = mean(abs(dTau_dt));

% Variation in torque rate
dTau_dt_std = std(dTau_dt);

%% ============================================================
% 13. ANGULAR POSITION FEATURES
% =============================================================

Theta_start = theta_deg(1);

Theta_final = theta_deg(end);

% Actual position range reached
AngularTravel = max(theta_deg) - min(theta_deg);

%% ============================================================
% 14. ANGULAR VELOCITY
% =============================================================

omega_deg_s = gradient(theta_deg,tTheta);

% Mean absolute angular velocity
Omega_mean_abs = mean(abs(omega_deg_s));

%% ============================================================
% 15. OPERATING TIME
%
% Here operating time is estimated from 5% to 95% of completed
% angular travel. This prevents tiny initial/final numerical
% changes from affecting the operating time.
% =============================================================

theta0 = theta_deg(1);
thetaEnd = theta_deg(end);

travel_signed = thetaEnd - theta0;

if abs(travel_signed) < 1e-9

    OperatingTime = 0;

    warning("Very little angular movement detected.");

else

    % Normalized operation progress:
    % approximately 0 at initial position and 1 at final position
    progress = (theta_deg - theta0) ./ travel_signed;

    % Find first 5% crossing
    k_start = find(progress >= 0.05,1,"first");

    % Find first 95% crossing
    k_end = find(progress >= 0.95,1,"first");

    if isempty(k_start) || isempty(k_end)

        warning("Could not determine 5%%-95%% operating time.");

        OperatingTime = tTheta(end) - tTheta(1);

    else

        OperatingTime = ...
            tTheta(k_end) - tTheta(k_start);

    end

end

%% ============================================================
% 16. CREATE FINAL 32 x 1 FEATURE VECTOR
% =============================================================

F = [ ...
    I_rms;                 % 1
    I_peak_abs;            % 2
    I_mean_abs;            % 3

    V_mean;                % 4
    V_min;                 % 5
    V_span;                % 6

    dI_dt_min;             % 7
    dI_dt_max;             % 8
    max_abs_dIdt;          % 9
    mean_abs_dIdt;         % 10

    dV_dt_min;             % 11
    dV_dt_max;             % 12
    max_abs_dVdt;          % 13
    mean_abs_dVdt;         % 14

    Pe_peak_abs;           % 15
    ElectricalEnergy;      % 16

    Tau_min;               % 17
    Tau_max;               % 18
    Tau_mean;              % 19
    Tau_mean_abs;          % 20
    Tau_peak_abs;          % 21
    Tau_std;               % 22

    dTau_dt_min;           % 23
    dTau_dt_max;           % 24
    max_abs_dTaudt;        % 25
    mean_abs_dTaudt;       % 26
    dTau_dt_std;           % 27

    Theta_start;           % 28
    Theta_final;           % 29
    AngularTravel;         % 30
    OperatingTime;         % 31
    Omega_mean_abs];       % 32

%% ============================================================
% 17. FEATURE NAMES
% =============================================================

featureNames = { ...
    'I_rms'
    'I_peak_abs'
    'I_mean_abs'
    'V_mean'
    'V_min'
    'V_span'
    'dI_dt_min'
    'dI_dt_max'
    'max_abs_dIdt'
    'mean_abs_dIdt'
    'dV_dt_min'
    'dV_dt_max'
    'max_abs_dVdt'
    'mean_abs_dVdt'
    'Pe_peak_abs'
    'ElectricalEnergy'
    'Tau_min'
    'Tau_max'
    'Tau_mean'
    'Tau_mean_abs'
    'Tau_peak_abs'
    'Tau_std'
    'dTau_dt_min'
    'dTau_dt_max'
    'max_abs_dTaudt'
    'mean_abs_dTaudt'
    'dTau_dt_std'
    'Theta_start'
    'Theta_final'
    'AngularTravel'
    'OperatingTime'
    'Omega_mean_abs'};

%% ============================================================
% 18. UNITS
% =============================================================

featureUnits = { ...
    'A'
    'A'
    'A'
    'V'
    'V'
    'V'
    'A/s'
    'A/s'
    'A/s'
    'A/s'
    'V/s'
    'V/s'
    'V/s'
    'V/s'
    'W'
    'J'
    'N*m'
    'N*m'
    'N*m'
    'N*m'
    'N*m'
    'N*m'
    'N*m/s'
    'N*m/s'
    'N*m/s'
    'N*m/s'
    'N*m/s'
    'deg'
    'deg'
    'deg'
    's'
    'deg/s'};

%% ============================================================
% 19. VERIFY FEATURE VECTOR
% =============================================================

fprintf("\n=======================================\n");
fprintf("       FEATURE EXTRACTION RESULT\n");
fprintf("=======================================\n");

fprintf("Feature vector size = %d x %d\n", ...
    size(F,1),size(F,2));

if size(F,1) ~= 32 || size(F,2) ~= 1
    error("Feature vector must be 32 x 1.");
end

if ~all(isfinite(F))
    error("Feature vector contains NaN or Inf.");
end

disp("All 32 features are finite.");

%% ============================================================
% 20. CREATE FEATURE TABLE
% =============================================================

FeatureTable = table( ...
    (1:32)', ...
    featureNames, ...
    F, ...
    featureUnits, ...
    'VariableNames', ...
    {'No','Feature','Value','Unit'});

disp(FeatureTable);

%% ============================================================
% 21. OPTIONAL IMPORTANT CHECKS
% =============================================================

fprintf("\n------------ IMPORTANT VALUES ------------\n");

fprintf("Current RMS          = %.6f A\n",I_rms);
fprintf("Current peak         = %.6f A\n",I_peak_abs);

fprintf("Voltage mean         = %.6f V\n",V_mean);
fprintf("Voltage min          = %.6f V\n",V_min);
fprintf("Voltage span         = %.6f V\n",V_span);

fprintf("Peak electrical P    = %.6f W\n",Pe_peak_abs);
fprintf("Electrical energy    = %.6f J\n",ElectricalEnergy);

fprintf("Torque min           = %.6f N*m\n",Tau_min);
fprintf("Torque max           = %.6f N*m\n",Tau_max);
fprintf("Torque mean abs      = %.6f N*m\n",Tau_mean_abs);
fprintf("Torque peak abs      = %.6f N*m\n",Tau_peak_abs);
fprintf("Torque std           = %.6f N*m\n",Tau_std);

fprintf("dTau/dt minimum      = %.6f N*m/s\n",dTau_dt_min);
fprintf("dTau/dt maximum      = %.6f N*m/s\n",dTau_dt_max);
fprintf("Max |dTau/dt|        = %.6f N*m/s\n",max_abs_dTaudt);
fprintf("Mean |dTau/dt|       = %.6f N*m/s\n",mean_abs_dTaudt);
fprintf("Std dTau/dt          = %.6f N*m/s\n",dTau_dt_std);

fprintf("Initial angle        = %.6f deg\n",Theta_start);
fprintf("Final angle          = %.6f deg\n",Theta_final);
fprintf("Angular travel       = %.6f deg\n",AngularTravel);
fprintf("Operating time       = %.6f s\n",OperatingTime);
fprintf("Mean |omega|         = %.6f deg/s\n",Omega_mean_abs);

%% ============================================================
% 22. SAVE HEALTHY RUN 01
% =============================================================

save("healthy_run_01.mat", ...
    "F", ...
    "FeatureTable", ...
    "featureNames", ...
    "featureUnits");

fprintf("\nhealthy_run_01.mat saved successfully.\n");