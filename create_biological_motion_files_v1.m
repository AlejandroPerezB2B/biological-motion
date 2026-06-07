function create_biological_motion_files_v1()
% Creates MATLAB files for the biological motion task.
% Includes individual and shared HOST/CLIENT conditions. No Psychtoolbox.

writeFile('make_bm_stimulus_table.m', make_stimulus_table_code());
writeFile('make_bm_trial_order.m', make_trial_order_code());
writeFile('run_biological_motion_individual.m', run_individual_code());
writeFile('run_biological_motion_shared_host.m', run_shared_host_code());
writeFile('run_biological_motion_shared_client.m', run_shared_client_code());
writeFile('bm_play_video_trial.m', play_video_code());
writeFile('bm_get_response.m', response_code());
writeFile('bm_wait_for_space.m', wait_space_code());
writeFile('bm_save_row.m', save_row_code());
writeFile('bm_compute_sdt.m', compute_sdt_code());
writeFile('bm_convert_stimuli_to_mp4.m', convert_code());

if ~exist('stimuli','dir'); mkdir('stimuli'); end
if ~exist('data','dir'); mkdir('data'); end

disp('Created biological motion task files.');
disp('Recommended: convert AVI to MP4 if needed, then run make_bm_stimulus_table and make_bm_trial_order.');
end

function writeFile(fname, txt)
fid = fopen(fname,'w');
if fid < 0; error('Could not create %s', fname); end
fprintf(fid,'%s',txt);
fclose(fid);
end

function txt = make_stimulus_table_code()
lines = [
"function stimTable = make_bm_stimulus_table(stimDir)"
"if nargin < 1 || isempty(stimDir)"
"    if exist(fullfile(pwd,'stimuli_mp4'),'dir')"
"        stimDir = fullfile(pwd,'stimuli_mp4');"
"    else"
"        stimDir = fullfile(pwd,'stimuli');"
"    end"
"end"
"if ~exist(stimDir,'dir'); error('Stimulus folder not found: %s', stimDir); end"
"files = [dir(fullfile(stimDir,'*.mp4')); dir(fullfile(stimDir,'*.avi'))];"
"if isempty(files); error('No MP4 or AVI files found in %s', stimDir); end"
"n = numel(files);"
"filename = strings(n,1); fullpath = strings(n,1); signalLabel = strings(n,1);"
"signalPresent = zeros(n,1); noise = zeros(n,1); direction = strings(n,1); position = zeros(n,1);"
"for i = 1:n"
"    fname = files(i).name;"
"    tok = regexp(fname, '^([SU])(12|24|48|96|192)([LR])(-?20|-?10|0)\.(avi|mp4)$', 'tokens', 'once');"
"    if isempty(tok); error('Filename does not match expected format: %s', fname); end"
"    filename(i) = string(fname); fullpath(i) = string(fullfile(stimDir,fname));"
"    noise(i) = str2double(tok{2}); direction(i) = string(tok{3}); position(i) = str2double(tok{4});"
"    if strcmp(tok{1},'U'); signalLabel(i) = 'walker'; signalPresent(i) = 1;"
"    else; signalLabel(i) = 'scrambled'; signalPresent(i) = 0; end"
"end"
"stimTable = table(filename,fullpath,signalLabel,signalPresent,noise,direction,position);"
"stimTable = sortrows(stimTable, {'signalLabel','noise','direction','position'});"
"writetable(stimTable,'stimuli.csv');"
"disp('Saved stimuli.csv');"
"disp(['Stimulus folder: ' stimDir]);"
"disp(['Number of stimuli found: ' num2str(height(stimTable))]);"
"nMain = sum(ismember(stimTable.noise,[24 48 96 192]));"
"if nMain ~= 80; warning('Expected 80 main-task stimuli, found %d.', nMain); end"
"end"
];
txt = char(strjoin(lines,newline));
end

