function [y, adc_bad] = mcxn547_adc_model(Vm, Im, tauNm, theta_deg, TorqueFullScaleNm)
%#codegen
% Paste ALL this code into the ADC MATLAB Function block.
% New fifth input: a Constant block with value TorqueFullScaleNm.
% y = [motor V, motor A, shaft torque N*m, output-shaft angle deg].
% Functional conditioning/quantization model, not MCXN547 emulation.
% The 16-bit / 3.3-V model is an illustrative configuration, not accuracy.

u = double([Vm, Im, tauNm, theta_deg]);
y = zeros(1,4);
adc_bad = ~all(isfinite(u)) || ~isfinite(TorqueFullScaleNm) || TorqueFullScaleNm <= 0;
if adc_bad
    return;
end

% EXAMPLE externally conditioned ranges, NOT a verified sensor circuit:
% Motor V: +/-150 V -> 0.15..3.15 V.
% Motor I: +/-25 A -> 0.15..3.15 V.
% Shaft torque: +/-TorqueFullScaleNm -> 0.15..3.15 V.
% Calibrated angle: 0..90 degrees -> 0.20..3.10 V.
v = [1.65 + 0.01*u(1), ...
    1.65 + 0.06*u(2), ...
    1.65 + 1.5*u(3)/TorqueFullScaleNm, ...
    0.20 + (2.90/90)*u(4)];
adc_bad = any(v <= 0) || any(v >= 3.3) || abs(tauNm) > TorqueFullScaleNm;
v = min(max(v,0),3.3);
counts = uint16(round(v*(65535/3.3)));
vq = double(counts)*(3.3/65535);
y = [(vq(1)-1.65)/0.01, ...
    (vq(2)-1.65)/0.06, ...
    (vq(3)-1.65)*TorqueFullScaleNm/1.5, ...
    (vq(4)-0.20)*(90/2.90)];
end
