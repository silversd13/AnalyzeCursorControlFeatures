function kf = fit_kf(a,w,dt,X,Y)

A = [...
        1       0       dt      0       0;
        0       1       0       dt      0;
        0       0       a       0       0;
        0       0       0       a       0;
        0       0       0       0       1];
W = [...
        0       0       0       0       0;
        0       0       0       0       0;
        0       0       w       0       0;
        0       0       0       w       0;
        0       0       0       0       0];

D = size(X,2);
C = (Y*X(3:end,:)') / (X(3:end,:)*X(3:end,:)');
C = [zeros(size(C,1),2), C];
Q = (1/D) * ((Y-C*X) * (Y-C*X)');

kf.A = A;
kf.W = W;
kf.C = C;
kf.Q = Q;

end
