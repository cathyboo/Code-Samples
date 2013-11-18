% SE_constant_v07 - seventh version of script,  
% full user input and saving of data plots,
% filename is given by user input, date taken from filename and used in the name of saved plots
% includes test to ensure the SE ID entered matches the SE ID in the raw data filename
% Extra folder included, date taken from the filename, all graphs saved in the date folder
% .m file to plot and model data from SE after a thermal cycle with no rotation
% includes simple text file with a few details of the measurement along with some of the calculated and given constants
% new plots, derivative of T vs T, tau_freq found using fewer points
% new plots, bias vs time filtered Temp and bias vs Frequency
% new fixed length filename to be used in this version, change to how date folders are named 
% SE number and folder taken directly from the filename now, as is where/how/if the SE is housed

close all
clear all

% start with the file to be worked on, 49 characters in total minus .ext
% load the data file to be worked on
% example of typical filename is '2012.05.14-15_ArSm_ThermalTest_GU010006X_SE010095', measurement is spread over two days in this example but can be just one day
dataFile = input('Enter the name of the data file: ', 's');
% the first 13 characters of the filename gives the date the measurement
% was STARTED to when it was STOPPED,
% this full date will be used as the ID date for the graphs saved later
meas_date = dataFile(1:13);

% SE name taken from the file name
SE_IDnum = dataFile(42:49);

