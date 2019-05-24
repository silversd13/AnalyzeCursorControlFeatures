function velocity_distributions()

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

% load each trajectory, use polar histogram to construct distributions
vel_ang = cell(1,8);
for n=1:length(files),
    load(fullfile(datadir,files{n}))
    idx = TrialData.TargetID;
    
    % only use data during reach target attempt
    if strcmp(TrialData.Events(end).Str,'Reach Target'),
        tidx = TrialData.Time > TrialData.Events(end).Time;
        vel_ang{idx}{end+1} = atan2(...
            -1*TrialData.CursorState(4,tidx),...
            TrialData.CursorState(3,tidx));
    end
end

% set up figure
figure('units','normalized','position',[.1,.1,.6,.8]);

angs = 0:45:360-45;
plts = [6,9,8,7,4,1,2,3];
for i=1:length(angs),
    ang = angs(i);
    plt = plts(i);
    subplot(3,3,plt);
    
    all_vel_angs = cat(2,vel_ang{i}{:});
    polarhistogram(all_vel_angs,linspace(0,2*pi,20),'Normalization','probability');
    title(sprintf('Target %i',i));
    
end
subplot(3,3,5);
set(gca,'Visible','off')

text(.5,.5,'Decoded Cursor Direction','horizontalalignment','center','fontsize',16)

end