function txt = make_trial_order_code()
lines = [
"function trialTable = make_bm_trial_order(stimCsv,repetitions)"
"if nargin < 1 || isempty(stimCsv); stimCsv = 'stimuli.csv'; end"
"if nargin < 2 || isempty(repetitions); repetitions = 2; end"
"if ~exist(stimCsv,'file'); error('stimuli.csv not found. Run make_bm_stimulus_table first.'); end"
"stimTable = readtable(stimCsv,'TextType','string');"
"stimTable = stimTable(ismember(stimTable.noise,[24 48 96 192]),:);"
"if height(stimTable) ~= 80; warning('Expected 80 main stimuli, found %d. Continuing anyway.', height(stimTable)); end"
"trialTable = repmat(stimTable,repetitions,1);"
"trialTable.repetition = repelem((1:repetitions)',height(stimTable));"
"rng(20260607,'twister');"
"trialTable = trialTable(randperm(height(trialTable)),:);"
"trialTable.trial = (1:height(trialTable))';"
"trialTable = movevars(trialTable,'trial','Before',1);"
"save('bm_trial_order.mat','trialTable');"
"writetable(trialTable,'bm_trial_order.csv');"
"disp('Saved bm_trial_order.mat and bm_trial_order.csv');"
"end"
];
txt = char(strjoin(lines,newline));
end

function txt = run_individual_code()
lines = [
"function run_biological_motion_individual(participantID)"
"if nargin < 1 || isempty(participantID); participantID = input('Participant ID: ','s'); end"
"prepareBMFiles(); load('bm_trial_order.mat','trialTable');"
"dataDir = fullfile(pwd,'data'); if ~exist(dataDir,'dir'); mkdir(dataDir); end"
"outfile = fullfile(dataDir,[participantID '_biological_motion_individual.csv']);"
"fig = figure('Color','k','MenuBar','none','ToolBar','none','NumberTitle','off','Name','Biological Motion - Individual');"
"set(fig,'WindowState','maximized'); drawnow;"
"try"
"    showInstructions(fig,'individual'); runPractice(fig);"
"    for t = 1:height(trialTable)"
"        thisTrial = trialTable(t,:);"
"        showFixation(fig,0.5); bm_play_video_trial(fig,char(thisTrial.fullpath));"
"        [response,rt] = bm_get_response(fig);"
"        row = makeTrialRow(participantID,'individual',t,thisTrial,response,rt,'',datetime('now'));"
"        bm_save_row(outfile,row); showBlank(fig,0.3 + rand()*0.2);"
"    end"
"    showEnd(fig);"
"catch ME"
"    if isvalid(fig); close(fig); end; rethrow(ME);"
"end"
"end"
];
txt = char(strjoin(lines,newline));
txt = [txt newline common_local_code()];
end

