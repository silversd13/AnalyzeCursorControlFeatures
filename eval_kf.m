function [mse,Xall,Xhatall] = eval_kf(kf,X,Y)

% use kf to estimate X (Xhat), compare Xhat to X, and compute mean squared
% error for xvel and yvel

% initialize
A = kf.A;
W = kf.W;
C = kf.C;
Q = kf.Q;
P = eye(size(W));

% filter
for i=1:length(X), % trials
    
    Xtrial = X{i};
    Xhat{i}(:,1) = [0,0,0,0,1]';
    for ii=2:size(Xtrial,2), % time
        % predict
        Xhat{i}(:,ii) = A*Xhat{i}(:,ii-1);
        P = A*P*A' + W;
        % update
        K = P*C'/(C*P*C' + Q);
        Xhat{i}(:,ii) = Xhat{i}(:,ii) + K*(Y{i}(:,ii) - C*Xhat{i}(:,ii));
        P = P - K*C*P;
    end

end

% aggregate across trials
Xall = cat(2,X{:});
Vx = Xall(3,:);
Vy = Xall(4,:);

Xhatall = cat(2,Xhat{:});
Vxhat = Xhatall(3,:);
Vyhat = Xhatall(4,:);

% compute mse
mse(1) = mean((Vxhat - Vx).^2); % xvel
mse(2) = mean((Vyhat - Vy).^2); % yvel

end