% small sentance on if and how SE is housed (GU200, Y axis or on it's own), information taken from the file name
SE_housing = dataFile(32:40);
if SE_housing == '000000000'
  SE_housing = 'SE not housed in GU';
else
  SE_housing = ['GU number ' , dataFile(32:39) , ', in ' , dataFile(40) , ' axis'];
endif

% type of test carried out on SE
SE_test_type = dataFile(20:30);

% test chamber test was carried out in
SE_test_chamber = dataFile(15:18);
if SE_test_chamber == 'ArSm'
  SE_test_chamber = 'Aerosmith Chamber';
elseif SE_test_chamber == 'TIRA'
  SE_test_chamber = 'TIRA Chamber';
elseif SE_test_chamber == 'Acut'
  SE_test_chamber = 'Acutronic Chamber';
endif

scale_factor = input('Scale factor for SE: ');
if (length(scale_factor) == 0)
  scale_factor = 0.02;
endif

therm_slope = input('Thermal slope used in thermal cycle: ');
if (length(therm_slope) == 0)
  therm_slope = 3;
endif

serial_board_no =  input('Number of the set of boards used: ', 's');
if (length(serial_board_no) == 0)
  serial_board_no = 'not specified';
endif

CutFreq_factor = input('Factor to divide the sampling frequency by to determine the Cutting Frequency: ');
if (length(CutFreq_factor) == 0)
  CutFreq_factor = 50;
endif

tau_step = input('Please give the step size to vary tau by: ');
if (length(tau_step) == 0)
  tau_step = 5;
endif

data = load(dataFile);
col_len = length(data);       % finds the length of the data columns


%------------------------------------ Creating the folder to save the plots to -----------------------------------------
% This should be done after the data file is loaded and the name of the data file should be used to create the directory created here

% Path to where all SE data folders are kept
SE_path = '~/Innalabs/Octave/SensitiveElements/';
new_SE_folder = [SE_path , SE_IDnum];

% create first directory associated with this SE, it may already exit if this SE has been measured already
if (exist(new_SE_folder) == 0)
  mkdir(new_SE_folder);
  new_SE_Thermal = [new_SE_folder , '/Thermal'];
  mkdir(new_SE_Thermal);
  meas_date_folder = [new_SE_Thermal , '/' , meas_date];
  mkdir(meas_date_folder);
elseif (exist(new_SE_folder) == 7)
  new_SE_Thermal = [new_SE_folder , '/Thermal'];
  if (exist(new_SE_Thermal) == 0)
    mkdir(new_SE_Thermal);
    meas_date_folder = [new_SE_Thermal , '/' , meas_date];
    mkdir(meas_date_folder);
  elseif (exist(new_SE_Thermal) == 7)
    meas_date_folder = [new_SE_Thermal , '/' , meas_date];
    if (exist(meas_date_folder) == 0)
      mkdir(meas_date_folder);
    endif
  endif
endif

% remember the present working directory
script_dir = pwd;


%------------------------------------------- Signal processing and Time calculations ----------------------------------------------------
% Get the Time in hrs, dTime in s and moving average of dTime, caluclate the Sampling Time

time_s = data(:,1);                % column 1 of the data (Time in s)
time_hr = time_s / 3600;

% find dTime
for i=2:col_len
   dTime_s(i-1) = data(i,1) - data(i-1,1);
end

% find moving average of dTime over 40 samples
dTime_ave = filter(1/40*ones(1,40), 1, dTime_s);

% for plotting need shorter time as dTime excludes the first point
time_short = time_hr(2:end);

  Ts_s = mean(dTime_s);
  Ts_Hz = 1/Ts_s;
  CutFreq = Ts_Hz / CutFreq_factor;
  z_factor = 0.5;
  tau_order1 = 1 / (2*pi*CutFreq);

% figure for dTime against time_hr
figure
    plot(time_short, dTime_s, 'g;dTime;', time_short(40:end), dTime_ave(40:end), 'r;dTime Moving Average;')
    xlabel('Time  (hrs)')
    ylabel('Time  (s)')
    title('Sampling Time')

% save the plot to a specific filename, realted to the date the script is run
Time_fname = ['01SamplingTime_' ,  meas_date , '_' , SE_IDnum , '.png'];
cd(meas_date_folder)
print(Time_fname, '-dpng', '-color')
cd(script_dir)


%------------------------------------------------- Temperature Conversion ---------------------------------------------------------------
% Need to calculate the conversion parameters (slope & intersect) to convert the temperature from V to degC

% Chamber temperature
temp_chamberV = -1* data(:,8);                   % column 8 of the data (temp in V)

TC_x = [min(temp_chamberV) ; max(temp_chamberV)];
TC_y = [-45 ; 90];

function y = con_Cham_temp(x, pin)
  y = (pin(1) .* x) .+ pin(2);
end
pin = [1 1];                         

% start the fit
[chamber_func, pout, kvg, iter, corp, covp, covr, stdresid, Z, r2] = leasqr(TC_x, TC_y, pin, 'con_Cham_temp');

chamber_m = pout(1);
chamber_c = pout(2);

temp_chamberC = (chamber_m .* temp_chamberV) .+ chamber_c;

% SE temperature
temp_SE_V = -1* data(:,4);                   % column 4 of the data (temp in V)

SE_C_x = [min(temp_SE_V) ; max(temp_SE_V)];
SE_C_y = [-45 ; 90];

function y = con_SE_temp(x, pin)
  y = (pin(1) .* x) .+ pin(2);
end
pin = [1 1];                         

% start the fit
[SE_func, pout, kvg, iter, corp, covp, covr, stdresid, Z, r2] = leasqr(SE_C_x, SE_C_y, pin, 'con_SE_temp');

SE_m = pout(1);
SE_c = pout(2);

temp_SE_C = (SE_m .* temp_SE_V) .+ SE_c;

figure
plot(time_hr, temp_SE_C, 'b;SE sensor temp;', time_hr, temp_chamberC, 'g;Chamber temp;')
    xlabel('Time  (hrs)')
    ylabel('Temp degC')
    title('Temperature')
    axis([1,10,-50,100])              % want to set the y-axis range but must set a range for the x-axis too
    axis('auto x')                    % resets the x-axis to auto scale

% save the plot to a specific filename, realted to the date the script is run
TempVTime_fname = ['02TempVsTime_' ,  meas_date , '_' , SE_IDnum , '.png'];
cd(meas_date_folder)
print(TempVTime_fname, '-dpng', '-color')
cd(script_dir)


%----------------------------------------- Frequency & First Order Temp Filtering -------------------------------------------------------
% Frequency is column 5 from data file
Freq_Hz = data(:,5);

% get average of first 100 data points Frequency
Freq_ave = mean(Freq_Hz(500:1000));

% find dFrequency in Hz
dFreq = Freq_Hz - Freq_ave;

% need to calculate where to position the text each time on the y axis
max_dFreq = max(dFreq);
text_posn_Freq = max_dFreq - ((max_dFreq / 100) * 2);

% using shorter data file to find tau_freq
dFreq_short = dFreq(2000:end-2000);
temp_SE_C_short = temp_SE_C(2000:end-2000);
Freq_Hz_short = Freq_Hz(2000:end-2000);
time_hr_short = time_hr(2000:end-2000);
dFreq_short_shift = dFreq_short + 10;

figure
plot(time_hr, dFreq, 'b;dFreq (Hz);', time_hr_short, dFreq_short_shift, 'g;dFreq range used to find tau;')
    xlabel('Time  (hrs)')
    ylabel('Hz')
    title('Frequency')

% save the plot to a specific filename, realted to the date the script is run
FreqVTime_fname = ['03FreqVsTime_' ,  meas_date , '_' , SE_IDnum , '.png'];
cd(meas_date_folder)
print(FreqVTime_fname, '-dpng', '-color')
cd(script_dir)

% the temperature is time filtered so that the frequency is plotted against the actual temperature corresponding to the frequency
% the constant tau_freq is the time constant used to filter the frequency but this is different in every case so it is a parameter that must be found

% calculate thermal constant tau_freq for temp filtering
function y = FTM_cons_calc(x, pin)

  col_len = length(x);
  for i = 1:col_len
    if (i == 1)
      temp_tau_freq(i,1) = x(i);
    elseif (i > 1)
      temp_tau_freq(i,1) = (1 / (1 + pin(1))) * (x(i) + (pin(1) * temp_tau_freq(i-1)));
    endif
  end
  
   % fourth order polynom
  y = (pin(2) .* temp_tau_freq.^4) + (pin(3) .* temp_tau_freq.^3) .+ (pin(4) .* temp_tau_freq.^2) .+ (pin(5) .* temp_tau_freq) .+ pin(6);
end
pin = [200 1 1 1 1 1];

[Freq_Therm_Mod, pout, kvg, iter, corp, covp, covr, stdresid, Z, r2] = leasqr(temp_SE_C_short, dFreq_short, pin, 'FTM_cons_calc');

% temp_tau_freq is only defined inside the function, it needs to be re-defined outside using the newly calculated tau_freq (= pout(1) * Ts_s)
tau_freq = pout(1) * Ts_s;

% first order filtered temp using tau_freq
for i = 1:col_len
  if (i == 1)
    temp_tau_freq(i,1) = temp_SE_C(i);
  elseif (i > 1)
    temp_tau_freq(i,1) = (1 / (1 + pout(1))) * (temp_SE_C(i) + (pout(1) * temp_tau_freq(i-1)));              % pout(1) = tau_freq / Ts_s
  endif
end

Res_Freq_ppm = ((dFreq_short .- Freq_Therm_Mod) ./ Freq_Hz_short)  * 1000000;

figure
subplot(2, 1, 1)
plot(temp_SE_C, dFreq, 'b;dFreq (Hz);', temp_tau_freq, dFreq, 'r;dFreq vs filtered Temp;')
    xlabel('Temp  (deg C)')
    ylabel('Hz')
    title('Frequency')
    axis([-50,100])              % want to set the x-axis range

strg_Freq = sprintf("Freq ave is %1.2f Hz", Freq_ave);
text(-30, text_posn_Freq, strg_Freq)

subplot(2, 1, 2)
plot(temp_SE_C_short, Res_Freq_ppm, 'g;Frequency Residue (ppm);')
    xlabel('Temp  (deg C)')
    ylabel('ppm')
    title('Frequency Residue in ppm')
    axis([-50,100])              % want to set the x-axis range

% save the plot to a specific filename, realted to the date the script is run
FreqVTemp_fname = ['04FreqVsTemp_' ,  meas_date , '_' , SE_IDnum , '.png'];
cd(meas_date_folder)
print(FreqVTemp_fname, '-dpng', '-color')
cd(script_dir)

% Determine type of resonator based on average frequency of the resonator calculated 
if Freq_ave > 6400 && Freq_ave < 6800
  SE_type = 'B';
elseif Freq_ave > 7000 && Freq_ave < 7400
  SE_type = 'C';
elseif Freq_ave > 5800 && Freq_ave < 6200
  SE_type = 'A';
else
  SE_type = 'unknown';
endif


%------------------------------------------ Bias, from PO and NO -----------------------------------------------------------------------
% PO is column 2 & NO is column 3 of data file
PO_V = -1*data(:,2);
NO_V = -1*data(:,3);

PO_deg_s = PO_V / scale_factor;
NO_deg_s = NO_V / scale_factor;
Bias_deg_s = (PO_deg_s - NO_deg_s) / 2;

% get average of first 100 data points for PO, NO and Bias in deg per s
PO_ave = mean(PO_deg_s(1:100));
NO_ave = mean(NO_deg_s(1:100));
Bias_ave = mean(Bias_deg_s(1:100));

% dPO, dNO and dBias in deg per hr
dPO_deg_hr = (PO_deg_s - PO_ave) * 3600;
dNO_deg_hr = (NO_deg_s - NO_ave) * 3600;
dBias_deg_hr = (Bias_deg_s - Bias_ave) * 3600;

% need to calculate where to position the text each time on the y axis
max_dPO = max(dPO_deg_hr);
max_dNO = max(dNO_deg_hr);
if max_dPO > max_dNO
  text_posn_Bias = max_dPO - ((max_dPO / 100) * 2);
elseif max_dNO > max_dPO
  text_posn_Bias = max_dNO - ((max_dNO / 100) * 2);
end

figure
plot(time_hr, dPO_deg_hr, 'b;dPO signal;', time_hr, dNO_deg_hr, 'g;dNO signal;', time_hr, dBias_deg_hr, 'r;dBias signal;')
    xlabel('Time  (hrs)')
    ylabel('deg / hr')
    title('dBias, dPO and dNO')

strg_Bias = sprintf("Bias ave is %1.2f deg per hr", (Bias_ave*3600));
text(0.1, text_posn_Bias, strg_Bias)

% save the plot to a specific filename, realted to the date the script is run
BiasVTime_fname = ['05BiasVsTime_' ,  meas_date , '_' , SE_IDnum , '.png'];
cd(meas_date_folder)
print(BiasVTime_fname, '-dpng', '-color')
cd(script_dir)


%------------------------------------------------------- Cq and Ca ---------------------------------------------------------------------
% Cq is column 6 and Ca is column 7 from data file
Cq_V = -1*data(:,6);
Ca_V = -1*data(:,7);

% get average of first 100 data points for Cq and Ca in V
Cq_ave = mean(Cq_V(1:100));
Ca_ave = mean(Ca_V(1:100));

% find dCq and dCa in mV
dCq_mV = (Cq_V - Cq_ave) * 1000;
dCa_mV = (Ca_V - Ca_ave) * 1000;

% need to calculate where to position the text each time on the y axis
max_dCq = max(dCq_mV);
text_posn_CqCa = max_dCq - ((max_dCq / 100) * 2);

figure
% plot of Cq & Ca has two different y axes, plotyy is used
[ax, h1, h2] = plotyy(time_hr, dCq_mV, time_hr, dCa_mV);
    xlabel('Time  (hrs)')
    ylabel (ax(1), 'dCq  (mV)')
    ylabel (ax(2), 'dCa  (mV)')
    title('dCq and dCa in mV')
   
y1Label = 'dCq in mV';
y2Label = 'dCa in mV';
legend (y1Label, y2Label)

strg_CqCa = sprintf("Cq ave = %1.2f V, Ca ave = %1.2f V.", Cq_ave, Ca_ave);
text(0.1, text_posn_CqCa, strg_CqCa)

% save the plot to a specific filename, realted to the date the script is run
CqCaVTime_fname = ['06CqCaVsTime_' ,  meas_date , '_' , SE_IDnum , '.png'];
cd(meas_date_folder)
print(CqCaVTime_fname, '-dpng', '-color')
cd(script_dir)


%-------------------------------------------------------- Model 14 ---------------------------------------------------------------------
% Model based on Cq, Ca in V and dTemp (frequency filtered temp using tau_freq)

% create a series of tau_freq values to test the importance of an exact tau_freq
tau_min = tau_freq - (tau_step * 5);

% for loop to get values and create data coloumn to hold them
for i = 1:11
  tau_values(i) = tau_min + (tau_step * (i-1));
end

% 11 different filtered temperatures so there should be 11 versions of Res_Mod_14

% -------------------- tau_freq 1 --------------------
% T filtereing for tau_values(1)
filt_cons01 = tau_values(1) / Ts_s;
for i = 1:col_len
  if (i == 1)
    temp_tau_freq01(i) = temp_SE_C(i);
  elseif (i > 1)
    temp_tau_freq01(i) = (1 / (1 + filt_cons01)) * (temp_SE_C(i) + (filt_cons01 * temp_tau_freq01(i-1)));
  endif
end

emal_mod14 = Cq_V;
emal_mod14(:,2) = Ca_V;
emal_mod14(:,3) = temp_tau_freq01 - temp_tau_freq01(1);

function y = calc_mod14_v1(emal_mod14, pin)
  y = (pin(1) .* emal_mod14(:,1)) .+ (pin(2) .* emal_mod14(:,1).^2) .+ (pin(3) .* emal_mod14(:,2)) .+ (pin(4) .* emal_mod14(:,1) .* emal_mod14(:,2)) .+ (pin(5) .* emal_mod14(:,3).^2) + pin(6);
end
pin = [1 1 1 1 1 1];

% start the fit
[Bias_Mod_14_v1, parameters_out, kvg, iter, corp, covp, covr, stdresid, Z, r2] = leasqr(emal_mod14, dBias_deg_hr, pin, 'calc_mod14_v1');
Res_Mod_14_v1 = dBias_deg_hr .- Bias_Mod_14_v1;

% fit Res_Mod_14 using polynomial T
function y = calc_ResMod14_v1(x, pin)
  % 6th order polynom
  y = (pin(1) .* x) .+ (pin(2) .* x.^2) .+ (pin(3) .* x.^3) .+ (pin(4) .* x.^4) .+ (pin(5) .* x.^5) .+ (pin(6).* x.^6) .+ pin(7);
end
pin = [1 1 1 1 1 1 1];

% start the fit
[Mod_ResMod14_v1, pout, kvg, iter, corp, covp, covr, stdresid, Z, r2] = leasqr(emal_mod14(:,3), Res_Mod_14_v1, pin, 'calc_ResMod14_v1');
Res2_ModRes14_v1 = Res_Mod_14_v1 - Mod_ResMod14_v1;

% -------------------- tau_freq 2 --------------------
% T filtereing for tau_values(2)
filt_cons02 = tau_values(2) / Ts_s;
for i = 1:col_len
  if (i == 1)
    temp_tau_freq02(i) = temp_SE_C(i);
  elseif (i > 1)
    temp_tau_freq02(i) = (1 / (1 + filt_cons02)) * (temp_SE_C(i) + (filt_cons02 * temp_tau_freq02(i-1)));
  endif
end

emal_mod14 = Cq_V;
emal_mod14(:,2) = Ca_V;
emal_mod14(:,3) = temp_tau_freq02 - temp_tau_freq02(1);

function y = calc_mod14_v2(emal_mod14, pin)
  y = (pin(1) .* emal_mod14(:,1)) .+ (pin(2) .* emal_mod14(:,1).^2) .+ (pin(3) .* emal_mod14(:,2)) .+ (pin(4) .* emal_mod14(:,1) .* emal_mod14(:,2)) .+ (pin(5) .* emal_mod14(:,3).^2) + pin(6);
end
pin = [1 1 1 1 1 1];

% start the fit
[Bias_Mod_14_v2, parameters_out, kvg, iter, corp, covp, covr, stdresid, Z, r2] = leasqr(emal_mod14, dBias_deg_hr, pin, 'calc_mod14_v2');
Res_Mod_14_v2 = dBias_deg_hr .- Bias_Mod_14_v2;

% fit Res_Mod_14 using polynomial T
function y = calc_ResMod14_v2(x, pin)
  % 6th order polynom
  y = (pin(1) .* x) .+ (pin(2) .* x.^2) .+ (pin(3) .* x.^3) .+ (pin(4) .* x.^4) .+ (pin(5) .* x.^5) .+ (pin(6).* x.^6) .+ pin(7);
end
pin = [1 1 1 1 1 1 1];

% start the fit
[Mod_ResMod14_v2, pout, kvg, iter, corp, covp, covr, stdresid, Z, r2] = leasqr(emal_mod14(:,3), Res_Mod_14_v2, pin, 'calc_ResMod14_v2');
Res2_ModRes14_v2 = Res_Mod_14_v2 - Mod_ResMod14_v2;

% -------------------- tau_freq 3 --------------------
% T filtereing for tau_values(3)
filt_cons03 = tau_values(3) / Ts_s;
for i = 1:col_len
  if (i == 1)
    temp_tau_freq03(i) = temp_SE_C(i);
  elseif (i > 1)
    temp_tau_freq03(i) = (1 / (1 + filt_cons03)) * (temp_SE_C(i) + (filt_cons03 * temp_tau_freq03(i-1)));
  endif
end

emal_mod14 = Cq_V;
emal_mod14(:,2) = Ca_V;
emal_mod14(:,3) = temp_tau_freq03 - temp_tau_freq03(1);

function y = calc_mod14_v3(emal_mod14, pin)
  y = (pin(1) .* emal_mod14(:,1)) .+ (pin(2) .* emal_mod14(:,1).^2) .+ (pin(3) .* emal_mod14(:,2)) .+ (pin(4) .* emal_mod14(:,1) .* emal_mod14(:,2)) .+ (pin(5) .* emal_mod14(:,3).^2) + pin(6);
end
pin = [1 1 1 1 1 1];

% start the fit
[Bias_Mod_14_v3, parameters_out, kvg, iter, corp, covp, covr, stdresid, Z, r2] = leasqr(emal_mod14, dBias_deg_hr, pin, 'calc_mod14_v3');
Res_Mod_14_v3 = dBias_deg_hr .- Bias_Mod_14_v3;

% fit Res_Mod_14 using polynomial T
function y = calc_ResMod14_v3(x, pin)
  % 6th order polynom
  y = (pin(1) .* x) .+ (pin(2) .* x.^2) .+ (pin(3) .* x.^3) .+ (pin(4) .* x.^4) .+ (pin(5) .* x.^5) .+ (pin(6).* x.^6) .+ pin(7);
end
pin = [1 1 1 1 1 1 1];

% start the fit
[Mod_ResMod14_v3, pout, kvg, iter, corp, covp, covr, stdresid, Z, r2] = leasqr(emal_mod14(:,3), Res_Mod_14_v3, pin, 'calc_ResMod14_v3');
Res2_ModRes14_v3 = Res_Mod_14_v3 - Mod_ResMod14_v3;

% -------------------- tau_freq 4 --------------------
% T filtereing for tau_values(4)
filt_cons04 = tau_values(4) / Ts_s;
for i = 1:col_len
  if (i == 1)
    temp_tau_freq04(i) = temp_SE_C(i);
  elseif (i > 1)
    temp_tau_freq04(i) = (1 / (1 + filt_cons04)) * (temp_SE_C(i) + (filt_cons04 * temp_tau_freq04(i-1)));
  endif
end

emal_mod14 = Cq_V;
emal_mod14(:,2) = Ca_V;
emal_mod14(:,3) = temp_tau_freq04 - temp_tau_freq04(1);

function y = calc_mod14_v4(emal_mod14, pin)
  y = (pin(1) .* emal_mod14(:,1)) .+ (pin(2) .* emal_mod14(:,1).^2) .+ (pin(3) .* emal_mod14(:,2)) .+ (pin(4) .* emal_mod14(:,1) .* emal_mod14(:,2)) .+ (pin(5) .* emal_mod14(:,3).^2) + pin(6);
end
pin = [1 1 1 1 1 1];

% start the fit
[Bias_Mod_14_v4, parameters_out, kvg, iter, corp, covp, covr, stdresid, Z, r2] = leasqr(emal_mod14, dBias_deg_hr, pin, 'calc_mod14_v4');
Res_Mod_14_v4 = dBias_deg_hr .- Bias_Mod_14_v4;

% fit Res_Mod_14 using polynomial T
function y = calc_ResMod14_v4(x, pin)
  % 6th order polynom
  y = (pin(1) .* x) .+ (pin(2) .* x.^2) .+ (pin(3) .* x.^3) .+ (pin(4) .* x.^4) .+ (pin(5) .* x.^5) .+ (pin(6).* x.^6) .+ pin(7);
end
pin = [1 1 1 1 1 1 1];

% start the fit
[Mod_ResMod14_v4, pout, kvg, iter, corp, covp, covr, stdresid, Z, r2] = leasqr(emal_mod14(:,3), Res_Mod_14_v4, pin, 'calc_ResMod14_v4');
Res2_ModRes14_v4 = Res_Mod_14_v4 - Mod_ResMod14_v4;

% -------------------- tau_freq 5 --------------------
% T filtereing for tau_values(5)
filt_cons05 = tau_values(5) / Ts_s;
for i = 1:col_len
  if (i == 1)
    temp_tau_freq05(i) = temp_SE_C(i);
  elseif (i > 1)
    temp_tau_freq05(i) = (1 / (1 + filt_cons05)) * (temp_SE_C(i) + (filt_cons05 * temp_tau_freq05(i-1)));
  endif
end

emal_mod14 = Cq_V;
emal_mod14(:,2) = Ca_V;
emal_mod14(:,3) = temp_tau_freq05 - temp_tau_freq05(1);

function y = calc_mod14_v5(emal_mod14, pin)
  y = (pin(1) .* emal_mod14(:,1)) .+ (pin(2) .* emal_mod14(:,1).^2) .+ (pin(3) .* emal_mod14(:,2)) .+ (pin(4) .* emal_mod14(:,1) .* emal_mod14(:,2)) .+ (pin(5) .* emal_mod14(:,3).^2) + pin(6);
end
pin = [1 1 1 1 1 1];

% start the fit
[Bias_Mod_14_v5, parameters_out, kvg, iter, corp, covp, covr, stdresid, Z, r2] = leasqr(emal_mod14, dBias_deg_hr, pin, 'calc_mod14_v5');
Res_Mod_14_v5 = dBias_deg_hr .- Bias_Mod_14_v5;

% fit Res_Mod_14 using polynomial T
function y = calc_ResMod14_v5(x, pin)
  % 6th order polynom
  y = (pin(1) .* x) .+ (pin(2) .* x.^2) .+ (pin(3) .* x.^3) .+ (pin(4) .* x.^4) .+ (pin(5) .* x.^5) .+ (pin(6).* x.^6) .+ pin(7);
end
pin = [1 1 1 1 1 1 1];

% start the fit
[Mod_ResMod14_v5, pout, kvg, iter, corp, covp, covr, stdresid, Z, r2] = leasqr(emal_mod14(:,3), Res_Mod_14_v5, pin, 'calc_ResMod14_v5');
Res2_ModRes14_v5 = Res_Mod_14_v5 - Mod_ResMod14_v5;

% -------------------- tau_freq 6 --------------------
% T filtereing for tau_values(6)
filt_cons06 = tau_values(6) / Ts_s;
for i = 1:col_len
  if (i == 1)
    temp_tau_freq06(i) = temp_SE_C(i);
  elseif (i > 1)
    temp_tau_freq06(i) = (1 / (1 + filt_cons06)) * (temp_SE_C(i) + (filt_cons06 * temp_tau_freq06(i-1)));
  endif
end

emal_mod14 = Cq_V;
emal_mod14(:,2) = Ca_V;
emal_mod14(:,3) = temp_tau_freq06 - temp_tau_freq06(1);

function y = calc_mod14_v6(emal_mod14, pin)
  y = (pin(1) .* emal_mod14(:,1)) .+ (pin(2) .* emal_mod14(:,1).^2) .+ (pin(3) .* emal_mod14(:,2)) .+ (pin(4) .* emal_mod14(:,1) .* emal_mod14(:,2)) .+ (pin(5) .* emal_mod14(:,3).^2) + pin(6);
end
pin = [1 1 1 1 1 1];

% start the fit
[Bias_Mod_14_v6, parameters_out, kvg, iter, corp, covp, covr, stdresid, Z, r2] = leasqr(emal_mod14, dBias_deg_hr, pin, 'calc_mod14_v6');
Res_Mod_14_v6 = dBias_deg_hr .- Bias_Mod_14_v6;

% fit Res_Mod_14 using polynomial T
function y = calc_ResMod14_v6(x, pin)
  % 6th order polynom
  y = (pin(1) .* x) .+ (pin(2) .* x.^2) .+ (pin(3) .* x.^3) .+ (pin(4) .* x.^4) .+ (pin(5) .* x.^5) .+ (pin(6).* x.^6) .+ pin(7);
end
pin = [1 1 1 1 1 1 1];

% start the fit
[Mod_ResMod14_v6, pout, kvg, iter, corp, covp, covr, stdresid, Z, r2] = leasqr(emal_mod14(:,3), Res_Mod_14_v6, pin, 'calc_ResMod14_v6');
Res2_ModRes14_v6 = Res_Mod_14_v6 - Mod_ResMod14_v6;

% -------------------- tau_freq 7 --------------------
% T filtereing for tau_values(7)
filt_cons07 = tau_values(7) / Ts_s;
for i = 1:col_len
  if (i == 1)
    temp_tau_freq07(i) = temp_SE_C(i);
  elseif (i > 1)
    temp_tau_freq07(i) = (1 / (1 + filt_cons07)) * (temp_SE_C(i) + (filt_cons07 * temp_tau_freq07(i-1)));
  endif
end

emal_mod14 = Cq_V;
emal_mod14(:,2) = Ca_V;
emal_mod14(:,3) = temp_tau_freq07 - temp_tau_freq07(1);

function y = calc_mod14_v7(emal_mod14, pin)
  y = (pin(1) .* emal_mod14(:,1)) .+ (pin(2) .* emal_mod14(:,1).^2) .+ (pin(3) .* emal_mod14(:,2)) .+ (pin(4) .* emal_mod14(:,1) .* emal_mod14(:,2)) .+ (pin(5) .* emal_mod14(:,3).^2) + pin(6);
end
pin = [1 1 1 1 1 1];

% start the fit
[Bias_Mod_14_v7, parameters_out, kvg, iter, corp, covp, covr, stdresid, Z, r2] = leasqr(emal_mod14, dBias_deg_hr, pin, 'calc_mod14_v7');
Res_Mod_14_v7 = dBias_deg_hr .- Bias_Mod_14_v7;

% fit Res_Mod_14 using polynomial T
function y = calc_ResMod14_v7(x, pin)
  % 6th order polynom
  y = (pin(1) .* x) .+ (pin(2) .* x.^2) .+ (pin(3) .* x.^3) .+ (pin(4) .* x.^4) .+ (pin(5) .* x.^5) .+ (pin(6).* x.^6) .+ pin(7);
end
pin = [1 1 1 1 1 1 1];

% start the fit
[Mod_ResMod14_v7, pout, kvg, iter, corp, covp, covr, stdresid, Z, r2] = leasqr(emal_mod14(:,3), Res_Mod_14_v7, pin, 'calc_ResMod14_v7');
Res2_ModRes14_v7 = Res_Mod_14_v7 - Mod_ResMod14_v7;

% -------------------- tau_freq 8 --------------------
% T filtereing for tau_values(8)
filt_cons08 = tau_values(8) / Ts_s;
for i = 1:col_len
  if (i == 1)
    temp_tau_freq08(i) = temp_SE_C(i);
  elseif (i > 1)
    temp_tau_freq08(i) = (1 / (1 + filt_cons08)) * (temp_SE_C(i) + (filt_cons08 * temp_tau_freq08(i-1)));
  endif
end

emal_mod14 = Cq_V;
emal_mod14(:,2) = Ca_V;
emal_mod14(:,3) = temp_tau_freq08 - temp_tau_freq08(1);

function y = calc_mod14_v8(emal_mod14, pin)
  y = (pin(1) .* emal_mod14(:,1)) .+ (pin(2) .* emal_mod14(:,1).^2) .+ (pin(3) .* emal_mod14(:,2)) .+ (pin(4) .* emal_mod14(:,1) .* emal_mod14(:,2)) .+ (pin(5) .* emal_mod14(:,3).^2) + pin(6);
end
pin = [1 1 1 1 1 1];

% start the fit
[Bias_Mod_14_v8, parameters_out, kvg, iter, corp, covp, covr, stdresid, Z, r2] = leasqr(emal_mod14, dBias_deg_hr, pin, 'calc_mod14_v8');
Res_Mod_14_v8 = dBias_deg_hr .- Bias_Mod_14_v8;

% fit Res_Mod_14 using polynomial T
function y = calc_ResMod14_v8(x, pin)
  % 6th order polynom
  y = (pin(1) .* x) .+ (pin(2) .* x.^2) .+ (pin(3) .* x.^3) .+ (pin(4) .* x.^4) .+ (pin(5) .* x.^5) .+ (pin(6).* x.^6) .+ pin(7);
end
pin = [1 1 1 1 1 1 1];

% start the fit
[Mod_ResMod14_v8, pout, kvg, iter, corp, covp, covr, stdresid, Z, r2] = leasqr(emal_mod14(:,3), Res_Mod_14_v8, pin, 'calc_ResMod14_v8');
Res2_ModRes14_v8 = Res_Mod_14_v8 - Mod_ResMod14_v8;

% -------------------- tau_freq 9 --------------------
% T filtereing for tau_values(9)
filt_cons09 = tau_values(9) / Ts_s;
for i = 1:col_len
  if (i == 1)
    temp_tau_freq09(i) = temp_SE_C(i);
  elseif (i > 1)
    temp_tau_freq09(i) = (1 / (1 + filt_cons09)) * (temp_SE_C(i) + (filt_cons09 * temp_tau_freq09(i-1)));
  endif
end

emal_mod14 = Cq_V;
emal_mod14(:,2) = Ca_V;
emal_mod14(:,3) = temp_tau_freq09 - temp_tau_freq09(1);

function y = calc_mod14_v9(emal_mod14, pin)
  y = (pin(1) .* emal_mod14(:,1)) .+ (pin(2) .* emal_mod14(:,1).^2) .+ (pin(3) .* emal_mod14(:,2)) .+ (pin(4) .* emal_mod14(:,1) .* emal_mod14(:,2)) .+ (pin(5) .* emal_mod14(:,3).^2) + pin(6);
end
pin = [1 1 1 1 1 1];

% start the fit
[Bias_Mod_14_v9, parameters_out, kvg, iter, corp, covp, covr, stdresid, Z, r2] = leasqr(emal_mod14, dBias_deg_hr, pin, 'calc_mod14_v9');
Res_Mod_14_v9 = dBias_deg_hr .- Bias_Mod_14_v9;

% fit Res_Mod_14 using polynomial T
function y = calc_ResMod14_v9(x, pin)
  % 6th order polynom
  y = (pin(1) .* x) .+ (pin(2) .* x.^2) .+ (pin(3) .* x.^3) .+ (pin(4) .* x.^4) .+ (pin(5) .* x.^5) .+ (pin(6).* x.^6) .+ pin(7);
end
pin = [1 1 1 1 1 1 1];

% start the fit
[Mod_ResMod14_v9, pout, kvg, iter, corp, covp, covr, stdresid, Z, r2] = leasqr(emal_mod14(:,3), Res_Mod_14_v9, pin, 'calc_ResMod14_v9');
Res2_ModRes14_v9 = Res_Mod_14_v9 - Mod_ResMod14_v9;

% -------------------- tau_freq 10 --------------------
% T filtereing for tau_values(10)
filt_cons10 = tau_values(10) / Ts_s;
for i = 1:col_len
  if (i == 1)
    temp_tau_freq10(i) = temp_SE_C(i);
  elseif (i > 1)
    temp_tau_freq10(i) = (1 / (1 + filt_cons10)) * (temp_SE_C(i) + (filt_cons10 * temp_tau_freq10(i-1)));
  endif
end

emal_mod14 = Cq_V;
emal_mod14(:,2) = Ca_V;
emal_mod14(:,3) = temp_tau_freq10 - temp_tau_freq10(1);

function y = calc_mod14_v10(emal_mod14, pin)
  y = (pin(1) .* emal_mod14(:,1)) .+ (pin(2) .* emal_mod14(:,1).^2) .+ (pin(3) .* emal_mod14(:,2)) .+ (pin(4) .* emal_mod14(:,1) .* emal_mod14(:,2)) .+ (pin(5) .* emal_mod14(:,3).^2) + pin(6);
end
pin = [1 1 1 1 1 1];

% start the fit
[Bias_Mod_14_v10, parameters_out, kvg, iter, corp, covp, covr, stdresid, Z, r2] = leasqr(emal_mod14, dBias_deg_hr, pin, 'calc_mod14_v10');
Res_Mod_14_v10 = dBias_deg_hr .- Bias_Mod_14_v10;

% fit Res_Mod_14 using polynomial T
function y = calc_ResMod14_v10(x, pin)
  % 6th order polynom
  y = (pin(1) .* x) .+ (pin(2) .* x.^2) .+ (pin(3) .* x.^3) .+ (pin(4) .* x.^4) .+ (pin(5) .* x.^5) .+ (pin(6).* x.^6) .+ pin(7);
end
pin = [1 1 1 1 1 1 1];

% start the fit
[Mod_ResMod14_v10, pout, kvg, iter, corp, covp, covr, stdresid, Z, r2] = leasqr(emal_mod14(:,3), Res_Mod_14_v10, pin, 'calc_ResMod14_v10');
Res2_ModRes14_v10 = Res_Mod_14_v10 - Mod_ResMod14_v10;

% -------------------- tau_freq 10 --------------------
% T filtereing for tau_values(10)
filt_cons11 = tau_values(11) / Ts_s;
for i = 1:col_len
  if (i == 1)
    temp_tau_freq11(i) = temp_SE_C(i);
  elseif (i > 1)
    temp_tau_freq11(i) = (1 / (1 + filt_cons11)) * (temp_SE_C(i) + (filt_cons11 * temp_tau_freq11(i-1)));
  endif
end

emal_mod14 = Cq_V;
emal_mod14(:,2) = Ca_V;
emal_mod14(:,3) = temp_tau_freq11 - temp_tau_freq11(1);

function y = calc_mod14_v11(emal_mod14, pin)
  y = (pin(1) .* emal_mod14(:,1)) .+ (pin(2) .* emal_mod14(:,1).^2) .+ (pin(3) .* emal_mod14(:,2)) .+ (pin(4) .* emal_mod14(:,1) .* emal_mod14(:,2)) .+ (pin(5) .* emal_mod14(:,3).^2) + pin(6);
end
pin = [1 1 1 1 1 1];

% start the fit
[Bias_Mod_14_v11, parameters_out, kvg, iter, corp, covp, covr, stdresid, Z, r2] = leasqr(emal_mod14, dBias_deg_hr, pin, 'calc_mod14_v11');
Res_Mod_14_v11 = dBias_deg_hr .- Bias_Mod_14_v11;

% fit Res_Mod_14 using polynomial T
function y = calc_ResMod14_v11(x, pin)
  % 6th order polynom
  y = (pin(1) .* x) .+ (pin(2) .* x.^2) .+ (pin(3) .* x.^3) .+ (pin(4) .* x.^4) .+ (pin(5) .* x.^5) .+ (pin(6).* x.^6) .+ pin(7);
end
pin = [1 1 1 1 1 1 1];

% start the fit
[Mod_ResMod14_v11, pout, kvg, iter, corp, covp, covr, stdresid, Z, r2] = leasqr(emal_mod14(:,3), Res_Mod_14_v11, pin, 'calc_ResMod14_v11');
Res2_ModRes14_v11 = Res_Mod_14_v11 - Mod_ResMod14_v11;


%----------------------------------------------- Plots of the Model's Residue ----------------------------------------------------------
figure
subplot(2,1,1)
plot(temp_SE_C, Res_Mod_14_v1, 'b;Res Mod 14 v1;')
    xlabel('Temp  (deg C)')
    ylabel('deg / hr')
    title('Version 1 of Model 14, using min tau frequency')
    axis([-50,100])              % want to set the x and y axis range

subplot(2,1,2)
plot(temp_SE_C, Res2_ModRes14_v1, 'b;Res of Mod Res 14 v1;')
    xlabel('Temp  (deg C)')
    ylabel('deg / hr')
    title('Version 1 of Res of Model 14, using min tau frequency')
    axis([-50,100])              % want to set the x and y axis range

% save these plots to a specific filename, realted to the date the script is run
Res14v1_fname = ['07Mod14v1_' ,  meas_date , '_' , SE_IDnum , '.png'];
cd(meas_date_folder)
print(Res14v1_fname, '-dpng', '-color')
cd(script_dir)

figure
subplot(2,1,1)
plot(temp_SE_C, Res_Mod_14_v6, 'b;Res Mod 14 v6;')
    xlabel('Temp  (deg C)')
    ylabel('deg / hr')
    title('Version 6 of Model 14, using optimum tau frequency')
    axis([-50,100])              % want to set the x and y axis range

subplot(2,1,2)
plot(temp_SE_C, Res2_ModRes14_v6, 'b;Res of Mod Res 14 v6;')
    xlabel('Temp  (deg C)')
    ylabel('deg / hr')
    title('Version 6 of Res of Model 14, using optimum tau frequency')
    axis([-50,100])              % want to set the x and y axis range

% save these plots to a specific filename, realted to the date the script is run
Res14v6_fname = ['08Mod14v6_' ,  meas_date , '_' , SE_IDnum , '.png'];
cd(meas_date_folder)
print(Res14v6_fname, '-dpng', '-color')
cd(script_dir)

figure
subplot(2,1,1)
plot(temp_SE_C, Res_Mod_14_v11, 'b;Res Mod 14 v11;')
    xlabel('Temp  (deg C)')
    ylabel('deg / hr')
    title('Version 11 of Model 14, using maximum tau frequency')
    axis([-50,100])              % want to set the x and y axis range

subplot(2,1,2)
plot(temp_SE_C, Res2_ModRes14_v11, 'b;Res of Mod Res 14 v11;')
    xlabel('Temp  (deg C)')
    ylabel('deg / hr')
    title('Version 11 of Res of Model 14, using maximum tau frequency')
    axis([-50,100])              % want to set the x and y axis range

% save these plots to a specific filename, realted to the date the script is run
Res14v11_fname = ['09Mod14v11_' ,  meas_date , '_' , SE_IDnum , '.png'];
cd(meas_date_folder)
print(Res14v11_fname, '-dpng', '-color')
cd(script_dir)


%----------------------------------------------- Model deviation and SPEC --------------------------------------------------------------

Mod_nums = [1 ; 2 ; 3 ; 4 ; 5 ; 6 ; 7 ; 8 ; 9 ; 10 ; 11];

tau_freq_vals = [tau_values(1) ; tau_values(2) ; tau_values(3) ; tau_values(4) ; tau_values(5) ; tau_values(6) ; tau_values(7) ; tau_values(8) ; tau_values(9) ; tau_values(10) ; tau_values(11)];

Mod_specs = [std(Res2_ModRes14_v1) ; std(Res2_ModRes14_v2) ; std(Res2_ModRes14_v3) ; std(Res2_ModRes14_v4) ; std(Res2_ModRes14_v5) ; std(Res2_ModRes14_v6) ; std(Res2_ModRes14_v7) ; std(Res2_ModRes14_v8) ; std(Res2_ModRes14_v9) ; std(Res2_ModRes14_v10) ; std(Res2_ModRes14_v11)];

SPEC_needed = [15 ; 15 ; 15 ; 15 ; 15 ; 15 ; 15 ; 15 ; 15 ; 15 ; 15];


%----------------------------------------------- Model Peak to Peak Noise --------------------------------------------------------------
Mod_numsPP = [1 ; 2 ; 3 ; 4 ; 5 ; 6 ; 7 ; 8 ; 9 ; 10 ; 11];
SPEC_neededPP = [45 ; 45 ; 45 ; 45 ; 45 ; 45 ; 45 ; 45 ; 45 ; 45 ; 45];

Peak_1 = max(max(Res_Mod_14_v1) - min(Res_Mod_14_v1));
Peak_Res1 = max(max(Res2_ModRes14_v1) - min(Res2_ModRes14_v1));

Peak_2 = max(max(Res_Mod_14_v2) - min(Res_Mod_14_v2));
Peak_Res2 = max(max(Res2_ModRes14_v2) - min(Res2_ModRes14_v2));

Peak_3 = max(max(Res_Mod_14_v3) - min(Res_Mod_14_v3));
Peak_Res3 = max(max(Res2_ModRes14_v3) - min(Res2_ModRes14_v3));

Peak_4 = max(max(Res_Mod_14_v4) - min(Res_Mod_14_v4));
Peak_Res4 = max(max(Res2_ModRes14_v4) - min(Res2_ModRes14_v4));

Peak_5 = max(max(Res_Mod_14_v5) - min(Res_Mod_14_v5));
Peak_Res5 = max(max(Res2_ModRes14_v5) - min(Res2_ModRes14_v5));

Peak_6 = max(max(Res_Mod_14_v6) - min(Res_Mod_14_v6));
Peak_Res6 = max(max(Res2_ModRes14_v6) - min(Res2_ModRes14_v6));

Peak_7 = max(max(Res_Mod_14_v7) - min(Res_Mod_14_v7));
Peak_Res7 = max(max(Res2_ModRes14_v7) - min(Res2_ModRes14_v7));

Peak_8 = max(max(Res_Mod_14_v8) - min(Res_Mod_14_v8));
Peak_Res8 = max(max(Res2_ModRes14_v8) - min(Res2_ModRes14_v8));

Peak_9 = max(max(Res_Mod_14_v9) - min(Res_Mod_14_v9));
Peak_Res9 = max(max(Res2_ModRes14_v9) - min(Res2_ModRes14_v9));

Peak_10 = max(max(Res_Mod_14_v10) - min(Res_Mod_14_v10));
Peak_Res10 = max(max(Res2_ModRes14_v10) - min(Res2_ModRes14_v10));

Peak_11 = max(max(Res_Mod_14_v11) - min(Res_Mod_14_v11));
Peak_Res11 = max(max(Res2_ModRes14_v11) - min(Res2_ModRes14_v11));

Peak_to_Peak = [Peak_Res1 ; Peak_Res2 ; Peak_Res3 ; Peak_Res4 ; Peak_Res5 ; Peak_Res6 ; Peak_Res7 ; Peak_Res8 ; Peak_Res9 ; Peak_Res10 ; Peak_Res11];

tau_min_plot = tau_values(1) - 5;
tau_max_plot = tau_values(11) + 5;

figure
subplot(2, 1, 1)
plot(tau_freq_vals, Peak_to_Peak, 'b;Peak to peak;',  tau_freq_vals, SPEC_neededPP, 'r;Advertised Peak to Peak;')
    xlabel('tau freq values (s)')
    ylabel('Peak to Peak (deg / hr)')
    title('SE Peak to Peak')
    axis([tau_min_plot,tau_max_plot])

subplot(2, 1, 2)
plot(tau_freq_vals, Mod_specs, 'b;Standard Deviation of Model;', tau_freq_vals, SPEC_needed, 'r;Advertised SPEC;')
    xlabel('tau freq values (s)')
    ylabel('Standard Deviation (deg / hr)')
    title('SE Standard Deviation')
    axis([tau_min_plot,tau_max_plot])

% save these plots to a specific filename, realted to the date the script is run
Peak_fname = ['10Peak_' ,  meas_date , '_' , SE_IDnum , '.png'];
cd(meas_date_folder)
print(Peak_fname, '-dpng', '-color')
cd(script_dir)

%----------------------------------------- Plots of Bias against Temp and Filtered Temp ------------------------------------------------
figure
subplot(2, 1, 1)
plot(temp_SE_C, dPO_deg_hr, 'b;dPO signal;', temp_SE_C, dNO_deg_hr, 'g;dNO signal;', temp_SE_C, dBias_deg_hr, 'r;dBias signal;')
    xlabel('Temp  (deg C)')
    ylabel('deg / hr')
    title('dBias, dPO and dNO against unfiltered temperature')
    axis([-50,100])              % want to set the x-axis range

subplot(2, 1, 2)
plot(temp_tau_freq, dPO_deg_hr, 'b;dPO signal;', temp_tau_freq, dNO_deg_hr, 'g;dNO signal;', temp_tau_freq, dBias_deg_hr, 'r;dBias signal;')
    xlabel('Temp  (deg C)')
    ylabel('deg / hr')
    title('dBias, dPO and dNO against temp filtered using thermal constant')
    axis([-50,100])              % want to set the x-axis range

% save the plot to a specific filename, realted to the date the script is run
BiasVTemp_fname = ['11BiasVsTemp_' ,  meas_date , '_' , SE_IDnum , '.png'];
cd(meas_date_folder)
print(BiasVTemp_fname, '-dpng', '-color')
cd(script_dir)


%-------------------------------------------------- Plot of Bias vs Freqency -----------------------------------------------------------
figure
subplot(2, 1, 1)
plot(dFreq, dPO_deg_hr, 'b;dPO signal;', dFreq, dNO_deg_hr, 'g;dNO signal;', dFreq, dBias_deg_hr, 'r;dBias signal;')
    xlabel('Freq  (Hz)')
    ylabel('deg / hr')
    title('dBias, dPO and dNO against Frequency')

subplot(2, 1, 2)
plot(dFreq, Bias_deg_s, 'b;Raw Bias signal;')
    xlabel('Freq  (Hz)')
    ylabel('deg / s')
    title('Raw Bias against Frequency')

% save the plot to a specific filename, realted to the date the script is run
BiasVFreq_fname = ['12BiasVsTFreq_' ,  meas_date , '_' , SE_IDnum , '.png'];
cd(meas_date_folder)
print(BiasVFreq_fname, '-dpng', '-color')
cd(script_dir)


%--------------------------------------- Plots of Cq and Ca against Temperature --------------------------------------------------------
figure
subplot(2, 1, 1)
plot(temp_SE_C, Cq_V, 'b;Cq vs unfiltered Temp;', temp_tau_freq, Cq_V, 'r;Cq vs filtered Temp;')
    xlabel('Temp  (deg C)')
    ylabel('V')
    title('Cq vs Temp')
    axis([-50,100])              % want to set the x-axis range

subplot(2, 1, 2)
plot(temp_SE_C, Ca_V, 'b;Ca vs unfiltered Temp;', temp_tau_freq, Ca_V, 'r;Ca vs filtered Temp;')
    xlabel('Temp  (deg C)')
    ylabel('V')
    title('Ca vs Temp')
    axis([-50,100])              % want to set the x-axis range

% save these plots to a specific filename, realted to the date the script is run
CqCaVsTemp_fname = ['13CqCaVsTemp_' ,  meas_date , '_' , SE_IDnum , '.png'];
cd(meas_date_folder)
print(CqCaVsTemp_fname, '-dpng', '-color')
cd(script_dir)


%------------------------------------------ First derivative of the temp vs temp --------------------------------------------------------
% get the derivative of the temperatures for the SE & Chamber over 100 points every 10 points
temp_int = 100;
i_step = 10;
i_start = temp_int + 1;
i_end = floor((col_len - 100) / 10) * 10;

q = 0;

for i = i_start : i_step : i_end
  q ++;
  dTemp_Chamber(q) = ((temp_chamberC(i) - temp_chamberC(i-temp_int)) / (time_hr(i) - time_hr(i-temp_int))) * 60;
  dTemp_SE(q) = ((temp_SE_C(i) - temp_SE_C(i-temp_int)) / (time_hr(i) - time_hr(i-temp_int))) * 60;
  temp_cham_der(q) = temp_chamberC(i);
  temp_SE_der(q) = temp_SE_C(i);
end


figure
plot(temp_cham_der, dTemp_Chamber, 'g;Derivative of Chamber temp;', temp_SE_der, dTemp_SE, 'b;Derivative of SE temp;')
    xlabel('Temp  (deg C)')
    ylabel('Derivative of Temp  (deg C per min)')
    title('Temperature Derivatives')
    axis([-50,100])              % want to set the x-axis range

% save the plot to a specific filename, realted to the date the script is run
DerivVTemp_fname = ['14TempDeriv_' ,  meas_date , '_' , SE_IDnum , '.png'];
cd(meas_date_folder)
print(DerivVTemp_fname, '-dpng', '-color')
cd(script_dir)


%------------------------------------------- Simple text file with a list of constants -------------------------------------------------
% filename is based on the SE number and the date
textfname = ['SE' , SE_IDnum(6:8) , '_ThermalTest_'  , meas_date , '.txt'];

% move to the folder where the graphs are stored
cd(meas_date_folder)
fout = fopen(textfname, 'w');

fprintf(fout, "Sensitive element ID is %s and is type %s. \n", SE_IDnum, SE_type);
fprintf(fout, "Sensitive element housing details: %s. \n", SE_housing);
fprintf(fout, "Thermal test carried out in %s. \n", SE_test_chamber);
fprintf(fout, "Thermal slope used during the thermal cycle is %1.1f degC per min. \n", therm_slope);
fprintf(fout, "The serial boards used for this test are %s. \n", serial_board_no); 
fprintf(fout, "\n");
fprintf(fout, "Scale factor for this SE is %f. \n", scale_factor);
fprintf(fout, "Sampling time is %f s and sampling frequency is %f Hz. \n", Ts_s, Ts_Hz);
fprintf(fout, "Calculated cutting frequency is %f Hz, calculated using a factor of %d. \n", CutFreq, CutFreq_factor);
fprintf(fout, "Thermal time constant for temperature filtering used in plots of frequency is %f s. \n", tau_freq);
fprintf(fout, "\n");
fprintf(fout, "The max value of Cq over the test cycle is %1.2f V. \n", max(Cq_V));
fprintf(fout, "The min value of Cq over the test cycle is %1.2f V. \n", min(Cq_V));
fprintf(fout, "The max value of Ca over the test cycle is %1.2f V. \n", max(Ca_V));
fprintf(fout, "The min value of Ca over the test cycle is %1.2f V. \n", min(Ca_V));
fprintf(fout, "\n");
fprintf(fout, "Model 14: (k0 * Cq) + (k1 * Cq^2) + (k2 * Ca) + (k3 * Ca * Cq) + (k4 * T(fil)^2) + k5 \n");
fprintf(fout, "Model Res 14: Sixth order temperature polynomial \n");
fprintf(fout, "\n");
fprintf(fout, "Minium frequency thermal time constant is %f s. \n", tau_values(1));
fprintf(fout, "Standard deviation of the Res of Model Res 14 is %f deg per hr. \n", std(Res2_ModRes14_v1));
fprintf(fout, "Peak to peak noise of the Res of Model Res 14 is %f deg per hr. \n", Peak_Res1);
fprintf(fout, "\n");
fprintf(fout, "Optimum frequency thermal time constant is %f s. \n", tau_values(6));
fprintf(fout, "Standard deviation of the Res of Model Res 14 is %f deg per hr. \n", std(Res2_ModRes14_v6));
fprintf(fout, "Peak to peak noise of the Res of Model Res 14 is %f deg per hr. \n", Peak_Res6);
fprintf(fout, "\n");
fprintf(fout, "Maximum frequency thermal time constant is %f s. \n", tau_values(11));
fprintf(fout, "Standard deviation of the Res of Model Res 14 is %f deg per hr. \n", std(Res2_ModRes14_v11));
fprintf(fout, "Peak to peak noise of the Res of Model Res 14 is %f deg per hr. \n", Peak_Res11);
fprintf(fout, "\n");

fclose(fout)
cd(script_dir)

