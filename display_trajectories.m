function display_trajectories()

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

% get params
load(fullfile(datadir,files{1}))
target_sz = 4*TrialData.Params.TargetSize;
target_col = TrialData.Params.OutTargetColor;
target_rad = TrialData.Params.ReachTargetRadius;
% cc = brewermap(8,'Paired');
% cc = get(groot,'defaultAxesColorOrder');
cc = hsv(8);

% set up figure
figure('units','normalized','position',[.1,.1,.6,.8]);

% screen output
hold on
plot(0,0,'.','MarkerSize',target_sz,'color',target_col/255);
angs = 0:45:360-45;
for i=1:length(angs),
    ang = angs(i);
    plot(target_rad*cosd(ang),target_rad*sind(ang),'.',...
        'MarkerSize',target_sz,'color',cc(i,:));
end
axis equal
xlim([-300,+300])
ylim([-300,+300])
set(gca,'YDir','reverse')

% plot each trajectory
for n=1:length(files),
    load(fullfile(datadir,files{n}))
    cc_idx = TrialData.TargetID;
    
    % plot after instructed delay
    tidx = TrialData.Time > TrialData.Events(2).Time;
    plot([TrialData.CursorState(1,tidx)],[TrialData.CursorState(2,tidx)],'-','color',cc(cc_idx,:))
end

end
