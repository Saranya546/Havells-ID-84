%% ============================================================
% GENERATE_HEALTHY_DATASET.M
%
% HV ISOLATOR - HEALTHY DATASET GENERATION
%
% Model required:
%       coremodel.slx
%
% Logged signals required:
%       Vm
%       Im
%       tauNm
%       theta_deg
%
% Output:
%       HealthyX = N x 32
%
% Example:
%       50 runs -> HealthyX = 50 x 32
%% ============================================================

clc;


fprintf("\n==============================================\n");
fprintf("       HEALTHY DATASET GENERATION\n");
fprintf("==============================================\n");

%% ============================================================
% 1. MODEL
%% ============================================================

mdl = "coremodel";

if ~bdIsLoaded(mdl)
    load_system(mdl);
end

%% ============================================================
% 2. NUMBER OF HEALTHY RUNS
%% ============================================================

N = 50;

fprintf("\nNumber of requested healthy runs = %d\n",N);

%% Reproducible random values
rng(1);

%% ============================================================
% 3. FEATURE NAMES
%% ============================================================

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

featureNames = featureNames(:);

%% ============================================================
% 4. PREALLOCATE STORAGE
%% ============================================================

HealthyX = nan(N,32);

Vscale_used = nan(N,1);
Bshaft_used = nan(N,1);

ValidRun = false(N,1);

%% ============================================================
% 5. GENERATE HEALTHY RUNS
%% ============================================================

