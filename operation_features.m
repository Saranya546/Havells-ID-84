

function [F,ready,valid] = operation_features(y,state,t,adc_bad)
%#codegen
%
% y(1) = motor voltage Vm [V]
% y(2) = motor current Im [A]
% y(3) = mechanism torque tau [N*m]
% y(4) = mechanism position theta [deg]
%
% F     = 18 x 1 feature vector
% ready = one-sample pulse when operation completes
% valid = measurement validity for the completed operation

%% ------------------------------------------------------------
% STATE DEFINITIONS
% Change if your controller uses different values
% -------------------------------------------------------------
STATE_OPEN    = 0;
STATE_CLOSING = 1;
STATE_CLOSED  = 2;
STATE_OPENING = 3;
STATE_FAULT   = 4;

%% ------------------------------------------------------------
% OUTPUTS
% -------------------------------------------------------------
F = zeros(18,1,'single');

ready = false;
valid = false;

%% ------------------------------------------------------------
% PERSISTENT VARIABLES
% -------------------------------------------------------------
persistent active
persistent badDuringOperation

persistent n

persistent tStart
persistent tPrevious

persistent thetaStart
persistent thetaFinal

persistent sumI2
persistent sumAbsI
persistent maxAbsI

persistent sumV
persistent minV
persistent maxV

persistent previousI
persistent previousV
persistent maxAbsDI
persistent maxAbsDV

persistent peakPower
persistent energyAbs

persistent sumAbsTau
persistent sumTau
persistent sumTau2
persistent peakAbsTau

persistent sumAbsOmega

persistent storedFeatures
persistent lastOperationValid

%% ------------------------------------------------------------
% INITIALIZATION
% -------------------------------------------------------------
if isempty(active)

    active = false;
    badDuringOperation = false;

    n = uint32(0);

    tStart = 0;
    tPrevious = 0;

    thetaStart = 0;
    thetaFinal = 0;

    sumI2 = 0;
    sumAbsI = 0;
    maxAbsI = 0;

    sumV = 0;
    minV = 0;
    maxV = 0;

    previousI = 0;
    previousV = 0;

    maxAbsDI = 0;
    maxAbsDV = 0;

    peakPower = 0;
    energyAbs = 0;

    sumAbsTau = 0;
    sumTau = 0;
    sumTau2 = 0;
    peakAbsTau = 0;

    sumAbsOmega = 0;

    storedFeatures = zeros(18,1,'single');

    lastOperationValid = false;
end

%% ------------------------------------------------------------
% INPUT EXTRACTION
% -------------------------------------------------------------
V = double(y(1));
I = double(y(2));
tau = double(y(3));
theta = double(y(4));

%% ------------------------------------------------------------
% DETERMINE WHETHER MECHANISM IS MOVING
% -------------------------------------------------------------
moving = ...
    (state == STATE_CLOSING) || ...
    (state == STATE_OPENING);

%% ------------------------------------------------------------
% START OF NEW OPERATION
% -------------------------------------------------------------
if moving && ~active

    active = true;

    badDuringOperation = logical(adc_bad);

    n = uint32(1);

    tStart = double(t);
    tPrevious = double(t);

    thetaStart = theta;
    thetaFinal = theta;

    sumI2 = I*I;
    sumAbsI = abs(I);
    maxAbsI = abs(I);

    sumV = V;
    minV = V;
    maxV = V;

    previousI = I;
    previousV = V;

    maxAbsDI = 0;
    maxAbsDV = 0;

    P = V*I;

    peakPower = abs(P);
    energyAbs = 0;

    sumAbsTau = abs(tau);
    sumTau = tau;
    sumTau2 = tau*tau;
    peakAbsTau = abs(tau);

    sumAbsOmega = 0;