function txt = run_shared_host_code()
lines = [
"function run_biological_motion_shared_host(dyadID,participantID,port)"
"if nargin < 1 || isempty(dyadID); dyadID = input('Dyad ID: ','s'); end"
"if nargin < 2 || isempty(participantID); participantID = [dyadID '_A']; end"
"if nargin < 3 || isempty(port); port = 50000; end"
"prepareBMFiles(); load('bm_trial_order.mat','trialTable');"
"dataDir = fullfile(pwd,'data'); if ~exist(dataDir,'dir'); mkdir(dataDir); end"
"localFile = fullfile(dataDir,[participantID '_biological_motion_shared.csv']);"
"syncFile = fullfile(dataDir,[dyadID '_biological_motion_shared_sync.csv']);"
"disp(['Starting TCP server on port ' num2str(port)]);"
"srv = tcpserver('0.0.0.0',port,'Timeout',60); configureTerminator(srv,'LF');"
"disp('Waiting for client connection...'); while srv.Connected == 0; pause(0.1); end; disp('Client connected.');"
"writeline(srv,'HELLO_FROM_HOST');"
"fig = figure('Color','k','MenuBar','none','ToolBar','none','NumberTitle','off','Name','Biological Motion - Shared Host');"
"set(fig,'WindowState','maximized'); drawnow;"
"try"
"    showInstructions(fig,'shared'); runPractice(fig); writeline(srv,'HOST_READY_FOR_MAIN');"
"    for t = 1:height(trialTable)"
"        thisTrial = trialTable(t,:);"
"        showSharedWaiting(fig,t,height(trialTable));"
"        triggeredBy = waitForSharedStartHost(fig,srv);"
"        trialStartTime = datetime('now');"
"        writeline(srv,sprintf('START|%d|%s',t,triggeredBy));"
"        showFixation(fig,0.5); bm_play_video_trial(fig,char(thisTrial.fullpath));"
"        [response,rt] = bm_get_response(fig); localDoneTime = datetime('now');"
"        writeline(srv,sprintf('DONE|%d|HOST',t));"
"        waitForClientDone(srv,t); bothDoneTime = datetime('now');"
"        iti = 0.3 + rand()*0.2; writeline(srv,sprintf('ITI|%.3f',iti));"
"        row = makeTrialRow(participantID,'shared',t,thisTrial,response,rt,triggeredBy,localDoneTime);"
"        bm_save_row(localFile,row);"
"        syncRow = table(string(dyadID),t,thisTrial.filename,thisTrial.signalLabel,thisTrial.signalPresent,thisTrial.noise,thisTrial.direction,thisTrial.position,string(triggeredBy),trialStartTime,bothDoneTime,iti, ..."
"            'VariableNames',{'dyadID','trial','filename','signalLabel','signalPresent','noise','direction','position','triggeredBy','trialStartTime','bothDoneTime','ITI'});"
"        bm_save_row(syncFile,syncRow); showBlank(fig,iti);"
"    end"
"    writeline(srv,'FINISHED'); showEnd(fig);"
"catch ME"
"    try; writeline(srv,'ABORT'); catch; end"
"    if isvalid(fig); close(fig); end; rethrow(ME);"
"end"
"end"
"function triggeredBy = waitForSharedStartHost(fig,srv)"
"triggeredBy = ''; abortTask = false; set(fig,'KeyPressFcn',@keyHandler);"
"while isempty(triggeredBy)"
"    drawnow; if abortTask; error('Experiment aborted by HOST with ESC.'); end"
"    while srv.NumBytesAvailable > 0"
"        msg = char(readline(srv));"
"        if startsWith(msg,'SPACE'); triggeredBy = 'CLIENT'; return; end"
"        if startsWith(msg,'ABORT'); error('Experiment aborted by CLIENT.'); end"
"    end"
"    pause(0.005);"
"end"
"    function keyHandler(~,event)"
"        switch event.Key; case 'space'; triggeredBy = 'HOST'; case 'escape'; abortTask = true; end"
"    end"
"end"
"function waitForClientDone(srv,trialNum)"
"while true"
"    drawnow;"
"    if srv.NumBytesAvailable > 0"
"        msg = char(readline(srv));"
"        if startsWith(msg,sprintf('DONE|%d|CLIENT',trialNum)); return; end"
"        if startsWith(msg,'ABORT'); error('Experiment aborted by CLIENT.'); end"
"    end"
"    pause(0.005);"
"end"
"end"
];
txt = char(strjoin(lines,newline));
txt = [txt newline common_local_code()];
end

