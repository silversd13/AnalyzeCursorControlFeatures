%% classify targets
clear, clc
target_angles = 0:45:360-45;

%% experiment info including adapt and fixed blocks
expts = [];

expts(end+1).yyyymmdd = '20190403';
expts(end).imagined = {'105510'};
expts(end).adapt = {'105510'};
expts(end).fixed = {'105510'};

%% organize data
basedir = '/media/dsilver/data/Bravo1';

%% load data and split into training and testing
expt = expts(1);

traindir = {fullfile(basedir,expt.yyyymmdd,'GangulyServer','Center-Out',...
    expt.yyyymmdd,expt.imagined{1},'Imagined'),...
    fullfile(basedir,expt.yyyymmdd,'GangulyServer','Center-Out',...
    expt.yyyymmdd,expt.adapt{1},'BCI_CLDA')};
trainfiles = cat(1,dir(fullfile(traindir{1},'Data*.mat')),...
    dir(fullfile(traindir{2},'Data*.mat')));

testdir = fullfile(basedir,expt.yyyymmdd,'GangulyServer','Center-Out',...
    expt.yyyymmdd,expt.fixed{1},'BCI_Fixed');
testfiles = dir(fullfile(testdir,'Data*.mat'));

%% try different hyper params
BinSizeVec = 100:100:2000;
MaxTime = 1000;
FeatureVec = {'theta','beta','high_gamma'};

