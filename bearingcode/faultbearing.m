%% Diagnostic bearing fault parameters

Bwear = 1000;
Twear = 0.50*Tref;
Awear = 0.40*Tref;

Nwear = 4;
phiWear = 0;
omegaEps = 0.02;

assignin("base","Bwear",Bwear);
assignin("base","Twear",Twear);
assignin("base","Awear",Awear);
assignin("base","Nwear",Nwear);
assignin("base","phiWear",phiWear);
assignin("base","omegaEps",omegaEps);

%% Run simulation

outBearingTest = sim(mdl, ...
    "StopTime",num2str(Tstop), ...
    "ReturnWorkspaceOutputs","on");

disp("Diagnostic simulation completed.");