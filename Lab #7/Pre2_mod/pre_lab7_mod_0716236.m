%% BPSK transmission over AWGN channel
close all;clear all;clc;           % BPSK
dist=100:100:400;        % distance in meters
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
%% TODO-2
%% BPSK: {1,0} -> {1+0i, -1+0i}
%% QPSK: {11,10,01,00} -> {1+i, -1+i, -1-i, 1-i} * scaling factor
%% 16QAM: {1111, 1110, 1101, 1100, 1011, 1010, 1001, 1000, 0111, 0110, 0101, 0100, 0011, 0010, 0001, 0000}
%% -> {3a+3ai, 3a+ai, a+3ai, a+ai, -a+3ai, -3a+3ai, -3a+ai, -a+ai, 3a-ai, 3a-3ai, a-ai, a-3ai, -a-ai, -a-3ai, -3a-ai, -3a-3ai}
n=(randn(1,Bit_Length)+randn(1,Bit_Length)*i)/sqrt(2);  % AWGN noises
n=n*sqrt(Pn);
for mod_order=[1,2,4]
    % BPSK
    if mod_order == 1
        for j=1:Bit_Length
            x(mod_order,j)=(tx_data(j).*2-1)+0i;                                    % TODO-2: change it to three different modulated symbols
        end
    %QPSK
    elseif mod_order == 2
        a = sqrt(1/2);
        for j=1:Bit_Length/2
            % 11
            if (tx_data(j*2-1) == 1) &&  (tx_data(j*2) == 1)
                x(mod_order,j)=a+a*1i;
            % 10
            elseif (tx_data(j*2-1) == 1) &&  (tx_data(j*2) == 0)
                x(mod_order,j)=-a+a*1i;
            % 01
            elseif (tx_data(j*2-1) == 0) &&  (tx_data(j*2) == 1)
                x(mod_order,j)=-a-a*1i;
            % 00
            else
                x(mod_order,j)=a-a*1i;
            end
        end
    %16QAM    
    else
        a = sqrt(1/((18+10+10+2)*4/16));
        for j=1:Bit_Length/4
            % 1111
            if (tx_data(j*4-3) == 1) && (tx_data(j*4-2) == 1) && (tx_data(j*4-1) == 1) && (tx_data(j*4) == 1)
                x(mod_order,j)=3*a+3*a*1i;
            % 1110
            elseif (tx_data(j*4-3) == 1) && (tx_data(j*4-2) == 1) && (tx_data(j*4-1) == 1) && (tx_data(j*4) == 0)
                x(mod_order,j)=3*a+a*1i;
            % 1101
            elseif (tx_data(j*4-3) == 1) && (tx_data(j*4-2) == 1) && (tx_data(j*4-1) == 0) && (tx_data(j*4) == 1)
                x(mod_order,j)=a+3*a*1i;
            % 1100
            elseif (tx_data(j*4-3) == 1) && (tx_data(j*4-2) == 1) && (tx_data(j*4-1) == 0) && (tx_data(j*4) == 0)
                x(mod_order,j)=a+a*1i;

            % 1011
            elseif (tx_data(j*4-3) == 1) && (tx_data(j*4-2) == 0) && (tx_data(j*4-1) == 1) && (tx_data(j*4) == 1)
                x(mod_order,j)=-a+3*a*1i;
            % 1010
            elseif (tx_data(j*4-3) == 1) && (tx_data(j*4-2) == 0) && (tx_data(j*4-1) == 1) && (tx_data(j*4) == 0)
                x(mod_order,j)=-3*a+3*a*1i;
            % 1001
            elseif (tx_data(j*4-3) == 1) && (tx_data(j*4-2) == 0) && (tx_data(j*4-1) == 0) && (tx_data(j*4) == 1)
                x(mod_order,j)=-3*a+a*1i;
            % 1000
            elseif (tx_data(j*4-3) == 1) && (tx_data(j*4-2) == 0) && (tx_data(j*4-1) == 0) && (tx_data(j*4) == 0)
                x(mod_order,j)=-a+a*1i;

            % 0111
            elseif (tx_data(j*4-3) == 0) && (tx_data(j*4-2) == 1) && (tx_data(j*4-1) == 1) && (tx_data(j*4) == 1)
                x(mod_order,j)=3*a-a*1i;
            % 0110
            elseif (tx_data(j*4-3) == 0) && (tx_data(j*4-2) == 1) && (tx_data(j*4-1) == 1) && (tx_data(j*4) == 0)
                x(mod_order,j)=3*a-3*a*1i;
            % 0101
            elseif (tx_data(j*4-3) == 0) && (tx_data(j*4-2) == 1) && (tx_data(j*4-1) == 0) && (tx_data(j*4) == 1)
                x(mod_order,j)=a-a*1i;
            % 0100
            elseif (tx_data(j*4-3) == 0) && (tx_data(j*4-2) == 1) && (tx_data(j*4-1) == 0) && (tx_data(j*4) == 0)
                x(mod_order,j)=a-3*a*1i;

            % 0011
            elseif (tx_data(j*4-3) == 0) && (tx_data(j*4-2) == 0) && (tx_data(j*4-1) == 1) && (tx_data(j*4) == 1)
                x(mod_order,j)=-a-a*1i;
            % 0010
            elseif (tx_data(j*4-3) == 0) && (tx_data(j*4-2) == 0) && (tx_data(j*4-1) == 1) && (tx_data(j*4) == 0)
                x(mod_order,j)=-a-3*a*1i;
            % 0001
            elseif (tx_data(j*4-3) == 0) && (tx_data(j*4-2) == 0) && (tx_data(j*4-1) == 0) && (tx_data(j*4) == 1)
                x(mod_order,j)=-3*a-a*1i;
            % 0000
            else
                x(mod_order,j)=-3*a-3*a*1i;
            end
        end
    end

    for d=1:length(dist)
        y(mod_order,d,:)=sqrt(Pr(d))*x(mod_order,:)+n;
    end
