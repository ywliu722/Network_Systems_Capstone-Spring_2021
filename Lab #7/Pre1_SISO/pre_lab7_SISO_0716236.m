%% BPSK transmission over AWGN channel
close all;clear all;clc;           % BPSK
dist=50:50:500;        % distance in meters
PtdBm=10;                % transmit power in dBm
PndBm=-85;              % noise power in dBm
Pt=10^(PtdBm/10)/1000;  % transmit power in watt
Pn=10^(PndBm/10)/1000;  % noise power in watt
Bit_Length=1e3;         % number of bits transmitted

%% Friss Path Loss Model
Gt=1;
Gr=1;
freq=2.4e9;

% TODO: Calculate Pr(d)
%Pr=ones(length(dist),1);    % TODO: replace this with Friis' model
for d=1:length(dist)
   Pr(d)= Pt * Gt * Gr * ((3e8/freq)/(4*pi*dist(d)))^2; 
end

%% BPSK Transmission over AWGN channel
tx_data = randi(2, 1, Bit_Length) - 1;                  % random between 0 and 1
x=(tx_data.*2-1)+0i;                                    % transmitted BPSK samples
n=(randn(1,Bit_Length)+randn(1,Bit_Length)*i)/sqrt(2);  % AWGN noises
n=n*sqrt(Pn);

for d=1:length(dist)
    y(d,:)=sqrt(Pr(d))*x+n;
end


%% Equalization
% Detection Scheme:(Soft Detection)
% +1 if o/p >=0
% -1 if o/p<0
% Error if input and output are of different signs

figure('units','normalized','outerposition',[0 0 1 1])
for d=1:length(dist)
    % TODO: s = y/Pr
    s=[];
    s(d,:)=y(d,:)/sqrt(Pr(d));
    % TODO: x_est = 1 if real(s) >= 0; otherwise, x_est = -1
    for i=1:Bit_Length
        if real(s(d,i))>=0
            x_est(d,i)=1;
        else
            x_est(d,i)=-1;
        end
    end
    
    SNR(d)=Pr(d)/Pn;
    SNRdB(d)=10*log10(SNR(d));
    BER_simulated(d)=0;
    SNRdB_simulated(d)=0;
    % TODO: compare x_est with x (true value) and calculate BER_simulated(d)
    error=0;
    for i=1:Bit_Length
        if x_est(d,i)~=x(i)
            error=error+1;
        end
    end
    BER_simulated(d)=error/Bit_Length;
    % TODO: noise = s - x, and, then, calculate SNR_simulated(d)
    n_sum=0;
    for i=1:Bit_Length
        n_sum=n_sum+abs(s(d,i)-x(i))^2;
    end
    n_mean=n_sum/Bit_Length;
    SNR_simulated(d)=1/n_mean;
    SNRdB_simulated(d)=10*log10(SNR_simulated(d));
    
    subplot(2, 5, d)
    hold on
    plot(s,'bx');       % TODO: replace y with s
    plot(x,0i,'ro');
    hold off
    xlim([-2,2]);
    ylim([-2,2]);
    title(sprintf('Constellation points d=%d', dist(d)));
    legend('decoded samples', 'transmitted samples');
    grid
end


figure('units','normalized','outerposition',[0 0 1 1])
subplot(2, 1, 1)
semilogy(dist,BER_simulated,'b-o','linewidth',2.0);
hold on
semilogy(dist,qfunc(sqrt(SNR)),'r--v','linewidth',2.0);
hold off
title('BPSK over AWGN Simulation');
xlabel('Distance [m]');
ylabel('BER');
legend('BER(Simulated)','BER(Theoritical)');
axis tight 
grid

subplot(2, 1, 2)
plot(dist,SNRdB_simulated,'b-o','linewidth',2.0);
hold on
plot(dist,SNRdB,'r--v','linewidth',2.0);
hold off
title('BPSK over AWGN Simulation');
xlabel('Distance [m]');
ylabel('SNR');
legend('SNR(Simulated)','SNR(Theoritical)');
axis tight 
grid