function txt = run_shared_client_code()
lines = [
"function run_biological_motion_shared_client(dyadID,participantID,hostIP,port)"
"if nargin < 1 || isempty(dyadID); dyadID = input('Dyad ID: ','s'); end"
"if nargin < 2 || isempty(participantID); participantID = [dyadID '_B']; end"
"if nargin < 3 || isempty(hostIP); hostIP = input('Host IP address: ','s'); end"
"if nargin < 4 || isempty(port); port = 50000; end"
"prepareBMFiles(); load('bm_trial_order.mat','trialTable');"
"dataDir = fullfile(pwd,'data'); if ~exist(dataDir,'dir'); mkdir(dataDir); end"
"localFile = fullfile(dataDir,[participantID '_biological_motion_shared.csv']);"
"disp(['Connecting to host ' hostIP ':' num2str(port)]);"
"cli = tcpclient(hostIP,port,'Timeout',60); configureTerminator(cli,'LF'); pause(0.5);"
"fig = figure('Color','k','MenuBar','none','ToolBar','none','NumberTitle','off','Name','Biological Motion - Shared Client');"
"set(fig,'WindowState','maximized'); drawnow;"
"try"
"    showInstructions(fig,'shared'); runPractice(fig); waitForHostReady(cli);"
"    for t = 1:height(trialTable)"
"        thisTrial = trialTable(t,:); showSharedWaiting(fig,t,height(trialTable));"
"        [trialNum,triggeredBy] = waitForSharedStartClient(fig,cli);"
"        if trialNum ~= t; error('Trial mismatch: expected %d, got %d',t,trialNum); end"
"        showFixation(fig,0.5); bm_play_video_trial(fig,char(thisTrial.fullpath));"
"        [response,rt] = bm_get_response(fig); localDoneTime = datetime('now');"
"        writeline(cli,sprintf('DONE|%d|CLIENT',t));"
"        iti = waitForITIorAbort(cli);"
"        row = makeTrialRow(participantID,'shared',t,thisTrial,response,rt,triggeredBy,localDoneTime);"
"        bm_save_row(localFile,row); showBlank(fig,iti);"
"    end"
"    showEnd(fig);"
"catch ME"
"    try; writeline(cli,'ABORT'); catch; end"
"    if isvalid(fig); close(fig); end; rethrow(ME);"
"end"
"end"
"function waitForHostReady(cli)"
"while true"
"    drawnow;"
"    if cli.NumBytesAvailable > 0"
"        msg = char(readline(cli));"
"        if startsWith(msg,'HOST_READY_FOR_MAIN'); return; end"
"        if startsWith(msg,'ABORT'); error('Experiment aborted by HOST.'); end"
"    end"
"    pause(0.005);"
"end"
"end"
"function [trialNum,triggeredBy] = waitForSharedStartClient(fig,cli)"
"trialNum = NaN; triggeredBy = ''; spaceAlreadySent = false; abortTask = false; set(fig,'KeyPressFcn',@keyHandler);"
"while isnan(trialNum)"
"    drawnow; if abortTask; writeline(cli,'ABORT'); error('Experiment aborted by CLIENT with ESC.'); end"
"    while cli.NumBytesAvailable > 0"
"        msg = char(readline(cli));"
"        if startsWith(msg,'START'); parts = split(msg,'|'); trialNum = str2double(parts{2}); triggeredBy = parts{3}; return; end"
"        if startsWith(msg,'ABORT'); error('Experiment aborted by HOST.'); end"
"        if startsWith(msg,'FINISHED'); error('Host finished unexpectedly.'); end"
"    end"
"    pause(0.005);"
"end"
"    function keyHandler(~,event)"
"        switch event.Key"
"            case 'space'"
"                if ~spaceAlreadySent; writeline(cli,'SPACE|CLIENT'); spaceAlreadySent = true; end"
"            case 'escape'; abortTask = true;"
"        end"
"    end"
"end"
"function iti = waitForITIorAbort(cli)"
"iti = NaN;"
"while isnan(iti)"
"    drawnow;"
"    if cli.NumBytesAvailable > 0"
"        msg = char(readline(cli));"
"        if startsWith(msg,'ITI'); parts = split(msg,'|'); iti = str2double(parts{2}); return; end"
"        if startsWith(msg,'ABORT'); error('Experiment aborted by HOST.'); end"
"        if startsWith(msg,'FINISHED'); iti = 0; return; end"
"    end"
"    pause(0.005);"
"end"
"end"
];
txt = char(strjoin(lines,newline));
txt = [txt newline common_local_code()];
end

