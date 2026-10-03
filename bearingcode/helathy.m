%% =========================================================
%  HEALTHY BEARING SIMULATION + VISUALIZATION
%  Model: coremodel
%% =========================================================


clc

%% 1. Load Simulink model
mdl = "coremodel";      % Change if model name is different
load_system(mdl);

%% 2. Simulation duration
Tstop = 12;             % seconds

%% 3. Restore healthy shaft damping
Bshaft = 2000;

% Put Bshaft in base workspace
assignin("base","Bshaft",Bshaft);

% Also update model workspace if Bshaft exists there
mw = get_param(mdl,"ModelWorkspace");

if hasVariable(mw,"Bshaft")
    assignin(mw,"Bshaft",Bshaft);
end

%% 4. Healthy bearing parameters
% For healthy condition all additional bearing fault
% parameters are zero.

Bwear = 0;              % Additional damping
Twear = 0;              % Additional friction torque
Awear = 0;              % Periodic disturbance amplitude

Nwear = 4;              % Number of disturbance cycles / rev
phiWear = 0;            % Phase angle
omegaEps = 0.02;        % Small speed value to avoid division problems

% Send variables to base workspace
assignin("base","Bwear",Bwear);
assignin("base","Twear",Twear);
assignin("base","Awear",Awear);
assignin("base","Nwear",Nwear);
assignin("base","phiWear",phiWear);
assignin("base","omegaEps",omegaEps);

%% 5. Run healthy bearing simulation
outBearingHealthy = sim(mdl, ...
    "StopTime",num2str(Tstop));

disp("Healthy bearing simulation completed.");

%% =========================================================
% 6. GET LOGGED SIGNALS
%% =========================================================

logs = outBearingHealthy.logsout;

% Display available signal names
disp("Available logged signals:");
disp(logs.getElementNames);

%% Extract required signals
Vm_sig = logs.get("Vm");
Im_sig = logs.get("Im");
tau_sig = logs.get("tauNm");
theta_sig = logs.get("theta_deg");

%% Extract time and data separately
% IMPORTANT:
% Each signal uses its OWN time vector.

tV = Vm_sig.Values.Time;
Vm = squeeze(Vm_sig.Values.Data);

tI = Im_sig.Values.Time;
Im = squeeze(Im_sig.Values.Data);

tTau = tau_sig.Values.Time;
tauNm = squeeze(tau_sig.Values.Data);

tTheta = theta_sig.Values.Time;
theta_deg = squeeze(theta_sig.Values.Data);

%% =========================================================
% 7. VISUALIZATION
%% =========================================================

figure("Name","Healthy Bearing Simulation", ...
       "NumberTitle","off");

tiledlayout(4,1);

%% Motor voltage
nexttile
plot(tV,Vm,"LineWidth",1.3);
grid on
xlabel("Time (s)");
ylabel("Voltage (V)");
title("Motor Voltage - Healthy Bearing");

%% Motor current
nexttile
plot(tI,Im,"LineWidth",1.3);
grid on
xlabel("Time (s)");
ylabel("Current (A)");
title("Motor Current - Healthy Bearing");

%% Shaft torque
nexttile
plot(tTau,tauNm,"LineWidth",1.3);
grid on
xlabel("Time (s)");
ylabel("Torque (N m)");
title("Shaft Torque - Healthy Bearing");

%% Angular displacement
nexttile
plot(tTheta,theta_deg,"LineWidth",1.3);
grid on
xlabel("Time (s)");
ylabel("Angle (deg)");
title("Isolator Angular Position - Healthy Bearing");

sgtitle("Healthy Bearing Simulation Results");

%% =========================================================
% 8. INDIVIDUAL FIGURES
%% =========================================================

figure("Name","Motor Voltage");
plot(tV,Vm,"LineWidth",1.5);
grid on
xlabel("Time (s)");
ylabel("Motor Voltage (V)");
title("Motor Voltage");

figure("Name","Motor Current");
plot(tI,Im,"LineWidth",1.5);
grid on
xlabel("Time (s)");
ylabel("Motor Current (A)");
title("Motor Current");

figure("Name","Shaft Torque");
plot(tTau,tauNm,"LineWidth",1.5);
grid on
xlabel("Time (s)");
ylabel("Torque (N m)");
title("Shaft Torque");

figure("Name","Angular Displacement");
plot(tTheta,theta_deg,"LineWidth",1.5);
grid on
xlabel("Time (s)");
ylabel("Angle (deg)");
title("Isolator Angular Position");

%% =========================================================
% 9. BASIC HEALTHY CONDITION STATISTICS
%% =========================================================

fprintf("\n============================================\n");
fprintf("       HEALTHY BEARING SIMULATION\n");
fprintf("============================================\n");

fprintf("Voltage mean       : %.4f V\n",mean(Vm));
fprintf("Voltage min        : %.4f V\n",min(Vm));
fprintf("Voltage max        : %.4f V\n",max(Vm));

fprintf("\nCurrent RMS        : %.4f A\n",rms(Im));
fprintf("Current mean       : %.4f A\n",mean(Im));

fprintf("\nTorque mean abs    : %.4f N.m\n",mean(abs(tauNm)));
fprintf("Torque std dev     : %.4f N.m\n",std(tauNm));
fprintf("Torque max         : %.4f N.m\n",max(tauNm));

fprintf("\nFinal angle        : %.4f degrees\n",theta_deg(end));
fprintf("Maximum angle      : %.4f degrees\n",max(theta_deg));

fprintf("\nSimulation time    : %.2f seconds\n",Tstop);

fprintf("============================================\n");