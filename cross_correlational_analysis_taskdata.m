clear 
close all
%% load data
%preprocessed test data (intro rest period)
load('D:\Dinal\OrganizedCalibrationData\FrontalTask.mat');
load('D:\Dinal\OrganizedCalibrationData\MotorTask.mat');
load('D:\Dinal\OrganizedCalibrationData\TemporalTask.mat');

%% convolve wavelets with signal, calculate correlations
subjects = [1,3,7,9,11,12,13,17,20,22];
feature_channel = [6,4,6,6,6,4,4,4,6,4]; %represents the channel recording from ipsilateral ortex (1=4 & 2=6)
ipsichan = [2,1,2,2,2,1,1,1,2,1];
contrachan = [1,2,1,1,1,2,2,2,1,2];

s_i = 1;
% early = zeros(10,30,5);
% late = zeros(10,30,5);
% lag_store = zeros(10,10);

%find appropriate runs
for cur_subj = subjects
    trim_i = 1;
   for run = 1:size(FullRawTaskMat{cur_subj},1)
       if (sum(squeeze(FullRawTaskMat{cur_subj}(:,1,run)))==0) || (sum(squeeze(FullRawTaskMat{cur_subj}(:,2,run)))==0)
           fprintf('Run %d in Subject %d Removed - all zeros in Motor electrode\n',run,cur_subj)
       elseif(sum(squeeze(FrontalRawTaskMat{cur_subj}(:,1,run)))==0) || (sum(squeeze(FrontalRawTaskMat{cur_subj}(:,2,run)))==0)
           fprintf('Run %d in Subject %d Removed - all zeros in Frontal electrode\n',run,cur_subj)
       elseif (sum(squeeze(TemporalRawTaskMat{cur_subj}(:,1,run)))==0) || (sum(squeeze(TemporalRawTaskMat{cur_subj}(:,2,run)))==0)
           fprintf('Run %d in Subject %d Removed - all zeros in Temporal electrode\n',run,cur_subj)
       else
           trimCal{cur_subj}(:,:,trim_i) = FullRawTaskMat{cur_subj}(:,:,run);
           trimFrontal{cur_subj}(:,:,trim_i) = FrontalRawTaskMat{cur_subj}(:,:,run);
           trimTemporal{cur_subj}(:,:,trim_i) = TemporalRawTaskMat{cur_subj}(:,:,run);
           trim_i = trim_i+1;
       end
   end
end

lag_store = LagDiffs(trimCal);
% lag_store = LagDiffs(trimFrontal);
% lag_store = LagDiffs(trimTemporal);

figure
histogram(lag_store(:,1:5),'BinWidth',1)
hold on

histogram(lag_store(:,6:10),'BinWidth',1)
hold off

[H,P,CI,STATS] = ttest(lag_store(1:50),lag_store(51:100));

function store = LagDiffs(signalMat)

subjects = [1,3,7,9,11,12,13,17,20,22];
feature_channel = [6,4,6,6,6,4,4,4,6,4];
ipsichan = [2,1,2,2,2,1,1,1,2,1];
contrachan = [1,2,1,1,1,2,2,2,1,2];
lag_store = zeros(10,10);

s_i = 1;


% Gabor wavelets
fwhm = 4; %alpha = 4, beta = 8, delta = 2
cf = 10; %change center frequencies for each band. alpha = 10, beta = 21, delta = 2
span = fwhm2span(cf,fwhm);

%loop through valid runs

progressbar('Subjects','Runs')

% lag_final = nan(numel(subjects),10);

for cur_subj = 1:numel(subjects)
    disp(num2str(cur_subj));
    ptID = subjects(cur_subj);
    runNum = size(signalMat{ptID},1);
    runsToCount = horzcat(1:5,(runNum-4):runNum);
    runCountExceptions
    run_i = 1;
    
    
    runID = 0;
    for run = runsToCount
        runID = runID+1;
        cur_sig = squeeze(signalMat{ptID}(:,:,run)); %define current signal
        out = gpu_gabor_response_span(cur_sig,cf,span,256); %gabor convolution
        outEnv = squeeze((abs(out(:,:,:)))); %amplitude envelope calculation. for power, this would be squared

        ipsienv = outEnv(:,ipsichan(cur_subj)); %amplitude envelope for ipsi channel
        contraenv = outEnv(:,contrachan(cur_subj)); %amplitude envelope for contra channel

%         lag = nan(size(outEnv,1),numel(ipsienv)+numel(contraenv)-1);
        
  %      for freq = 1:size(outEnv,1)
            ipsienv = outEnv(:,ipsichan(cur_subj)); %amplitude envelope for ipsi channel
            contraenv = outEnv(:,contrachan(cur_subj)); %amplitude envelope for contra channel
            [r, lagTemp] = xcorr(ipsienv,contraenv); %calculate the cross correlation
        %   lag(freq,:) = r; 
    %    end
        
      %  temp = nanmean(lag,1);
        
        [~,I] = max(abs(r));
        lagDiff = lagTemp(I);
        
             
%         figure
%         
%         plot(lagTemp,r)
%         title(sprintf('Cross correlation for Subject %i and Run #%i for Beta band', cur_subj, run_i));
%         xlabel('Time')
%         ylabel('Cross correlation')
%         ytickformat('%.1f')
%         legend(sprintf('Maximum lag is at %0.2f', lagDiff))
        
%         lag_final(cur_subj,runID,:) = nanmean(lag,1); %average the lags
%         for one subject and one run

        lag_store(cur_subj, run_i) = lagDiff;
             
        progressbar([],run_i/10)
        run_i = run_i + 1;

        
    end
    progressbar(s_i/10)
    s_i=s_i+1;
end
store = lag_store;
end