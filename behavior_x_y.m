%% x vs y
clear, clc, close all

%% experiment info
expts = [];

% expts(end+1).yymmdd = '20190514';
% expts(end).hhmmss = {'135927','140808','141731','142704'};
% 
% expts(end+1).yymmdd = '20190515';
% expts(end).hhmmss = {'112302','113447'};
% 
% expts(end+1).yymmdd = '20190521';
% expts(end).hhmmss = {'135943'};
% 
% expts(end+1).yymmdd = '20190524';
% expts(end).hhmmss = {'111731','112353','134653','135957'};
% 
% expts(end+1).yymmdd = '20190529';
% expts(end).hhmmss = {'111528','114050','135644'};
% 
% expts(end+1).yymmdd = '20190531';
% expts(end).hhmmss = {'105048','110703','112444','133517','140204','141319'};
% 
% expts(end+1).yymmdd = '20190604';
% expts(end).hhmmss = {'112454','114636','143109'};
% 
% expts(end+1).yymmdd = '20190607';
% expts(end).hhmmss = {'105615','135050','140828'};
% 
% expts(end+1).yymmdd = '20190610';
% expts(end).hhmmss = {'105809','110746','132416','133734'};
% 
% expts(end+1).yymmdd = '20190618';
% expts(end).hhmmss = {'133933','135944','143103'};

expts(end+1).yymmdd = '20190621';
expts(end).hhmmss = {'110942','113715','134143','141129'};

%% collect beh measures per target

target_ang = 0:45:360-45;
time_to_targ = cell(1,8);
success = cell(1,8);
smoothness = cell(1,8);
rwd_rate = cell(1,8);
tbl = {};

% go through expts
ct = 0;
for i=1:length(expts),
    expt = expts(i);
    yymmdd = expt.yymmdd;
    for ii=1:length(expt.hhmmss),
        hhmmss = expt.hhmmss{ii};
        ct = ct + 1;
        
        % per block
        time_to_targ_pb = cell(1,8);
        success_pb = cell(1,8);
        smoothness_pb = cell(1,8);
        rwd_rate_pb = cell(1,8);
        
        % go through datafiles in fixed blocks
        datadir = fullfile('/media/dsilver/data/Bravo1',yymmdd,...
            'GangulyServer','Center-Out',yymmdd,hhmmss,'BCI_Fixed');
        fprintf('\n%s-%s\n',yymmdd,hhmmss)
        files = dir(fullfile(datadir,'Data*.mat'));
        for iii=1:length(files),
            % load data
            load(fullfile(datadir,files(iii).name));
            
            % compute behavior and place in target holders
            target_idx = TrialData.TargetAngle==target_ang;
            success{target_idx}(end+1) = TrialData.ErrorID==0;
            success_pb{target_idx}(end+1) = TrialData.ErrorID==0;
            if TrialData.ErrorID==0, % successful trial
                time_to_targ{target_idx}(end+1) = TrialData.Time(end)-...
                    TrialData.Events(end).Time;
                time_to_targ_pb{target_idx}(end+1) = TrialData.Time(end)-...
                    TrialData.Events(end).Time;
            else, % unsuccessful, set to max time
                time_to_targ{target_idx}(end+1) = ...
                    TrialData.Params.MaxReachTime;
                time_to_targ_pb{target_idx}(end+1) = ...
                    TrialData.Params.MaxReachTime;
            end
            tidx = TrialData.Time >= TrialData.Events(end).Time;
            xpos = TrialData.CursorState(1,tidx);
            ypos = TrialData.CursorState(2,tidx);
            xvel = TrialData.CursorState(3,tidx);
            yvel = TrialData.CursorState(4,tidx);
            xacc = gradient(xvel,TrialData.Time(tidx));
            yacc = gradient(yvel,TrialData.Time(tidx));
            xjrk = gradient(xacc,TrialData.Time(tidx));
            yjrk = gradient(yacc,TrialData.Time(tidx));
            smoothness{target_idx}(end+1) = (mean(xjrk.^2) + mean(yjrk.^2)) / 2;
            smoothness_pb{target_idx}(end+1) = (mean(xjrk.^2) + mean(yjrk.^2)) / 2;
        end
        
        % output measures per block
        success_per_session = mean(cat(2,success_pb{:}));
        time_to_target_per_session = median(cat(2,time_to_targ_pb{:}));
        it_rate_per_session = ...
            (1/time_to_target_per_session) * log2((200 + 30)/30);
        smoothness_per_session = mean(cat(2,smoothness_pb{:}));
        fprintf('Trials: %i\n',length(files))
        fprintf('Target Size: %i\n',TrialData.Params.TargetSize)
        fprintf('Center-Reset: %i\n',TrialData.Params.CenterReset)
        fprintf('Success Rate: %i%%\n',round(100*success_per_session))
        fprintf('Time to Target: %.1f sec\n',time_to_target_per_session)
        fprintf('Fitt''s IT Rate: %.2f bits/sec\n',it_rate_per_session)
        fprintf('Smoothness: %.2f \n',smoothness_per_session)
        
        % store measures in cell array
        tbl{ct,1} = sprintf('\n%s-%s\n',yymmdd,hhmmss);
        tbl{ct,2} = length(files);
        tbl{ct,3} = TrialData.Params.TargetSize;
        tbl{ct,4} = TrialData.Params.CenterReset;
        tbl{ct,5} = round(100*success_per_session);
        tbl{ct,6} = time_to_target_per_session;
        tbl{ct,7} = it_rate_per_session;
        tbl{ct,8} = smoothness_per_session;
        
    end
end
% overall_success = mean(cat(2,success{:}));
% overall_time_to_target = mean(cat(2,time_to_targ{:}));
% information_transfer_rate = (1/overall_time_to_target) * ...
%    log2((200 + 30)/30);
% fprintf('\n\nOverall Performance:\n',round(100*overall_success))
% fprintf('Success Rate: %i%%\n',round(100*overall_success))
% fprintf('Time to Target: %.1f sec\n',overall_time_to_target)
% fprintf('Fitt''s IT Rate: %.2f bits/sec\n',information_transfer_rate)
% 
% 
% %% plot
% figure('position',[681 647 855 303]);
% cc = hsv(8);
% 
% subplot(1,2,1); hold on
% for t=1:8,
%     h=bar(t,100*mean(cat(1,success{t}),2));
%     h.FaceColor = cc(t,:);
%     h.FaceAlpha = .4;
% end
% set(gca,'XTick',1:8,'XtickLabel',strsplit(num2str(target_ang),' '))
% xlabel('target')
% ylabel('Percent Success')
% 
% subplot(1,2,2); hold on
% for t=1:8,
%     h=bar(t,mean(cat(1,time_to_targ{t}),2));
%     h.FaceColor = cc(t,:);
%     h.FaceAlpha = .4;
%     errorbar(t,mean(cat(1,time_to_targ{t}),2),...
%         std(cat(1,time_to_targ{t}),[],2)/sqrt(26),...
%         '.k','linewidth',1,'capsize',2)
% end
% set(gca,'XTick',1:8,'XtickLabel',strsplit(num2str(target_ang),' '))
% xlabel('target')
% ylabel('Time to Target (s)')
