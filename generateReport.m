%function[] = generateReport(pathname,filename)
%%
outputFile = strcat(results.imageStackInfo.fileName(1:end-4),'-Report_Summary.pdf');
outputPath = results.imageStackInfo.pathName;
publish('reportScript.m','outputDir',outputPath,'showCode',false,...
    'createThumbnail',false,'format','pdf',...
    'figureSnapMethod','print')
movefile(strcat(outputPath,'reportScript.pdf'),strcat(outputPath,outputFile));