function txt = common_local_code()
lines = [
"function prepareBMFiles()"
"if ~exist('stimuli.csv','file'); make_bm_stimulus_table(); end"
"if ~exist('bm_trial_order.mat','file'); make_bm_trial_order(); end"
"end"
"function showInstructions(fig,modeLabel)"
"clf(fig); set(fig,'Color','k');"
"text(0.5,0.82,'Biological Motion Detection Task','Color','w','HorizontalAlignment','center','FontSize',28,'Units','normalized','Interpreter','none');"
"if strcmp(modeLabel,'shared')"
"    extra = {'In this condition, you and your partner will see the same animations.','Please respond privately. Do not discuss your response.',''};"
"else; extra = {}; end"
"instructions = [{'You will see short animations made of moving dots.'},{''},{'Your task is to decide whether you saw a human walker.'},{''},{'Press Y if you saw a walker.'},{'Press N if you did not see a walker.'},{''},extra,{'Please respond even if you are not completely sure.'},{''},{'Press SPACE to start practice.'}];"
"text(0.5,0.45,instructions,'Color','w','HorizontalAlignment','center','FontSize',20,'Units','normalized','Interpreter','none');"
"axis off; drawnow; bm_wait_for_space(fig);"
"end"
"function runPractice(fig)"
"stimTable = readtable('stimuli.csv','TextType','string');"
"practicePool = stimTable(ismember(stimTable.noise,[12 24]),:);"
"if height(practicePool) < 10; practicePool = stimTable; end"
"rng(20260608,'twister'); practicePool = practicePool(randperm(height(practicePool)),:);"
"practiceTable = practicePool(1:min(10,height(practicePool)),:);"
"for p = 1:height(practiceTable)"
"    showFixation(fig,0.5); bm_play_video_trial(fig,char(practiceTable.fullpath(p)));"
"    [response,~] = bm_get_response(fig);"
"    correct = double(strcmp(response,'yes')) == practiceTable.signalPresent(p);"
"    clf(fig); set(fig,'Color','k'); if correct; msg = 'Correct'; else; msg = 'Incorrect'; end"
"    text(0.5,0.5,msg,'Color','w','HorizontalAlignment','center','FontSize',32,'Units','normalized','Interpreter','none');"
"    axis off; drawnow; pause(0.8);"
"end"
"clf(fig); set(fig,'Color','k');"
"text(0.5,0.5,{'Practice finished.','','Press SPACE to start the main task.'},'Color','w','HorizontalAlignment','center','FontSize',24,'Units','normalized','Interpreter','none');"
"axis off; drawnow; bm_wait_for_space(fig);"
"end"
"function showSharedWaiting(fig,t,nTrials)"
"clf(fig); set(fig,'Color','k');"
"text(0.5,0.5,sprintf(['Trial %d of %d\n\nYou and your partner will see the same animation.\nRespond privately.\n\nAfter both have responded, either participant may press SPACE to start.'],t,nTrials),'Color','w','HorizontalAlignment','center','FontSize',22,'Units','normalized','Interpreter','none');"
"axis off; drawnow;"
"end"
"function showFixation(fig,dur)"
"clf(fig); set(fig,'Color','k'); text(0.5,0.5,'+','Color','w','HorizontalAlignment','center','FontSize',40,'Units','normalized','Interpreter','none'); axis off; drawnow; pause(dur);"
"end"
"function showBlank(fig,dur)"
"clf(fig); set(fig,'Color','k'); axis off; drawnow; pause(dur);"
"end"
"function showEnd(fig)"
"clf(fig); set(fig,'Color','k'); text(0.5,0.5,'Finished. Thank you.','Color','w','HorizontalAlignment','center','FontSize',28,'Units','normalized','Interpreter','none'); axis off; drawnow;"
"end"
"function row = makeTrialRow(participantID,conditionLabel,t,thisTrial,response,rt,triggeredBy,timestamp)"
"signalPresent = thisTrial.signalPresent; responseWalker = double(strcmp(response,'yes')); correct = responseWalker == signalPresent;"
"hit = signalPresent == 1 && responseWalker == 1; falseAlarm = signalPresent == 0 && responseWalker == 1; miss = signalPresent == 1 && responseWalker == 0; correctRejection = signalPresent == 0 && responseWalker == 0;"
"row = table(string(participantID),string(conditionLabel),t,thisTrial.filename,thisTrial.signalLabel,signalPresent,string(response),responseWalker,correct,hit,falseAlarm,miss,correctRejection,thisTrial.noise,thisTrial.direction,thisTrial.position,rt,string(triggeredBy),timestamp, ..."
"    'VariableNames',{'participantID','condition','trial','filename','signalLabel','signalPresent','response','responseWalker','correct','hit','falseAlarm','miss','correctRejection','noise','direction','position','RT','triggeredBy','timestamp'});"
"end"
];
txt = char(strjoin(lines,newline));
end