for run = 1:N

    fprintf("\n==============================================\n");
    fprintf("          HEALTHY RUN %d / %d\n",run,N);
    fprintf("==============================================\n");

    %% --------------------------------------------------------
    % HEALTHY PARAMETER VALUES
    %
    % Run 1 = nominal condition
    % Run 2-50 = small normal variations
    %% --------------------------------------------------------

    if run == 1

        Vscale_i = 1.00;
        Bshaft_i = 2000;

    else

        % ±2 %% voltage variation
        Vscale_i = 0.98 + ...
                   (1.02 - 0.98)*rand;

        % ±5 %% damping/friction variation
        Bshaft_i = 1900 + ...
                   (2100 - 1900)*rand;

    end

    fprintf("Vscale = %.5f\n",Vscale_i);
    fprintf("Bshaft = %.3f\n",Bshaft_i);

    %% --------------------------------------------------------
    % CREATE SIMULATION INPUT
    %% --------------------------------------------------------

    simIn = Simulink.SimulationInput(mdl);

    %% Variable healthy parameters

    simIn = setVariable( ...
        simIn, ...
        "Vscale", ...
        Vscale_i);

    simIn = setVariable( ...
        simIn, ...
        "Bshaft", ...
        Bshaft_i);

    %% Fixed model parameters

    simIn = setVariable( ...
        simIn, ...
        "Ts", ...
        Ts);

    simIn = setVariable( ...
        simIn, ...
        "theta_limit", ...
        theta_limit);

    simIn = setVariable( ...
        simIn, ...
        "TorqueFullScaleNm", ...
        TorqueFullScaleNm);

    %% Simulation stop time

    simIn = setModelParameter( ...
        simIn, ...
        "StopTime", ...
        "12");

    %% --------------------------------------------------------
    % SIMULATE MODEL
    %% --------------------------------------------------------

    try

        out = sim(simIn);

        logs = out.logsout;

        %% ====================================================
        % 6. READ LOGGED SIGNALS
        %% ====================================================

        Vm_sig = logs.get("Vm");
        Im_sig = logs.get("Im");
        tau_sig = logs.get("tauNm");
        theta_sig = logs.get("theta_deg");

        if isempty(Vm_sig)
            error("Signal Vm not found.");
        end

        if isempty(Im_sig)
            error("Signal Im not found.");
        end

        if isempty(tau_sig)
            error("Signal tauNm not found.");
        end

        if isempty(theta_sig)
            error("Signal theta_deg not found.");
        end

        %% ====================================================
        % 7. EXTRACT DATA
        %% ====================================================

        Vm = squeeze(Vm_sig.Values.Data);
        tV = Vm_sig.Values.Time;

        Im = squeeze(Im_sig.Values.Data);
        tI = Im_sig.Values.Time;

        tauNm = squeeze(tau_sig.Values.Data);
        tTau = tau_sig.Values.Time;

        theta_deg = squeeze(theta_sig.Values.Data);
        tTheta = theta_sig.Values.Time;

        %% Convert everything to columns

        Vm = Vm(:);
        tV = tV(:);

        Im = Im(:);
        tI = tI(:);

        tauNm = tauNm(:);
        tTau = tTau(:);

        theta_deg = theta_deg(:);
        tTheta = tTheta(:);

        %% ====================================================
        % 8. REMOVE DUPLICATE TIME POINTS
        %% ====================================================

        [tV,idx] = unique(tV,"stable");
        Vm = Vm(idx);

        [tI,idx] = unique(tI,"stable");
        Im = Im(idx);

        [tTau,idx] = unique(tTau,"stable");
        tauNm = tauNm(idx);

        [tTheta,idx] = unique(tTheta,"stable");
        theta_deg = theta_deg(idx);

        %% Check sufficient samples

        if numel(Vm) < 2 || ...
           numel(Im) < 2 || ...
           numel(tauNm) < 2 || ...
           numel(theta_deg) < 2

            error("One or more signals contain insufficient samples.");

        end

        %% ====================================================
        % 9. CURRENT FEATURES
        %% ====================================================

        I_rms = sqrt(mean(Im.^2));

        I_peak_abs = max(abs(Im));

        I_mean_abs = mean(abs(Im));

        %% ====================================================
        % 10. VOLTAGE FEATURES
        %% ====================================================

        V_mean = mean(Vm);

        V_min = min(Vm);

        V_max = max(Vm);

        V_span = V_max - V_min;

        %% ====================================================
        % 11. CURRENT RATE OF CHANGE
        %% ====================================================

        dI_dt = gradient(Im,tI);

        dI_dt_min = min(dI_dt);

        dI_dt_max = max(dI_dt);

        max_abs_dIdt = max(abs(dI_dt));

        mean_abs_dIdt = mean(abs(dI_dt));

        %% ====================================================
        % 12. VOLTAGE RATE OF CHANGE
        %% ====================================================

        dV_dt = gradient(Vm,tV);

        dV_dt_min = min(dV_dt);

        dV_dt_max = max(dV_dt);

        max_abs_dVdt = max(abs(dV_dt));

        mean_abs_dVdt = mean(abs(dV_dt));

        %% ====================================================
        % 13. ELECTRICAL POWER + ENERGY
        %% ====================================================

        % Interpolate current to voltage time base
        Im_on_Vtime = interp1( ...
            tI,...
            Im,...
            tV,...
            "linear",...
            "extrap");

        % Instantaneous power
        Pe = Vm .* Im_on_Vtime;

        Pe_peak_abs = max(abs(Pe));

        ElectricalEnergy = trapz(tV,Pe);

        %% ====================================================
        % 14. TORQUE FEATURES
        %% ====================================================

        Tau_min = min(tauNm);

        Tau_max = max(tauNm);

        Tau_mean = mean(tauNm);

        Tau_mean_abs = mean(abs(tauNm));

        Tau_peak_abs = max(abs(tauNm));

        Tau_std = std(tauNm);

        %% ====================================================
        % 15. TORQUE RATE OF CHANGE
        %% ====================================================

        dTau_dt = gradient(tauNm,tTau);

        dTau_dt_min = min(dTau_dt);

        dTau_dt_max = max(dTau_dt);

        max_abs_dTaudt = max(abs(dTau_dt));

        mean_abs_dTaudt = mean(abs(dTau_dt));

        dTau_dt_std = std(dTau_dt);

        %% ====================================================
        % 16. ANGULAR POSITION FEATURES
        %% ====================================================

        Theta_start = theta_deg(1);

        Theta_final = theta_deg(end);

        AngularTravel = ...
            max(theta_deg) - min(theta_deg);

        %% ====================================================
        % 17. ANGULAR VELOCITY
        %% ====================================================

        omega_deg_s = gradient(theta_deg,tTheta);

        Omega_mean_abs = ...
            mean(abs(omega_deg_s));

        %% ====================================================
        % 18. OPERATING TIME
        %
        % 5 %% -> 95 %% movement time
        %% ====================================================

        travelSigned = ...
            Theta_final - Theta_start;

        if abs(travelSigned) < 1e-9

            OperatingTime = 0;

        else

            progress = ...
                (theta_deg - Theta_start) ./ ...
                travelSigned;

            kStart = find( ...
                progress >= 0.05,...
                1,...
                "first");

            kEnd = find( ...
                progress >= 0.95,...
                1,...
                "first");

            if ~isempty(kStart) && ~isempty(kEnd)

                OperatingTime = ...
                    tTheta(kEnd) - tTheta(kStart);

            else

                OperatingTime = ...
                    tTheta(end) - tTheta(1);

            end

        end

        %% ====================================================
        % 19. CREATE 32 x 1 FEATURE VECTOR
        %% ====================================================

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

        %% ====================================================
        % 20. CHECK FEATURE VECTOR
        %% ====================================================

        if numel(F) ~= 32

            error( ...
                "Feature vector contains %d features instead of 32.",...
                numel(F));

        end

        if any(~isfinite(F))

            error( ...
                "Feature vector contains NaN or Inf.");

        end

        %% ====================================================
        % 21. STORE THIS RUN
        %% ====================================================

        HealthyX(run,:) = F.';

        Vscale_used(run) = Vscale_i;

        Bshaft_used(run) = Bshaft_i;

        ValidRun(run) = true;

        fprintf("\nRun %d stored successfully.\n",run);

    catch ME

        fprintf("\n==============================================\n");
        fprintf("*** RUN %d FAILED ***\n",run);
        fprintf("==============================================\n");

        fprintf("\nMAIN ERROR:\n");
        fprintf("%s\n",ME.message);

        fprintf("\nFULL MATLAB ERROR REPORT:\n");
        fprintf("%s\n", ...
            getReport(ME,"extended","hyperlinks","off"));

        %% Display nested causes individually
        if ~isempty(ME.cause)

            fprintf("\n----------- UNDERLYING CAUSES -----------\n");

            for c = 1:numel(ME.cause)

                fprintf("\nCause %d:\n",c);

                fprintf("%s\n", ...
                    getReport( ...
                    ME.cause{c}, ...
                    "extended", ...
                    "hyperlinks", ...
                    "off"));

            end

        end

    end