%% go through each file in load data, comp features, grab target
sf = matfile('classify_targets.mat','writable',true);
ct = 0;
for i=1:length(BinSizeVec),
    BinSize = BinSizeVec(i);
    
    MaxNumBins = MaxTime / BinSize;
    NumBinsVec = 1:MaxNumBins;
    for ii=1:length(NumBinsVec),
        NumBins = NumBinsVec(ii);
        fprintf('%i %ims Bins\n',NumBins,BinSize)
        
        for iii=1:2^length(FeatureVec)-1,
            feature_idx = strfind(dec2bin(iii,length(FeatureVec)),'1');
            Features = {FeatureVec{feature_idx}};
            fprintf('    %s\n',Features{:})
            
            % train data
            N = length(trainfiles);
            train_features = cell(1,N);
            train_target = cell(1,N);
            msg = '';
            for iiii=1:N,
                %% update screen
                %fprintf(repmat('\b',1,length(msg)))
                %msg = sprintf('      %i of %i',iiii,N);
                %fprintf(msg)
                
                % load data and grab instructed delay broadband
                load(fullfile(trainfiles(iiii).folder,trainfiles(iiii).name));
                event_idx = strcmp({TrialData.Events(:).Str},'Reach Target');
                tidx = TrialData.Time > TrialData.Events(event_idx).Time;
                X = cat(1,TrialData.BroadbandData{tidx})';
                
                % skip if too short
                if size(X,2) < 2000,
                    continue;
                end
                
                % compute and bin neural features
                train_features{iiii} = compute_features(X,...
                    Features,BinSize,NumBins);
                % bin other useful params (
                train_target{iiii} = find(TrialData.TargetAngle==target_angles);
            end
            fprintf(repmat('\b',1,length(msg)))
            fprintf('\n')
            
            % test data
            N = length(testfiles);
            test_features = cell(1,N);
            test_target = cell(1,N);
            msg = '';
            for iiii=1:N,
                %% update screen
                %fprintf(repmat('\b',1,length(msg)))
                %msg = sprintf('      %i of %i',iiii,N);
                %fprintf(msg)
                
                % load data and grab instructed delay broadband
                load(fullfile(testfiles(iiii).folder,testfiles(iiii).name));
                event_idx = strcmp({TrialData.Events(:).Str},'Reach Target');
                tidx = TrialData.Time > TrialData.Events(event_idx).Time;
                X = cat(1,TrialData.BroadbandData{tidx})';
                
                % skip if too short
                if size(X,2) < 2000,
                    continue;
                end
                
                % compute and bin neural features
                test_features{iiii} = compute_features(X,...
                    Features,BinSize,NumBins);
                % bin other useful params (
                test_target{iiii} = find(TrialData.TargetAngle==target_angles);
            end
            fprintf(repmat('\b',1,length(msg)))
            fprintf('\n')
        

            % train classifiers
            X = cat(2,train_features{:})';
            Y = cat(1,train_target{:});

            % linear discriminant analysis
            lin_mdl = compact(fitcdiscr(X,Y,...
                'DiscrimType','linear',...
                'Prior','uniform',...
                'OptimizeHyperparameters','none',...
                'HyperparameterOptimizationOptions',...
                struct('KFold',10,'ShowPlots',false,'Verbose',0,'Repartition',true)));

            % knn
            knn_mdl = compact(fitcknn(X,Y,...
                'Prior','uniform',...
                'OptimizeHyperparameters','auto',...
                'HyperparameterOptimizationOptions',...
                struct('KFold',10,'ShowPlots',false,'Verbose',0,'Repartition',true)));
            
            % binary tree
            tree_mdl = compact(fitctree(X,Y,...
                'Prior','uniform',...
                'OptimizeHyperparameters','auto',...
                'HyperparameterOptimizationOptions',...
                struct('KFold',10,'ShowPlots',false,'Verbose',0,'Repartition',true)));
        
            % keep track
            out.BinSize = BinSize;
            out.NumBins = NumBins;
            out.Features = Features;
            
            % evaluate classifiers
            X = cat(2,test_features{:})';
            Y = cat(1,test_target{:});

            % linear discriminant analysis
            Yhat = predict(lin_mdl,X);
            accuracy = mean(Y==Yhat);
            dist1 = mod(Y-Yhat,8);
            dist2 = mod(Yhat-Y,8);
            dist = min([dist1,dist2],[],2);
            avg_dist = mean(dist);

            % print update to screen
            fprintf('    LDA Accuracy: %.2f\n',accuracy)
            fprintf('    LDA Avg Dist: %.2f\n',avg_dist)

            % keep track
%             out.lin_mdl = lin_mdl;
            out.lin_mdl_accuracy = accuracy;
            out.lin_mdl_avg_target_dist = avg_dist;
            
            % k nearest neighbors
            Yhat = predict(knn_mdl,X);
            accuracy = mean(Y==Yhat);
            dist1 = mod(Y-Yhat,8);
            dist2 = mod(Yhat-Y,8);
            dist = min([dist1,dist2],[],2);
            avg_dist = mean(dist);
            
            % print update to screen
            fprintf('    KNN Accuracy: %.2f\n',accuracy)
            fprintf('    KNN Avg Dist: %.2f\n',avg_dist)
            
            % keep track
%             out.knn_mdl = knn_mdl;
            out.knn_mdl_accuracy = accuracy;
            out.knn_mdl_avg_target_dist = avg_dist;
            
            % binary tree
            Yhat = predict(tree_mdl,X);
            accuracy = mean(Y==Yhat);
            dist1 = mod(Y-Yhat,8);
            dist2 = mod(Yhat-Y,8);
            dist = min([dist1,dist2],[],2);
            avg_dist = mean(dist);
            
            % print update to screen
            fprintf('    TREE Accuracy: %.2f\n',accuracy)
            fprintf('    TREE Avg Dist: %.2f\n',avg_dist)
            
            % keep track
%             out.tree_mdl = tree_mdl;
            out.tree_mdl_accuracy = accuracy;
            out.tree_mdl_avg_target_dist = avg_dist;

            % print to screen
            fprintf('\n\n')
            
            % save
            ct = ct + 1;
            sf.out(1,ct) = out;
            %save('classify_targets.mat','-append','out')

        end % features
    end % num bins
end % bin size
        