function txt = play_video_code()
lines = [
"function bm_play_video_trial(fig,videoPath)"
"if ~exist(videoPath,'file'); error('Video file not found: %s',videoPath); end"
"try; vid = VideoReader(videoPath);"
"catch ME"
"    error(['Could not read video file:\n%s\n\nOriginal error:\n%s\n\nIf this is an AVI file with cvid/Cinepak codec, convert stimuli to MP4 first:\nbm_convert_stimuli_to_mp4\nmake_bm_stimulus_table\nmake_bm_trial_order'],videoPath,ME.message);"
"end"
"clf(fig); set(fig,'Color','k'); ax = axes('Parent',fig,'Color','k','Position',[0 0 1 1]); axis(ax,'off');"
"firstFrame = readFrame(vid); h = image(ax,firstFrame); axis(ax,'image'); axis(ax,'off'); drawnow;"
"frameDuration = 1 / vid.FrameRate;"
"while hasFrame(vid)"
"    tic; frame = readFrame(vid); set(h,'CData',frame); drawnow limitrate; pause(max(0,frameDuration - toc));"
"end"
"end"
];
txt = char(strjoin(lines,newline));
end

function txt = response_code()
lines = [
"function [response,rt] = bm_get_response(fig)"
"response = ''; rt = NaN; abortTask = false; responseTic = tic;"
"clf(fig); set(fig,'Color','k');"
"text(0.5,0.58,'Did you see a human walker?','Color','w','HorizontalAlignment','center','FontSize',28,'Units','normalized','Interpreter','none');"
"text(0.5,0.43,'Y = Yes     N = No','Color','w','HorizontalAlignment','center','FontSize',26,'Units','normalized','Interpreter','none');"
"axis off; drawnow; set(fig,'KeyPressFcn',@keyHandler);"
"while isempty(response)"
"    drawnow; if abortTask; error('Experiment aborted with ESC.'); end; pause(0.005);"
"end"
"    function keyHandler(~,event)"
"        switch lower(event.Key); case 'y'; response = 'yes'; rt = toc(responseTic); case 'n'; response = 'no'; rt = toc(responseTic); case 'escape'; abortTask = true; end"
"    end"
"end"
];
txt = char(strjoin(lines,newline));
end

function txt = wait_space_code()
lines = [
"function bm_wait_for_space(fig)"
"done = false; abortTask = false; set(fig,'KeyPressFcn',@keyHandler);"
"while ~done"
"    drawnow; if abortTask; error('Experiment aborted with ESC.'); end; pause(0.005);"
"end"
"    function keyHandler(~,event)"
"        switch event.Key; case 'space'; done = true; case 'escape'; abortTask = true; end"
"    end"
"end"
];
txt = char(strjoin(lines,newline));
end

