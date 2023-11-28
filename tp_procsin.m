%Taxa de dizimação/interpolação
M = 3; 
%Frequência borda de passagem
wp = pi/M; 
%Frequência borda de rejeição
ws = (5/4)*pi/M;
%Máxima distorção 1%
delta = 0.01;

[audio, fs] = audioread('EuGostoDeDSP.wav');
sinal_interpolado = interpolador(audio, M);
sinal_dizimado = dizimador(audio, M);

%número de amostras N do sinal
signalLength = length(audio);
%Declaração de um vetor com o tamanho exato do número de amostras do sinal
sampleVector = 0:signalLength-1;
%Declaração de um vetor com o intervalo de tempo de cada amostra --> x(t)=x[nT]
timeVector = sampleVector/(fs);

signalLength_interpolado = length(sinal_interpolado);
sampleVector_interpolado = 0:signalLength_interpolado-1;
timeVector_interpolado = sampleVector_interpolado/(fs);

signalLength_dizimado = length(sinal_dizimado);
sampleVector_dizimado = 0:signalLength_dizimado-1;
timeVector_dizimado = sampleVector_dizimado/(fs);

figure;
subplot(1, 3, 1);
plot(timeVector, audio);
title('Audio');
subplot(1, 3, 2);
plot(timeVector_interpolado, sinal_interpolado);
title('Audio interpolado');
subplot(1, 3, 3);
plot(timeVector_dizimado, sinal_dizimado);
title('Audio dizimado');

signalLength = length(audio); %número de amostras N do sinal
freqAudio = fft(audio);
freqAudio = fftshift(freqAudio);
moduleAudio = abs(freqAudio/signalLength); %normalização do módulo

%Calculo dos parâmetro da janela de Kaiser
N = kaiser_M(ws, wp, delta);
beta = kaiser_beta(delta);

%Frequência de corte normalizada
wc = (ws+wp)/2;
a = N/2;
h = zeros(1,ceil(N));
w_kaiser = zeros(1,ceil(N));

% Projeto da janela de Kaiser
for n = 1:ceil(N)
    
    w_kaiser(n) = (besseli(0,beta*(1-((n-a)/a)^2)^(1/2))/besseli(0,beta));
    h(n) =  w_kaiser(n)* (sin(wc*(n-a))/(pi*(n-a)));

end

amostraKaiser = (0:ceil(N)-1);
freqVectorKaiser = linspace(-fs/2,fs/2,length(amostraKaiser));

% Plotagem da janela de Kaiser
figure;
plot(w_kaiser);
title(['Janela de Kaiser - Ordem: ' num2str(ceil(N)) ' - beta: ' num2str(beta)]);
xlabel('Amostras');
ylabel('Amplitude');

freq_kaiser = fft(h);
freq_kaiser = fftshift(freq_kaiser);
module_kaiser = abs(freq_kaiser);
angle_kaiser = angle(freq_kaiser);

% Plotar a resposta ao impulso
figure();
subplot(1, 3, 1);
plot(amostraKaiser, h);
title('Resposta ao impulso no tempo'), xlabel('Número de amostras'),ylabel('Amplitude Normalizada');
subplot(1, 3, 2);
plot (freqVectorKaiser, module_kaiser);
title('Domínio da frequência'), xlabel('Frequência (Hz)'),ylabel('Magnitude');
subplot(1, 3, 3);
plot (freqVectorKaiser, angle_kaiser);
title('Domínio da frequência'), xlabel('Frequência (Hz)'),ylabel('Fase');

%Saída do interpolador
saida_interpolador = conv(sinal_interpolado,h);
audiowrite('SinalInterpolado.wav', saida_interpolador, fs);
freq_sinal = fft(saida_interpolador);
freq_sinal = fftshift(freq_sinal);
module_saida_interpolador = abs(freq_sinal);

%Saída do dizimador
saida_dizimador = conv(sinal_dizimado,h);
audiowrite('SinalDizimado.wav', saida_dizimador, fs);
freq_sinal = fft(saida_dizimador);
freq_sinal = fftshift(freq_sinal);
module_saide_dizimador = abs(freq_sinal);

% Plotar o sinal de saída interpolador
figure();
subplot(1, 2, 1);
plot(saida_interpolador);
title('Sinal interpolado'), xlabel('Amostras'),ylabel('Amplitude Normalizada');
subplot(1, 2, 2);
plot(module_saida_interpolador);
title('Modulo'), xlabel('Amostras'),ylabel('Amplitude');

% Plotar o sinal de saída dizimador
figure();
subplot(1, 2, 1);
plot(saida_dizimador);
title('Sinal dizimado'), xlabel('Amostras'),ylabel('Amplitude Normalizada');
subplot(1, 2, 2);
plot(module_saide_dizimador);
title('Modulo'), xlabel('Amostras'),ylabel('Amplitude ');

%sound(saida_dizimador, fs);
%sound(saida_interpolador, fs);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% INFORMAÇÕES DA COMPRESSÃO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Abrir o arquivo para escrita
fid = fopen('informacoes.txt', 'w');

% Escrever os dados no arquivo
fprintf(fid, 'Frequencia de amostragem: %d \nTaxa de Compressão: %d', fs, M);

% Fechar o arquivo
fclose(fid);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% RECONSTRUÇÃO DO SINAL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[comprimido, fs] = audioread('SinalDizimado.wav');
sinal_reconstruido = interpolador(comprimido, M);
sinal_reconstruido = conv(sinal_reconstruido, h);
audiowrite('SinalReconstruido.wav', sinal_reconstruido, fs);
freq_recon = fft(sinal_reconstruido);
freq_recon = fftshift(freq_recon);
module_recon = abs(freq_recon);

% Plotar o sinal reconstruído
figure();
subplot(1, 2, 1);
plot(sinal_reconstruido);
title('Sinal reconstruído'), xlabel('Amostras'),ylabel('Amplitude Normalizada');
subplot(1, 2, 2);
plot(module_recon);
title('Modulo'), xlabel('Amostras'),ylabel('Amplitude ');

sound(sinal_reconstruido, fs);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% FUNÇÕES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function y = dizimador(x, M)
    % x: sinal de entrada
    % M: fator de redução

    y = x(1:M:end); % Seleciona cada M-ésima amostra
end

function y = interpolador(x, L)
    % x: sinal de entrada
    % L: fator de interpolação

    N = length(x);
    y = zeros(1, N * L); % Inicializa o vetor de saída com zeros

    % Insere L-1 zeros entre cada par de amostras
    y(1:L:end) = x;
end

function y = kaiser_M(ws, wp, delta)

A = -20*log10(delta);
M = (A - 8)/(2.285*(ws-wp));
y = M;
end 

function y = kaiser_beta(delta)

A = -20*log10(delta);
if A > 50
    beta = 0.1102*(A-8.7);

elseif A <= 50 && A >= 21
    beta = 0.5842*(A-21)^0.4 + 0.07886*(A-21);
    
elseif A < 21
    beta = 0;
end

y = beta;
end

