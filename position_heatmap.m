function position_heatmap()

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

% density map boundaries
x_edges = -300:25:300;
y_edges = -300:25:300;
x = (x_edges(1:end-1) + x_edges(2:end)) / 2;
y = (y_edges(1:end-1) + y_edges(2:end)) / 2;

% load each trajectory, use 2d histogram to construct density map
map = cell(1,8);
for n=1:length(files),
    load(fullfile(datadir,files{n}))
    idx = TrialData.TargetID;
    
    % only use data during reach target attempt
    if strcmp(TrialData.Events(end).Str,'Reach Target'),
        tidx = TrialData.Time > TrialData.Events(end).Time;
        map{idx}{end+1} = histcounts2(...
            TrialData.CursorState(1,tidx),...
            TrialData.CursorState(2,tidx),...
            x_edges,y_edges,...
            'Normalization','probability')';
    end
end

% set up figure
cmap = brewermap(10,'Blues');
figure('units','normalized','position',[.1,.1,.6,.8]);

angs = 0:45:360-45;
plts = [6,9,8,7,4,1,2,3];
for i=1:length(angs),
    ang = angs(i);
    plt = plts(i);
    subplot(3,3,plt);
    
    avg_map = mean(cat(3,map{i}{:}),3);
    imagesc(x,y,avg_map);
    colormap(cmap);
    title(num2str(ang));
    
    axis equal
    xlim(minmax(x_edges))
    ylim(minmax(y_edges))
    set(gca,'YDir','reverse',...
        'XTick',x_edges,'XTickLabel','',...
        'YTick',y_edges,'YTickLabel','')
    grid on

end
subplot(3,3,5);
colormap(cmap);
colorbar('location','southoutside')
set(gca,'Visible','off')
text(.5,-.2,'Normalized Density','horizontalalignment','center','fontsize',12)

text(.5,.5,'Density Maps','horizontalalignment','center','fontsize',16)

end