function txt = save_row_code()
lines = [
"function bm_save_row(outfile,row)"
"[folder,~,~] = fileparts(outfile); if ~isempty(folder) && ~exist(folder,'dir'); mkdir(folder); end"
"if exist(outfile,'file'); writetable(row,outfile,'WriteMode','append'); else; writetable(row,outfile); end"
"end"
];
txt = char(strjoin(lines,newline));
end

function txt = compute_sdt_code()
lines = [
"function summary = bm_compute_sdt(dataFile)"
"if nargin < 1 || isempty(dataFile); [f,p] = uigetfile('*.csv','Select participant data file'); if isequal(f,0); return; end; dataFile = fullfile(p,f); end"
"T = readtable(dataFile,'TextType','string'); noiseLevels = unique(T.noise); rows = table(); overall = computeOne(T,'overall');"
"for i = 1:numel(noiseLevels); rows = [rows; computeOne(T(T.noise==noiseLevels(i),:),string(noiseLevels(i)))]; end %#ok<AGROW>"
"summary = [overall; rows]; [folder,name,~] = fileparts(dataFile); outFile = fullfile(folder,[name '_SDT_summary.csv']); writetable(summary,outFile); disp(summary); disp(['Saved SDT summary: ' outFile]);"
"end"
"function row = computeOne(T,noiseText)"
"signalTrials = sum(T.signalPresent==1); noiseTrials = sum(T.signalPresent==0); hits = sum(T.hit==1); falseAlarms = sum(T.falseAlarm==1); misses = sum(T.miss==1); correctRejections = sum(T.correctRejection==1);"
"hitRate = (hits + 0.5)/(signalTrials + 1); faRate = (falseAlarms + 0.5)/(noiseTrials + 1); zH = norminv(hitRate); zFA = norminv(faRate); dprime = zH - zFA; criterionC = -0.5*(zH + zFA); accuracy = mean(T.correct); meanRT = mean(T.RT,'omitnan');"
"row = table(string(noiseText),signalTrials,noiseTrials,hits,misses,falseAlarms,correctRejections,hitRate,faRate,dprime,criterionC,accuracy,meanRT,'VariableNames',{'noise','signalTrials','noiseTrials','hits','misses','falseAlarms','correctRejections','hitRate','falseAlarmRate','dprime','criterionC','accuracy','meanRT'});"
"end"
];
txt = char(strjoin(lines,newline));
end

function txt = convert_code()
lines = [
"function bm_convert_stimuli_to_mp4(stimDir,outDir)"
"if nargin < 1 || isempty(stimDir); stimDir = fullfile(pwd,'stimuli'); end"
"if nargin < 2 || isempty(outDir); outDir = fullfile(pwd,'stimuli_mp4'); end"
"if ~exist(stimDir,'dir'); error('Stimulus folder not found: %s',stimDir); end"
"if ~exist(outDir,'dir'); mkdir(outDir); end"
"[status,~] = system('ffmpeg -version');"
"if status ~= 0; error('ffmpeg was not found. Install it first. On Windows: winget install -e --id Gyan.FFmpeg'); end"
"files = dir(fullfile(stimDir,'*.avi')); if isempty(files); error('No AVI files found in %s',stimDir); end"
"for i = 1:numel(files)"
"    inFile = fullfile(stimDir,files(i).name); [~,base,~] = fileparts(files(i).name); outFile = fullfile(outDir,[base '.mp4']);"
"    if exist(outFile,'file'); fprintf('Already exists: %s\n',outFile); continue; end"
"    cmd = sprintf('ffmpeg -y -i ""%s"" -c:v libx264 -pix_fmt yuv420p -an ""%s""',inFile,outFile);"
"    fprintf('Converting %s\n',files(i).name); status = system(cmd); if status ~= 0; error('ffmpeg failed while converting %s',files(i).name); end"
"end"
"disp('Conversion finished. Regenerate stimuli.csv and bm_trial_order files.');"
"end"
];
txt = char(strjoin(lines,newline));
end
