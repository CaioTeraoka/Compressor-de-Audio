processarAudio('EuGostoDeDSP.wav', 5)

% Função principal para alterar a velocidade de reprodução do áudio
function processarAudio(nomeArquivo, taxaReducaoAmpliacao)
    % Carregar o sinal de áudio
    [audio, fs] = audioread(nomeArquivo);
    
    % Aplicar a taxa de redução/ampliação usando interpolação ou dizimação
    if taxaReducaoAmpliacao < 1
        audioProcessado = interpolaAudio(audio, taxaReducaoAmpliacao);
    else
        audioProcessado = dizimaAudio(audio, taxaReducaoAmpliacao);
    end
    
    % Minimizar o "efeito Chipmunk" ajustando o espectro de frequências
    audioProcessado = ajustarEspectro(audio, audioProcessado, taxaReducaoAmpliacao);
    
    % Gerar gráficos da forma de onda e espectro de frequências
    plotWaveform(audio, fs, 'Áudio Original');
    plotWaveform(audioProcessado, fs, 'Áudio Processado');
    
    plotSpectrum(audio, fs, 'Espectro Original');
    plotSpectrum(audioProcessado, fs, 'Espectro Processado');
    
    % Reproduzir os áudios
    sound(audio, fs);
    pause(length(audio) / fs);
    sound(audioProcessado, fs);
end

% Função para interpolar o áudio
function audioInterpolado = interpolaAudio(audio, taxaReducao)
    fatorInterpolacao = 1 / taxaReducao;
    audioInterpolado = resample(audio, fatorInterpolacao, 1);
end

% Função para dizimar o áudio
function audioDizimado = dizimaAudio(audio, taxaAmpliacao)
    fatorDizimacao = round(taxaAmpliacao);
    audioDizimado = resample(audio, 1, fatorDizimacao);
end

% Função para ajustar o espectro de frequências
function audioAjustado = ajustarEspectro(audioOriginal, audioProcessado, taxaReducaoAmpliacao)
    % Adicione aqui a lógica para ajustar o espectro de frequências
    % Pode ser necessário usar filtros passa-baixa ou outras técnicas
    
    % Exemplo: aplicando um filtro passa-baixa
    cutoffFrequency = 0.9 * 0.5 * min(1, taxaReducaoAmpliacao);
    filtroPassaBaixa = designfilt('lowpassfir', 'CutoffFrequency', cutoffFrequency, 'SampleRate', length(audioProcessado), 'DesignMethod', 'window');
    audioAjustado = filter(filtroPassaBaixa, audioProcessado);
end

% Função para plotar a forma de onda do áudio
function plotWaveform(audio, fs, titulo)
    figure;
    t = (0:length(audio)-1) / fs;
    plot(t, audio);
    xlabel('Tempo (s)');
    ylabel('Amplitude');
    title(titulo);
end

% Função para plotar o espectro de frequências do áudio
function plotSpectrum(audio, fs, titulo)
    figure;
    fftSize = 2^nextpow2(length(audio));
    f = (-fs/2:fs/fftSize:fs/2 - fs/fftSize);
    espectro = fftshift(fft(audio, fftSize) / length(audio));
    plot(f, 20*log10(abs(espectro)));
    xlabel('Frequência (Hz)');
    ylabel('Magnitude (dB)');
    title(titulo);
end