end

%% ============================================================
% 22. REMOVE FAILED RUNS
%% ============================================================

HealthyX = HealthyX(ValidRun,:);

Vscale_used = Vscale_used(ValidRun);

Bshaft_used = Bshaft_used(ValidRun);

nHealthy = size(HealthyX,1);

%% ============================================================
% 23. SUMMARY
%% ============================================================

fprintf("\n==============================================\n");
fprintf("             RUN SUMMARY\n");
fprintf("==============================================\n");

fprintf("Requested runs  = %d\n",N);
fprintf("Successful runs = %d\n",nHealthy);
fprintf("Failed runs     = %d\n",N-nHealthy);

fprintf("\nHealthyX size = %d x %d\n",...
    size(HealthyX,1),...
    size(HealthyX,2));

if nHealthy == 0
    error("No healthy runs were successfully generated.");
end

%% ============================================================
% 24. HEALTHY CLASS LABEL
%% ============================================================

YHealthy = categorical( ...
    repmat("Healthy",nHealthy,1));

%% ============================================================
% 25. CREATE HEALTHY TABLE
%% ============================================================

HealthyTable = array2table( ...
    HealthyX,...
    'VariableNames',featureNames.');

HealthyTable.Vscale = Vscale_used;

HealthyTable.Bshaft = Bshaft_used;

HealthyTable.Label = YHealthy;

%% ============================================================
% 26. CALCULATE FEATURE STATISTICS
%% ============================================================

featureMin = min(HealthyX,[],1);

featureMax = max(HealthyX,[],1);

featureRange = ...
    featureMax - featureMin;

featureMean = ...
    mean(HealthyX,1);

if nHealthy > 1

    featureStd = ...
        std(HealthyX,0,1);

else

    featureStd = ...
        zeros(1,32);

end

%% ============================================================
% 27. CREATE FEATURECHECK TABLE
%% ============================================================

FeatureCheck = table( ...
    (1:32)',...
    featureNames,...
    featureMin.',...
    featureMax.',...
    featureRange.',...
    featureMean.',...
    featureStd.',...
    'VariableNames',{ ...
        'No',...
        'Feature',...
        'Minimum',...
        'Maximum',...
        'Range',...
        'Mean',...
        'StdDev'});

%% ============================================================
% 28. DISPLAY FEATURE STATISTICS
%% ============================================================

fprintf("\n==============================================\n");
fprintf("          HEALTHY FEATURE STATISTICS\n");
fprintf("==============================================\n\n");

disp(FeatureCheck);

%% ============================================================
% 29. CHECK CONSTANT FEATURES
%% ============================================================

tolerance = 1e-12;

constantFeatures = ...
    featureStd < tolerance;

if nHealthy > 1

    if any(constantFeatures)

        fprintf("\n==============================================\n");
        fprintf("       CONSTANT / NEAR-CONSTANT FEATURES\n");
        fprintf("==============================================\n\n");

        disp(FeatureCheck(constantFeatures,:));

    else

        fprintf("\nNo constant features detected.\n");

    end

end

%% ============================================================
% 30. DISPLAY FIRST FIVE RUNS
%% ============================================================

fprintf("\n==============================================\n");
fprintf("             FIRST HEALTHY RUNS\n");
fprintf("==============================================\n");

nShow = min(5,nHealthy);

disp(HealthyTable(1:nShow,:));

%% ============================================================
% 31. COMPARE RUN 1 AND RUN 2
%% ============================================================

if nHealthy >= 2

    difference12 = ...
        norm(HealthyX(1,:) - HealthyX(2,:));

    fprintf("\nDifference between Run 1 and Run 2 = %.6g\n",...
        difference12);

    if difference12 == 0

        warning([ ...
            "Run 1 and Run 2 are identical. " ...
            "Check whether Vscale and Bshaft are actually " ...
            "used inside coremodel." ...
            ]);

    end

end

%% ============================================================
% 32. SAVE COMPLETE HEALTHY DATASET
%% ============================================================

save( ...
    "healthy_dataset.mat",...
    "HealthyX",...
    "YHealthy",...
    "HealthyTable",...
    "featureNames",...
    "Vscale_used",...
    "Bshaft_used",...
    "FeatureCheck",...
    "featureMin",...
    "featureMax",...
    "featureRange",...
    "featureMean",...
    "featureStd");

fprintf("\n==============================================\n");
fprintf("      HEALTHY DATASET SAVED SUCCESSFULLY\n");
fprintf("==============================================\n");

fprintf("\nSaved file: healthy_dataset.mat\n");

fprintf("\nFinal HealthyX size = %d x %d\n",...
    size(HealthyX,1),...
    size(HealthyX,2));