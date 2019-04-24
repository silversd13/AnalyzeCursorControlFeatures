function decoder_accuracy()

% ask user for files
[files,datadir] = uigetfile('*.mat','Select the INPUT DATA FILE(s)','MultiSelect','on');
if ~iscell(files),
    tmp = files;
    clear files;
    files{1} = tmp;
    clear tmp;
end
disp(datadir)
disp(files{1})
disp(files{end})

% angular velocity error per bin
target_ids = [];
kf_ang_err = cell(0);
internal_ang_err = cell(0);
internal_ang_4bin_err = cell(0);
internal_ang_5bin_err = cell(0);
internal_ang_6bin_err = cell(0);

kf_x_err = cell(0);
kf_y_err = cell(0);
internal_ang_err = cell(0);
internal_ang_4bin_err = cell(0);
internal_ang_5bin_err = cell(0);
internal_ang_6bin_err = cell(0);

for n=1:length(files),
    % load data
    load(fullfile(datadir,files{n}))
    target_ids = cat(1,target_ids,TrialData.TargetID);
    
    % grab velocities of interest
    tidx = TrialData.Time > TrialData.Events(2).Time;
    opt_vel = TrialData.IntendedCursorState(3:4,tidx);
    kf_vel = TrialData.CursorState(3:4,tidx);
    
    % compute internal state
    internal_state = TrialData.KalmanFilter.C(:,3:end)\cat(2,TrialData.NeuralFeatures{tidx});
    internal_vel = internal_state(1:2,:);
    
    % compute smoothed internal state
    bins = 4;
    tmp = cat(2,zeros(2,bins-1),internal_vel);
    x1 = conv(tmp(1,:),1/bins*ones(1,bins),'full');
    x2 = conv(tmp(2,:),1/bins*ones(1,bins),'full');
    internal_vel_4bin = x1(bins:end-(bins-1));
    internal_vel_4bin(2,:) = x2(bins:end-(bins-1));
    
    % compute smoothed internal state
    bins = 5;
    tmp = cat(2,zeros(2,bins-1),internal_vel);
    x1 = conv(tmp(1,:),1/bins*ones(1,bins),'full');
    x2 = conv(tmp(2,:),1/bins*ones(1,bins),'full');
    internal_vel_5bin = x1(bins:end-(bins-1));
    internal_vel_5bin(2,:) = x2(bins:end-(bins-1));
    
    % compute smoothed internal state
    bins = 6;
    tmp = cat(2,zeros(2,bins-1),internal_vel);
    x1 = conv(tmp(1,:),1/bins*ones(1,bins),'full');
    x2 = conv(tmp(2,:),1/bins*ones(1,bins),'full');
    internal_vel_6bin = x1(bins:end-(bins-1));
    internal_vel_6bin(2,:) = x2(bins:end-(bins-1));
    
    % normalize velocity vectors
    opt_vel_ang = atan2d(opt_vel(2,:),opt_vel(1,:));
    kf_vel_ang = atan2d(kf_vel(2,:),kf_vel(1,:));
    internal_vel_ang = atan2d(internal_vel(2,:),internal_vel(1,:));
    internal_vel_4bin_ang = atan2d(internal_vel_4bin(2,:),internal_vel_4bin(1,:));
    internal_vel_5bin_ang = atan2d(internal_vel_5bin(2,:),internal_vel_5bin(1,:));
    internal_vel_6bin_ang = atan2d(internal_vel_6bin(2,:),internal_vel_6bin(1,:));
    
    % compute angular error
    kf_ang_err{n} = wrapTo180(kf_vel_ang - opt_vel_ang);
    internal_ang_err{n} = wrapTo180(internal_vel_ang - opt_vel_ang);
    internal_ang_4bin_err{n} = wrapTo180(internal_vel_4bin_ang - opt_vel_ang);
    internal_ang_5bin_err{n} = wrapTo180(internal_vel_5bin_ang - opt_vel_ang);
    internal_ang_6bin_err{n} = wrapTo180(internal_vel_6bin_ang - opt_vel_ang);
    
    % compute x- & y-vel err (cartesian)
    kf_x_err{n} = kf_vel(1,:) - opt_vel(1,:);
    kf_y_err{n} = kf_vel(2,:) - opt_vel(2,:);
    
end

% set up angular error figure
fig = figure('units','normalized','position',[.1,.1,.5,.3]);

subplot(2,3,1)
polarhistogram(cat(2,kf_ang_err{:}),20)
title({'Error: KF',...
    sprintf('mu=%i, sigma=%i',...
    round(circ_mean((cat(2,kf_ang_err{:})*pi/180)')*180/pi),...
    round(circ_std((cat(2,kf_ang_err{:})*pi/180)')*180/pi))})

subplot(2,3,2)
polarhistogram(cat(2,internal_ang_err{:}),20)
title({'Error: Internal',...
    sprintf('mu=%i, sigma=%i',...
    round(circ_mean((cat(2,internal_ang_err{:})*pi/180)')*180/pi),...
    round(circ_std((cat(2,internal_ang_err{:})*pi/180)')*180/pi))})

subplot(2,3,3)
polarhistogram(cat(2,internal_ang_4bin_err{:}),20)
title({'Error: Internal (4bins)',...
    sprintf('mu=%i, sigma=%i',...
    round(circ_mean((cat(2,internal_ang_4bin_err{:})*pi/180)')*180/pi),...
    round(circ_std((cat(2,internal_ang_4bin_err{:})*pi/180)')*180/pi))})

subplot(2,3,4)
polarhistogram(cat(2,internal_ang_5bin_err{:}),20)
title({'Error: Internal (5bins)',...
    sprintf('mu=%i, sigma=%i',...
    round(circ_mean((cat(2,internal_ang_5bin_err{:})*pi/180)')*180/pi),...
    round(circ_std((cat(2,internal_ang_5bin_err{:})*pi/180)')*180/pi))})

subplot(2,3,5)
polarhistogram(cat(2,internal_ang_6bin_err{:}),20)
title({'Error: Internal (6bins)',...
    sprintf('mu=%i, sigma=%i',...
    round(circ_mean((cat(2,internal_ang_6bin_err{:})*pi/180)')*180/pi),...
    round(circ_std((cat(2,internal_ang_6bin_err{:})*pi/180)')*180/pi))})

% set up angular error figure
fig = figure('units','normalized','position',[.1,.1,.5,.3]);

subplot(2,3,1); hold on
X = cat(2,kf_x_err{:});
Y = cat(2,kf_y_err{:});
histogram(X,20)
histogram(Y,20)
title({'Residuals: KF',...
    sprintf('mu=%i, sigma=%i',...
    round(circ_mean((cat(2,kf_ang_err{:})*pi/180)')*180/pi),...
    round(circ_std((cat(2,kf_ang_err{:})*pi/180)')*180/pi))})

end
