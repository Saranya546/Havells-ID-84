function selftest_blocks
% Numerical checks for CURRENT 18-feature isolator implementation.

%% ============================================================
% RESET
% ============================================================

clear operation_features;

%% ============================================================
% TEST 1: NORMAL ADC INPUT
% ============================================================

[y,bad] = mcxn547_adc_model(100,2,500,45,10000);

assert(~bad, ...
    'Normal measurement should not produce adc_bad.');

yActual = y(:);

yExpected = [
    100
    2
    500
    45
];

yTolerance = [
    0.003
    0.0005
    0.18
    0.002
];

assert(all(abs(yActual-yExpected) < yTolerance), ...
    'ADC output outside expected tolerance.');

%% ============================================================
% TEST 2: VOLTAGE SATURATION
% ============================================================

[~,bad] = mcxn547_adc_model(200,2,500,45,10000);

assert(bad, ...
    'Voltage ADC saturation must be detected.');

%% ============================================================
% TEST 3: TORQUE OUT OF RANGE
% ============================================================

[~,bad] = mcxn547_adc_model(100,2,11000,45,10000);

assert(bad, ...
    'Torque above configured range must be detected.');

%% ============================================================
% TEST 4: FEATURE BLOCK INITIAL CONDITION
% ============================================================

clear operation_features;

[~,ready,valid] = ...
    operation_features([0,0,0,0],0,0,false);

assert(~ready && ~valid, ...
    'Initial ready and valid must both be false.');

%% ============================================================
% TEST 5: SIMULATE CLOSING OPERATION
%
% Current = 2 A
% Voltage = 100 V
% Torque  = 500 N*m
%
% Angle changes 0 -> approximately 90 degrees
% over 2 seconds.
% ============================================================

for k = 0:1999

    t = 1 + k*0.001;

    theta = 45*(t-1);

    [~,ready,~] = operation_features( ...
        [100,2,500,theta], ...
        1, ...
        t, ...
        false);

    assert(~ready, ...
        'ready must remain false while movement is occurring.');

end

%% ============================================================
% TEST 6: END OF OPERATION
% ============================================================

[F,ready,valid] = operation_features( ...
    [0,0,0,90], ...
    2, ...
    3, ...
    false);

assert(ready, ...
    'ready should pulse when operation finishes.');

assert(valid, ...
    'Healthy operation should be valid.');

F = F(:);

%% ============================================================
% TEST 7: VERIFY ALL 18 FEATURES
% ============================================================

expectedF = [
    2.0
    2.0
    2.0
    100.0
    100.0
    0.0
    0.0
    0.0
    200.0
    399.8
    500.0
    500.0
    0.0
    0.0
    90.0
    90.0
    2.0
    45.0
];

tolerance = 1e-3;

featureError = abs(F-expectedF);

assert(max(featureError) < tolerance, ...
    '18-feature vector does not match expected values.');

%% ============================================================
% TEST 8: DISPLAY RESULTS
% ============================================================

fprintf('\nCurrent 18-feature vector:\n');

for k = 1:18
    fprintf('F(%2d) = %10.4f\n',k,F(k));
end

fprintf('\nMaximum feature error = %.6g\n', ...
    max(featureError));

%% ============================================================
% TEST 9: ADC FAILURE DURING AN OPERATION
% ============================================================

clear operation_features;

for k = 0:19

    operation_features( ...
        [100,2,-500,k], ...
        1, ...
        1+k*0.001, ...
        k==10);

end

[~,ready,valid] = operation_features( ...
    [0,0,0,20], ...
    4, ...
    1.020, ...
    false);

assert(ready, ...
    'Operation termination should produce ready.');

assert(~valid, ...
    'Operation containing adc_bad must be invalid.');

%% ============================================================
% FINISHED
% ============================================================

clear operation_features;

fprintf('\n');
fprintf('=============================================\n');
fprintf('ADC and 18-feature numerical tests PASSED.\n');
fprintf('=============================================\n');

end