%% check if feature distributions are converging within and across days
clear, clc, close all
cc = hsv(8);

%% experiment info
expts = [];

expts(end+1).yymmdd = '20190514';
expts(end).hhmmss = {'135927','140808','141731','142704'};

expts(end+1).yymmdd = '20190515';
expts(end).hhmmss = {'112302','113447'};

expts(end+1).yymmdd = '20190521';
expts(end).hhmmss = {'135943'};

expts(end+1).yymmdd = '20190524';
expts(end).hhmmss = {'111731','112353','134653','135957'};

expts(end+1).yymmdd = '20190529';
expts(end).hhmmss = {'111528','114050'};

expts(end+1).yymmdd = '20190531';
expts(end).hhmmss = {'105048','110703','112444','133517','140204','141319'};

expts(end+1).yymmdd = '20190604';
expts(end).hhmmss = {'114636','143109'};

expts(end+1).yymmdd = '20190607';
expts(end).hhmmss = {'105615','135050','140828'};

expts(end+1).yymmdd = '20190610';
expts(end).hhmmss = {'105809','110746'};

expts(end+1).yymmdd = '20190618';
expts(end).hhmmss = {'135944','143103'};

expts(end+1).yymmdd = '20190621';
expts(end).hhmmss = {'110942','113715','134143','141129'};

days = cat(1,expts.yymmdd);

%% load data

% go through expts
Fcell = {};
TargetID = {};

trial = 1;
trials = [];
day_break = [];
session_break = [];
for i=1:length(expts),
    expt = expts(i);
    yymmdd = expt.yymmdd;
    day_break(end+1) = trial; 
    
    for ii=1:length(expt.hhmmss),
        hhmmss = expt.hhmmss{ii};
        session_break(end+1) = trial; 
        
        datadir = fullfile('/media/dsilver/data/Bravo1',yymmdd,...
            'GangulyServer','Center-Out',yymmdd,hhmmss,'BCI_Fixed');
        datafiles = dir(fullfile(datadir,'Data*.mat'));
        T = length(datafiles);

        for iii=1:T,
            % load data, grab neural features
            disp(datafiles(iii).name)
            load(fullfile(datadir,datafiles(iii).name))
            
            if strcmp(TrialData.Events(end).Str,'Reach Target'),
                idx = (TrialData.Time > TrialData.Events(end).Time);
                Fcell{trial} = cat(2,TrialData.NeuralFeatures{idx})';
                TargetID{trial} = TrialData.TargetID;
            else,
                Fcell{trial} = [];
                TargetID{trial} = [];
            end
            
            trials(trial) = trial;
            trial = trial + 1;
        end
        
    end
end
day_break(end+1) = trial;
session_break(end+1) = trial; 

%% look at dist btw features (across days)

bhat_dist = zeros(length(day_break)-1,length(day_break)-1,8);
mahal_dist = zeros(length(day_break)-1,length(day_break)-1,8);
cov_dist = zeros(length(day_break)-1,length(day_break)-1,8);
for i=1:length(day_break)-1, % day
    day1_idx = day_break(i):day_break(i+1)-1; % last trial in day
    F_day1 = Fcell(day1_idx);
    T_day1 = TargetID(day1_idx);
    
    % march through sessions
    for ii=setdiff(1:length(day_break)-1,i), % day
        day2_idx = day_break(ii):day_break(ii+1)-1; % last trial in day
        F_day2 = Fcell(day2_idx);
        T_day2 = TargetID(day2_idx);
    
        for target=1:8, % target
            % build feature matrices
            targ_idx = cat(1,T_day1{:})==target;
            F_day1_targ = cat(1,F_day1{targ_idx});
            F_day1_targ = F_day1_targ(:,128*6+1:128*7);
            
            targ_idx = cat(1,T_day2{:})==target;
            F_day2_targ = cat(1,F_day2{targ_idx});
            F_day2_targ = F_day2_targ(:,128*6+1:128*7);
            
            % compute bhat dist
            mu1 = mean(F_day1_targ)';
            sigma1 = cov(F_day1_targ);
            mu2 = mean(F_day2_targ)';
            sigma2 = cov(F_day2_targ);
            sigma_avg = .5*(sigma1 + sigma2);
            
            bhat_dist(i,ii,target) = 1/8 * (mu1-mu2)' / (sigma_avg) * (mu1-mu2) ...
                + 1/2 * log( det(sigma_avg) / sqrt(det(sigma1)*det(sigma2)) );
            mahal_dist(i,ii,target) = 1/8 * (mu1-mu2)' / (sigma_avg) * (mu1-mu2);
            cov_dist(i,ii,target) = 1/2 * log( det(sigma_avg) / sqrt(det(sigma1)*det(sigma2)) );
            
        end % target
    end % day2
end % day1

%% make bhat dist plots

% per target
figure('units','normalized','position',[0.0943 0.1000 0.5089 0.7528]);
angs = 0:45:360-45;
w = .2;
h = .2;
r = .38;

