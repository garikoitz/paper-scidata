%% Download or clone the repository
%{
   cd ~/toolboxes 
    !git clone https://github.com/garikoitz/paper-scidata.git
    !git clone https://github.com/vistalab/scitran.git
    rootDir     = '~/toolboxes/paper-scidata';
    scitrarnDir = '~/toolboxes/scitran';
    addpath(genpath(rootDir));
    addpath(genpath(scitranDir));
%} 
clear all; close all; clc;
    

%% Obtain the data from Flywheel
% (this takes a lot of time and it is better, better if run in standalone server)
serverName       = 'stanfordlabs';
collectionName   = 'ComputationalReproducibility';  
% GET ALL ANALYSIS FROM COLLECTION
JL = dr_fwCheckJobs(serverName, collectionName);
% FILTER
gearName         = 'afq-pipeline'; gearVersion = '3.0.6';
dateFrom         = '04-Feb-2019 00:00:00';
labelContains    = 'AllV03:v3.0.6';
state            = 'complete'; 
t                = JL(JL.state==state & JL.gearName==gearName & ...
                      JL.gearVersion==gearVersion & JL.JobCreated>dateFrom & ...
                      contains(string(JL.label), labelContains),:);
% Generate and save the dataset
measurements     = {'fa','ad','cl','curvature','md','rd','torsion','volume'};
dt               = dr_fwReadDtFromAnalysisTable(serverName, t, measurements);
fname            = fullfile(stRootPath,'local','tmp', ...
                      sprintf('AllV04_multiSiteAndMeas_%s.mat',collectionName));
save(fname, 'dt')
% Upload the data to the server, as attachment to the collection that generated it
st   = scitran('stanfordlabs'); st.verify;
cc   = st.search('collection','collection label exact',collectionName);
stts = st.fileUpload(fname,cc{1}.collection.id,'collection');

%% Read the data locally for analyses
paperPath  = '/Users/glerma/gDrive/STANFORD/PROJECTS/2019 RTP_Methods/ScientificData/';
saveItHere = string(fullfile(paperPath,'Figures','raw'));
dataPath   = string(fullfile(paperPath,'DATA'));
if ~exist(saveItHere); mkdir(saveItHere); end
if ~exist(dataPath); mkdir(dataPath); end

% Read the data 
% (check if there is a local cache, otherwise download it from FW
DataVersion    = '04';
collectionName = 'ComputationalReproducibility';
measure        = 'multiSiteAndMeas';
fname          = sprintf('AllV%s_%s_%s.mat',DataVersion, measure, collectionName);
localfname     = fullfile(rootPath,'local',fname);
if exist(localfname,'file')
    data       = load(localfname);
else  % Download it from the Flywheel collection attachment
    serverName = 'stanfordlabs';
    st         = scitran(serverName);
    cc         = st.search('collection','collection label contains',collectionName);
    data       = load(st.fw.downloadFileFromCollection(cc{1}.collection.id,fname,localfname));
end

%% Checks and conversions
DT      = data.dt;
% Rename project names coming from FW
DT.Proj = renamecats(DT.Proj,'HCP_preproc','HCP');
DT.Proj = renamecats(DT.Proj,'PRATIK','WHL');
DT.Proj = renamecats(DT.Proj,'Weston Havens','YWM');
% Change the names of the TRT fields
DT.TRT(DT.Proj=="WHL") = 'TEST';
DT.TRT(DT.Proj=="YWM")   = 'TEST';
DT.TRT = removecats(DT.TRT);

okk = @(x)  x;
unique(varfun(okk,DT,'GroupingVariables',{'Proj','SubjID','TRT'},'InputVariables',{'TRT'}))


summary(DT)


% Plot some tests
figure(1)
subplot(2,2,1)
plot(mean(DT{DT.Struct=='LeftArcuate','fa'}',2)); hold on;
plot(mean(DT{DT.Struct=='RightArcuate','fa'}',2))
title('FA LeftRightArcuate'); xlabel('Profile divisions'); ylabel('FA')
legend({'mean Left','mean Right'})
subplot(2,2,2)
plot(mean(DT{DT.Struct=='LeftArcuate','md'}',2)); hold on;
plot(mean(DT{DT.Struct=='RightArcuate','md'}',2))
title('MD LeftRightArcuate'); xlabel('Profile divisions'); ylabel('MD')
legend({'mean Left','mean Right'})
subplot(2,2,3)
plot(mean(DT{DT.Struct=='LeftArcuate','rd'}',2)); hold on;
plot(mean(DT{DT.Struct=='RightArcuate','rd'}',2))
title('RD LeftRightArcuate'); xlabel('Profile divisions'); ylabel('RD')
legend({'mean Left','mean Right'})
subplot(2,2,4)
plot(mean(DT{DT.Struct=='LeftArcuate','volume'}',2)); hold on;
plot(mean(DT{DT.Struct=='RightArcuate','volume'}',2))
title('VOL LeftRightArcuate'); xlabel('Profile divisions'); ylabel('VOLUME')
legend({'mean Left','mean Right'})





%% WRITE FILES FOR SCI-DATA
% AS MAT
% Time stamp: 
timeStamp  = string(datetime('now','Format','yyyy-MM-dd''T''HH-mm'));
ext        = '.mat';
fname      = sprintf('AllV04_multiSiteAndMeas_ComputationalReproducibility_%s%s',timeStamp,ext);
fpname     = fullfile(dataPath, fname);
save(fpname,'DT')


% AS JSON
% Select filename to be saved
ext        = '.json';
fname      = sprintf('AllV04_multiSiteAndMeas_ComputationalReproducibility_%s%s',timeStamp,ext);
fpname     = fullfile(dataPath, fname);
% Encode json
jsonString = jsonencode(DT);
% Format a little bit
jsonString = strrep(jsonString, ',', sprintf(',\n'));
jsonString = strrep(jsonString, '[{', sprintf('[\n{\n'));
jsonString = strrep(jsonString, '}]', sprintf('\n}\n]'));
% Write it
fid = fopen(fpname,'w');if fid == -1,error('Cannot create JSON file');end
fwrite(fid, jsonString,'char');fclose(fid);

