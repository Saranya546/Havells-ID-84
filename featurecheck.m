%% ============================================================
% FEATURECHECK.M
% Works for:
%   1. Single healthy run: healthy_run_01.mat containing F
%   2. Healthy dataset:    healthy_dataset.mat containing HealthyX
%
% Expected feature count = 32
%% ============================================================

clc;

fprintf("\n========================================\n");
fprintf("      HEALTHY FEATURE CHECK\n");
fprintf("========================================\n");

%% ============================================================
% 1. SELECT AVAILABLE FILE
%% ============================================================

if isfile("healthy_dataset.mat")

    datasetFile = "healthy_dataset.mat";

    fprintf("\nUsing healthy_dataset.mat\n");

elseif isfile("healthy_run_01.mat")

    datasetFile = "healthy_run_01.mat";

    fprintf("\nhealthy_dataset.mat not found.\n");
    fprintf("Using healthy_run_01.mat instead.\n");

else

    error([ ...
        "Neither healthy_dataset.mat nor healthy_run_01.mat was found." ...
        newline ...
        "Run extract_all_features.m first." ...
        ]);

end

%% ============================================================
% 2. LOAD FILE
%% ============================================================

S = load(datasetFile);

%% ============================================================
% 3. GET FEATURE DATA
%% ============================================================

if isfield(S,"HealthyX")

    % ---------------------------------------------------------
    % CASE 1:
    % Complete healthy dataset
    % HealthyX = N x 32
    % ---------------------------------------------------------

    HealthyX = S.HealthyX;

    fprintf("\nHealthyX successfully loaded.\n");

elseif isfield(S,"F")

    % ---------------------------------------------------------
    % CASE 2:
    % Only one healthy run exists
    % F = 32 x 1
    %
    % Convert it to:
    % HealthyX = 1 x 32
    % ---------------------------------------------------------

    F = S.F;

    F = F(:);

    if numel(F) ~= 32

        error( ...
            "F must contain 32 features, but contains %d.", ...
            numel(F));

    end

    HealthyX = F.';

    fprintf("\nSingle healthy feature vector F loaded.\n");
    fprintf("Converted F = 32x1 to HealthyX = 1x32.\n");

    fprintf("\nNOTE:\n");
    fprintf("Only one healthy run is available.\n");
    fprintf("Therefore Min = Max = Mean and StdDev = 0.\n");
    fprintf("Generate multiple healthy runs later for useful statistics.\n");

else

    error([ ...
        "Neither 'HealthyX' nor 'F' exists inside " ...
        datasetFile ...
        ]);

end

%% ============================================================
% 4. LOAD FEATURE NAMES
%% ============================================================

if isfield(S,"featureNames")

    featureNames = S.featureNames;

else

    fprintf("\nfeatureNames not found.\n");
    fprintf("Creating the default 32 feature names.\n");

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

end

%% Make sure featureNames is 32 x 1

featureNames = featureNames(:);

%% ============================================================
% 5. CHECK DIMENSIONS
%% ============================================================

[nRuns,nFeatures] = size(HealthyX);

fprintf("\n========================================\n");
fprintf("          DATASET INFORMATION\n");
fprintf("========================================\n");

fprintf("Number of healthy runs = %d\n",nRuns);
fprintf("Number of features     = %d\n",nFeatures);

if nFeatures ~= 32

    error( ...
        "HealthyX must contain 32 columns. Current size is %d x %d.", ...
        nRuns,nFeatures);

end

if numel(featureNames) ~= nFeatures

    error( ...
        "Number of feature names (%d) does not match number of features (%d).", ...
        numel(featureNames),nFeatures);

end

%% ============================================================
% 6. CHECK FOR NaN / Inf
%% ============================================================

if any(isnan(HealthyX),"all")

    error("HealthyX contains NaN values.");

end

if any(isinf(HealthyX),"all")

    error("HealthyX contains Inf values.");

end

fprintf("No NaN or Inf values detected.\n");

%% ============================================================
% 7. CALCULATE FEATURE STATISTICS
%% ============================================================

featureMin = min(HealthyX,[],1);

featureMax = max(HealthyX,[],1);

featureRange = featureMax - featureMin;

featureMean = mean(HealthyX,1);