for target=1:8,
    ang = angs(target);
    ax(target) = axes('position',...
        [.5+r*cosd(ang)-w/2,.5-r*sind(ang)-h/2,w,h]);
    
    imagesc(bhat_dist(:,:,target))
    if target==3,
        title('Bhat Distance across days')
    elseif target==6,
        xlabel('days')
        ylabel('days')
    elseif target==7,
        colorbar('location','southoutside',...
            'position',[.4 .6 .2 .05])
    end
    
end

set(ax,'CLim',[0,100],'XTick',[],'YTick',[]);
colormap(brewermap(10,'Blues'))

%% make mahal dist plots

% per target
figure('units','normalized','position',[0.0943 0.1000 0.5089 0.7528]);
angs = 0:45:360-45;
w = .2;
h = .2;
r = .38;

for target=1:8,
    ang = angs(target);
    ax(target) = axes('position',...
        [.5+r*cosd(ang)-w/2,.5-r*sind(ang)-h/2,w,h]);
    
    imagesc(mahal_dist(:,:,target))
    if target==3,
        title('Mahal Distance across days')
    elseif target==6,
        xlabel('days')
        ylabel('days')
    elseif target==7,
        colorbar('location','southoutside',...
            'position',[.4 .6 .2 .05])
    end
    
end

set(ax,'CLim',[0,.05],'XTick',[],'YTick',[]);
colormap(brewermap(10,'Blues'))


%% make cov dist plots

% per target
figure('units','normalized','position',[0.0943 0.1000 0.5089 0.7528]);
angs = 0:45:360-45;
w = .2;
h = .2;
r = .38;

for target=1:8,
    ang = angs(target);
    ax(target) = axes('position',...
        [.5+r*cosd(ang)-w/2,.5-r*sind(ang)-h/2,w,h]);
    
    imagesc(cov_dist(:,:,target))
    if target==3,
        title('Cov Distance across days')
    elseif target==6,
        xlabel('days')
        ylabel('days')
    elseif target==7,
        colorbar('location','southoutside',...
            'position',[.4 .6 .2 .05])
    end
    
end

set(ax,'CLim',[0,.005],'XTick',[],'YTick',[]);
colormap(brewermap(10,'Blues'))

%% look at dist btw all features (across days)

bhat_dist = zeros(length(day_break)-1,length(day_break)-1,8,7);
mahal_dist = zeros(length(day_break)-1,length(day_break)-1,8,7);
cov_dist = zeros(length(day_break)-1,length(day_break)-1,8,7);

for feature=2:7,
    for i=1:length(day_break)-1, % day
        day1_idx = day_break(i):day_break(i+1)-1; % last trial in day
        F_day1 = Fcell(day1_idx);
        T_day1 = TargetID(day1_idx);
        
        % march through sessions
        for ii=setdiff(1:length(day_break)-1,i), % day
            day2_idx = day_break(ii):day_break(ii+1)-1; % last trial in day
            F_day2 = Fcell(day2_idx);
            T_day2 = TargetID(day2_idx);
            
            for target=1:8, % target
                % build feature matrices
                targ_idx = cat(1,T_day1{:})==target;
                F_day1_targ = cat(1,F_day1{targ_idx});
                F_day1_targ = F_day1_targ(:,128*6+1:128*7);
                
                targ_idx = cat(1,T_day2{:})==target;
                F_day2_targ = cat(1,F_day2{targ_idx});
                F_day2_targ = F_day2_targ(:,128*6+1:128*7);
                
                % compute bhat dist
                mu1 = mean(F_day1_targ)';
                sigma1 = cov(F_day1_targ);
                mu2 = mean(F_day2_targ)';
                sigma2 = cov(F_day2_targ);
                sigma_avg = .5*(sigma1 + sigma2);
                
                bhat_dist(i,ii,target,feature) = 1/8 * (mu1-mu2)' / (sigma_avg) * (mu1-mu2) ...
                    + 1/2 * log( det(sigma_avg) / sqrt(det(sigma1)*det(sigma2)) );
                mahal_dist(i,ii,target,feature) = 1/8 * (mu1-mu2)' / (sigma_avg) * (mu1-mu2);
                cov_dist(i,ii,target,feature) = 1/2 * log( det(sigma_avg) / sqrt(det(sigma1)*det(sigma2)) );
                
            end % target
        end % day2
    end % day1
end % feature

% make bhat dist plots

% avg across int velocity bins and features
figure('units','normalized','position',[0.0943 0.1000 0.5089 0.7528]);

imagesc(mean(mean(bhat_dist,3),4))
title('Avg Bhat Distance (over targets & pwr features) across days')
colorbar('location','eastoutside')

set(gca,'CLim',[0,100],'XTick',[],'YTick',[]);
colormap(brewermap(10,'Blues'))
set(gca,'YTick',1:length(days),'YTickLabel',days)


