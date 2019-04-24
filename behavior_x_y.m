%% x vs y
clear, clc, close all

%% experiment info
expts = [];

expts(end+1).yymmdd = '20190401';
expts(end).hhmmss = {'111316','111942','112738','114253','133838','135810','141638'};

expts(end+1).yymmdd = '20190403';
expts(end).hhmmss = {'105510','111944','132634','135357'};

expts(end+1).yymmdd = '20190409';
expts(end).hhmmss = {'110409','112241','114901','135644'};

expts(end+1).yymmdd = '20190412';
expts(end).hhmmss = {'111554'};

expts(end+1).yymmdd = '20190415';
expts(end).hhmmss = {'111333','112549','132231','134412','140311'};

expts(end+1).yymmdd = '20190417';
expts(end).hhmmss = {'110418','112437','113706','135345'};

%% collect beh measures per target

target_ang = 0:45:360-45;
time_to_targ = cell(1,8);
success = cell(1,8);

% go through expts
for i=6%1:length(expts),
    expt = expts(i);
    yymmdd = expt.yymmdd;
    for ii=1:length(expt.hhmmss),
        hhmmss = expt.hhmmss{ii};
        
        % per block
        time_to_targ_pb = cell(1,8);
        success_pb = cell(1,8);
        
        % go through datafiles in fixed blocks
        datadir = fullfile('/media/dsilver/data/Bravo1',yymmdd,...
            'GangulyServer','Center-Out',yymmdd,hhmmss,'BCI_Fixed');
        disp(datadir)
        files = dir(fullfile(datadir,'Data*.mat'));
        for iii=1:length(files),
            % load data
            load(fullfile(datadir,files(iii).name));
            
            % compute behavior and place in target holders
            target_idx = TrialData.TargetAngle==target_ang;
            success{target_idx}(end+1) = TrialData.ErrorID==0;
            time_to_targ{target_idx}(end+1) = TrialData.Time(end)-...
                TrialData.Events(end).Time;
            success_pb{target_idx}(end+1) = TrialData.ErrorID==0;
            time_to_targ_pb{target_idx}(end+1) = TrialData.Time(end)-...
                TrialData.Events(end).Time;
        end
        
        % output measures per block
        success_per_session = mean(cat(2,success_pb{:}));
        time_to_target_per_session = mean(cat(2,time_to_targ_pb{:}));
        disp(success_per_session)
        disp(time_to_target_per_session)

    end
end
overall_success = mean(cat(2,success{:}));
overall_time_to_target = mean(cat(2,time_to_targ{:}));
disp(overall_success)
disp(overall_time_to_target)

%% plot
figure('position',[681 647 855 303]);

subplot(1,2,1)
bar(target_ang,100*mean(cat(1,success{:}),2))
xlabel('target')
ylabel('Percent Success')

subplot(1,2,2)
bar(target_ang,mean(cat(1,time_to_targ{:}),2)); hold on
errorbar(target_ang,mean(cat(1,time_to_targ{:}),2),std(cat(1,time_to_targ{:}),[],2)/sqrt(26),...
    'sk','linewidth',1.5)
xlabel('target')
ylabel('Time to Target (s)')
