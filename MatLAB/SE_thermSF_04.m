% SE_thermSF_04.m - fourth version of script, started 07 June 2012
% Script to find the scale factor while SE is undergoing a thermal cycle, important parameters here are temperature and rotation
% Change in how tau is calculated and the temperature is filtered
% Introduce a further filtering of the data points based on the temperature difference between them
% Double the number scale factor and bias points calculated
% User decides how many points to be skipped in the plateaus

close all
clear all

% start with the file to be worked on, 49 characters in total minus .ext
% load the data file to be worked on
% example of typical filename is '2012.05.14-15_ArSm_ThermSF0100_GU010006X_SE010315', measurement is spread over two days in this example but can be just one day
dataFile = input('Enter the name of the data file: ', 's');
% the first 13 characters of the filename gives the date the measurement
% was STARTED to when it was STOPPED,
% this full date will be used as the ID date for the graphs saved later
meas_date = dataFile(1:13);

% SE name taken from the file name
SE_IDnum = dataFile(42:49);

% small sentence on if and how SE is housed (GU200, Y axis or on it's own), information taken from the file name
SE_housing = dataFile(32:40);
if SE_housing == "GU0000000"
  SE_housing = "SE not housed in GU";
else
  SE_housing = ["GU number " , dataFile(32:39) , ", in " , dataFile(40) , " axis"];
endif

% type of test carried out on SE
SE_test_type = dataFile(20:30);

% test chamber test was carried out in
SE_test_chamber = dataFile(15:18);
if SE_test_chamber == "ArSm"
  SE_test_chamber = "Aerosmith Chamber";
elseif SE_test_chamber == "TIRA"
  SE_test_chamber = "TIRA Chamber";
elseif SE_test_chamber == "Acut"
  SE_test_chamber = "Acutronic Chamber";
endif

plateau_skip = input("Amount of points to skip at the beginning and end of each plateau: ");
if (length(plateau_skip) == 0)
  plateau_skip = 5;
endif

temp_int = input("Temperature interval between data points: ");
if (length(temp_int) == 0)
  temp_int = 0.5;
endif

CutFreq_factor = input("Factor to divide the sampling frequency by to determine the Cutting Frequency: ");
if (length(CutFreq_factor) == 0)
  CutFreq_factor = 50;
endif

SF_desire = 32;

data = load(dataFile);
col_len = length(data);       % finds the length of the data columns


%------------------------------------ Creating the folder to save the plots to -----------------------------------------
% This should be done after the data file is loaded and the name of the data file should be used to create the directory created here

% Path to where all SE data folders are kept
SE_path = "~/Innalabs/Octave/SensitiveElements/";
new_SE_folder = [SE_path , SE_IDnum];

% create first directory associated with this SE, it may already exit if this SE has been measured already
if (exist(new_SE_folder) == 0)
  mkdir(new_SE_folder);
  new_SE_Thermal_SF = [new_SE_folder , "/Thermal_SF"];
  mkdir(new_SE_Thermal_SF);
  meas_date_folder = [new_SE_Thermal_SF , "/" , meas_date];
  mkdir(meas_date_folder);
elseif (exist(new_SE_folder) == 7)
  new_SE_Thermal_SF = [new_SE_folder , "/Thermal_SF"];
  if (exist(new_SE_Thermal_SF) == 0)
    mkdir(new_SE_Thermal_SF);
    meas_date_folder = [new_SE_Thermal_SF , "/" , meas_date];
    mkdir(meas_date_folder);
  elseif (exist(new_SE_Thermal_SF) == 7)
    meas_date_folder = [new_SE_Thermal_SF , "/" , meas_date];
    if (exist(meas_date_folder) == 0)
      mkdir(meas_date_folder);
    endif
  endif
endif

% remember the present working directory
script_dir = pwd;


%-------------------------------------- List all the data columns taken from the data file ----------------------------------------------
time_s = data(:,1);
PO_V = -1 * data(:,2);
NO_V = -1 * data(:,3);
temp_SE_V = -1 * data(:,4);
Freq_Hz = data(:,5);
Cq_V = -1 * data(:,6);
Ca_V = -1 * data(:,7);
temp_chamber_V = -1 * data(:,8);
rot_V = data(:,9);


%------------------------------------------- Signal processing and Time calculations ----------------------------------------------------
% Get the Time in hrs, dTime in s and moving average of dTime, calculate the Sampling Time
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
    plot(time_short, dTime_s, "g;dTime;", time_short(40:end), dTime_ave(40:end), "r;dTime Moving Average;")
    xlabel("Time  (hrs)")
    ylabel("Time  (s)")
    title("Sampling Time")

% save the plot to a specific filename, related to the date the script is run
Time_fname = ["01SamplingTime_" ,  meas_date , "_" , SE_IDnum , ".png"];
cd(meas_date_folder)
print(Time_fname, "-dpng", "-color")
cd(script_dir)


%------------------------------------------------- Temperature Conversion ---------------------------------------------------------------
% Need to calculate the conversion parameters (slope & intersect) to convert the temperature from V to degC
% Chamber temperature
TC_x = [min(temp_chamber_V) ; max(temp_chamber_V)];
TC_y = [-50 ; 94];

function y = con_Cham_temp(x, pin)
  y = (pin(1) .* x) .+ pin(2);
end
pin = [1 1];                         
% start the fit
[chamber_func, pout, kvg, iter, corp, covp, covr, stdresid, Z, r2] = leasqr(TC_x, TC_y, pin, "con_Cham_temp");

chamber_m = pout(1);
chamber_c = pout(2);
temp_chamber_C = (chamber_m .* temp_chamber_V) .+ chamber_c;

% Need to put the temperature through a low pass filter in order to get it to match the temperature seen by the sensitive elements thermal sensor
% y(n) = (T_e / (tau + T_e)) * x(n) + (tau / (tau + T_e)) * y(n-1) , where tau is the time constant and T_e is 

% SE temperature
SE_C_x = [min(temp_SE_V) ; max(temp_SE_V)];
SE_C_y = [-45 ; 86];

function y = con_SE_temp(x, pin)
  y = (pin(1) .* x) .+ pin(2);
end
pin = [1 1];                         
% start the fit
[SE_func, pout, kvg, iter, corp, covp, covr, stdresid, Z, r2] = leasqr(SE_C_x, SE_C_y, pin, "con_SE_temp");

SE_m = pout(1);
SE_c = pout(2);
temp_SE_C = (SE_m .* temp_SE_V) .+ SE_c;

figure
plot(time_hr, temp_SE_C, "b;SE sensor temp;", time_hr, temp_chamber_C, "g;Chamber temp;")
    xlabel("Time  (hrs)")
    ylabel("Temp degC")
    title("Temperature")
    axis([1,10,-60,100])              % want to set the y-axis range but must set a range for the x-axis too
    axis("auto x")                    % resets the x-axis to auto scale

% save the plot to a specific filename, related to the date the script is run
TempVTime_fname = ["02TempVsTime_" ,  meas_date , "_" , SE_IDnum , ".png"];
cd(meas_date_folder)
print(TempVTime_fname, "-dpng", "-color")
cd(script_dir)


%--------------------------------------------------- Rotation Conversion ----------------------------------------------------------------
% Convert rotation voltage into deg per s and plot it against time
rot_deg_s = 10 * rot_V;
time_min = time_s / 60;

% If there is no real rotation data, create it using the PO output
if max(rot_deg_s) < 5
  for i = 1:col_len
    if PO_V(i) <= 3 && PO_V(i) >= -3
      rot_deg_s(i) = 0;
    elseif PO_V(i) > 3
      rot_deg_s(i) = 100;
    elseif PO_V(i) < -3
      rot_deg_s(i) = -100;
    endif
  end
endif

% Rotation profile over 10 mins, repeated throughout the length of the measurement
figure
plot(time_min, rot_deg_s, "m-o;Rotation profile;");
    xlabel("Time  (mins)")
    ylabel ("Rotation  (deg per s)")
    title("Rotation profile over 10 mins, continued throughout the measurement")
    axis([0,10,-110,110])
   
% save the plot to a specific filename, related to the date the script is run
RotTC_fname = ["03RotTC_" ,  meas_date , "_" , SE_IDnum , ".png"];
cd(meas_date_folder)
print(RotTC_fname, "-dpng", "-color")
cd(script_dir)


%--------------------------- Need to get the data where rot is actually + and - 100 deg/s ----------------------------------------------
% Set up loop to catch the data
max_rot = max(rot_deg_s);               % find the max rotation value
min_rot = min(rot_deg_s);               % find the min rotation value
rot_up_cutoff = max_rot - ((max_rot / 100) * 3);     % 3% less than the max, data is kept above this limit
rot_low_cutoff = min_rot - ((min_rot / 100) * 3);    % 3% greater than the min, data is kept below this limit

p = 1;   % to catch the positive roation data
n = 1;   % to catch the negitive roation data
for i = 1:col_len     % col_len is the total no of data points in the raw data
  if rot_deg_s(i) > rot_up_cutoff  
    time_s_prot(p) = time_s(i);
    PO_V_prot(p) = PO_V(i);
    NO_V_prot(p) = NO_V(i);
    Ca_V_prot(p) = Ca_V(i);
    Cq_V_prot(p) = Cq_V(i);
    temp_SE_V_prot(p) = temp_SE_V(i);
    temp_SE_C_prot(p) = temp_SE_C(i);
    temp_chamber_V_prot(p) = temp_chamber_V(i);
    temp_chamber_C_prot(p) = temp_chamber_C(i);
    rot_deg_s_prot(p) = rot_deg_s(i);
    index_list_prot(p) = i;
    p++;
  elseif rot_deg_s(i) < rot_low_cutoff
    time_s_nrot(n) = time_s(i);
    PO_V_nrot(n) = PO_V(i);
    NO_V_nrot(n) = NO_V(i);
    Ca_V_nrot(n) = Ca_V(i);
    Cq_V_nrot(n) = Cq_V(i);
    temp_SE_V_nrot(n) = temp_SE_V(i);
    temp_SE_C_nrot(n) = temp_SE_C(i);
    temp_chamber_V_nrot(n) = temp_chamber_V(i);
    temp_chamber_C_nrot(n) = temp_chamber_C(i);
    rot_deg_s_nrot(n) = rot_deg_s(i);
    index_list_nrot(n) = i;
    n++;
  endif
end

% final arrays to hold the actual data going to be used
% positive rotation only
diff_index_prot = diff(index_list_prot);
fin_time_s_prot = [];
fin_PO_V_prot = [];
fin_NO_V_prot = [];
fin_Ca_V_prot = [];
fin_Cq_V_prot = [];
fin_temp_SE_V_prot = [];
fin_temp_SE_C_prot = [];
fin_temp_chamber_V_prot = [];
fin_temp_chamber_C_prot = [];
fin_rot_deg_s_prot = [];
PO_V_prot_ave = [];
PO_V_prot_ptp = [];
PO_V_prot_std = [];
NO_V_prot_ave = [];
NO_V_prot_ptp = [];
NO_V_prot_std = [];
time_s_prot_ave = [];
temp_SE_V_prot_ave = [];
temp_SE_C_prot_ave = [];
rot_deg_s_prot_ave = [];
Cq_V_prot_ave = [];
Ca_V_prot_ave = [];
p = 1;
for i = 1:length(diff_index_prot)
  if diff_index_prot(i) == 1
    new_time_prot(p) = time_s_prot(i);
    new_PO_prot(p) = PO_V_prot(i);
    new_NO_prot(p) = NO_V_prot(i);
    new_Ca_prot(p) = Ca_V_prot(i);
    new_Cq_prot(p) = Cq_V_prot(i);
    new_SE_V_prot(p) = temp_SE_V_prot(i);
    new_SE_C_prot(p) = temp_SE_C_prot(i);
    new_cham_V_prot(p) = temp_chamber_V_prot(i);
    new_cham_C_prot(p) = temp_chamber_C_prot(i);
    new_prot(p) = rot_deg_s_prot(i);
    p++;
  elseif diff_index_prot(i) > 1 && p > 1;
    % new data arrays holding only the middle points of each positive rotation plateau
    fin_time_s_prot = [fin_time_s_prot new_time_prot(plateau_skip:end-plateau_skip)];
    fin_PO_V_prot = [fin_PO_V_prot new_PO_prot(plateau_skip:end-plateau_skip)];
    fin_NO_V_prot = [fin_NO_V_prot new_NO_prot(plateau_skip:end-plateau_skip)];
    fin_Ca_V_prot = [fin_Ca_V_prot new_Ca_prot(plateau_skip:end-plateau_skip)];
    fin_Cq_V_prot = [fin_Cq_V_prot new_Cq_prot(plateau_skip:end-plateau_skip)];
    fin_temp_SE_V_prot = [fin_temp_SE_V_prot new_SE_V_prot(plateau_skip:end-plateau_skip)];
    fin_temp_SE_C_prot = [fin_temp_SE_C_prot new_SE_C_prot(plateau_skip:end-plateau_skip)];
    fin_temp_chamber_V_prot = [fin_temp_chamber_V_prot new_cham_V_prot(plateau_skip:end-plateau_skip)];
    fin_temp_chamber_C_prot = [fin_temp_chamber_C_prot new_cham_C_prot(plateau_skip:end-plateau_skip)];
    fin_rot_deg_s_prot = [fin_rot_deg_s_prot new_prot(plateau_skip:end-plateau_skip)];

    % statistical data of PO and NO on each plateau
    PO_V_prot_ptp = [PO_V_prot_ptp max(max(new_PO_prot(plateau_skip:end-plateau_skip))-min(new_PO_prot(plateau_skip:end-plateau_skip)))];
    PO_V_prot_std = [PO_V_prot_std std(new_PO_prot(plateau_skip:end-plateau_skip))];
    NO_V_prot_ptp = [NO_V_prot_ptp max(max(new_NO_prot(plateau_skip:end-plateau_skip))-min(new_NO_prot(plateau_skip:end-plateau_skip)))];
    NO_V_prot_std = [NO_V_prot_std std(new_NO_prot(plateau_skip:end-plateau_skip))];

    % data averaged over each plateau
    PO_V_prot_ave = [PO_V_prot_ave mean(new_PO_prot(plateau_skip:end-plateau_skip))];
    NO_V_prot_ave = [NO_V_prot_ave mean(new_NO_prot(plateau_skip:end-plateau_skip))];
    time_s_prot_ave = [time_s_prot_ave mean(new_time_prot(plateau_skip:end-plateau_skip))];
    temp_SE_V_prot_ave = [temp_SE_V_prot_ave mean(new_SE_V_prot(plateau_skip:end-plateau_skip))];
    temp_SE_C_prot_ave = [temp_SE_C_prot_ave mean(new_SE_C_prot(plateau_skip:end-plateau_skip))];
    rot_deg_s_prot_ave = [rot_deg_s_prot_ave mean(new_prot(plateau_skip:end-plateau_skip))];
    Cq_V_prot_ave = [Cq_V_prot_ave mean(new_Cq_prot(plateau_skip:end-plateau_skip))];
    Ca_V_prot_ave = [Ca_V_prot_ave mean(new_Ca_prot(plateau_skip:end-plateau_skip))];
    p = 1;
  endif
end

% negitive rotation only
diff_index_nrot = diff(index_list_nrot);
fin_time_s_nrot = [];
fin_PO_V_nrot = [];
fin_NO_V_nrot = [];
fin_Ca_V_nrot = [];
fin_Cq_V_nrot = [];
fin_temp_SE_V_nrot = [];
fin_temp_SE_C_nrot = [];
fin_temp_chamber_V_nrot = [];
fin_temp_chamber_C_nrot = [];
fin_rot_deg_s_nrot = [];
PO_V_nrot_ave = [];
PO_V_nrot_ptp = [];
PO_V_nrot_std = [];
NO_V_nrot_ave = [];
NO_V_nrot_ptp = [];
NO_V_nrot_std = [];
time_s_nrot_ave = [];
temp_SE_V_nrot_ave = [];
temp_SE_C_nrot_ave = [];
rot_deg_s_nrot_ave = [];
Cq_V_nrot_ave = [];
Ca_V_nrot_ave = [];
n = 1;
for i = 1:length(diff_index_nrot)
  if diff_index_nrot(i) == 1
    new_time_nrot(n) = time_s_nrot(i);
    new_PO_nrot(n) = PO_V_nrot(i);
    new_NO_nrot(n) = NO_V_nrot(i);
    new_Ca_nrot(n) = Ca_V_nrot(i);
    new_Cq_nrot(n) = Cq_V_nrot(i);
    new_SE_V_nrot(n) = temp_SE_V_nrot(i);
    new_SE_C_nrot(n) = temp_SE_C_nrot(i);
    new_cham_V_nrot(n) = temp_chamber_V_nrot(i);
    new_cham_C_nrot(n) = temp_chamber_C_nrot(i);
    new_nrot(n) = rot_deg_s_nrot(i);
    n++;
  elseif diff_index_nrot(i) > 1 && n > 1;
    % new data arrays holding only the middle points of each negitive rotation plateau
    fin_time_s_nrot = [fin_time_s_nrot fin_time_s_nrot];
    fin_PO_V_nrot = [fin_PO_V_nrot new_PO_nrot(plateau_skip:end-plateau_skip)];
    fin_NO_V_nrot = [fin_NO_V_nrot new_NO_nrot(plateau_skip:end-plateau_skip)];
    fin_Ca_V_nrot = [fin_Ca_V_nrot new_Ca_nrot(plateau_skip:end-plateau_skip)];
    fin_Cq_V_nrot = [fin_Cq_V_nrot new_Cq_nrot(plateau_skip:end-plateau_skip)];
    fin_temp_SE_V_nrot = [fin_temp_SE_V_nrot new_SE_V_nrot(plateau_skip:end-plateau_skip)];
    fin_temp_SE_C_nrot = [fin_temp_SE_C_nrot new_SE_C_nrot(plateau_skip:end-plateau_skip)];
    fin_temp_chamber_V_nrot = [fin_temp_chamber_V_nrot new_cham_V_nrot(plateau_skip:end-plateau_skip)];
    fin_temp_chamber_C_nrot = [fin_temp_chamber_C_nrot new_cham_C_nrot(plateau_skip:end-plateau_skip)];
    fin_rot_deg_s_nrot = [fin_rot_deg_s_nrot new_nrot(plateau_skip:end-plateau_skip)];

    % statistical data on each plateau
    PO_V_nrot_ptp = [PO_V_nrot_ptp max(max(new_PO_nrot(plateau_skip:end-plateau_skip))-min(new_PO_nrot(plateau_skip:end-plateau_skip)))];
    PO_V_nrot_std = [PO_V_nrot_std std(new_PO_nrot(plateau_skip:end-plateau_skip))];
    NO_V_nrot_ptp = [NO_V_nrot_ptp max(max(new_NO_nrot(plateau_skip:end-plateau_skip))-min(new_NO_nrot(plateau_skip:end-plateau_skip)))];
    NO_V_nrot_std = [NO_V_nrot_std std(new_NO_nrot(plateau_skip:end-plateau_skip))];
    
    % data averaged over each plateau
    PO_V_nrot_ave = [PO_V_nrot_ave mean(new_PO_nrot(plateau_skip:end-plateau_skip))];
    NO_V_nrot_ave = [NO_V_nrot_ave mean(new_NO_nrot(plateau_skip:end-plateau_skip))];
    time_s_nrot_ave = [time_s_nrot_ave mean(new_time_nrot(plateau_skip:end-plateau_skip))];
    temp_SE_V_nrot_ave = [temp_SE_V_nrot_ave mean(new_SE_V_nrot(plateau_skip:end-plateau_skip))];
    temp_SE_C_nrot_ave = [temp_SE_C_nrot_ave mean(new_SE_C_nrot(plateau_skip:end-plateau_skip))];
    rot_deg_s_nrot_ave = [rot_deg_s_nrot_ave mean(new_nrot(plateau_skip:end-plateau_skip))];
    Cq_V_nrot_ave = [Cq_V_nrot_ave mean(new_Cq_nrot(plateau_skip:end-plateau_skip))];
    Ca_V_nrot_ave = [Ca_V_nrot_ave mean(new_Ca_nrot(plateau_skip:end-plateau_skip))];
    n = 1;
  endif
end


%----------------------------------- Filter data according to temperature difference ----------------------------------------------------
% Want only a few points per temperature so al temperatures are weighted the same during fits

% data for positive rotation
p = 1;
diff_temp_SE_C_prot_ave = diff(temp_SE_C_prot_ave);
for i = 1:(length(diff_temp_SE_C_prot_ave) - 1);
  if diff_temp_SE_C_prot_ave(i) >= temp_int && diff_temp_SE_C_prot_ave(i) > 0
    PO_V_prot_opt(p) = PO_V_prot_ave(i+1);
    NO_V_prot_opt(p) = NO_V_prot_ave(i+1);
    Cq_V_prot_opt(p) = Cq_V_prot_ave(i+1);
    Ca_V_prot_opt(p) = Ca_V_prot_ave(i+1);
    time_s_prot_opt(p) = time_s_prot_ave(i+1);
    temp_SE_V_prot_opt(p) = temp_SE_V_prot_ave(i+1);
    temp_SE_C_prot_opt(p) = temp_SE_C_prot_ave(i+1);
    rot_deg_s_prot_opt(p) = rot_deg_s_prot_ave(i+1);
    p++;
  elseif diff_temp_SE_C_prot_ave(i) <= (-1 * temp_int) && diff_temp_SE_C_prot_ave(i) < 0
    PO_V_prot_opt(p) = PO_V_prot_ave(i+1);
    NO_V_prot_opt(p) = NO_V_prot_ave(i+1);
    Cq_V_prot_opt(p) = Cq_V_prot_ave(i+1);
    Ca_V_prot_opt(p) = Ca_V_prot_ave(i+1);
    time_s_prot_opt(p) = time_s_prot_ave(i+1);
    temp_SE_V_prot_opt(p) = temp_SE_V_prot_ave(i+1);
    temp_SE_C_prot_opt(p) = temp_SE_C_prot_ave(i+1);
    rot_deg_s_prot_opt(p) = rot_deg_s_prot_ave(i+1);
    p++;
  endif
endfor

% data for negitive rotation
n = 1;
diff_temp_SE_C_nrot_ave = diff(temp_SE_C_nrot_ave);
for i = 1:length(diff_temp_SE_C_nrot_ave);
  if diff_temp_SE_C_nrot_ave(i) >= temp_int && diff_temp_SE_C_nrot_ave(i) > 0
    PO_V_nrot_opt(n) = PO_V_nrot_ave(i+1);
    NO_V_nrot_opt(n) = NO_V_nrot_ave(i+1);
    Cq_V_nrot_opt(n) = Cq_V_nrot_ave(i+1);
    Ca_V_nrot_opt(n) = Ca_V_nrot_ave(i+1);
    time_s_nrot_opt(n) = time_s_nrot_ave(i+1);
    temp_SE_V_nrot_opt(n) = temp_SE_V_nrot_ave(i+1);
    temp_SE_C_nrot_opt(n) = temp_SE_C_nrot_ave(i+1);
    rot_deg_s_nrot_opt(n) = rot_deg_s_nrot_ave(i+1);
    n++;
  elseif diff_temp_SE_C_nrot_ave(i) <= (-1 * temp_int) && diff_temp_SE_C_nrot_ave(i) < 0
    PO_V_nrot_opt(n) = PO_V_nrot_ave(i+1);
    NO_V_nrot_opt(n) = NO_V_nrot_ave(i+1);
    Cq_V_nrot_opt(n) = Cq_V_nrot_ave(i+1);
    Ca_V_nrot_opt(n) = Ca_V_nrot_ave(i+1);
    time_s_nrot_opt(n) = time_s_nrot_ave(i+1);
    temp_SE_V_nrot_opt(n) = temp_SE_V_nrot_ave(i+1);
    temp_SE_C_nrot_opt(n) = temp_SE_C_nrot_ave(i+1);
    rot_deg_s_nrot_opt(n) = rot_deg_s_nrot_ave(i+1);
    n++;
  endif
endfor


%--------------------------------- PO, NO and Diff for Positive and Negitive Rotation ---------------------------------------------------
Diff_V_prot_opt = (PO_V_prot_opt - NO_V_prot_opt) * 0.5;
Diff_V_nrot_opt = (PO_V_nrot_opt - NO_V_nrot_opt) * 0.5;

dDiff_V_prot_opt = Diff_V_prot_opt - Diff_V_prot_opt(1);
dDiff_V_nrot_opt = Diff_V_nrot_opt - Diff_V_nrot_opt(1);

% need to calculate where to position the text each time on the y axis
text_posn_dD = max(dDiff_V_prot_opt) - ((max(dDiff_V_prot_opt) / 100) * 10);

% the difference between PO and NO is used to caluclate the Bias and Scale Factor, not just PO
figure
plot(temp_SE_C_prot_opt, dDiff_V_prot_opt, 'g-o;Diff due to +rot;', temp_SE_C_nrot_opt, dDiff_V_nrot_opt, 'r-o;Diff due to -rot;')
    xlabel("Temperature  (deg per s)")
    ylabel ("dDiff  (V)")
    title("Diff between PO & NO vs Temperature")
    axis([-50,90])
strg_dD = sprintf("+ve rot offset is %1.2f V\n-ve rot offset is %1.2f V", Diff_V_prot_opt(1), Diff_V_nrot_opt(1));
text(-30, text_posn_dD, strg_dD)

% save the plot to a specific filename, related to the date the script is run
DiffvsTemp_fname = ["04DiffVsTemp_" ,  meas_date , "_" , SE_IDnum , ".png"];
cd(meas_date_folder)
print(DiffvsTemp_fname, "-dpng", "-color")
cd(script_dir)

% the difference between PO and NO is used to caluclate the Bias and Scale Factor, not just PO
figure
plot(rot_deg_s_prot_opt, Diff_V_prot_opt, 'go;Diff due to +100 rot;', rot_deg_s_nrot_opt, Diff_V_nrot_opt, 'ro;Diff due to -100 rot;')
    xlabel("Rotation  (deg per s)")
    ylabel ("Diff  (V)")
    title("Diff between PO & NO vs Rotation")
    axis([-110,110])

% save the plot to a specific filename, related to the date the script is run
DiffvsRot_fname = ["05DiffVsRot_" ,  meas_date , "_" , SE_IDnum , ".png"];
cd(meas_date_folder)
print(DiffvsRot_fname, "-dpng", "-color")
cd(script_dir)


%--------------------------------------------- Bias, Scale Factor and Epsilon -----------------------------------------------------------
% find scale factor and Bias (zero rotation Diff) from the slope and intercept of diff vs rotation

% need to make sure Diff_V_prot_opt & Diff_V_nrot_opt are the same length as well as the rotation for each
if length(Diff_V_prot_opt) > length(Diff_V_nrot_opt)
  Diff_V_prot_opt = Diff_V_prot_opt(1:length(Diff_V_nrot_opt));
  rot_deg_s_prot_opt = rot_deg_s_prot_opt(1:length(Diff_V_nrot_opt));
  temp_SE_V_prot_opt = temp_SE_V_prot_opt(1:length(Diff_V_nrot_opt));
  temp_SE_C_prot_opt = temp_SE_C_prot_opt(1:length(Diff_V_nrot_opt));
  time_s_prot_opt = time_s_prot_opt(1:length(Diff_V_nrot_opt));
  Cq_V_prot_opt = Cq_V_prot_opt(1:length(Diff_V_nrot_opt));
  Ca_V_prot_opt = Ca_V_prot_opt(1:length(Diff_V_nrot_opt));
elseif length(Diff_V_nrot_opt) > length(Diff_V_prot_opt)
  Diff_V_nrot_opt = Diff_V_nrot_opt(1:length(Diff_V_prot_opt));
  rot_deg_s_nrot_opt = rot_deg_s_nrot_opt(1:length(Diff_V_prot_opt));
  temp_SE_V_nrot_opt = temp_SE_V_nrot_opt(1:length(Diff_V_prot_opt));
  temp_SE_C_nrot_opt = temp_SE_C_nrot_opt(1:length(Diff_V_prot_opt));
  time_s_nrot_opt = time_s_nrot_opt(1:length(Diff_V_prot_opt));
  Cq_V_nrot_opt = Cq_V_nrot_opt(1:length(Diff_V_prot_opt));
  Ca_V_nrot_opt = Ca_V_nrot_opt(1:length(Diff_V_prot_opt));
endif

% need to combine +ve and -ve data in a way which will have an array of -ve, +ve, -ve, +ve ...  values
Diff_combined = [];
rot_combined = [];
temp_SE_V_combined = [];
temp_SE_C_combined = [];
Cq_V_combined = [];
Ca_V_combined = [];
time_s_combined = [];
for i = 1:length(rot_deg_s_prot_opt)
  Diff_combined = [Diff_combined Diff_V_nrot_opt(i) Diff_V_prot_opt(i)]; 
  rot_combined = [rot_combined rot_deg_s_nrot_opt(i) rot_deg_s_prot_opt(i)]; 
  temp_SE_V_combined = [temp_SE_V_combined temp_SE_V_nrot_opt(i) temp_SE_V_prot_opt(i)];
  temp_SE_C_combined = [temp_SE_C_combined temp_SE_C_nrot_opt(i) temp_SE_C_prot_opt(i)];
  Ca_V_combined = [Ca_V_combined Ca_V_nrot_opt(i) Ca_V_prot_opt(i)];
  Cq_V_combined = [Cq_V_combined Cq_V_nrot_opt(i) Cq_V_prot_opt(i)];
  time_s_combined = [time_s_combined time_s_nrot_opt(i) time_s_prot_opt(i)];
end

j = 1;
SF_from_slope = [];
Bias_from_inter = [];
for i = 2:1:length(rot_combined)
  function y = calc_m_c(x, pin)
    y = (pin(1) .* x) .+ pin(2);    % m*x + c, m is slope (SF) and c is intercept (bias) 
  end
  pin = [1 1];
  % start the fit
  [Mod_cons, pout, kvg, iter, corp, covp, covr, stdresid, Z, r2] = leasqr(rot_combined(i-1:i), Diff_combined(i-1:i), pin, "calc_m_c");
  SF_from_slope = [SF_from_slope pout(1)];
  Bias_from_inter = [Bias_from_inter pout(2)];
  Ca_V_com_ave(j) = (Ca_V_combined(i) + Ca_V_combined(i-1)) / 2;
  Cq_V_com_ave(j) = (Cq_V_combined(i) + Cq_V_combined(i-1)) / 2;
  j++;
end
SF_from_slope = SF_from_slope * 1000;    % convert from V/deg/s to mV/deg/s

figure
plot(temp_SE_C_combined(2:end), Bias_from_inter, "b;Bias calculated from intercept;")
    xlabel("Temperature  (degC)")
    ylabel ("Bias  (V)")
    title("Bias vs Temperature")
    axis([-60,100])

% save the plot to a specific filename, related to the date the script is run
BiasvsTemp_fname = ["06BiasVsTemp_" ,  meas_date , "_" , SE_IDnum , ".png"];
cd(meas_date_folder)
print(BiasvsTemp_fname, "-dpng", "-color")
cd(script_dir)

% need to calculate where to position the text each time on the y axis
text_posn_sf = max(SF_from_slope) - ((max(SF_from_slope) / 100) * 2);

figure
plot(temp_SE_V_combined(2:end), SF_from_slope, "b;SF calculated from slope;")
    xlabel("Temperature  (V)")
    ylabel ("SF  (mV/deg/s)")
    title("Scale Factor vs Temperature")
    axis([-0.2,3.2])
strg_sf = sprintf("The average scale factor value is %1.2f mV/deg/s.", mean(SF_from_slope));
text(1, text_posn_sf, strg_sf)

% save the plot to a specific filename, related to the date the script is run
SFvsTemp_fname = ["07SFvsTemp_" ,  meas_date , "_" , SE_IDnum , ".png"];
cd(meas_date_folder)
print(SFvsTemp_fname, "-dpng", "-color")
cd(script_dir)

% Epsilon error in scale factor 
epsilon_percent = (SF_from_slope / SF_desire) - 1;
epsil_tot = max(max(epsilon_percent)-min(epsilon_percent));


%---------------------------------- Filtering the Temperature with respect to Epsilon ---------------------------------------------------
% filter the temperature by finding the best value of tau_ep
% epsilon is fitted using temp, Ca and Cq

temp_SE_V_combined = temp_SE_V_combined(2:end);
temp_SE_V_combined = temp_SE_V_combined';
epsilon_percent = epsilon_percent';
Cq_V_com_ave = Cq_V_com_ave';
Ca_V_com_ave = Ca_V_com_ave';

emal_ep(:,1) = temp_SE_V_combined;
emal_ep(:,2) = Cq_V_com_ave;
emal_ep(:,3) = Ca_V_com_ave;

function y = calc_tau_ep(x, pin)
  for i = 1:length(x)
    if i == 1
      new_x(i) = x(i,1);
    elseif i > 1
      new_x(i) = (1 / (1 + pin(1))) .* (x(i,1) .+ (pin(1) .* new_x(i-1)));
    endif
  endfor
  new_x = new_x';
  new_Cq = x(:,2);
  new_Ca = x(:,3);

  y = pin(2) .+ (pin(3) .* new_x) .+ (pin(4) .* new_x.^2) .+ (pin(5) .* new_x.^3) .+ (pin(6) .* new_x.^4) .+ (pin(7) .* new_x.^5) .+ (pin(8) .* new_Cq) .+ (pin(9) .* new_Ca);
endfunction
pin = [1 1 1 1 1 1 1 1 1];
% start fitting
[Mod_tau_ep, pout, kvg, iter, corp, covp, covr, stdresid, Z, r2] = leasqr(emal_ep, epsilon_percent, pin, "calc_tau_ep");
tau_ep = pout(1) / Ts_s;
tau_cons = pout(1);
Res_tau_ep = (epsilon_percent .- Mod_tau_ep) * 1000000;

% stop tau_ep from being a negitive value
if tau_ep < 0
  tau_ep = 0;
endif

% filter the temperature using tau_ep
for i = 1:length(temp_SE_V_combined)
  if i == 1
    temp_filtered(i) = temp_SE_V_combined(i);
  elseif i > 1
    temp_filtered(i) = (1 / (1 + tau_cons)) * (temp_SE_V_combined(i) + (tau_cons * temp_filtered(i-1)));
  endif
endfor
temp_filtered = temp_filtered';


%-------------------------------------------- Epsilon Coarse adjustment Model -----------------------------------------------------------
% Coarse adjustment model uses filtered temperature only, k0 + k1*T(fil) + k2*T(fil)^2

function y = calc_coarse(x, pin)
  y = pin(1) .+ (pin(2) .* x) .+ (pin(3) .* x.^2);
endfunction
pin = [1 1 1];
% start fitting
[Mod_coarse_ep, pout, kvg, iter, corp, covp, covr, stdresid, Z, r2] = leasqr(temp_filtered, epsilon_percent, pin, "calc_coarse");
k_coarse = pout;
Res_coarse_ep = ((epsilon_percent .- Mod_coarse_ep) / 100) * 1000000;

% Scale factor should be 32 mV/deg/s at room temperature, a0 is the parameter to be changed in order to tune the SF
% a0 = k0 + k1*RT + k2*RT^2
room_temp = mean(temp_SE_V(1:100));
a0_coarse = k_coarse(1) + (k_coarse(2) * room_temp) + (k_coarse(3) * room_temp^2);

% need to calculate where to position the text each time on the y axis
text_posn_ep = max(epsilon_percent) - ((max(epsilon_percent) / 100) * 7);
text_posn_er = max(Res_coarse_ep) - ((max(Res_coarse_ep) / 100) * 10);

figure
subplot(2,1,1)
plot(temp_SE_V_combined, epsilon_percent, "b;Epsilon;", temp_SE_V_combined, Mod_coarse_ep, "r;Coarse Tuning Model;") 
    xlabel("Temperature  (V)")
    ylabel ("Epsilon  (%)")
    title("Epsilon vs Temperature")
    axis([-0.2,3.2])
strg_ep = sprintf("Overall Epsilon value is %1.2f %%.\nTau for epsilon is %1.1f s.\nCoarse Model = k_0*T^0 + k_1*T^1 + k_2*T^2\nk_0=%1.2f, k_1=%1.2f, k_2=%1.2f", epsil_tot, tau_ep,k_coarse(1),k_coarse(2),k_coarse(3));
text(1, text_posn_ep, strg_ep)

subplot(2,1,2)
plot(temp_SE_V_combined, Res_coarse_ep, "g;Epsilon Residue;") 
    xlabel("Temperature  (V)")
    ylabel ("Epsilon  (ppm)")
    title("Coarse Tuning Epsilon Residue vs Temperature")
    axis([-0.2,3.2])
strg_er = sprintf("a_0 = k_0 + k_1*RT + k_2*RT^2\na_0 = %1.2f", a0_coarse);
text(1, text_posn_er, strg_er)

% save the plot to a specific filename, realted to the date the script is run
EpVTemp_fname = ["08EpVsTemp_" ,  meas_date , "_" , SE_IDnum , ".png"];
cd(meas_date_folder)
print(EpVTemp_fname, "-dpng", "-color")
cd(script_dir)

% Scale factor should be 32 mV/deg/s at room temperature, a0 is the parameter to be changed in order to tune the SF
% a0 = k0 + k1*RT + k2*RT^2
room_temp = mean(temp_SE_V(1:100));
a0_coarse = k_coarse(1) + (k_coarse(2) * room_temp) + (k_coarse(3) * room_temp^2);


%-------------------------------------------------------- Ca and Cq ---------------------------------------------------------------------
% Ca and Cq against time
time_hr_combined  = time_s_combined' / 3600;

figure
[ax, h1, h2] = plotyy(time_hr_combined(2:end), Cq_V_com_ave, time_hr_combined(2:end), Ca_V_com_ave);
    xlabel("Time  (hr)")
    ylabel (ax(1), "Cq  (V)")
    ylabel (ax(2), "Ca  (V)")
    title("Cq and Ca versus Temperature")

y1Label = "Cq in V";
y2Label = "Ca in V";
legend (y1Label, y2Label)

% save the plot to a specific filename, realted to the date the script is run
CqCaVTime_fname = ["09CqCaVsTime_" ,  meas_date , "_" , SE_IDnum , ".png"];
cd(meas_date_folder)
print(CqCaVTime_fname, "-dpng", "-color")
cd(script_dir)

% Ca and Cq against temp
figure
subplot(2,1,1)
plot(temp_SE_V_combined, Cq_V_com_ave, "b;Cq in V;")
    xlabel("Temp  (V)")
    ylabel("Cq  (V)")
    title("Cq versus Temperature")

subplot(2,1,2)
plot(temp_SE_V_combined, Ca_V_com_ave, "g;Ca in V;")
    xlabel("Temp  (V)")
    ylabel("Ca  (V)")
    title("Ca versus Temperature")

% save the plot to a specific filename, realted to the date the script is run
CqCaVTemp_fname = ["10CqCaVsTemp_" ,  meas_date , "_" , SE_IDnum , ".png"];
cd(meas_date_folder)
print(CqCaVTemp_fname, "-dpng", "-color")
cd(script_dir)


%-------------------------------------------- First derivative of the temperature -------------------------------------------------------
% want to see the slope of the temperature over ten points

deriv_temp = [];
new_time_min = [];
new_temp_SE_C = [];
j = 1;
for i = 1000:5:length(temp_SE_C)
  function y = calc_m_c(x, pin)
    y = (pin(1) .* x) .+ pin(2);    % m*x + c, m is slope (SF) and c is intercept (bias) 
  end
  pin = [1 1];
  % start the fit
  [Mod_cons, pout, kvg, iter, corp, covp, covr, stdresid, Z, r2] = leasqr(time_min(i-10:i), temp_SE_C(i-10:i), pin, "calc_m_c");
  deriv_temp = [deriv_temp pout(1)];
  new_time_min = [new_time_min time_min(i)];
  new_temp_SE_C = [new_temp_SE_C temp_SE_C(i)];
endfor

figure
subplot(2,1,1)
plot(new_time_min, deriv_temp)
    xlabel("Time  (min)")
    ylabel("Temp Slope  (deg C per min)")
    title("Temperature Slope vs Time")

subplot(2,1,2)
plot(new_temp_SE_C, deriv_temp)
    xlabel("Temp  (deg C)")
    ylabel("Temp Slope  (deg C per min)")
    title("Temperature Slope vs Temperature")
    axis([-60,100])

% save the plot to a specific filename, realted to the date the script is run
TempSlope_fname = ["11TempSlope_" ,  meas_date , "_" , SE_IDnum , ".png"];
cd(meas_date_folder)
print(TempSlope_fname, "-dpng", "-color")
cd(script_dir)


%------------------------------------------- Simple text file with a list of constants -------------------------------------------------
% filename is based on the SE number and the date
textfname = ["SE" , SE_IDnum(6:8) , "_ThermSF_"  , meas_date , ".txt"];

% move to the folder where the graphs are stored
cd(meas_date_folder)
fout = fopen(textfname, "w");

fprintf(fout, "Sensitive element ID is %s. \n", SE_IDnum);
fprintf(fout, "Sensitive element housing details: %s. \n", SE_housing);
fprintf(fout, "Rotation and thermal cycle test carried out in %s. \n", SE_test_chamber);
fprintf(fout, "\n");
fprintf(fout, "The average scale factor value across the cycle is %1.2f mV/deg/s. \n", mean(SF_from_slope));
fprintf(fout, "Epsilon min value is %1.2f %%. \n", min(epsilon_percent));
fprintf(fout, "Epsilon max value is %1.2f %%. \n", max(epsilon_percent));
fprintf(fout, "Epsilon difference is %1.2f %%. \n", epsil_tot);
fprintf(fout, "\n");
fprintf(fout, "Model to find tau: k_0*T^0 + k_1*T^1 + k_2*T^2 + k_3*T^3 + k_4*T^4 + k_5*T^5 + k_6*Cq + k_7*Ca \n");
fprintf(fout, "The thermal constant value tau used for temperature filtering is %1.2f s. \n", tau_ep);
fprintf(fout, "\n");
fprintf(fout, "Temperature filtered using tau and the formula: \n");
fprintf(fout, "\t T(fil)_n = (1 / (1 + (tau * Ts))) * (T(unfil)_n + (tau * Ts) * T(fil)_(n-1)) \n");
fprintf(fout, "\n");

fclose(fout)
cd(script_dir)





