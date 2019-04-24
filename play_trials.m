function play_trials(playback_speed,saveFlag)
% playback_speed sets playback speed (default=1, real time)
% saveFlag [0,1], if 1, movie is saved

if ~exist('speed','var'), playback_speed = 1; end
if ~exist('saveFlag','var'), saveFlag = 0; end

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

% type of trials
block_str = strsplit(datadir,'/');
block_str = block_str{end-1};
switch block_str,
    case 'BCI_Imagined',
        block_flag = 1;
    case 'BCI_CLDA',
        block_flag = 2;
    case 'BCI_Fixed',
        block_flag = 3;
end

% for movie
if saveFlag,
    savefile = input('Movie File Name: ','s');
    if ismac,
        vidObj = VideoWriter(sprintf('%s',savefile),'MPEG-4');
    else,
        vidObj = VideoWriter(sprintf('%s.avi',savefile));
    end
    vidObj.FrameRate = playback_speed/.1;
    vidObj.Quality = 100;
    open(vidObj);
end

% get params
load(fullfile(datadir,files{1}))
screen_sz = TrialData.Params.ScreenRectangle(3:4);
cursor_sz = 4*TrialData.Params.CursorSize;
cursor_col = TrialData.Params.CursorColor;
target_sz = 4*TrialData.Params.TargetSize;
target_col = TrialData.Params.OutTargetColor;

% set up figure
fig = figure('units','normalized','position',[.1,.1,.8,.8]);

% screen output
hold on
start = plot(0,0,'.','MarkerSize',target_sz,'color',target_col/255);
target = plot(nan,nan,'.','MarkerSize',target_sz,'color',target_col/255);
cursor = plot(nan,nan,'.','MarkerSize',cursor_sz,'color',cursor_col/255);
INTvel = plot([-400,nan],[-400,nan],'-g');
OPTvel = plot([-400,nan],[-400,nan],'-b');
KFvel = plot([-400,nan],[-400,nan],'-r','linewidth',1.8);
txt = text(300,400,{'',''},...
    'horizontalalignment','left',...
    'verticalalignment','bottom',...
    'fontsize',12);
axis equal
xlim([-500,+500])
ylim([-500,+500])
set(gca,'YDir','reverse')
legend(gca,[INTvel,OPTvel,KFvel],...
    {'Intended Vel', 'Optimal Vel', 'KF Vel'}, ...
    'location','southwest','fontsize',12)
       
% go through each file, load and play movie
for n=1:length(files),
    load(fullfile(datadir,files{n})) %#ok<LOAD>
    
    % target position
    target.XData = TrialData.TargetPosition(1);
    target.YData = TrialData.TargetPosition(2);
    
    % go through trial
    ct = 0;
    for t=1:length(TrialData.Time),
        % trial stage
        time = TrialData.Time(t);
        if time < TrialData.Events(2).Time, % ITI
            ct = ct + 1;
            Flag = 0;
            start.Visible = 'off';
            target.Visible = 'off';
        else, % past ITI
            if length(TrialData.Events)>2, % made it past start target
                if time < TrialData.Events(3).Time, % START
                    Flag = 1;
                    start.Visible = 'on';
                    target.Visible = 'off';
                else, % REACH
                    Flag = 2;
                    start.Visible = 'off';
                    target.Visible = 'on';
                end
            else, % error on start target
                Flag = 1;
                start.Visible = 'off';
                target.Visible = 'on';
            end
        end
        
        % plot cursor, target, pause
        cursor.XData = TrialData.CursorState(1,t);
        cursor.YData = TrialData.CursorState(2,t);
        
        
        % plot KF vel, assist vel, C vel
        if Flag>0,
            % compute vel from eq. Y = C*X, ie. X = C\Y.
            %int_state = TrialData.KalmanFilter{t-ct}.C(:,3:end)\TrialData.NeuralFeatures{t};
        
            KFvel.XData(2)  = (TrialData.CursorState(3,t)-400);
            KFvel.YData(2)  = (TrialData.CursorState(4,t)-400);
            OPTvel.XData(2) = (TrialData.IntendedCursorState(3,t)-400);
            OPTvel.YData(2) = (TrialData.IntendedCursorState(4,t)-400);
            %INTvel.XData(2) = (int_state(1)-400);
            %INTvel.YData(2) = (int_state(2)-400);
        end
        
        % text
        switch block_flag,
            case 1,
                txt.String = {
                    sprintf('Visual Feedback')
                    sprintf('Trial: %i',TrialData.Trial)
                    sprintf('Time: %.1f',time-TrialData.Time(1))
                    };
            case 2,
                txt.String = {
                    sprintf('Adaptation')
                    sprintf('Trial: %i',TrialData.Trial)
                    sprintf('Assist: %.2f',TrialData.CursorAssist(1))
                    %sprintf('Lambda: %.2f',TrialData.KalmanFilter{t}.Lambda)
                    sprintf('Lambda: %.2f',500)
                    sprintf('Time: %.1f',time-TrialData.Time(1))
                    };
            case 3,
                txt.String = {
                    sprintf('Fixed')
                    sprintf('Trial: %i',TrialData.Trial)
                    sprintf('Time: %.1f',time-TrialData.Time(1))
                    };
        end
        
        % for saving movie
        if saveFlag,
            frame = getframe(fig);
            writeVideo(vidObj,frame)
        else,
            % draw
            drawnow
            pause(.1/playback_speed)
        end
    end
end

if saveFlag,
    close(vidObj);
end
close all


end

