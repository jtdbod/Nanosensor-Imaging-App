function[] = generateReport(app)

outputFile = strcat(app.results.imageStackInfo.fileName(1:end-4),'-Report_Summary.pdf');
outputPath = app.results.imageStackInfo.pathName;
results = app.results;
assignin('base','results',results);
publish('reportScript.m','outputDir',outputPath,'showCode',false,...
    'createThumbnail',false,'format','pdf',...
    'figureSnapMethod','print',...
    'codeToEvaluate','x=results;reportScript(x)');
movefile(strcat(outputPath,'reportScript.pdf'),strcat(outputPath,outputFile));