%% ------------------------------------------------------------
% Standard deviation
%
% For only one run, MATLAB std using N-1 normalization can
% produce an unhelpful result for statistical interpretation.
% Explicitly set it to zero for a single run.
%% ------------------------------------------------------------

if nRuns == 1

    featureStd = zeros(1,nFeatures);

else

    featureStd = std(HealthyX,0,1);

end

%% ============================================================
% 8. CREATE FEATURE CHECK TABLE
%% ============================================================

FeatureCheck = table( ...
    (1:nFeatures)', ...
    featureNames, ...
    featureMin.', ...
    featureMax.', ...
    featureRange.', ...
    featureMean.', ...
    featureStd.', ...
    'VariableNames', ...
    { ...
    'No', ...
    'Feature', ...
    'Minimum', ...
    'Maximum', ...
    'Range', ...
    'Mean', ...
    'StdDev'});

%% ============================================================
% 9. DISPLAY COMPLETE TABLE
%% ============================================================

fprintf("\n========================================\n");
fprintf("          FEATURE STATISTICS\n");
fprintf("========================================\n\n");

disp(FeatureCheck);

%% ============================================================
% 10. CONSTANT / NEAR-CONSTANT FEATURES
%% ============================================================

tolerance = 1e-12;

constantFeature = featureStd < tolerance;

if nRuns == 1

    fprintf("\nNOTE:\n");
    fprintf("Constant-feature detection is not meaningful with only one run.\n");

else

    if any(constantFeature)

        fprintf("\n========================================\n");
        fprintf(" CONSTANT / NEAR-CONSTANT FEATURES\n");
        fprintf("========================================\n\n");

        disp(FeatureCheck(constantFeature,:));

    else

        fprintf("\nNo constant features detected.\n");

    end

end

%% ============================================================
% 11. ZERO RANGE FEATURES
%% ============================================================

zeroRange = abs(featureRange) < tolerance;

if nRuns > 1 && any(zeroRange)

    fprintf("\n========================================\n");
    fprintf("       ZERO-RANGE FEATURES\n");
    fprintf("========================================\n\n");

    disp(FeatureCheck(zeroRange,:));

end

%% ============================================================
% 12. MOST VARIABLE FEATURES
%% ============================================================

if nRuns > 1

    [sortedStd,idx] = sort(featureStd,"descend");

    fprintf("\n========================================\n");
    fprintf("       MOST VARIABLE FEATURES\n");
    fprintf("========================================\n");

    numberToShow = min(10,length(idx));

    for k = 1:numberToShow

        fprintf( ...
            "%2d. %-22s StdDev = %.6g\n", ...
            k, ...
            featureNames{idx(k)}, ...
            sortedStd(k));

    end

else

    fprintf("\nMost-variable-feature ranking skipped.\n");
    fprintf("At least two healthy runs are required.\n");

end

%% ============================================================
% 13. IMPORTANT MECHANICAL / TORQUE FEATURES
%% ============================================================

importantFeatures = { ...
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
    'Theta_final'
    'AngularTravel'
    'OperatingTime'
    'Omega_mean_abs'};

importantRows = ismember(featureNames,importantFeatures);

fprintf("\n========================================\n");
fprintf("      IMPORTANT MECHANICAL FEATURES\n");
fprintf("========================================\n\n");

disp(FeatureCheck(importantRows,:));

%% ============================================================
% 14. IMPORTANT ELECTRICAL FEATURES
%% ============================================================

electricalFeatures = { ...
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
    'ElectricalEnergy'};

electricalRows = ismember(featureNames,electricalFeatures);

fprintf("\n========================================\n");
fprintf("       IMPORTANT ELECTRICAL FEATURES\n");
fprintf("========================================\n\n");

disp(FeatureCheck(electricalRows,:));

%% ============================================================
% 15. SAVE CHECK RESULTS
%% ============================================================

save( ...
    "healthy_feature_check.mat", ...
    "HealthyX", ...
    "FeatureCheck", ...
    "featureMin", ...
    "featureMax", ...
    "featureRange", ...
    "featureMean", ...
    "featureStd", ...
    "featureNames");

fprintf("\n========================================\n");
fprintf("healthy_feature_check.mat saved.\n");
fprintf("       FEATURE CHECK COMPLETED\n");
fprintf("========================================\n");