%% ------------------------------------------------------------
% OPERATION IN PROGRESS
% -------------------------------------------------------------
elseif moving && active

    dt = double(t) - tPrevious;

    if dt > 0

        n = n + 1;

        %% Current
        sumI2 = sumI2 + I*I;
        sumAbsI = sumAbsI + abs(I);

        if abs(I) > maxAbsI
            maxAbsI = abs(I);
        end

        %% Voltage
        sumV = sumV + V;

        if V < minV
            minV = V;
        end

        if V > maxV
            maxV = V;
        end

        %% Current derivative
        dIdt = (I-previousI)/dt;

        if abs(dIdt) > maxAbsDI
            maxAbsDI = abs(dIdt);
        end

        %% Voltage derivative
        dVdt = (V-previousV)/dt;

        if abs(dVdt) > maxAbsDV
            maxAbsDV = abs(dVdt);
        end

        %% Electrical power
        P = V*I;

        if abs(P) > peakPower
            peakPower = abs(P);
        end

        %% Electrical energy consumed
        energyAbs = energyAbs + abs(P)*dt;

        %% Torque
        sumAbsTau = sumAbsTau + abs(tau);
        sumTau = sumTau + tau;
        sumTau2 = sumTau2 + tau*tau;

        if abs(tau) > peakAbsTau
            peakAbsTau = abs(tau);
        end

        %% Angular velocity
        omega = ...
            (theta-thetaFinal)/dt;

        sumAbsOmega = ...
            sumAbsOmega + abs(omega);

        %% Update previous sample
        previousI = I;
        previousV = V;

        thetaFinal = theta;

        tPrevious = double(t);

    end

    if adc_bad
        badDuringOperation = true;
    end

%% ------------------------------------------------------------
% END OF OPERATION
% -------------------------------------------------------------
elseif ~moving && active

    active = false;

    thetaFinal = theta;

    duration = double(t)-tStart;

    Nd = double(n);

    if Nd >= 2 && duration > 0

        %% Current
        I_rms = sqrt(sumI2/Nd);

        I_mean_abs = sumAbsI/Nd;

        %% Voltage
        V_mean = sumV/Nd;

        V_span = maxV-minV;

        %% Torque
        Tau_mean_abs = sumAbsTau/Nd;

        Tau_mean = sumTau/Nd;

        varianceTau = ...
            max(sumTau2/Nd - Tau_mean*Tau_mean,0);

        Tau_std = sqrt(varianceTau);

        %% Position
        travelAngle = ...
            abs(thetaFinal-thetaStart);

        %% Angular velocity
        Omega_mean_abs = ...
            sumAbsOmega/max(Nd-1,1);

        %% ----------------------------------------------------
        % FEATURE VECTOR
        % -----------------------------------------------------
        storedFeatures(1)  = single(I_rms);
        storedFeatures(2)  = single(maxAbsI);
        storedFeatures(3)  = single(I_mean_abs);

        storedFeatures(4)  = single(V_mean);
        storedFeatures(5)  = single(minV);
        storedFeatures(6)  = single(V_span);

        storedFeatures(7)  = single(maxAbsDI);
        storedFeatures(8)  = single(maxAbsDV);

        storedFeatures(9)  = single(peakPower);
        storedFeatures(10) = single(energyAbs);

        storedFeatures(11) = single(Tau_mean_abs);
        storedFeatures(12) = single(peakAbsTau);
        storedFeatures(13) = single(Tau_std);

        storedFeatures(14) = single(thetaStart);
        storedFeatures(15) = single(thetaFinal);

        storedFeatures(16) = single(travelAngle);
        storedFeatures(17) = single(duration);

        storedFeatures(18) = single(Omega_mean_abs);

        lastOperationValid = ...
            ~badDuringOperation;

        ready = true;
        valid = lastOperationValid;

    else

        lastOperationValid = false;

        ready = true;
        valid = false;

    end
end

%% ------------------------------------------------------------
% OUTPUT STORED VECTOR
% -------------------------------------------------------------
F = storedFeatures;

end