% converts the CSV files of QPID into a MAT file, using the correct formats and encoding

%% import database tables
sites   = readtable('../../data/sites.csv');
samples = readtable('../../data/samples.csv','Format','%s%f%f%s%s%s%f%f');
studies = readtable('../../data/studies.csv','Format','%s%q%q%q%u%s%q%q', 'FileEncoding','UTF-8');
taxa    = readtable('../../data/taxa.csv','Format','%s%s%s%s%s%s%q');
env     = readtable('../../data/env.csv','Format','%s%f');

save('../../data/compiled/qpid.mat','sites','samples','studies','taxa','env')