end

%% Equalization
% Detection Scheme:(Soft Detection)
% +1 if o/p >=0
% -1 if o/p<0
% Error if input and output are of different signs

QAM_a=sqrt(1/((18+10+10+2)*4/16));
QAM_sym=[3*a+3*a*1i, 3*a+a*1i, a+3*a*1i, a+a*1i, -a+3*a*1i, -3*a+3*a*1i, -3*a+a*1i, -a+a*1i, 3*a-a*1i, 3*a-3*a*1i, a-a*i, a-3*a*i, -a-a*i, -a-3*a*i, -3*a-a*i, -3*a-3*a*i];
for mod_order=[1,2,4]
    figure('units','normalized','outerposition',[0 0 1 1])
	sgtitle(sprintf('Modulation order: %d', mod_order)); 
    for d=1:length(dist)
        % TODO: s = y/Pr
        if mod_order==1
            s1=[];
            s1(d,:)=y(mod_order,d,1:Bit_Length/mod_order)/sqrt(Pr(d));
        elseif mod_order==2
            s2=[];
            s2(d,:)=y(mod_order,d,1:Bit_Length/mod_order)/sqrt(Pr(d));
        else
            s3=[];
            s3(d,:)=y(mod_order,d,1:Bit_Length/mod_order)/sqrt(Pr(d));
        end
        % TODO: x_est = 1 if real(s) >= 0; otherwise, x_est = -1
        % BPSK(check the real part is positive or not)
        if mod_order==1
            for i=1:Bit_Length
                if real(s1(d,i))>=0
                    x_est(mod_order,d,i)=1;
                else
                    x_est(mod_order,d,i)=-1;
                end
            end
        % QPSK(check the quadrant of the symbol)
        elseif mod_order==2
            a = sqrt(1/2);
            real_part=0;
            image_part=0;
            for j=1:Bit_Length/2
                % first bit
                if imag(s2(d,j)) >= 0
                    image_part=1i;
                else
                    image_part=-1i;
                end
                % second bit
                if real(s2(d,j)) >= 0
                    real_part=1;
                else
                    real_part=-1;
                end
                x_est(mod_order,d,j)=real_part*a+image_part*a;
            end
        % 16QAM(determine which one is the closest)
        else
            for j=1:Bit_Length/4
                closest_index=0;
                closest_dist=Inf;
                for index=1:16
                    distance=abs(s3(d,j)-QAM_sym(index));
                    if distance<closest_dist
                        closest_index=index;
                        closest_dist=distance;
                    end
                end    
                x_est(mod_order,d,j)=QAM_sym(closest_index);
            end
        end
        
        SNR(d,mod_order)=Pr(d)/Pn;
        SNRdB(d,mod_order)=10*log10(SNR(d,mod_order));
        BER_simulated(d,mod_order)=0;
        SNRdB_simulated(d,mod_order)=0;
        % TODO-2: demodulate x_est to x' for various modulation schemes and calculate BER_simulated(d)
        % BPSK(check the real part is positive or not)
        if mod_order==1
            for j=1:Bit_Length
                if real(x_est(mod_order,d,j))>=0
                    rx_data(mod_order,d,j)=1;
                else
                    rx_data(mod_order,d,j)=0;
                end
            end
        % QPSK(check the quadrant of the symbol)
        elseif mod_order==2
            for j=1:Bit_Length/2
                % 11
                if real(x_est(mod_order,d,j))>=0 && imag(x_est(mod_order,d,j))>=0
                    rx_data(mod_order,d,j*2-1)=1;
                    rx_data(mod_order,d,j*2)=1;
                % 10
                elseif real(x_est(mod_order,d,j))<0 && imag(x_est(mod_order,d,j))>=0
                    rx_data(mod_order,d,j*2-1)=1;
                    rx_data(mod_order,d,j*2)=0;
                % 01
                elseif real(x_est(mod_order,d,j))<0 && imag(x_est(mod_order,d,j))<0
                    rx_data(mod_order,d,j*2-1)=0;
                    rx_data(mod_order,d,j*2)=1;
                % 00
                else
                    rx_data(mod_order,d,j*2-1)=0;
                    rx_data(mod_order,d,j*2)=0;
                end
            end
        % 16QAM(determine which one is the closest)
        else
            for j=1:Bit_Length/4
                % 1111
                if real(x_est(mod_order,d,j))>=0.5 && imag(x_est(mod_order,d,j))>=0.5
                    rx_data(mod_order,d,j*4-3)=1;
                    rx_data(mod_order,d,j*4-2)=1;
                    rx_data(mod_order,d,j*4-1)=1;
                    rx_data(mod_order,d,j*4)=1;
                % 1110
                elseif real(x_est(mod_order,d,j))>=0.5 && imag(x_est(mod_order,d,j))>=0 && imag(x_est(mod_order,d,j))<0.5
                    rx_data(mod_order,d,j*4-3)=1;
                    rx_data(mod_order,d,j*4-2)=1;
                    rx_data(mod_order,d,j*4-1)=1;
                    rx_data(mod_order,d,j*4)=0;
                % 1101
                elseif real(x_est(mod_order,d,j))>=0 && real(x_est(mod_order,d,j))<0.5 && imag(x_est(mod_order,d,j))>=0.5
                    rx_data(mod_order,d,j*4-3)=1;
                    rx_data(mod_order,d,j*4-2)=1;
                    rx_data(mod_order,d,j*4-1)=0;
                    rx_data(mod_order,d,j*4)=1;
                % 1100
                elseif real(x_est(mod_order,d,j))>=0 && real(x_est(mod_order,d,j))<0.5 && imag(x_est(mod_order,d,j))>=0 && imag(x_est(mod_order,d,j))<0.5
                    rx_data(mod_order,d,j*4-3)=1;
                    rx_data(mod_order,d,j*4-2)=1;
                    rx_data(mod_order,d,j*4-1)=0;
                    rx_data(mod_order,d,j*4)=0;

                % 1011
                elseif real(x_est(mod_order,d,j))>=-0.5 && real(x_est(mod_order,d,j))<0 && imag(x_est(mod_order,d,j))>=0.5
                    rx_data(mod_order,d,j*4-3)=1;
                    rx_data(mod_order,d,j*4-2)=0;
                    rx_data(mod_order,d,j*4-1)=1;
                    rx_data(mod_order,d,j*4)=1;
                % 1010
                elseif real(x_est(mod_order,d,j))<-0.5 && imag(x_est(mod_order,d,j))>=0.5
                    rx_data(mod_order,d,j*4-3)=1;
                    rx_data(mod_order,d,j*4-2)=0;
                    rx_data(mod_order,d,j*4-1)=1;
                    rx_data(mod_order,d,j*4)=0;
                % 1001
                elseif real(x_est(mod_order,d,j))<-0.5 && imag(x_est(mod_order,d,j))>=0 && imag(x_est(mod_order,d,j))<0.5
                    rx_data(mod_order,d,j*4-3)=1;
                    rx_data(mod_order,d,j*4-2)=0;
                    rx_data(mod_order,d,j*4-1)=0;
                    rx_data(mod_order,d,j*4)=1;
                % 1000
                elseif real(x_est(mod_order,d,j))>=-0.5 && real(x_est(mod_order,d,j))<0 && imag(x_est(mod_order,d,j))>=0 && imag(x_est(mod_order,d,j))<0.5
                    rx_data(mod_order,d,j*4-3)=1;
                    rx_data(mod_order,d,j*4-2)=0;
                    rx_data(mod_order,d,j*4-1)=0;
                    rx_data(mod_order,d,j*4)=0;

                % 0111
                elseif real(x_est(mod_order,d,j))>=0.5 && imag(x_est(mod_order,d,j))>=-0.5 && imag(x_est(mod_order,d,j))<0
                    rx_data(mod_order,d,j*4-3)=0;
                    rx_data(mod_order,d,j*4-2)=1;
                    rx_data(mod_order,d,j*4-1)=1;
                    rx_data(mod_order,d,j*4)=1;
                % 0110
                elseif real(x_est(mod_order,d,j))>=0.5 && imag(x_est(mod_order,d,j))<-0.5
                    rx_data(mod_order,d,j*4-3)=0;
                    rx_data(mod_order,d,j*4-2)=1;
                    rx_data(mod_order,d,j*4-1)=1;
                    rx_data(mod_order,d,j*4)=0;
                % 0101
                elseif real(x_est(mod_order,d,j))>=0 && real(x_est(mod_order,d,j))<0.5 && imag(x_est(mod_order,d,j))>=-0.5 && imag(x_est(mod_order,d,j))<0
                    rx_data(mod_order,d,j*4-3)=0;
                    rx_data(mod_order,d,j*4-2)=1;
                    rx_data(mod_order,d,j*4-1)=0;
                    rx_data(mod_order,d,j*4)=1;
                % 0100
                elseif real(x_est(mod_order,d,j))>=0 && real(x_est(mod_order,d,j))<0.5 && imag(x_est(mod_order,d,j))<-0.5
                    rx_data(mod_order,d,j*4-3)=0;
                    rx_data(mod_order,d,j*4-2)=1;
                    rx_data(mod_order,d,j*4-1)=0;
                    rx_data(mod_order,d,j*4)=0;

                % 0011
                elseif real(x_est(mod_order,d,j))>=-0.5 && real(x_est(mod_order,d,j))<0 && imag(x_est(mod_order,d,j))>=-0.5 && imag(x_est(mod_order,d,j))<0
                    rx_data(mod_order,d,j*4-3)=0;
                    rx_data(mod_order,d,j*4-2)=0;
                    rx_data(mod_order,d,j*4-1)=1;
                    rx_data(mod_order,d,j*4)=1;
                % 0010
                elseif real(x_est(mod_order,d,j))>=-0.5 && real(x_est(mod_order,d,j))<0 && imag(x_est(mod_order,d,j))<-0.5
                    rx_data(mod_order,d,j*4-3)=0;
                    rx_data(mod_order,d,j*4-2)=0;
                    rx_data(mod_order,d,j*4-1)=1;
                    rx_data(mod_order,d,j*4)=0;
                % 0001
                elseif real(x_est(mod_order,d,j))<-0.5 && imag(x_est(mod_order,d,j))>=-0.5 && imag(x_est(mod_order,d,j))<0
                    rx_data(mod_order,d,j*4-3)=0;
                    rx_data(mod_order,d,j*4-2)=0;
                    rx_data(mod_order,d,j*4-1)=0;
                    rx_data(mod_order,d,j*4)=1;
                % 0000
                else
                    rx_data(mod_order,d,j*4-3)=0;
                    rx_data(mod_order,d,j*4-2)=0;
                    rx_data(mod_order,d,j*4-1)=0;
                    rx_data(mod_order,d,j*4)=0;
                end
            end
        end
        error = 0;
        for j=1:Bit_Length
            if rx_data(mod_order,d,j) ~= tx_data(j)
                error = error+1;
            end
        end
        BER_simulated(d,mod_order)=error/Bit_Length;
        % TODO: noise = s - x, and, then, calculate SNR_simulated(d)
        n_sum=0;
        x_sum=0;
        for i=1:Bit_Length/mod_order
            x_sum=x_sum+abs(x(mod_order,i))^2;
            if mod_order == 1
                n_sum=n_sum+abs(s1(d,i)-x(mod_order,i))^2;
            elseif mod_order == 2
                n_sum=n_sum+abs(s2(d,i)-x(mod_order,i))^2;
            else
                n_sum=n_sum+abs(s3(d,i)-x(mod_order,i))^2;
            end
        end
        n_mean=n_sum/(Bit_Length/mod_order);
        x_mean=x_sum/(Bit_Length/mod_order);
        SNR_simulated(d,mod_order)=x_mean/n_mean;
        SNRdB_simulated(d,mod_order)=10*log10(SNR_simulated(d,mod_order));
        
        subplot(2, 2, d)
        hold on;
        
        if mod_order == 1
            plot(s1,'bx');       % TODO: replace y with s
            plot(x(mod_order,:),0i,'ro');
        elseif mod_order == 2
            plot(s2,'bx');       % TODO: replace y with s
            plot(x(mod_order,1:Bit_Length/mod_order),'ro');
        else
            plot(s3,'bx');       % TODO: replace y with s
            plot(x(mod_order,1:Bit_Length/mod_order),'ro');
        end
        hold off;
        xlim([-2,2]);
        ylim([-2,2]);
        title(sprintf('Constellation points d=%d', dist(d)));
        legend('decoded samples', 'transmitted samples');
        grid
    end
    filename = sprintf('IQ_%d.jpg', mod_order);
    saveas(gcf,filename,'jpg')
end

%% TODO-2: modify the figures to compare three modulation schemes
figure('units','normalized','outerposition',[0 0 1 1])
hold on;
semilogy(dist,SNRdB_simulated(:,1),'bo-','linewidth',2.0);
semilogy(dist,SNRdB_simulated(:,2),'rv--','linewidth',2.0);
semilogy(dist,SNRdB_simulated(:,4),'mx-.','linewidth',2.0);
hold off;
title('SNR');
xlabel('Distance [m]');
ylabel('SNR [dB]');
legend('BPSK','QPSK','16QAM');
axis tight 
grid
saveas(gcf,'SNR.jpg','jpg')

figure('units','normalized','outerposition',[0 0 1 1])
hold on;
semilogy(dist,BER_simulated(:,1),'bo-','linewidth',2.0);
semilogy(dist,BER_simulated(:,2),'rv--','linewidth',2.0);
semilogy(dist,BER_simulated(:,4),'mx-.','linewidth',2.0);
hold off;
title('BER');
xlabel('Distance [m]');
ylabel('BER');
legend('BPSK','QPSK','16QAM');
axis tight 
grid
saveas(gcf,'BER.jpg','jpg')
return;
