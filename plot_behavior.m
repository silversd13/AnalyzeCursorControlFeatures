function plot_behavior()

% ask user for files
[files,datadir] = uigetfile('*.mat','Select the INPUT DATA FILE(s)','MultiSelect','on');
if ~iscell(files),
    tmp = files;
    clear files;
    files{1} = tmp;
    clear tmp;
end

% get behavior metrics per trial
cursor_assist = [];
target_ang = [];
time_to_target = [];
time_start = [];
success = [];
cursor_distance = [];
cursor_max_dev_from_opt = [];
for n=1:length(files),
    load(fullfile(datadir,files{n})) %#ok<*LOAD>
    
    % trial params
    cursor_assist(n) = TrialData.CursorAssist(1); %#ok<*AGROW>
    target_ang(n) = TrialData.TargetAngle;

    % performance measures
    time_to_target(n) = TrialData.Time(end) - TrialData.Events(end).Time;
    success(n) = TrialData.ErrorID==0;
    
    tidx = TrialData.Time >= TrialData.Events(end).Time;
    time_start(n) = TrialData.Time(find(tidx,1));
    cursor_traj = TrialData.CursorState(1:2,tidx);
    cursor_distance(n) = sum(sqrt(sum(diff(cursor_traj,1,2).^2)));
    
    opt_axis = TrialData.TargetPosition' - cursor_traj(:,1);
    cursor_dev_from_opt = ...
        abs(opt_axis(1)*cursor_traj(1,:) + opt_axis(2)*cursor_traj(2,:))...
        / norm(opt_axis);
    cursor_max_dev_from_opt(n) = max(cursor_dev_from_opt);
end

% make plots
trials = 1:n;

figure;
subplot(5,1,1)
plot(trials,cursor_assist)
ylabel('cursor assist')

subplot(5,1,2)
% plot(trials,smooth(success,5),'--k')
plot(trials(1:end-1),smooth(1./diff(time_start/60),1),'--k')
ylabel('successes / min')

subplot(5,1,3)
plot(trials,time_to_target)
ylabel('time to target (secs)')

subplot(5,1,4)
plot(trials,cursor_distance)
ylabel('cursor dist (px)')

subplot(5,1,5)
plot(trials,cursor_max_dev_from_opt)
ylabel('max dev from opt (px)')


end