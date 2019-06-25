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
target_sz = 75*TrialData.Params.TargetSize;
target_rad = TrialData.Params.ReachTargetRadius;
cc = hsv(8);
cc = cc([1,3,5,7,2,4,6,8],:); % make similar colors a bit further apart

% set up figure
figure('units','normalized','position',[.1,.1,.6,.8]);

% targets
hold on
scatter(0,0,target_sz,'k');
angs = 0:45:360-45;
for i=1:length(angs),
    ang = angs(i);
    scatter(target_rad*cosd(ang),target_rad*sind(ang),target_sz,cc(i,:),...
        'MarkerFaceColor',cc(i,:),'MarkerFaceAlpha',.4);
end
axis equal
xlim([-300,+300])
ylim([-300,+300])
set(gca,'YDir','reverse')

% plot each trajectory
TargetIDs = [];
Trajectories = cell(8,1);
for n=1:length(files),
    load(fullfile(datadir,files{n}))
    cc_idx = TrialData.TargetID;
    TargetIDs(end+1) = cc_idx;
    
    % plot after instructed delay
    if strcmp(TrialData.Events(end).Str,'Reach Target'),
        tidx = TrialData.Time > TrialData.Events(end).Time;
        plot([TrialData.CursorState(1,tidx)],...
            [TrialData.CursorState(2,tidx)],...
            '-','color',cc(cc_idx,:),'linewidth',1.5)
        Trajectories{cc_idx}{end+1} = cat(2,TrialData.CursorState(1,tidx)',...
            TrialData.CursorState(2,tidx)');
    end
end

% figure 2 - plot each target in separate axes
figure('units','normalized','position',[.1,.1,.6,.8]);

w = .2;
h = .2;
r = .38;
for i=1:length(angs),
    ang = angs(i);
    % comment line below, to plot all in the same axes
    axes('position',[.5+r*cosd(ang)-w/2,.5-r*sind(ang)-h/2,w,h]);
    hold on
    
    % target
    scatter(target_rad*cosd(ang),target_rad*sind(ang),target_sz/25,cc(i,:),...
        'MarkerFaceColor',cc(i,:),'MarkerFaceAlpha',.4);
    
    % traj
    for ii=1:length(Trajectories{i}),
        plot(Trajectories{i}{ii}(:,1),Trajectories{i}{ii}(:,2),...
            'color',cc(i,:))
    end
    
    % clean up
    axis equal
    xlim([-300,+300])
    ylim([-300,+300])
    set(gca,'YDir','reverse','XTick',[],'YTick',[])
    box on

end

end
